/// Produits d'abonnement Wina : `wina_<1|2|3>team[s]_<monthly|annual>` (App Store Connect : `wina_1team_monthly`,
/// `wina_3teams_annual`...), ou l'ancienne écriture `wina_team<n>_<monthly|yearly>`. « annual » vaut yearly.
/// Sur Google Play, RevenueCat expose « identifiant de l'abonnement:identifiant du plan » : le séparateur peut
/// être `:` et un identifiant de plan de base peut suivre (`wina_3teams_annual:p1y`).
/// Même motif que `parseProduct` côté serveur (functions/src/billing/subscription.ts).
enum BillingPeriod { monthly, yearly }

class PlanProduct {
  const PlanProduct(this.teams, this.period);

  final int teams;
  final BillingPeriod period;

  static final RegExp _pattern = RegExp(r'^wina_(?:team([123])|([123])teams?)[_:](monthly|yearly|annual)(?::[a-z0-9_.-]+)?$');

  static PlanProduct? parse(String? productId) {
    if (productId == null) return null;
    final RegExpMatch? m = _pattern.firstMatch(productId);
    if (m == null) return null;
    return PlanProduct(
      int.parse((m.group(1) ?? m.group(2))!),
      m.group(3) == 'monthly' ? BillingPeriod.monthly : BillingPeriod.yearly,
    );
  }
}
