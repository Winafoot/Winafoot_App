import 'package:flutter_test/flutter_test.dart';
import 'package:wina/billing/offers.dart';
import 'package:wina/billing/plan.dart';

PlanOffer _offer(int teams, BillingPeriod period, double price) => PlanOffer(
  productId: 'wina_team${teams}_${period.name}',
  teams: teams,
  period: period,
  price: price,
  currencyCode: 'EUR',
  priceString: '$price €',
);

String _flat(String s) => s.replaceAll(RegExp(r'\s'), ' ');

void main() {
  test('groupOffers range chaque produit sous son nombre d\'équipes', () {
    final Map<int, TeamsOffer> g = groupOffers(<PlanOffer>[
      _offer(1, BillingPeriod.monthly, 19.5),
      _offer(1, BillingPeriod.yearly, 198.9),
      _offer(2, BillingPeriod.monthly, 29.25),
    ]);
    expect(g.keys.toSet(), <int>{1, 2});
    expect(g[1]!.monthly!.price, 19.5);
    expect(g[1]!.yearly!.price, 198.9);
    expect(g[2]!.yearly, isNull);
  });

  test('les montants dérivés correspondent aux maquettes', () {
    final TeamsOffer one = groupOffers(<PlanOffer>[
      _offer(1, BillingPeriod.monthly, 19.5),
      _offer(1, BillingPeriod.yearly, 198.9),
    ])[1]!;
    expect(one.yearlyFullPrice, closeTo(234.0, 1e-9));
    expect(_flat(formatMoney(one.yearlyFullPrice!, 'EUR')), '234,00 €');
    expect(_flat(formatMoney(one.yearlyPerMonth!, 'EUR')), '16,58 €');

    final TeamsOffer two = groupOffers(<PlanOffer>[
      _offer(2, BillingPeriod.monthly, 29.25),
      _offer(2, BillingPeriod.yearly, 298.35),
    ])[2]!;
    expect(_flat(formatMoney(two.yearlyFullPrice!, 'EUR')), '351,00 €');
    expect(_flat(formatMoney(two.yearlyPerMonth!, 'EUR')), '24,86 €');
    expect(_flat(formatMoney(two.monthlyPerTeam!, 'EUR')), '14,63 €');

    final TeamsOffer three = groupOffers(<PlanOffer>[
      _offer(3, BillingPeriod.monthly, 43.5),
      _offer(3, BillingPeriod.yearly, 443.7),
    ])[3]!;
    expect(_flat(formatMoney(three.yearlyPerMonth!, 'EUR')), '36,98 €');
    expect(_flat(formatMoney(three.monthlyPerTeam!, 'EUR')), '14,50 €');
  });

  test('sans offre mensuelle, pas de prix barré', () {
    final TeamsOffer only = groupOffers(<PlanOffer>[_offer(1, BillingPeriod.yearly, 198.9)])[1]!;
    expect(only.yearlyFullPrice, isNull);
    expect(only.monthlyPerTeam, isNull);
  });
}
