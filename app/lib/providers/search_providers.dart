import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:wina/data/search/search_key.dart';
import 'package:wina/data/search/search_service.dart';
import 'package:wina/providers/auth_providers.dart';

/// Récupération de la clé de recherche (callable `getSearchKey`) : surchargeable
/// en test pour éviter Firebase.
final searchKeyFetcherProvider = Provider<Future<SearchKey> Function()>(
  (ref) => fetchSearchKey,
);

/// Client HTTP des requêtes Algolia, fermé avec le provider : surchargeable en
/// test (faux client).
final searchHttpClientProvider = Provider<http.Client>((ref) {
  final http.Client client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Service de recherche Algolia (compositions, matchs), en complément du filtre
/// local des écrans.
///
/// Rien n'est touché à la construction : ni Firebase, ni réseau. Le callable
/// `getSearchKey` n'est appelé qu'à la première requête non vide. Le compte
/// connecté ([authUidProvider]) est transmis au service, qui jette sa clé au
/// changement de compte ou à la déconnexion.
///
/// Les tests d'écran le surchargent par un faux service (`overrideWithValue`).
final searchServiceProvider = Provider<SearchService>((ref) {
  final SearchService service = SearchService(
    fetchKey: ref.read(searchKeyFetcherProvider),
    httpClient: ref.read(searchHttpClientProvider),
  );
  ref.listen<AsyncValue<String?>>(
    authUidProvider,
    (_, AsyncValue<String?> next) => service.setUid(next.valueOrNull),
    fireImmediately: true,
  );
  return service;
});
