import 'package:flutter_test/flutter_test.dart';
import 'package:wina/billing/plan.dart';

void main() {
  group('PlanProduct.parse', () {
    test('lit un identifiant App Store', () {
      final PlanProduct? p = PlanProduct.parse('wina_team2_yearly');
      expect(p?.teams, 2);
      expect(p?.period, BillingPeriod.yearly);
    });

    test('lit un identifiant Google Play (abonnement:plan)', () {
      final PlanProduct? p = PlanProduct.parse('wina_team3:monthly');
      expect(p?.teams, 3);
      expect(p?.period, BillingPeriod.monthly);
    });

    test("lit les identifiants créés dans App Store Connect (« annual » = yearly)", () {
      const Map<String, (int, BillingPeriod)> expected = <String, (int, BillingPeriod)>{
        'wina_1team_monthly': (1, BillingPeriod.monthly),
        'wina_1team_annual': (1, BillingPeriod.yearly),
        'wina_2teams_monthly': (2, BillingPeriod.monthly),
        'wina_2teams_annual': (2, BillingPeriod.yearly),
        'wina_3teams_monthly': (3, BillingPeriod.monthly),
        'wina_3teams_annual': (3, BillingPeriod.yearly),
        // Google Play, mêmes noms, avec ou sans identifiant de plan de base.
        'wina_1team:monthly': (1, BillingPeriod.monthly),
        'wina_3teams_annual:p1y': (3, BillingPeriod.yearly),
      };
      expected.forEach((String id, (int, BillingPeriod) want) {
        final PlanProduct? p = PlanProduct.parse(id);
        expect(p?.teams, want.$1, reason: id);
        expect(p?.period, want.$2, reason: id);
      });
    });

    test('refuse tout le reste', () {
      for (final String? id in <String?>[
        null,
        '',
        'wina_team4_monthly',
        'wina_team1_weekly',
        'wina_4teams_monthly',
        'wina_0team_annual',
        'wina_2teams_weekly',
        'xwina_2teams_annual',
        'autre',
      ]) {
        expect(PlanProduct.parse(id), isNull, reason: '$id');
      }
    });
  });
}
