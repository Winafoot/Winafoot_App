import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/billing/access_info.dart';
import 'package:wina/billing/offers.dart';
import 'package:wina/providers/auth_providers.dart';
import 'package:wina/providers/billing_providers.dart';
import 'package:wina/view/widget/custom_back_button.dart';
import 'package:wina/view/widget/subscription_gate.dart';

import 'support/fake_billing_service.dart';

class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      json.decode(File('$path/fr-FR.json').readAsStringSync()) as Map<String, dynamic>;
}

AccessInfo _active() => AccessInfo(active: true, until: DateTime.now().add(const Duration(days: 30)));

/// Un bouton « COUP D'ENVOI » qui passe par la porte, et affiche ce qu'elle a répondu.
Widget _host({required bool enforced, required Stream<AccessInfo?> info, required ValueNotifier<String> outcome}) =>
    ProviderScope(
      overrides: <Override>[
        authUidProvider.overrideWith((ref) => Stream<String?>.value('u1')),
        paywallEnforcedProvider.overrideWith((ref) => Stream<bool>.value(enforced)),
        accessInfoProvider.overrideWith((ref) => info),
        billingServiceProvider.overrideWithValue(FakeBillingService()),
        offersProvider.overrideWith((ref) async => <int, TeamsOffer>{}),
      ],
      child: EasyLocalization(
        supportedLocales: const <Locale>[Locale('fr', 'FR')],
        startLocale: const Locale('fr', 'FR'),
        path: 'assets/translations',
        assetLoader: const _DiskAssetLoader(),
        saveLocale: false,
        child: ScreenUtilInit(
          designSize: const Size(1194, 834),
          builder: (BuildContext context, _) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            builder: (BuildContext ctx, Widget? child) => ResponsiveWrapper.builder(
              child,
              minWidth: 450,
              breakpoints: const <ResponsiveBreakpoint>[
                ResponsiveBreakpoint.tag(800, name: PHONE),
                ResponsiveBreakpoint.tag(1100, name: TABLET),
                ResponsiveBreakpoint.tag(double.infinity, name: DESKTOP),
              ],
            ),
            home: Scaffold(
              body: Consumer(
                builder: (BuildContext context, WidgetRef ref, _) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final bool ok = await ensureCanStartMatch(context, ref);
                      outcome.value = ok ? 'LANCE' : 'REFUSE';
                    },
                    child: const Text("COUP D'ENVOI"),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

void _tablet(WidgetTester tester) {
  tester.view.physicalSize = const Size(1194, 834);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets("mur désactivé : le match se lance sans écran de paiement", (WidgetTester tester) async {
    _tablet(tester);
    final ValueNotifier<String> outcome = ValueNotifier<String>('');
    await tester.pumpWidget(_host(enforced: false, info: Stream<AccessInfo?>.value(const AccessInfo()), outcome: outcome));
    await tester.pumpAndSettle();

    await tester.tap(find.text("COUP D'ENVOI"));
    await tester.pumpAndSettle();

    expect(outcome.value, 'LANCE');
    expect(find.text('Choisissez votre formule'), findsNothing);
  });

  testWidgets("abonnement actif : le match se lance sans écran de paiement", (WidgetTester tester) async {
    _tablet(tester);
    final ValueNotifier<String> outcome = ValueNotifier<String>('');
    await tester.pumpWidget(_host(enforced: true, info: Stream<AccessInfo?>.value(_active()), outcome: outcome));
    await tester.pumpAndSettle();

    await tester.tap(find.text("COUP D'ENVOI"));
    await tester.pumpAndSettle();

    expect(outcome.value, 'LANCE');
    expect(find.text('Choisissez votre formule'), findsNothing);
  });

  testWidgets("sans abonnement : le paiement s'ouvre, et le retour annule le lancement", (WidgetTester tester) async {
    _tablet(tester);
    final ValueNotifier<String> outcome = ValueNotifier<String>('');
    await tester.pumpWidget(_host(enforced: true, info: Stream<AccessInfo?>.value(const AccessInfo()), outcome: outcome));
    await tester.pumpAndSettle();

    await tester.tap(find.text("COUP D'ENVOI"));
    await tester.pumpAndSettle();

    expect(outcome.value, '');
    expect(find.text('Choisissez votre formule'), findsOneWidget);
    expect(find.textContaining('Pour lancer un match'), findsOneWidget);

    // L'écran est refermable : le retour annule le lancement du match.
    await tester.tap(find.byType(CustomBackButton));
    await tester.pumpAndSettle();
    expect(outcome.value, 'REFUSE');
  });

  testWidgets("sans abonnement : dès que l'accès devient actif, l'écran se referme et le match se lance", (WidgetTester tester) async {
    _tablet(tester);
    final ValueNotifier<String> outcome = ValueNotifier<String>('');
    final StreamController<AccessInfo?> access = StreamController<AccessInfo?>();
    addTearDown(access.close);
    access.add(const AccessInfo());
    await tester.pumpWidget(_host(enforced: true, info: access.stream, outcome: outcome));
    await tester.pumpAndSettle();

    await tester.tap(find.text("COUP D'ENVOI"));
    await tester.pumpAndSettle();
    expect(find.text('Choisissez votre formule'), findsOneWidget);

    // Le webhook d'achat pose users/{uid}.access : l'écran de paiement se referme et le lancement se poursuit.
    access.add(_active());
    await tester.pumpAndSettle();

    expect(outcome.value, 'LANCE');
    expect(find.text('Choisissez votre formule'), findsNothing);
  });
}
