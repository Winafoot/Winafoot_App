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
import 'package:wina/data/linked_team_repository.dart';
import 'package:wina/providers/auth_providers.dart';
import 'package:wina/providers/billing_providers.dart';
import 'package:wina/view/page/access_guard.dart';

import 'support/fake_billing_service.dart';

class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      json.decode(File('$path/fr-FR.json').readAsStringSync()) as Map<String, dynamic>;
}

AccessInfo _info({bool active = true, String? ownerUid, int? teamsAllowed = 1}) => AccessInfo(
  active: active,
  until: DateTime.now().add(Duration(days: active ? 30 : -1)),
  ownerUid: ownerUid,
  teamIndex: ownerUid == null ? null : 2,
  teamsAllowed: teamsAllowed,
);

Widget _host({
  required bool enforced,
  AccessInfo? info,
  FakeBillingService? billing,
  List<LinkedTeam> linked = const <LinkedTeam>[],
}) => ProviderScope(
  overrides: <Override>[
    authUidProvider.overrideWith((ref) => Stream<String?>.value('u1')),
    paywallEnforcedProvider.overrideWith((ref) => Stream<bool>.value(enforced)),
    accessInfoProvider.overrideWith((ref) => Stream<AccessInfo?>.value(info)),
    linkedTeamsProvider.overrideWith((ref) => Stream<List<LinkedTeam>>.value(linked)),
    billingServiceProvider.overrideWithValue(billing ?? FakeBillingService()),
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
        // La bannière de notification (NotifBanner) exige un ResponsiveWrapper, présent dans l'app réelle.
        builder: (BuildContext ctx, Widget? child) => ResponsiveWrapper.builder(
          child,
          minWidth: 450,
          breakpoints: const <ResponsiveBreakpoint>[
            ResponsiveBreakpoint.tag(800, name: PHONE),
            ResponsiveBreakpoint.tag(1100, name: TABLET),
            ResponsiveBreakpoint.tag(double.infinity, name: DESKTOP),
          ],
        ),
        home: const AccessGuard(child: Text('APP OUVERTE')),
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
  testWidgets('mur désactivé : l\'app s\'ouvre sans accès', (WidgetTester tester) async {
    _tablet(tester);
    await tester.pumpWidget(_host(enforced: false, info: const AccessInfo()));
    await tester.pumpAndSettle();
    expect(find.text('APP OUVERTE'), findsOneWidget);
  });

  testWidgets('mur activé, propriétaire sans accès : écran Abonnement', (WidgetTester tester) async {
    _tablet(tester);
    await tester.pumpWidget(_host(enforced: true, info: _info(active: false)));
    await tester.pumpAndSettle();
    expect(find.text('APP OUVERTE'), findsNothing);
    // L'écran Abonnement s'affiche même sans offres (le titre est toujours présent).
    expect(find.text('Choisissez votre formule'), findsOneWidget);
    expect(find.text('Abonnement'), findsOneWidget);
  });

  testWidgets('mur activé, compte lié sans accès : équipe bloquée', (WidgetTester tester) async {
    _tablet(tester);
    await tester.pumpWidget(_host(enforced: true, info: _info(active: false, ownerUid: 'o1')));
    await tester.pumpAndSettle();
    expect(find.text('Abonnement du propriétaire inactif'), findsOneWidget);
    expect(find.text('APP OUVERTE'), findsNothing);
  });

  testWidgets('mur activé, accès actif : l\'app s\'ouvre', (WidgetTester tester) async {
    _tablet(tester);
    await tester.pumpWidget(_host(enforced: true, info: _info()));
    await tester.pumpAndSettle();
    expect(find.text('APP OUVERTE'), findsOneWidget);
  });

  testWidgets('un propriétaire est rattaché à RevenueCat, pas un compte lié', (WidgetTester tester) async {
    _tablet(tester);
    final FakeBillingService owner = FakeBillingService();
    await tester.pumpWidget(_host(enforced: true, info: _info(), billing: owner));
    await tester.pumpAndSettle();
    expect(owner.loggedIn, <String>['u1']);

    final FakeBillingService linked = FakeBillingService();
    await tester.pumpWidget(_host(enforced: true, info: _info(ownerUid: 'o1'), billing: linked));
    await tester.pumpAndSettle();
    expect(linked.loggedIn, isEmpty);
  });

  testWidgets('chargement des données : un indicateur, jamais l\'app ni le mur', (WidgetTester tester) async {
    _tablet(tester);
    await tester.pumpWidget(_host(enforced: true, info: null));
    await tester.pump();
    expect(find.text('APP OUVERTE'), findsNothing);
  });
}
