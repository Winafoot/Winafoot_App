import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_period.dart';
import 'package:wina/models/player.dart';
import 'package:wina/models/stat_catalog.dart';

/// Nombre d'actions affichées dans l'« Historique » du direct (les plus récentes).
///
/// Limite d'AFFICHAGE seulement : [LiveMatch.events] garde le journal complet, car
/// `LiveMatchNotifier.removeEvent` recalcule les statistiques et le score en rejouant ce
/// journal. Le tronquer à 20 ferait perdre les actions plus anciennes à la première annulation.
const int kMatchHistoryDisplayLimit = 20;

/// Un événement enregistré pendant le match (incrément/décrément d'une stat),
/// affiché dans l'« Historique ».
@immutable
class MatchEvent {
  const MatchEvent({
    this.id = '',
    required this.atSeconds,
    required this.playerId,
    required this.playerName,
    required this.statKey,
    required this.statLabel,
    required this.delta,
    required this.half,
  });

  /// Identifiant stable de l'événement : l'adjoint désigne ainsi l'événement à retirer (l'index change
  /// dès qu'un nouvel événement arrive). Vide pour un événement d'avant l'adjoint.
  final String id;
  final int atSeconds;
  final String playerId;
  final String playerName;
  final String statKey;
  final String statLabel;
  final int delta;

  /// Mi-temps (1 ou 2) en cours quand l'événement a été saisi : c'est elle qui
  /// répartit les statistiques entre les deux périodes (voir
  /// [LiveMatch.firstHalfStats]).
  final int half;
}

/// État d'un match en direct : composition jouée, chrono, score, statistiques
/// par joueur, événements et joueur sélectionné.
@immutable
class LiveMatch {
  const LiveMatch({
    required this.formationLabel,
    required this.slots,
    required this.assignments,
    required this.enabledStatKeys,
    this.numbers = const <String, int>{},
    this.substituteIds = const <String>[],
    this.playerStats = const <String, Map<String, int>>{},
    this.scoreUs = 0,
    this.scoreThem = 0,
    this.elapsedSeconds = 0,
    this.half = 1,
    this.status = MatchStatus.live,
    this.events = const <MatchEvent>[],
    this.selectedPlayerId,
    this.halfTimeStatKeys,
    this.swapSides = false,
  });

  final String formationLabel;
  final List<FormationSlot> slots;

  /// playerId par emplacement (titulaires).
  final List<String?> assignments;
  final List<String> enabledStatKeys;

  /// Numéro de maillot attribué à chaque joueur : playerId → numéro.
  final Map<String, int> numbers;

  /// Remplaçants de la composition (tableaux de statistiques).
  final List<String> substituteIds;

  /// playerId → { statKey → valeur }.
  final Map<String, Map<String, int>> playerStats;

  final int scoreUs;
  final int scoreThem;
  final int elapsedSeconds;
  final int half;
  final MatchStatus status;
  final List<MatchEvent> events;
  final String? selectedPlayerId;

  /// Statistiques suivies à l'ouverture de la mi-temps, AVANT les modifications
  /// faites pendant la coupure (« Modifier statistiques ») : sans cet
  /// instantané, une stat activée à la mi-temps passerait pour suivie en 1re
  /// mi-temps. `null` tant que la mi-temps n'a pas commencé.
  final List<String>? halfTimeStatKeys;

  /// Terrain inversé à la main (« Changer de côté ») : partagé entre le coach et l'adjoint, qui voient
  /// ainsi le même sens de jeu. Se cumule avec le changement de côté de la 2e mi-temps.
  final bool swapSides;

  bool get isLive => status == MatchStatus.live;
  bool get isPaused => status == MatchStatus.paused;

