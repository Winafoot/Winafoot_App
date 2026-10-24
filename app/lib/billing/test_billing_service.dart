import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:wina/billing/billing_service.dart';
import 'package:wina/billing/offers.dart';
import 'package:wina/billing/plan.dart';
import 'package:wina/config/skeleton_config.dart';

/// Achats simulés, pour tester le parcours d'abonnement tant que les produits des stores ne sont pas
/// disponibles. Activé par `--dart-define=TEST_BILLING=true`, JAMAIS dans un build release.
///
/// `purchase` appelle le callable `grantTestSubscription`, qui pose `subscription` et `access` sur le compte
/// comme le webhook RevenueCat. Le serveur le refuse tant que `TEST_PURCHASES_ENABLED` n'y est pas activé.
class TestBillingService implements BillingService {
  static const bool _enabled = bool.fromEnvironment('TEST_BILLING');

  /// Mode test demandé ET build non release : un build release ignore le drapeau.
  static bool get isActive => _enabled && !kReleaseMode;

  /// Prix factices, à remplacer par ceux du store quand les produits existent.
  static const Map<int, (double, double)> _prices = <int, (double, double)>{
    1: (4.99, 49.99),
    2: (7.99, 79.99),
    3: (9.99, 99.99),
  };

  @override
  bool get isAvailable => isActive;

  @override
  Future<void> logIn(String uid) async {}

  @override
  Future<List<PlanOffer>> loadOffers() async {
    final List<PlanOffer> out = <PlanOffer>[];
    _prices.forEach((int teams, (double, double) p) {
      out.add(
        _offer(
          'wina_${teams}team${teams > 1 ? 's' : ''}_monthly',
          teams,
          BillingPeriod.monthly,
          p.$1,
        ),
      );
      out.add(
        _offer(
          'wina_${teams}team${teams > 1 ? 's' : ''}_annual',
          teams,
          BillingPeriod.yearly,
          p.$2,
        ),
      );
    });
    return out;
  }

  PlanOffer _offer(
    String productId,
    int teams,
    BillingPeriod period,
    double price,
  ) => PlanOffer(
    productId: productId,
    teams: teams,
    period: period,
    price: price,
    currencyCode: 'EUR',
    priceString: formatMoney(price, 'EUR'),
  );

  @override
  Future<PurchaseResult> purchase(String productId) async {
    if (!isActive) throw const BillingUnavailable();
    try {
      await FirebaseFunctions.instanceFor(region: kCloudRegion)
          .httpsCallable('grantTestSubscription')
          .call<dynamic>(<String, dynamic>{'productId': productId});
      return PurchaseResult.purchased;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition' &&
          e.message == 'test-purchases-disabled') {
        throw const BillingException(
          'Les achats de test sont désactivés sur ce serveur.',
        );
      }
      throw BillingException(e.message ?? 'L\'achat de test a échoué.');
    }
  }

  /// Rien à restaurer : l'abonnement de test vit déjà sur la fiche du compte.
  @override
  Future<bool> restore() async => false;
}
