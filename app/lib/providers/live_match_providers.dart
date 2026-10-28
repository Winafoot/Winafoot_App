import 'dart:math' as math;

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/data/match_repository.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/providers/assistant_providers.dart';
import 'package:wina/providers/match_providers.dart';

int _eventCounter = 0;

/// Identifiant d'événement unique sur tous les téléphones : horodatage, compteur et aléa.
String newEventId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
    '${(_eventCounter++).toRadixString(36)}'
    '${math.Random().nextInt(1 << 20).toRadixString(36)}';

/// État du match en direct. `null` tant qu'aucun match n'est démarré.
class LiveMatchNotifier extends StateNotifier<LiveMatch?> {
  LiveMatchNotifier() : super(null);

  void start(GameMatch match) => state = LiveMatch.fromGameMatch(match);

  /// Avance le chrono d'une seconde (appelé chaque seconde par l'écran tant que
  /// le match est en cours).
  void tick() {
    final LiveMatch? s = state;
    if (s == null || !s.isLive) return;
    state = s.copyWith(elapsedSeconds: s.elapsedSeconds + 1);
  }

  void selectPlayer(String playerId) {
    final LiveMatch? s = state;
    if (s == null) return;
    state = s.copyWith(selectedPlayerId: playerId);
  }

  /// Remplace le titulaire [outId] (sur le terrain) par [inId] (banc) : le
  /// remplaçant prend l'emplacement du sortant et devient le joueur
  /// sélectionné. Les statistiques déjà saisies pour le sortant sont conservées.
  void substitute(String outId, String inId) {
    final LiveMatch? s = state;
    if (s == null || outId == inId) return;
    final int idx = s.assignments.indexOf(outId);
    if (idx < 0) return;
    final List<String?> next = List<String?>.from(s.assignments);
    next[idx] = inId;
    // L'entrant quitte le banc, le sortant l'y rejoint : un joueur remplacé
    // peut rentrer à nouveau (catégories jeunes / foot loisir, où les rentrées
    // multiples sont la règle).
    //
    // `where` plutôt qu'un `..add(outId)` nu : un joueur peut DÉJÀ figurer
    // dans `substituteIds` tout en tenant un emplacement, un ajout direct le
    // doublerait. C'est aussi ce qui maintient l'invariant dont dépend le
    // filtre du banc (`match_live_screen`, critère `subIds.contains`) :
    // substituteIds ∩ assignments = ∅.
    final List<String> subs = <String>[
      ...s.substituteIds.where((String id) => id != inId && id != outId),
      outId,
    ];
    // Numéros affichés : sans numéro attribué, un titulaire porte celui de son
    // emplacement (index + 1), qu un remplaçant n a pas. On fige donc le numéro
    // du sortant (il le garde sur le banc) et on en donne un libre à l entrant
    // qui n en a pas, au lieu de lui laisser celui de l emplacement : il
    // doublerait celui du sortant et changerait au fil des remplacements.
    final Map<String, int> numbers = Map<String, int>.from(s.numbers);
    numbers.putIfAbsent(outId, () => idx + 1);
    if (!numbers.containsKey(inId)) {
      final Set<int> used = <int>{
        ...numbers.values,
        for (int i = 0; i < next.length; i++)
          if (next[i] != null && !numbers.containsKey(next[i])) i + 1,
      };
      int free = 1;
      while (used.contains(free)) {
        free++;
      }
      numbers[inId] = free;
    }
    state = s.copyWith(
      assignments: next,
      substituteIds: subs,
      selectedPlayerId: inId,
      numbers: numbers,
    );
  }

  /// Incrémente / décrémente une statistique du joueur sélectionné, journalise
  /// l'événement et met à jour le score pour les buts.
  void bump({
    required String statKey,
    required String statLabel,
    required String playerName,
    required int delta,
  }) {
    final String? pid = state?.selectedPlayerId;
    if (pid == null) return;
    bumpFor(
      playerId: pid,
      statKey: statKey,
      statLabel: statLabel,
      playerName: playerName,
      delta: delta,
    );
  }

