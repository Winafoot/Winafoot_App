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
    this.trialEligible = false,
  });

  final String productId;
  final int teams;
  final BillingPeriod period;
  final double price;
  final String currencyCode;

  /// Prix tel que le store l'affiche (devise et séparateurs de l'utilisateur).
  final String priceString;

  /// Vrai si l'essai gratuit s'applique à CET utilisateur (un seul essai par compte, géré par le store) :
  /// la promesse « jours gratuits » ne s'affiche que dans ce cas.
  final bool trialEligible;
}

/// Les deux périodes d'une formule à N équipes.
class TeamsOffer {
  const TeamsOffer(this.teams, {this.monthly, this.yearly});

  final int teams;
  final PlanOffer? monthly;
  final PlanOffer? yearly;

  /// Au moins une des deux formules offre l'essai gratuit à cet utilisateur.
  bool get hasTrial =>
      (monthly?.trialEligible ?? false) || (yearly?.trialEligible ?? false);

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
