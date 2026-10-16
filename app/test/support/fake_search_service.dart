import 'package:wina/data/search/search_service.dart';

/// Faux service de recherche pour les tests d'écran : aucune clé, aucun réseau.
///
/// Chaque requête reçue est consignée ; la réponse est fournie par
/// [onCompositions] / [onMatches] (par défaut : « indisponible », donc `null`).
class FakeSearchService implements SearchService {
  final List<String> compositionQueries = <String>[];
  final List<String> matchQueries = <String>[];

  Future<Set<String>?> Function(String query) onCompositions =
      (_) async => null;
  Future<Set<String>?> Function(String query) onMatches = (_) async => null;

  int get callCount => compositionQueries.length + matchQueries.length;

  @override
  void setUid(String? uid) {}

  @override
  Future<Set<String>?> searchCompositions(String query) {
    compositionQueries.add(query);
    return onCompositions(query);
  }

  @override
  Future<Set<String>?> searchMatches(String query) {
    matchQueries.add(query);
    return onMatches(query);
  }
}