  /// Même effet que [bump] pour un joueur désigné (saisie de l'adjoint), avec l'identifiant [eventId] de
  /// l'événement : celui de l'adjoint, pour que son affichage immédiat et l'état publié par le coach
  /// parlent du même événement. Sans [eventId], un identifiant est généré.
  void bumpFor({
    required String playerId,
    required String statKey,
    required String statLabel,
    required String playerName,
    required int delta,
    String? eventId,
  }) {
    final LiveMatch? s = state;
    if (s == null) return;
    // Commande rejouée (ou déjà appliquée) : l'événement existe, rien à refaire.
    if (eventId != null && s.events.any((MatchEvent e) => e.id == eventId)) {
      return;
    }
    final String pid = playerId;

    final int cur = s.statValue(pid, statKey);
    final int max = maxStatValue(statKey);
    // Sortie avant le clamp : sans elle, un « + » sur une valeur héritée
    // au-dessus du plafond la ferait BAISSER au lieu de ne rien faire.
    if (delta > 0 && cur >= max) return;
    final int next = (cur + delta).clamp(0, max).toInt();
    if (next == cur) return;

    final Map<String, Map<String, int>> ps = Map<String, Map<String, int>>.from(
      s.playerStats,
    );
    final Map<String, int> pm = Map<String, int>.from(
      ps[pid] ?? const <String, int>{},
    );
    pm[statKey] = next;
    ps[pid] = pm;

    int us = s.scoreUs;
    int them = s.scoreThem;
    if (statKey == 'butsMarques') us = (us + delta).clamp(0, 99).toInt();
    if (statKey == 'butsSubis') them = (them + delta).clamp(0, 99).toInt();

    state = s.copyWith(
      playerStats: ps,
      scoreUs: us,
      scoreThem: them,
      events: <MatchEvent>[
        MatchEvent(
          id: eventId ?? newEventId(),
          atSeconds: s.elapsedSeconds,
          playerId: pid,
          playerName: playerName,
          statKey: statKey,
          statLabel: statLabel,
          delta: delta,
          half: s.half,
        ),
        ...s.events,
      ],
    );
  }

  /// Retire l'événement [index] de l'historique et défait son effet — statistique
  /// du joueur concerné et, pour les buts, score — sans journaliser de nouvelle
  /// ligne (contrairement au `-` du compteur, qui lui reste tracé).
  void removeEvent(int index) {
    _removeEventAt(index);
  }

  /// Retire l'événement d'identifiant [id] (voir [removeEvent]) ; sans effet s'il n'existe plus.
  void removeEventById(String id) {
    final LiveMatch? s = state;
    if (s == null || id.isEmpty) return;
    final int index = s.events.indexWhere((MatchEvent e) => e.id == id);
    if (index >= 0) _removeEventAt(index);
  }

  void _removeEventAt(int index) {
    final LiveMatch? s = state;
    if (s == null || index < 0 || index >= s.events.length) return;

    final MatchEvent e = s.events[index];
    final List<MatchEvent> rest = List<MatchEvent>.from(s.events)
      ..removeAt(index);

    // On REJOUE le journal restant au lieu de soustraire le delta de la valeur
    // courante : `bump` ne journalise rien quand le clamp neutralise son effet,
    // donc la liste d'événements détermine seule l'état (`fromGameMatch` part
    // de zéro). Soustraire produit des stats et des scores fantômes — un
    // historique vide affirmant un but — persistés tels quels en Firestore.
    // `reversed` : `bump` préfixe, la liste est du plus récent au plus ancien.
    int replay(bool Function(MatchEvent) keep, int max) {
      int v = 0;
      for (final MatchEvent x in rest.reversed) {
        if (keep(x)) v = (v + x.delta).clamp(0, max).toInt();
      }
      return v;
    }

    final Map<String, Map<String, int>> ps = Map<String, Map<String, int>>.from(
      s.playerStats,
    );
    final Map<String, int> pm = Map<String, int>.from(
      ps[e.playerId] ?? const <String, int>{},
    );
    pm[e.statKey] = replay(
      (MatchEvent x) => x.playerId == e.playerId && x.statKey == e.statKey,
      maxStatValue(e.statKey),
    );
    ps[e.playerId] = pm;

    int us = s.scoreUs;
    int them = s.scoreThem;
    if (e.statKey == 'butsMarques') {
      us = replay((MatchEvent x) => x.statKey == 'butsMarques', 99);
    }
    if (e.statKey == 'butsSubis') {
      them = replay((MatchEvent x) => x.statKey == 'butsSubis', 99);
    }

    state = s.copyWith(
      playerStats: ps,
      scoreUs: us,
      scoreThem: them,
      events: rest,
    );
  }

  /// « Changer de côté » : inverse le sens du terrain (le coach qui ne commence pas du bon côté).
  void toggleSwapSides() => setSwapSides(!(state?.swapSides ?? false));

