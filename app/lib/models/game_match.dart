import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/match_period.dart';

/// Cycle de vie d'un match.
enum MatchStatus {
  /// Assistant « Coup d'envoi » en cours (adversaire / maillots).
  draft,

  /// Équipe gérée + statistiques paramétrées : prêt à démarrer.
  ready,

  /// Match en cours.
  live,

  /// En pause.
  paused,

  /// Mi-temps.
  halftime,

  /// Terminé (enregistré).
  finished,

  /// Quitté sans finaliser.
  abandoned,
}

/// Informations sur l'équipe adverse (assistant « Coup d'envoi » — étape 1).
@immutable
class MatchOpponent {
  const MatchOpponent({
    this.name = '',
    this.category,
    this.division,
    this.jerseyColor,
  });

  final String name;
  final TeamCategory? category;
  final TeamDivision? division;

  /// Couleur du maillot adverse (étape 2).
  final JerseyColorOption? jerseyColor;

  MatchOpponent copyWith({
    String? name,
    TeamCategory? category,
    TeamDivision? division,
    JerseyColorOption? jerseyColor,
  }) {
    return MatchOpponent(
      name: name ?? this.name,
      category: category ?? this.category,
      division: division ?? this.division,
      jerseyColor: jerseyColor ?? this.jerseyColor,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'category': category?.name,
    'division': division?.name,
    'jerseyColor': jerseyColor?.name,
  };

  factory MatchOpponent.fromJson(Map<String, dynamic> json) {
    return MatchOpponent(
      name: (json['name'] as String?) ?? '',
      category: TeamCategory.values.asNameMap()[json['category']],
      division: TeamDivision.values.asNameMap()[json['division']],
      jerseyColor: JerseyColorOption.values.asNameMap()[json['jerseyColor']],
    );
  }
}

/// Un match : construit dans l'assistant « Coup d'envoi », puis joué.
///
/// Porte l'adversaire et le maillot porté, la ou les compositions, les
/// statistiques activées, le statut, le score, le temps de jeu, la mi-temps et
/// les statistiques par joueur (voir README, section Fonctionnement).
@immutable
class GameMatch {
  const GameMatch({
    this.id,
    this.opponent = const MatchOpponent(),
    this.ownJersey,
    this.composition,
    this.compositions = const <MatchComposition>[],
    this.enabledStatKeys = const <String>[],
    this.status = MatchStatus.draft,
    this.createdAt,
    this.scoreUs = 0,
    this.scoreThem = 0,
    this.elapsedSeconds = 0,
    this.playerStats = const <String, Map<String, int>>{},
    this.finishedAt,
    this.half = 1,
    this.firstHalfStats,
    this.firstHalfStatKeys = const <String>[],
  });

  /// Identifiant Firestore (`users/{uid}/matches/{id}`). `null` tant que non
  /// persisté.
  final String? id;

  final MatchOpponent opponent;

  /// Maillot porté par l'équipe (choisi parmi les maillots du coach, étape 2).
  final Jersey? ownJersey;

  /// Composition validée (schéma + joueurs placés), via « Gérer mon équipe ».
  final MatchComposition? composition;

  /// Toutes les compositions employées au cours du match (par ex. un schéma
  /// différent en seconde mi-temps). Vide si une seule a servi : le getter
  /// [compositionsUsed] retombe alors sur [composition].
  final List<MatchComposition> compositions;

  /// Liste des compositions réellement utilisées pendant le match. Source de la
  /// colonne « Compositions utilisées » : la liste [compositions] si elle est
  /// renseignée, sinon l'unique [composition], sinon vide.
  List<MatchComposition> get compositionsUsed {
    if (compositions.isNotEmpty) return compositions;
    final MatchComposition? c = composition;
    return c == null ? const <MatchComposition>[] : <MatchComposition>[c];
  }

  /// Plusieurs compositions ont été employées au cours du match.
  bool get hasMultipleCompositions => compositionsUsed.length > 1;

  /// Clés des statistiques activées (écran « Paramétrez les statistiques »).
  final List<String> enabledStatKeys;

  final MatchStatus status;
  final DateTime? createdAt;

