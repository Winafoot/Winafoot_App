import 'dart:async';

/// Résultats visibles d'une barre de recherche : filtre local actuel UNION les
/// éléments dont l'identifiant est renvoyé par Algolia ([remoteIds]), dans
/// l'ordre de [items].
///
/// Algolia n'AJOUTE que des correspondances (fautes de frappe, accents, ordre
/// des mots) : il ne retire jamais un résultat local. Les identifiants inconnus
/// de [items] sont ignorés, donc la liste reste bornée à ce qui est déjà chargé.
List<T> unionVisible<T>({
  required List<T> items,
  required bool Function(T item) matchesLocally,
  required String? Function(T item) idOf,
  required Set<String> remoteIds,
}) => items
    .where((T item) {
      if (matchesLocally(item)) return true;
      final String? id = idOf(item);
      return id != null && remoteIds.contains(id);
    })
    .toList(growable: false);

/// Pilote une barre de recherche « local ∪ Algolia » : temporise la saisie
/// (300 ms), applique tout de suite la requête au filtre local, puis ajoute les
/// identifiants Algolia à leur arrivée.
///
/// [onChange] reçoit la requête et les identifiants distants courants : ensemble
/// vide à chaque nouvelle requête (le local s'affiche sans attendre), puis
/// rappelé avec les identifiants si Algolia répond. Une réponse périmée (frappe
/// plus récente, effacement, [dispose]) est ignorée ; toute erreur ou
/// indisponibilité (`null`) laisse le local seul, sans message.
///
/// [onPending] signale l'attente : vrai de l'envoi de la requête Algolia à sa
/// réponse ou à son échec (donc au plus la durée des délais du service), faux
/// pour une requête vide ou effacée. Les écrans s'en servent pour ne pas
/// afficher « aucun résultat » avant la réponse.
class UnionSearch {
  UnionSearch({
    required this.search,
    required this.onChange,
    this.onPending,
    this.debounce = const Duration(milliseconds: 300),
  });

  final Future<Set<String>?> Function(String query) search;
  final void Function(String query, Set<String> remoteIds) onChange;
  final void Function(bool pending)? onPending;
  final Duration debounce;

  Timer? _timer;
  bool _pending = false;
  int _generation = 0;
  bool _disposed = false;

  /// Saisie de l'utilisateur : appliquée après [debounce] d'inactivité.
  void input(String value) {
    _timer?.cancel();
    _timer = Timer(debounce, () => _apply(value));
  }

  /// Effacement immédiat : annule la frappe en attente et la réponse en vol.
  void clear() {
    _timer?.cancel();
    _generation++;
    _setPending(false);
    if (!_disposed) onChange('', const <String>{});
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _generation++;
  }

  void _setPending(bool value) {
    if (_pending == value) return;
    _pending = value;
    if (!_disposed) onPending?.call(value);
  }

  Future<void> _apply(String query) async {
    if (_disposed) return;
    final int generation = ++_generation;
    onChange(query, const <String>{});
    if (query.trim().isEmpty) return _setPending(false);
    _setPending(true);
    Set<String>? ids;
    try {
      ids = await search(query);
    } on Object {
      ids = null; // Repli silencieux : le filtre local reste seul.
    }
    // Réponse périmée : la requête plus récente gère elle-même l'attente.
    if (_disposed || generation != _generation) return;
    _setPending(false);
    if (ids != null) onChange(query, ids);
  }
}
