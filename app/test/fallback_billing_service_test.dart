import 'package:flutter_test/flutter_test.dart';
import 'package:wina/billing/billing_service.dart';
import 'package:wina/billing/fallback_billing_service.dart';
import 'package:wina/billing/offers.dart';
import 'package:wina/billing/plan.dart';

import 'support/fake_billing_service.dart';

const PlanOffer _real = PlanOffer(
  productId: 'wina_1team_monthly',
  teams: 1,
  period: BillingPeriod.monthly,
  price: 19.5,
  currencyCode: 'EUR',
  priceString: '19,50 €',
);
const PlanOffer _demo = PlanOffer(
  productId: 'wina_1team_monthly',
  teams: 1,
  period: BillingPeriod.monthly,
  price: 4.99,
  currencyCode: 'EUR',
  priceString: '4,99 €',
);

FallbackBillingService _service(FakeBillingService primary, FakeBillingService demo, {required bool testEnabled}) =>
    FallbackBillingService(primary: primary, fallback: demo, testEnabled: () async => testEnabled);

void main() {
  test('de vraies offres RevenueCat prennent la place des prix de démonstration', () async {
    final FakeBillingService primary = FakeBillingService(offers: <PlanOffer>[_real]);
    final FakeBillingService demo = FakeBillingService(offers: <PlanOffer>[_demo]);
    final FallbackBillingService service = _service(primary, demo, testEnabled: true);

    expect(await service.loadOffers(), <PlanOffer>[_real]);
    await service.purchase('wina_1team_monthly');

    expect(primary.purchased, <String>['wina_1team_monthly']);
    expect(demo.purchased, isEmpty);
  });

  test('sans offre RevenueCat et mode test actif : prix de démonstration et achat simulé', () async {
    final FakeBillingService primary = FakeBillingService();
    final FakeBillingService demo = FakeBillingService(offers: <PlanOffer>[_demo]);
    final FallbackBillingService service = _service(primary, demo, testEnabled: true);

    expect(await service.loadOffers(), <PlanOffer>[_demo]);
    await service.purchase('wina_1team_monthly');

    expect(demo.purchased, <String>['wina_1team_monthly']);
    expect(primary.purchased, isEmpty);
  });

  test('clés RevenueCat absentes et mode test actif : prix de démonstration', () async {
    final FakeBillingService primary = FakeBillingService(available: false);
    final FakeBillingService demo = FakeBillingService(offers: <PlanOffer>[_demo]);

    expect(await _service(primary, demo, testEnabled: true).loadOffers(), <PlanOffer>[_demo]);
  });

  test('mode test inactif : clés absentes donnent BillingUnavailable, aucune offre donne une liste vide', () async {
    final FakeBillingService demo = FakeBillingService(offers: <PlanOffer>[_demo]);

    await expectLater(
      _service(FakeBillingService(available: false), demo, testEnabled: false).loadOffers(),
      throwsA(isA<BillingUnavailable>()),
    );
    expect(await _service(FakeBillingService(), demo, testEnabled: false).loadOffers(), isEmpty);
  });

  test('une erreur RevenueCat remonte quand le mode test est inactif, et se rattrape quand il est actif', () async {
    final FakeBillingService demo = FakeBillingService(offers: <PlanOffer>[_demo]);
    final _FailingService failing = _FailingService();

    await expectLater(
      FallbackBillingService(primary: failing, fallback: demo, testEnabled: () async => false).loadOffers(),
      throwsA(isA<StateError>()),
    );
    expect(
      await FallbackBillingService(primary: failing, fallback: demo, testEnabled: () async => true).loadOffers(),
      <PlanOffer>[_demo],
    );
  });

  test('une lecture illisible de l\'interrupteur vaut « désactivé »', () async {
    final FakeBillingService demo = FakeBillingService(offers: <PlanOffer>[_demo]);
    final FallbackBillingService service = FallbackBillingService(
      primary: FakeBillingService(available: false),
      fallback: demo,
      testEnabled: () async => throw StateError('hors ligne'),
    );

    await expectLater(service.loadOffers(), throwsA(isA<BillingUnavailable>()));
  });

  test('la source suit le dernier chargement : les vraies offres reprennent la main', () async {
    final FakeBillingService primary = FakeBillingService();
    final FakeBillingService demo = FakeBillingService(offers: <PlanOffer>[_demo]);
    final FallbackBillingService service = _service(primary, demo, testEnabled: true);

    await service.loadOffers();
    primary.offers = <PlanOffer>[_real];
    expect(await service.loadOffers(), <PlanOffer>[_real]);
    await service.purchase('wina_1team_monthly');

    expect(primary.purchased, <String>['wina_1team_monthly']);
    expect(demo.purchased, isEmpty);
  });

  test('logIn est transmis à RevenueCat', () async {
    final FakeBillingService primary = FakeBillingService();
    await _service(primary, FakeBillingService(), testEnabled: true).logIn('uid-1');

    expect(primary.loggedIn, <String>['uid-1']);
  });
}

class _FailingService extends FakeBillingService {
  @override
  Future<List<PlanOffer>> loadOffers() async => throw StateError('RevenueCat KO');
}
