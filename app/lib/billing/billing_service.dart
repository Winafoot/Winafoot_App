import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show PlatformException;
// Le SDK expose sa propre classe `PurchaseResult` : on la masque pour garder notre enum.
import 'package:purchases_flutter/purchases_flutter.dart' hide PurchaseResult;
import 'package:wina/billing/offers.dart';
import 'package:wina/billing/plan.dart';

enum PurchaseResult { purchased, cancelled }

/// Échec d'un achat ou d'une restauration (message lisible par l'utilisateur).
class BillingException implements Exception {
  const BillingException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Les achats ne sont pas configurés (clés RevenueCat absentes du build) ou pas disponibles.
class BillingUnavailable implements Exception {
  const BillingUnavailable();
  @override
  String toString() => 'Achats indisponibles';
}

/// Frontière unique avec le SDK d'achat : le reste de l'app ne connaît pas `purchases_flutter`.
abstract class BillingService {
  bool get isAvailable;

  /// Rattache les achats à l'uid Firebase du PROPRIÉTAIRE (c'est l'`app_user_id` du webhook).
  Future<void> logIn(String uid);

  Future<List<PlanOffer>> loadOffers();

  /// [replacingProductId] : abonnement en cours que le nouveau remplace (changement de formule) ;
  /// [deferred] : le changement prend effet au prochain renouvellement (rétrogradation) au lieu d'être immédiat.
  Future<PurchaseResult> purchase(
    String productId, {
    String? replacingProductId,
    bool deferred = false,
  });

  /// `true` si un abonnement a été retrouvé.
  Future<bool> restore();
}

/// Implémentation RevenueCat. Clés publiques injectées au build :
/// `--dart-define=RC_IOS_KEY=appl_…` et `--dart-define=RC_ANDROID_KEY=goog_…`.
class RevenueCatBillingService implements BillingService {
  RevenueCatBillingService();

  static const String _iosKey = String.fromEnvironment('RC_IOS_KEY');
  static const String _androidKey = String.fromEnvironment('RC_ANDROID_KEY');

  bool _configured = false;

  String get _key =>
      defaultTargetPlatform == TargetPlatform.iOS ? _iosKey : _androidKey;

  @override
  bool get isAvailable => _key.isNotEmpty;

  Future<void> _ensureConfigured() async {
    if (!isAvailable) throw const BillingUnavailable();
    if (_configured) return;
    await Purchases.configure(PurchasesConfiguration(_key));
    _configured = true;
  }

  @override
  Future<void> logIn(String uid) async {
    if (!isAvailable) return;
    await _ensureConfigured();
    await Purchases.logIn(uid);
  }

  Package? _package(Offerings offerings, String productId) {
    for (final Package p
        in offerings.current?.availablePackages ?? const <Package>[]) {
      if (p.storeProduct.identifier == productId) return p;
    }
    return null;
  }

  @override
  Future<List<PlanOffer>> loadOffers() async {
    await _ensureConfigured();
    final Offerings offerings = await Purchases.getOfferings();
    final List<Package> packages =
        offerings.current?.availablePackages ?? const <Package>[];
    final Set<String> eligible = await _trialEligibleIds(packages);
    final List<PlanOffer> out = <PlanOffer>[];
    for (final Package p in packages) {
      final StoreProduct product = p.storeProduct;
      final PlanProduct? plan = PlanProduct.parse(product.identifier);
      if (plan == null) continue;
      out.add(
        PlanOffer(
          productId: product.identifier,
          teams: plan.teams,
          period: plan.period,
          price: product.price,
          currencyCode: product.currencyCode,
          priceString: product.priceString,
          trialEligible: eligible.contains(product.identifier),
        ),
      );
    }
    return out;
  }

  /// Produits dont l'essai gratuit est offert à cet utilisateur. iOS : éligibilité calculée par le SDK
  /// (un seul essai par groupe d'abonnement). Android : le SDK ne sait pas la calculer ; Google ne propose la
  /// phase gratuite dans l'option par défaut qu'aux comptes encore éligibles. En cas de doute : pas d'essai
  /// annoncé, jamais l'inverse (on ne promet pas un essai à quelqu'un qui serait débité aussitôt).
  Future<Set<String>> _trialEligibleIds(List<Package> packages) async {
    final Set<String> out = <String>{};
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final Map<String, IntroEligibility> map =
            await Purchases.checkTrialOrIntroductoryPriceEligibility(<String>[
              for (final Package p in packages) p.storeProduct.identifier,
            ]);
        map.forEach((String id, IntroEligibility e) {
          if (e.status ==
              IntroEligibilityStatus.introEligibilityStatusEligible) {
            out.add(id);
          }
        });
      } else {
        for (final Package p in packages) {
          if (p.storeProduct.defaultOption?.freePhase != null) {
            out.add(p.storeProduct.identifier);
          }
        }
      }
    } catch (_) {
      // Éligibilité inconnue : aucun essai annoncé.
    }
    return out;
  }

  @override
  Future<PurchaseResult> purchase(
    String productId, {
    String? replacingProductId,
    bool deferred = false,
  }) async {
    await _ensureConfigured();
    final Package? package = _package(
      await Purchases.getOfferings(),
      productId,
    );
    if (package == null)
      throw const BillingException(
        'Cette formule n\'est pas disponible pour le moment.',
      );
    try {
      // Changement de formule : sur Android, remplace l'abonnement en cours (immédiat avec prorata pour une
      // formule supérieure, au renouvellement pour une inférieure). iOS gère le changement dans le groupe.
      await Purchases.purchase(
        PurchaseParams.package(
          package,
          productChangeInfo:
              replacingProductId == null
                  ? null
                  : StoreProductChangeInfo(
                    replacingProductId,
                    replacementMode:
                        deferred
                            ? StoreReplacementMode.deferred
                            : StoreReplacementMode.chargeProratedPrice,
                  ),
        ),
      );
      return PurchaseResult.purchased;
    } on PlatformException catch (e) {
      final PurchasesErrorCode code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError)
        return PurchaseResult.cancelled;
      throw BillingException(e.message ?? 'L\'achat a échoué.');
    }
  }

  @override
  Future<bool> restore() async {
    await _ensureConfigured();
    try {
      final CustomerInfo info = await Purchases.restorePurchases();
      return info.entitlements.active.isNotEmpty;
    } on PlatformException catch (e) {
      throw BillingException(e.message ?? 'La restauration a échoué.');
    }
  }
}
