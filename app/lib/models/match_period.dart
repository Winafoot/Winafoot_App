import 'package:flutter/foundation.dart';

/// Période d'un bilan : une mi-temps ou le match entier.
enum MatchPeriod { firstHalf, secondHalf, total }

/// Ce qu'on peut dire des statistiques d'une période.
enum PeriodStatus {
  /// Valeurs exploitables.
  available,

  /// Match ancien, enregistré sans découpage : seule la période
  /// [MatchPeriod.total] est consultable.
  unavailable,

  /// 2e mi-temps jamais jouée (match terminé avant la reprise).
  notPlayed,
}

/// Statistiques d'un match sur une [MatchPeriod]. Un état sans valeurs
/// ([PeriodStatus.unavailable], [PeriodStatus.notPlayed]) est explicite : il ne
/// se confond ni avec « aucune stat saisie » ni avec un match à zéro.
@immutable
class PeriodStats {
  const PeriodStats(
    this.status, {
    this.playerStats = const <String, Map<String, int>>{},
    this.statKeys = const <String>[],
  });

  final PeriodStatus status;

  /// playerId → { statKey → valeur } sur la période. Compteurs bruts : les
  /// stats calculées se dérivent avec `readStat`.
  final Map<String, Map<String, int>> playerStats;

  /// Clés des stats suivies pendant la période : une stat absente de cette
  /// liste n'était pas suivie (à afficher « - », jamais 0).
  final List<String> statKeys;

  bool get isAvailable => status == PeriodStatus.available;
}