  String get clock {
    final int m = elapsedSeconds ~/ 60;
    final int s = elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Valeur d'une stat pour un joueur : un total calculé se dérive de ses
  /// composantes (voir [readStat]). Point d'entrée de l'écran live ; le
  /// tableau « Joueurs × Statistiques » et le PDF individuel affichent leurs
  /// cellules via `formatStat`.
  int statValue(String playerId, String key) =>
      readStat(playerStats[playerId], key);

  /// Statistiques de la 1re mi-temps : rejeu des seuls événements de la 1re
  /// mi-temps (`events` va du plus récent au plus ancien, d'où `reversed`) avec
  /// les MÊMES plafonds que `removeEvent`, cartons compris (2 jaunes, 1 rouge
  /// par MATCH : un jaune en 1re mi-temps en laisse un seul en 2e), bornées par
  /// le total du match.
  ///
  /// Toujours dérivées du journal, jamais stockées : supprimer un événement de
  /// 1re mi-temps pendant la 2e les met à jour d'elles-mêmes. La borne règle le
  /// « − » saisi en 2e mi-temps sur une stat comptée en 1re : la 1re mi-temps
  /// est amputée, la 2e (total − 1re) ne descend jamais sous zéro et
  /// 1re + 2e = total.
  Map<String, Map<String, int>> get firstHalfStats {
    final Map<String, Map<String, int>> replay = <String, Map<String, int>>{};
    for (final MatchEvent e in events.reversed) {
      if (e.half != 1) continue;
      final Map<String, int> m = replay.putIfAbsent(
        e.playerId,
        () => <String, int>{},
      );
      m[e.statKey] =
          ((m[e.statKey] ?? 0) + e.delta)
              .clamp(0, maxStatValue(e.statKey))
              .toInt();
    }
    return <String, Map<String, int>>{
      for (final MapEntry<String, Map<String, int>> p in replay.entries)
        p.key: <String, int>{
          for (final MapEntry<String, int> s in p.value.entries)
            s.key: math.min(s.value, statValue(p.key, s.key)),
        },
    };
  }

  /// Statistiques suivies pendant la 1re mi-temps : la sélection de
  /// l'ouverture de la mi-temps ([halfTimeStatKeys]), à défaut la sélection
  /// courante (match fini sans mi-temps), plus toute stat qui a une valeur en
  /// 1re mi-temps (désactivée en pause de 1re mi-temps, elle ne doit pas
  /// voir ses valeurs disparaître).
  List<String> get firstHalfStatKeys =>
      <String>{
        ...(halfTimeStatKeys ?? enabledStatKeys),
        for (final Map<String, int> m in firstHalfStats.values) ...m.keys,
      }.toList();

  /// Titulaires du poste [pos] dans l'ordre des emplacements, avec leur numéro
  /// de maillot (repli : index d'emplacement + 1). Source commune du tableau
  /// « Joueurs × Statistiques » et de son export PDF.
  List<({int? number, Player player})> startersAt(
    PlayerPosition pos,
    Map<String, Player> byId,
  ) {
    final List<({int? number, Player player})> entries =
        <({int? number, Player player})>[];
    for (int i = 0; i < slots.length; i++) {
      if (slots[i].role != pos) continue;
      final String? pid = i < assignments.length ? assignments[i] : null;
      final Player? p = pid != null ? byId[pid] : null;
      if (p == null) continue;
      entries.add((number: numbers[pid] ?? i + 1, player: p));
    }
    return entries;
  }

  /// Remplaçants connus de [byId]. Un remplaçant n'occupe aucun emplacement :
  /// son rang dans la liste n'est pas un numéro de maillot plausible
  /// (contrairement aux titulaires, dont l'index d'emplacement sert de repli).
  /// Sans numéro attribué, on n'en invente donc aucun : `number` reste nul.
  List<({int? number, Player player})> substitutes(Map<String, Player> byId) =>
      <({int? number, Player player})>[
        for (final String pid in substituteIds)
          if (byId[pid] != null) (number: numbers[pid], player: byId[pid]!),
      ];

  LiveMatch copyWith({
    String? formationLabel,
    List<FormationSlot>? slots,
    List<String?>? assignments,
    List<String>? substituteIds,
    List<String>? enabledStatKeys,
    Map<String, int>? numbers,
    Map<String, Map<String, int>>? playerStats,
    int? scoreUs,
    int? scoreThem,
    int? elapsedSeconds,
    int? half,
    MatchStatus? status,
    List<MatchEvent>? events,
    String? selectedPlayerId,
    List<String>? halfTimeStatKeys,
    bool? swapSides,
  }) {
    return LiveMatch(
      formationLabel: formationLabel ?? this.formationLabel,
      slots: slots ?? this.slots,
      assignments: assignments ?? this.assignments,
      enabledStatKeys: enabledStatKeys ?? this.enabledStatKeys,
      numbers: numbers ?? this.numbers,
      substituteIds: substituteIds ?? this.substituteIds,
      playerStats: playerStats ?? this.playerStats,
      scoreUs: scoreUs ?? this.scoreUs,
      scoreThem: scoreThem ?? this.scoreThem,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      half: half ?? this.half,
      status: status ?? this.status,
      events: events ?? this.events,
      selectedPlayerId: selectedPlayerId ?? this.selectedPlayerId,
      halfTimeStatKeys: halfTimeStatKeys ?? this.halfTimeStatKeys,
      swapSides: swapSides ?? this.swapSides,
    );
  }

  /// Initialise un match en direct depuis un match prêt (composition + stats).
  factory LiveMatch.fromGameMatch(GameMatch match) {
    final composition = match.composition;
    return LiveMatch(
      formationLabel: composition?.formationLabel ?? '',
      slots: composition?.slots ?? const <FormationSlot>[],
      assignments: composition?.assignments ?? const <String?>[],
      enabledStatKeys: match.enabledStatKeys,
      numbers: composition?.numbers ?? const <String, int>{},
      substituteIds: composition?.substituteIds ?? const <String>[],
    );
  }

  /// Reconstruit l'état d'un match terminé (avec résultats) pour la lecture,
  /// sur une [period] : ses statistiques et ses stats suivies (le match entier
  /// par défaut). Une 2e mi-temps non jouée garde les colonnes du match, sans
  /// valeurs ; une période indisponible (match ancien) n'a ni l'un ni l'autre.
  factory LiveMatch.fromFinished(
    GameMatch match, [
    MatchPeriod period = MatchPeriod.total,
  ]) {
    final composition = match.composition;
    final PeriodStats stats = match.statsFor(period);
    return LiveMatch(
      formationLabel: composition?.formationLabel ?? '',
      slots: composition?.slots ?? const <FormationSlot>[],
      assignments: composition?.assignments ?? const <String?>[],
      enabledStatKeys:
          stats.status == PeriodStatus.notPlayed
              ? match.statsFor(MatchPeriod.total).statKeys
              : stats.statKeys,
      numbers: composition?.numbers ?? const <String, int>{},
      substituteIds: composition?.substituteIds ?? const <String>[],
      playerStats: stats.playerStats,
      scoreUs: match.scoreUs,
      scoreThem: match.scoreThem,
      elapsedSeconds: match.elapsedSeconds,
      status: MatchStatus.finished,
    );
  }
}
