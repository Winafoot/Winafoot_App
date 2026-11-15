import 'package:intl/intl.dart';
import 'package:wina/billing/plan.dart';

/// Un produit à la vente, avec le prix renvoyé par le store (jamais écrit en dur).
class PlanOffer {
  const PlanOffer({
    required this.productId,
    required this.teams,
    required this.period,
    required this.price,
    required this.currencyCode,
    required this.priceString,
    this.promoPrices = const <String, String>{},
    this.regularPriceString,
  });

  final String productId;
  final int teams;
  final BillingPeriod period;
  final double price;
  final String currencyCode;

  /// Prix tel que le store l'affiche (devise et séparateurs de l'utilisateur).
  final String priceString;

  /// Android : tag d'offre (posé dans la Play Console) -> prix de la phase d'introduction de cette offre,
  /// tel que le store l'affiche. Sert à montrer le prix remisé une fois un code promo validé.
  final Map<String, String> promoPrices;

  /// Renseigné quand [priceString] est le prix remisé d'un code promo : le prix normal, affiché « au lieu de ».
  final String? regularPriceString;

  /// Cette offre avec, pour prix affiché, celui de l'offre portant [tag] ; inchangée si le tag n'a pas de prix.
  /// Seul l'affichage change : l'achat reste fait sur l'offre du tag (voir `BillingService.purchase`).
  PlanOffer withPromo(String? tag) {
    final String? promo = tag == null ? null : promoPrices[tag];
    if (promo == null) return this;
    return PlanOffer(
      productId: productId,
      teams: teams,
      period: period,
      price: price,
      currencyCode: currencyCode,
      priceString: promo,
      promoPrices: promoPrices,
      regularPriceString: priceString,
    );
  }
}

/// Les deux périodes d'une formule à N équipes.
class TeamsOffer {
  const TeamsOffer(this.teams, {this.monthly, this.yearly});

  final int teams;
  final PlanOffer? monthly;
  final PlanOffer? yearly;

  /// Prix barré de l'annuel : douze mensualités. `null` sans offre mensuelle.
  double? get yearlyFullPrice => monthly == null ? null : monthly!.price * 12;

  /// « soit X € par mois » de l'annuel.
  double? get yearlyPerMonth => yearly == null ? null : yearly!.price / 12;

  /// « soit X € par équipe » du mensuel.
  double? get monthlyPerTeam => monthly == null ? null : monthly!.price / teams;
}

Map<int, TeamsOffer> groupOffers(Iterable<PlanOffer> offers) {
  final Map<int, TeamsOffer> out = <int, TeamsOffer>{};
  for (final PlanOffer o in offers) {
    final TeamsOffer prev = out[o.teams] ?? TeamsOffer(o.teams);
    out[o.teams] = TeamsOffer(
      o.teams,
      monthly: o.period == BillingPeriod.monthly ? o : prev.monthly,
      yearly: o.period == BillingPeriod.yearly ? o : prev.yearly,
    );
  }
  return out;
}

/// Montant dérivé affiché en français. Arrondi au centime, demi vers le haut : 16,575 s'affiche 16,58
/// (comme les maquettes), pas 16,57 à cause de la représentation binaire.
String formatMoney(double amount, String currencyCode) {
  final double rounded = ((amount * 100) + 1e-9).round() / 100;
  return NumberFormat.simpleCurrency(
    locale: 'fr_FR',
    name: currencyCode,
  ).format(rounded);
}
