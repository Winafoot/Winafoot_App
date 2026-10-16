import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:wina/data/search/algolia_client.dart';
import 'package:wina/data/search/search_key.dart';

/// Marge de renouvellement : la clé est redemandée 5 min avant son échéance.
const Duration _kRenewMargin = Duration(seconds: 300);

/// Pause après une erreur du callable ou un second rejet 401/403 : aucun nouvel
/// appel du callable ni de requête Algolia pendant ce délai.
const Duration _kBackoff = Duration(minutes: 5);

/// Saisie faite uniquement de chiffres, tirets et espaces (un schéma de
/// composition, ex. « 4-3-3 ») → chiffres seuls (« 433 »), la forme indexée dans
/// `formationDigits`. Toute autre saisie est seulement rognée. Vide si la saisie
/// ne contient rien d'exploitable.
String normalizeFormationQuery(String raw) {
  final String q = raw.trim();
  if (RegExp(r'^[0-9\- ]*$').hasMatch(q)) {
    return q.replaceAll(RegExp(r'[^0-9]'), '');
  }
  return q;
}

/// Une clé et son échéance, lue sur l'horloge monotone.
class _CachedKey {
  const _CachedKey(this.key, this.expiresAt);

  final SearchKey key;
  final Duration expiresAt;
}

/// Recherche Algolia des compositions et des matchs, en complément du filtre
/// local des écrans : le résultat est un ensemble de `docId`, ou `null` quand la
/// recherche est indisponible (l'écran garde alors son filtre local seul).
///
/// Gère la clé de recherche : cache MÉMOIRE, échéance = réception + `ttlSeconds`
/// − 300 s sur horloge monotone (jamais l'heure de l'appareil), un seul appel en
/// vol, jetée au changement d'uid, et un 401/403 provoque un seul
/// renouvellement. Après une erreur du callable ou un second rejet, pause de
/// 5 min (recherche indisponible, sans réseau) ; remise à zéro au changement
/// d'uid.
///
/// Aucun accès réseau ni Firebase à la construction : tout se passe au premier
/// appel avec une requête non vide.
class SearchService {
  SearchService({
    required Future<SearchKey> Function() fetchKey,
    required http.Client httpClient,
    Duration Function()? clock,
  }) : _fetchKey = fetchKey,
       _client = AlgoliaClient(httpClient),
       _clock = clock ?? _monotonicClock();

  final Future<SearchKey> Function() _fetchKey;
  final AlgoliaClient _client;
  final Duration Function() _clock;

  String? _uid;
  _CachedKey? _cached;
  Future<SearchKey?>? _inFlight;
  Duration? _pausedUntil;

  static Duration Function() _monotonicClock() {
    final Stopwatch watch = Stopwatch()..start();
    return () => watch.elapsed;
  }

  /// Compte connecté (`null` = déconnecté). Un changement jette la clé en cache
  /// ET l'appel en vol : la clé d'un compte ne sert jamais à un autre.
  void setUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _cached = null;
    _inFlight = null;
    _pausedUntil = null;
  }

  Future<Set<String>?> searchCompositions(String query) {
    final String normalized = normalizeFormationQuery(query);
    // Chiffres seuls (clavier numérique de Tester l'équipe) : le filtre local
    // les couvre déjà, inutile de payer une requête Algolia.
    if (RegExp(r'^[0-9]+$').hasMatch(normalized)) {
      return Future<Set<String>?>.value(null);
    }
    return _search(normalized, (SearchKey k) => k.compositionsIndex);
  }

  Future<Set<String>?> searchMatches(String query) =>
      _search(query.trim(), (SearchKey k) => k.matchesIndex);

  Future<Set<String>?> _search(
    String query,
    String Function(SearchKey) indexOf,
  ) async {
    if (query.isEmpty) return null;
    final Duration? pausedUntil = _pausedUntil;
    if (pausedUntil != null && _clock() < pausedUntil) return null;
    SearchKey? key = await _key();
    if (key == null) return null;
    AlgoliaReply reply = await _client.search(key, indexOf(key), query);
    if (reply.authRejected) {
      // Un seul renouvellement : un second rejet abandonne la recherche.
      _discard(key);
      key = await _key();
      if (key == null) return null;
      reply = await _client.search(key, indexOf(key), query);
      if (reply.authRejected) {
        // La clé renouvelée est refusée elle aussi : pause, clé oubliée.
        _discard(key);
        _pause();
      }
    }
    return reply.ids;
  }

  void _pause() => _pausedUntil = _clock() + _kBackoff;

  /// Oublie [rejected] s'il est encore la clé en cache (une recherche
  /// concurrente a pu la renouveler entre-temps).
  void _discard(SearchKey rejected) {
    if (identical(_cached?.key, rejected)) _cached = null;
  }

  Future<SearchKey?> _key() {
    if (_uid == null) return Future<SearchKey?>.value(null);
    final _CachedKey? cached = _cached;
    if (cached != null && _clock() < cached.expiresAt) {
      return Future<SearchKey?>.value(cached.key);
    }
    return _inFlight ??= _request();
  }

  Future<SearchKey?> _request() {
    final String uid = _uid!;
    late final Future<SearchKey?> request;
    request = _fetchOnce(uid).whenComplete(() {
      if (identical(_inFlight, request)) _inFlight = null;
    });
    return request;
  }

  Future<SearchKey?> _fetchOnce(String uid) async {
    try {
      final SearchKey key = await _fetchKey();
      // Le compte a changé pendant l'appel : réponse jetée, jamais mise en cache.
      if (_uid != uid) return null;
      final Duration ttl = Duration(seconds: key.ttlSeconds);
      _cached = _CachedKey(key, _clock() + ttl - _kRenewMargin);
      return key;
    } on Object {
      if (_uid == uid) _pause();
      return null;
    }
  }
}