  void setSwapSides(bool value) {
    final LiveMatch? s = state;
    if (s == null || s.swapSides == value) return;
    state = s.copyWith(swapSides: value);
  }

  void togglePause() {
    final LiveMatch? s = state;
    if (s == null) return;
    state = s.copyWith(
      status: s.isLive ? MatchStatus.paused : MatchStatus.live,
    );
  }

  /// Ouvre la mi-temps (bouton « Mi-temps » du direct) : met le match en pause
  /// et mémorise les stats suivies AVANT que le coach ne les modifie pendant
  /// la coupure. La bascule en 2e mi-temps, elle, reste [startSecondHalf].
  /// L'instantané n'est pris qu'une fois : une réouverture de la mi-temps ne
  /// doit pas y glisser les stats activées pendant la première coupure.
  void beginHalfTime() {
    final LiveMatch? s = state;
    if (s == null) return;
    state = s.copyWith(
      status: MatchStatus.paused,
      halfTimeStatKeys: s.halfTimeStatKeys ?? s.enabledStatKeys,
    );
  }

  /// Annule la mi-temps (retour arrière sur l'écran de coupure) : le match reste
  /// en 1re mi-temps et reprend, l'instantané des stats suivies est effacé (une
  /// prochaine mi-temps en prendra un neuf). Ne touche ni au score ni aux stats.
  void cancelHalfTime() {
    final LiveMatch? s = state;
    if (s == null || s.half != 1) return;
    state = s.copyWith(
      status: MatchStatus.live,
      clearHalfTimeStatKeys: true,
    );
  }

  void startSecondHalf() {
    final LiveMatch? s = state;
    if (s == null) return;
    state = s.copyWith(
      half: 2,
      status: MatchStatus.live,
      // Filet si la mi-temps n'a pas été ouverte par [beginHalfTime].
      halfTimeStatKeys: s.halfTimeStatKeys ?? s.enabledStatKeys,
    );
  }

  void finish() {
    final LiveMatch? s = state;
    if (s == null) return;
    state = s.copyWith(status: MatchStatus.finished);
  }

  /// Abandonne le match en cours (quitté sans finaliser) : efface l'état.
  /// Met à jour en direct la liste des statistiques suivies (« Modifier
  /// statistiques » depuis l'écran de coupure).
  void setEnabledStats(List<String> keys) {
    final LiveMatch? s = state;
    if (s == null) return;
    state = s.copyWith(enabledStatKeys: keys);
  }

  /// Applique une nouvelle composition au match en direct (« Modifier
  /// composition » depuis l'écran de coupure) : nouveau schéma / placements /
  /// numéros, en conservant statistiques, score, chrono et historique.
  void applyComposition(MatchComposition comp) {
    final LiveMatch? s = state;
    if (s == null) return;
    state = s.copyWith(
      formationLabel: comp.formationLabel,
      slots: comp.slots,
      assignments: comp.assignments,
      numbers: comp.numbers,
      substituteIds: comp.substituteIds,
    );
  }

  void clear() => state = null;

  /// Reprise d'un match laissé ouvert (appli fermée ou plantée) : l'état publié sur Firebase, en pause.
  void restore(LiveMatch live) =>
      state = live.copyWith(status: MatchStatus.paused);
}

/// Sur le téléphone du coach : l'état de jeu lui-même. Sur celui de l'adjoint : le miroir du match publié
/// par le coach ([AssistantLiveNotifier]), ce qui permet de réutiliser l'écran du direct tel quel.
final liveMatchProvider = StateNotifierProvider<LiveMatchNotifier, LiveMatch?>((
  ref,
) {
  final String? coach = ref.watch(
    assistantOfProvider.select((AsyncValue<String?> v) => v.valueOrNull),
  );
  return coach == null ? LiveMatchNotifier() : AssistantLiveNotifier(ref, coach);
});

/// Quitte un match en direct sans le finaliser : marque le document Firestore
/// abandonné (non bloquant) et efface l'état en mémoire. Partagé par le bouton
/// « Quitter le match » de l'écran de direct et par le logo « wina », qui
/// propose la même sortie depuis n'importe quelle entête.
void abandonLiveMatch(WidgetRef ref) {
  final String? id = ref.read(matchDraftProvider).id;
  ref.read(liveMatchProvider.notifier).clear();
  // Abandon non bloquant : on quitte l'écran quoi qu'il arrive.
  if (id != null) MatchRepository.abandonMatch(id).catchError((Object _) {});
}
