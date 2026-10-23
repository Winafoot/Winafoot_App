import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/billing/billing_service.dart';
import 'package:wina/billing/offers.dart';
import 'package:wina/billing/plan.dart';
import 'package:wina/providers/billing_providers.dart';

import 'support/fake_billing_service.dart';

void main() {
  test('offersProvider expose les offres du service, triées par équipes', () async {
    final FakeBillingService fake = FakeBillingService(offers: <PlanOffer>[
      const PlanOffer(productId: 'wina_team2_monthly', teams: 2, period: BillingPeriod.monthly, price: 29.25, currencyCode: 'EUR', priceString: '29,25 €'),
      const PlanOffer(productId: 'wina_team1_monthly', teams: 1, period: BillingPeriod.monthly, price: 19.5, currencyCode: 'EUR', priceString: '19,50 €'),
    ]);
    final ProviderContainer c = ProviderContainer(overrides: <Override>[billingServiceProvider.overrideWithValue(fake)]);
    addTearDown(c.dispose);

    final Map<int, TeamsOffer> offers = await c.read(offersProvider.future);

    expect(offers.keys.toList(), <int>[1, 2]);
  });

  test('un service indisponible donne une erreur BillingUnavailable', () async {
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      billingServiceProvider.overrideWithValue(FakeBillingService(available: false)),
    ]);
    addTearDown(c.dispose);

    await expectLater(c.read(offersProvider.future), throwsA(isA<BillingUnavailable>()));
  });
}
