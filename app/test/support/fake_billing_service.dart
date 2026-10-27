import 'package:wina/billing/billing_service.dart';
import 'package:wina/billing/offers.dart';

/// Service d'achat de test : aucun SDK, résultats pilotés par le test.
class FakeBillingService implements BillingService {
  FakeBillingService({
    this.available = true,
    this.offers = const <PlanOffer>[],
    this.purchaseResult = PurchaseResult.purchased,
    this.restoreResult = false,
    this.purchaseError,
  });

  final bool available;
  List<PlanOffer> offers;
  PurchaseResult purchaseResult;
  bool restoreResult;
  Object? purchaseError;

  final List<String> loggedIn = <String>[];
  final List<String> purchased = <String>[];
  final List<String?> replacedProductIds = <String?>[];
  final List<bool> deferredPurchases = <bool>[];
  int restoreCalls = 0;

  @override
  bool get isAvailable => available;

  @override
  Future<void> logIn(String uid) async => loggedIn.add(uid);

  @override
  Future<List<PlanOffer>> loadOffers() async => offers;

  @override
  Future<PurchaseResult> purchase(
    String productId, {
    String? replacingProductId,
    bool deferred = false,
  }) async {
    if (purchaseError != null) throw purchaseError!;
    purchased.add(productId);
    replacedProductIds.add(replacingProductId);
    deferredPurchases.add(deferred);
    return purchaseResult;
  }

  @override
  Future<bool> restore() async {
    restoreCalls++;
    return restoreResult;
  }
}
