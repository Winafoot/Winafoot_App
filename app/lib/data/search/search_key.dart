import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:wina/config/skeleton_config.dart';

/// Clé de recherche Algolia sécurisée (durée de vie 1 h), délivrée par le
/// callable `getSearchKey` : elle ne donne accès qu'aux données du coach connecté.
///
/// Gardée en mémoire seulement : jamais écrite sur disque, jamais journalisée.
@immutable
class SearchKey {
  const SearchKey({
    required this.appId,
    required this.apiKey,
    required this.ttlSeconds,
    required this.compositionsIndex,
    required this.matchesIndex,
  });

  /// Lit la réponse du callable `{ appId, apiKey, ttlSeconds, indices }`.
  ///
  /// Lève une [FormatException] si un champ manque ou n'a pas le bon type : le
  /// service de recherche retombe alors sur le filtre local. `expiresAt` est
  /// volontairement ignoré (horloge de l'appareil non fiable), seul
  /// `ttlSeconds` sert à l'échéance.
  factory SearchKey.fromCallable(Object? data) {
    if (data is! Map) throw const FormatException('Clé de recherche absente.');
    final Object? indices = data['indices'];
    final Object? appId = data['appId'];
    final Object? apiKey = data['apiKey'];
    final Object? ttl = data['ttlSeconds'];
    if (indices is! Map ||
        appId is! String ||
        appId.isEmpty ||
        apiKey is! String ||
        apiKey.isEmpty ||
        ttl is! int ||
        indices['compositions'] is! String ||
        indices['matches'] is! String) {
      throw const FormatException('Clé de recherche invalide.');
    }
    return SearchKey(
      appId: appId,
      apiKey: apiKey,
      ttlSeconds: ttl,
      compositionsIndex: indices['compositions'] as String,
      matchesIndex: indices['matches'] as String,
    );
  }

  final String appId;
  final String apiKey;
  final int ttlSeconds;
  final String compositionsIndex;
  final String matchesIndex;
}

/// Demande une clé de recherche au callable `getSearchKey`.
///
/// À n'appeler qu'au premier besoin (requête non vide), jamais pendant un
/// `build` : le callable exige Firebase initialisé.
Future<SearchKey> fetchSearchKey() async {
  final HttpsCallableResult<dynamic> result =
      await FirebaseFunctions.instanceFor(region: kCloudRegion)
          .httpsCallable(
            'getSearchKey',
            // Délai court : le défaut du plugin (60 s) bloquerait toutes les
            // recherches, qui attendent le même appel en vol.
            options: HttpsCallableOptions(timeout: const Duration(seconds: 5)),
          )
          .call<dynamic>();
  return SearchKey.fromCallable(result.data);
}
