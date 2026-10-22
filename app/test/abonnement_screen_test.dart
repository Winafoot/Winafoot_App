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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('affiche la formule 1 équipe avec les prix du store', (WidgetTester tester) async {
    _tablet(tester);
    await tester.pumpWidget(_host(FakeBillingService(offers: _offers)));
    await tester.pumpAndSettle();

    expect(find.text('Choisissez votre formule'), findsOneWidget);
    expect(find.text('198,90 €'), findsOneWidget);
    expect(find.text('19,50 €'), findsOneWidget);
    expect(find.textContaining('234,00'), findsOneWidget); // prix barré : 12 x 19,50
    expect(find.textContaining('16,58'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('choisir 3 équipes change les prix et le texte « par équipe »', (WidgetTester tester) async {
    _tablet(tester);
    await tester.pumpWidget(_host(FakeBillingService(offers: _offers)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('3').first);
    await tester.pumpAndSettle();

    expect(find.text('443,70 €'), findsOneWidget);
    expect(find.text('43,50 €'), findsOneWidget);
    expect(find.textContaining('14,50'), findsOneWidget);
    expect(find.textContaining('vos 3 équipes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('« S\'abonner à l\'année » lance l\'achat du produit annuel choisi', (WidgetTester tester) async {
    _tablet(tester);
    final FakeBillingService fake = FakeBillingService(offers: _offers);
    await tester.pumpWidget(_host(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text("S'abonner à l'année"));
    await tester.pump();

    expect(fake.purchased, <String>['wina_team2_yearly']);
    expect(find.text('Activation de votre abonnement…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 61));
  });

  testWidgets('une annulation de l\'achat ne montre pas l\'écran d\'activation', (WidgetTester tester) async {
    _tablet(tester);
    final FakeBillingService fake = FakeBillingService(offers: _offers, purchaseResult: PurchaseResult.cancelled);
    await tester.pumpWidget(_host(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.text("S'abonner au mois"));
    await tester.pumpAndSettle();

    expect(fake.purchased, <String>['wina_team1_monthly']);
    expect(find.text('Activation de votre abonnement…'), findsNothing);
  });

  testWidgets('« Restaurer mes achats » appelle le service et prévient s\'il n\'y a rien', (WidgetTester tester) async {
    _tablet(tester);
    final FakeBillingService fake = FakeBillingService(offers: _offers);
    await tester.pumpWidget(_host(fake));
    await tester.pumpAndSettle();

    // Avec la police de test (Ahem, très large) le pied de page dépasse l'écran : on le fait défiler.
    await tester.ensureVisible(find.text('Restaurer mes achats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restaurer mes achats'));
    await tester.pumpAndSettle();

    expect(fake.restoreCalls, 1);
    expect(find.text('Aucun abonnement à restaurer sur ce compte.'), findsOneWidget);
    // La bannière s'efface après 3 s : on laisse son minuteur se terminer.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('sans clés RevenueCat : message « Achats indisponibles »', (WidgetTester tester) async {
    _tablet(tester);
    await tester.pumpWidget(_host(FakeBillingService(available: false)));
    await tester.pumpAndSettle();

    expect(find.text('Achats indisponibles pour le moment.'), findsOneWidget);
  });

  testWidgets('aucune exception de layout sur les formules 1, 2 et 3 équipes, même sur écran bas', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1194, 500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(FakeBillingService(offers: _offers)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (final String n in <String>['2', '3', '1']) {
      await tester.ensureVisible(find.text(n).first);
      await tester.tap(find.text(n).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'formule $n');
    }
  });
}
