import 'package:wina/billing/billing_service.dart';
import 'package:wina/billing/offers.dart';

/// RevenueCat d'abord ; achats simulés seulement quand RevenueCat n'a aucune offre à vendre ET que
/// l'administrateur a posé `app_config/config.test_purchases_enabled` (bêta fermée, avant la création des
/// produits des stores).
///
/// Le choix se refait à chaque [loadOffers] : dès que RevenueCat renvoie de vraies offres, elles prennent
/// la place des prix de démonstration, sans nouveau build. Un achat suit la source des offres affichées.
class FallbackBillingService implements BillingService {
  FallbackBillingService({required this.primary, required this.fallback, required this.testEnabled});

  final BillingService primary;
  final BillingService fallback;

  /// Lit l'interrupteur de l'administrateur. Une erreur de lecture vaut « désactivé ».
  final Future<bool> Function() testEnabled;

  bool _usingFallback = false;

  /// Toujours vrai : l'indisponibilité (ni offres RevenueCat, ni mode test) est signalée par
  /// [loadOffers], qui lève [BillingUnavailable].
  @override
  bool get isAvailable => true;

  @override
  Future<void> logIn(String uid) => primary.logIn(uid);

  Future<bool> _testOn() async {
    try {
      return await testEnabled();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<PlanOffer>> loadOffers() async {
    Object? failure;
    if (primary.isAvailable) {
      try {
        final List<PlanOffer> offers = await primary.loadOffers();
        if (offers.isNotEmpty) {
          _usingFallback = false;
          return offers;
        }
      } catch (e) {
        failure = e;
      }
    }
    if (await _testOn()) {
      _usingFallback = true;
      return fallback.loadOffers();
    }
    _usingFallback = false;
    if (failure != null) throw failure;
    if (!primary.isAvailable) throw const BillingUnavailable();
    return const <PlanOffer>[];
  }

  @override
  Future<PurchaseResult> purchase(String productId) =>
      _usingFallback ? fallback.purchase(productId) : primary.purchase(productId);

  /// Rien à restaurer en mode simulé : l'abonnement de test vit déjà sur la fiche du compte.
  @override
  Future<bool> restore() => _usingFallback ? fallback.restore() : primary.restore();
}
