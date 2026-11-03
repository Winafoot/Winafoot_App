import 'dart:convert';
import 'dart:io';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/billing/billing_service.dart';
import 'package:wina/billing/offers.dart';
import 'package:wina/billing/plan.dart';
import 'package:wina/providers/billing_providers.dart';
import 'package:wina/view/page/abonnement_screen.dart';

import 'support/fake_billing_service.dart';

class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      json.decode(File('$path/fr-FR.json').readAsStringSync()) as Map<String, dynamic>;
}

PlanOffer _o(int teams, BillingPeriod p, double price, String label) => PlanOffer(
  productId: 'wina_team${teams}_${p.name}',
  teams: teams,
  period: p,
  price: price,
  currencyCode: 'EUR',
  priceString: label,
);

final List<PlanOffer> _offers = <PlanOffer>[
  _o(1, BillingPeriod.monthly, 19.5, '19,50 €'),
  _o(1, BillingPeriod.yearly, 198.9, '198,90 €'),
  _o(2, BillingPeriod.monthly, 29.25, '29,25 €'),
  _o(2, BillingPeriod.yearly, 298.35, '298,35 €'),
  _o(3, BillingPeriod.monthly, 43.5, '43,50 €'),
  _o(3, BillingPeriod.yearly, 443.7, '443,70 €'),
];

Widget _host(FakeBillingService fake) => ProviderScope(
  overrides: <Override>[billingServiceProvider.overrideWithValue(fake)],
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
        home: const AbonnementScreen(),
      ),
    ),
  ),
);

void _tablet(WidgetTester tester) {
  tester.view.physicalSize = const Size(1194, 834);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("téléphone : les cartes Annuel et Mensuel portent le petit texte de réduction", (WidgetTester tester) async {
    _phone(tester);
    await tester.pumpWidget(_host(FakeBillingService(offers: _offers)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Annuel : prix barré (12 mois au tarif mensuel) et équivalent par mois, comme sur la tablette.
    expect(find.textContaining("234,00"), findsOneWidget);
    expect(find.textContaining("16,58"), findsOneWidget);
    // Mensuel (1 équipe) : « pour 1 équipe ».
    expect(find.textContaining("pour 1 équipe"), findsOneWidget);

    // Le détail d'une offre s'ouvre toujours sans erreur de mise en page.
    await tester.tap(find.text("Annuel"));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text("S'abonner à l'année"), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 61));
  });
}
