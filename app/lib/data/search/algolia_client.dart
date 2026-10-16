import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:wina/data/search/search_key.dart';

/// Réponse d'une recherche : [ids] vaut `null` quand la recherche est
/// indisponible (non-2xx, JSON invalide, délai, réseau) ; un ensemble vide
/// signifie « Algolia a répondu, sans résultat ».
class AlgoliaReply {
  const AlgoliaReply({this.ids, this.authRejected = false});

  final Set<String>? ids;

  /// Vrai sur un 401/403 : la clé est périmée ou refusée, à renouveler.
  final bool authRejected;
}

/// Client minimal de l'API Search d'Algolia (aucun SDK) : un POST sur l'hôte DSN.
///
/// Ne lève jamais : toute défaillance devient une [AlgoliaReply] sans `ids`, et
/// l'écran garde son filtre local. Aucun message d'erreur n'est conservé, la
/// clé n'apparaît ni dans l'URL ni dans un journal.
class AlgoliaClient {
  AlgoliaClient(this._http, {this.timeout = const Duration(seconds: 3)});

  final http.Client _http;

  /// Abandonne seulement la requête Algolia : l'écran affiche déjà le local.
  final Duration timeout;

  Future<AlgoliaReply> search(SearchKey key, String index, String query) async {
    final Uri url = Uri.https(
      '${key.appId}-dsn.algolia.net',
      '/1/indexes/${Uri.encodeComponent(index)}/query',
    );
    try {
      final http.Response response = await _http
          .post(
            url,
            headers: <String, String>{
              'X-Algolia-Application-Id': key.appId,
              'X-Algolia-API-Key': key.apiKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, Object>{
              'query': query,
              'hitsPerPage': 100,
              'attributesToRetrieve': <String>['docId'],
              'attributesToHighlight': <String>[],
              'analytics': false,
            }),
          )
          .timeout(timeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        return const AlgoliaReply(authRejected: true);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const AlgoliaReply();
      }
      return AlgoliaReply(ids: _parseIds(response.body));
    } on Object {
      // Réseau, délai, certificat… : repli silencieux sur le filtre local.
      return const AlgoliaReply();
    }
  }

  /// Identifiants `docId` des hits, ou `null` si le corps n'a pas la forme
  /// attendue.
  static Set<String>? _parseIds(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (decoded is! Map || decoded['hits'] is! List) return null;
    return <String>{
      for (final Object? hit in decoded['hits'] as List<Object?>)
        if (hit is Map && hit['docId'] is String) hit['docId'] as String,
    };
  }
}