  // ── Résultat (match terminé) ──────────────────────────────────────────────
  final int scoreUs;
  final int scoreThem;
  final int elapsedSeconds;

  /// playerId → { statKey → valeur } (match terminé).
  final Map<String, Map<String, int>> playerStats;
  final DateTime? finishedAt;

  // ── Découpage par mi-temps (matchs enregistrés depuis le direct) ──────────
  /// Mi-temps atteinte à la fin du match : 1 = terminé avant la reprise (la 2e
  /// mi-temps n'a pas été jouée), 2 = 2e mi-temps jouée.
  final int half;

  /// Statistiques de la 1re mi-temps (même forme que [playerStats], le total
  /// restant dans [playerStats]). `null` = match ancien, enregistré sans
  /// découpage ; une carte vide = découpage connu, rien saisi en 1re mi-temps.
  final Map<String, Map<String, int>>? firstHalfStats;

  /// Statistiques suivies pendant la 1re mi-temps.
  final List<String> firstHalfStatKeys;

  /// Statistiques et stats suivies d'une [period]. La 2e mi-temps se dérive du
  /// total : total − 1re mi-temps, jamais négatif. Match ancien (sans
  /// [firstHalfStats]) : 1re et 2e mi-temps [PeriodStatus.unavailable], seul le
  /// total est consultable ; match fini avant la reprise ([half] 1) : 2e
  /// mi-temps [PeriodStatus.notPlayed].
  PeriodStats statsFor(MatchPeriod period) {
    final Map<String, Map<String, int>>? first = firstHalfStats;
    switch (period) {
      case MatchPeriod.total:
        return PeriodStats(
          PeriodStatus.available,
          playerStats: playerStats,
          statKeys: _keysWithValues(<String>[
            ...enabledStatKeys,
            ...firstHalfStatKeys,
          ], playerStats),
        );
      case MatchPeriod.firstHalf:
        if (first == null) return const PeriodStats(PeriodStatus.unavailable);
        return PeriodStats(
          PeriodStatus.available,
          playerStats: first,
          statKeys: firstHalfStatKeys,
        );
      case MatchPeriod.secondHalf:
        if (first == null) return const PeriodStats(PeriodStatus.unavailable);
        if (half < 2) return const PeriodStats(PeriodStatus.notPlayed);
        final Map<String, Map<String, int>> second = <String, Map<String, int>>{
          for (final MapEntry<String, Map<String, int>> p
              in playerStats.entries)
            p.key: <String, int>{
              for (final MapEntry<String, int> s in p.value.entries)
                s.key: math.max(0, s.value - (first[p.key]?[s.key] ?? 0)),
            },
        };
        return PeriodStats(
          PeriodStatus.available,
          playerStats: second,
          statKeys: _keysWithValues(enabledStatKeys, second),
        );
    }
  }

  /// Libellé du résultat (du point de vue de l'équipe), pour un match terminé.
  String? get resultLabel {
    if (status != MatchStatus.finished) return null;
    if (scoreUs > scoreThem) return 'Victoire';
    if (scoreUs < scoreThem) return 'Défaite';
    return 'Match nul';
  }

  /// Durée du match en minutes (« 92m »).
  String get durationLabel => '${(elapsedSeconds / 60).round()}m';

  /// Étape 1 valide : un nom d'adversaire est saisi.
  bool get isOpponentValid => opponent.name.trim().isNotEmpty;

  /// Étape 2 valide : maillot porté choisi + couleur adverse choisie.
  bool get isJerseyValid => ownJersey != null && opponent.jerseyColor != null;

  /// Composition prête : schéma choisi et tous les titulaires placés.
  bool get isCompositionReady => composition?.isComplete ?? false;

  /// Statistiques prêtes : au moins une statistique activée.
  bool get isStatsReady => enabledStatKeys.isNotEmpty;

  /// Prêt à démarrer : équipe gérée ET statistiques paramétrées.
  bool get isReadyToStart => isCompositionReady && isStatsReady;

