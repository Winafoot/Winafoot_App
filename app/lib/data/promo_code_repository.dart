import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wina/config/skeleton_config.dart';

/// Offre Google Play débloquée par un code promo : `tag` est celui posé sur l'offre dans la Play Console.
class PromoOffer {
  const PromoOffer({required this.tag, required this.label});

  final String tag;
  final String label;
}

/// Refus du code (message du serveur, lisible par l'utilisateur) ou panne.
class PromoCodeException implements Exception {
  const PromoCodeException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class PromoCodeRepository {
  /// Valide [code] côté serveur : actif, non expiré, pas épuisé, compte principal sans abonnement.
  static Future<PromoOffer> redeem(String code) async {
    try {
      final HttpsCallableResult<dynamic> res = await FirebaseFunctions.instanceFor(
        region: kCloudRegion,
      ).httpsCallable('redeemPromoCode').call<dynamic>(<String, dynamic>{
        'code': code,
      });
      final Map<dynamic, dynamic> data = res.data as Map<dynamic, dynamic>;
      return PromoOffer(
        tag: data['offerTag'] as String,
        label: (data['label'] as String?) ?? '',
      );
    } on FirebaseFunctionsException catch (e) {
      const Set<String> business = <String>{
        'failed-precondition',
        'permission-denied',
        'invalid-argument',
        'resource-exhausted',
      };
      throw PromoCodeException(
        business.contains(e.code) && (e.message ?? '').isNotEmpty
            ? e.message!
            : 'utils.error-default'.tr(),
      );
    } catch (_) {
      throw PromoCodeException('utils.error-default'.tr());
    }
  }
}
