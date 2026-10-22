import 'package:flutter_test/flutter_test.dart';
import 'package:wina/billing/billing_service.dart';
import 'package:wina/billing/offers.dart';
import 'package:wina/billing/plan.dart';
import 'package:wina/billing/test_billing_service.dart';

void main() {
  test('sans --dart-define=TEST_BILLING le mode test est inactif', () {
    expect(TestBillingService.isActive, isFalse);
    expect(TestBillingService().isAvailable, isFalse);
  });

  test('les offres de test couvrent 1, 2 et 3 équipes en mensuel et annuel', () async {
    final Map<int, TeamsOffer> grouped = groupOffers(await TestBillingService().loadOffers());

    expect(grouped.keys, <int>[1, 2, 3]);
    for (final TeamsOffer o in grouped.values) {
      expect(o.monthly, isNotNull);
      expect(o.yearly, isNotNull);
      expect(PlanProduct.parse(o.monthly!.productId)?.teams, o.teams);
      expect(PlanProduct.parse(o.yearly!.productId)?.period, BillingPeriod.yearly);
    }
  });

  test('un achat est refusé quand le mode test est inactif', () async {
    await expectLater(TestBillingService().purchase('wina_1team_monthly'), throwsA(isA<BillingUnavailable>()));
  });
}