  GameMatch copyWith({
    String? id,
    MatchOpponent? opponent,
    Jersey? ownJersey,
    MatchComposition? composition,
    List<MatchComposition>? compositions,
    List<String>? enabledStatKeys,
    MatchStatus? status,
    DateTime? createdAt,
  }) {
    return GameMatch(
      id: id ?? this.id,
      opponent: opponent ?? this.opponent,
      ownJersey: ownJersey ?? this.ownJersey,
      composition: composition ?? this.composition,
      compositions: compositions ?? this.compositions,
      enabledStatKeys: enabledStatKeys ?? this.enabledStatKeys,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'opponent': opponent.toJson(),
    'ownJersey': ownJersey?.toJson(),
    'composition': composition?.toJson(),
    if (compositions.isNotEmpty)
      'compositions': <Map<String, dynamic>>[
        for (final MatchComposition c in compositions) c.toJson(),
      ],
    'enabledStatKeys': enabledStatKeys,
    'status': status.name,
  };

  factory GameMatch.fromDoc(String id, Map<String, dynamic> json) {
    final Object? jersey = json['ownJersey'];
    final Object? comp = json['composition'];
    return GameMatch(
      id: id,
      opponent: MatchOpponent.fromJson(
        (json['opponent'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      ownJersey:
          jersey is Map ? Jersey.fromDoc(jersey.cast<String, dynamic>()) : null,
      composition:
          comp is Map
              ? MatchComposition.fromJson(comp.cast<String, dynamic>())
              : null,
      compositions: <MatchComposition>[
        for (final dynamic c
            in (json['compositions'] as List<dynamic>?) ?? const <dynamic>[])
          if (c is Map)
            MatchComposition.fromJson(c.cast<String, dynamic>()),
      ],
      enabledStatKeys:
          ((json['enabledStatKeys'] as List<dynamic>?) ?? const <dynamic>[])
              .whereType<String>()
              .toList(),
      status:
          MatchStatus.values.asNameMap()[json['status']] ?? MatchStatus.draft,
      scoreUs: (json['scoreUs'] as num?)?.toInt() ?? 0,
      scoreThem: (json['scoreThem'] as num?)?.toInt() ?? 0,
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      playerStats:
          _parsePlayerStats(json['playerStats']) ??
          const <String, Map<String, int>>{},
      half: json['half'] == 2 ? 2 : 1,
      firstHalfStats: _parsePlayerStats(json['firstHalfStats']),
      firstHalfStatKeys:
          json['firstHalfStatKeys'] is List
              ? (json['firstHalfStatKeys'] as List<dynamic>)
                  .whereType<String>()
                  .toList()
              : const <String>[],
      createdAt:
          json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : null,
      finishedAt:
          json['finishedAt'] is Timestamp
              ? (json['finishedAt'] as Timestamp).toDate()
              : null,
    );
  }
}

/// [keys] plus toute stat qui a une valeur > 0 dans [stats] : une stat suivie
/// pendant une partie d'une période puis désactivée en pause (la sélection
/// finale ne la contient plus) ne doit pas voir ses valeurs disparaître.
/// Sans doublon, ordre de [keys] conservé.
List<String> _keysWithValues(
  Iterable<String> keys,
  Map<String, Map<String, int>> stats,
) =>
    <String>{
      ...keys,
      for (final Map<String, int> m in stats.values)
        for (final MapEntry<String, int> e in m.entries)
          if (e.value > 0) e.key,
    }.toList();

/// Lit une carte `joueur → { stat → valeur }` d'un document Firestore, sans
/// jamais lever : entrée non-Map ignorée, valeur non numérique lue comme 0.
/// `null` si [raw] n'est pas une carte (champ absent d'un ancien match), ce qui
/// se distingue d'une carte vide.
Map<String, Map<String, int>>? _parsePlayerStats(Object? raw) {
  if (raw is! Map) return null;
  return <String, Map<String, int>>{
    for (final MapEntry<dynamic, dynamic> e in raw.entries)
      if (e.key is String && e.value is Map)
        e.key as String: <String, int>{
          for (final MapEntry<dynamic, dynamic> s
              in (e.value as Map<dynamic, dynamic>).entries)
            if (s.key is String)
              s.key as String: s.value is num ? (s.value as num).toInt() : 0,
        },
  };
}
