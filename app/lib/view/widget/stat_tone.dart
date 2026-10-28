import 'package:flutter/painting.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/stat_catalog.dart';

/// Les 28 statistiques saisies se partagent en deux colonnes de 14, chacune dans son ordre de priorité.
///
/// Gagnés : colonne de droite, verte ; le carton jaune y figure en dernier, encadré de jaune.
const List<String> kGoodStatsByPriority = <String>[
  'passesReussies',
  'recuperations',
  'tirsCadres',
  'controleReussi',
  'fautesSubies',
  'duelsGagnes',
  'duelsAeriens',
  'arretsGardien',
  'passesProfondeur',
  'centresReussis',
  'passesDecisives',
  'butsMarques',
  'penaltysCrees',
  'cartonsJaunes',
];

/// Perdus : colonne de gauche, rouge.
const List<String> kBadStatsByPriority = <String>[
  'passesManquees',
  'pertesBallons',
  'tirsNonCadres',
  'controleManque',
  'fautesCommises',
  'duelsPerdus',
  'duelsAeriensPerdus',
  'tirsSubisDans',
  'tirsSubisHors',
  'centresRates',
  'horsJeu',
  'butsSubis',
  'penaltysSubis',
  'cartonsRouges',
];

/// Côté d'une statistique : [bad] (perdus, à gauche), [good] (gagnés, à droite) ou [neutral] (totaux
/// calculés, qui ne sont pas dans une colonne).
enum StatSide { bad, good, neutral }

StatSide statSide(String key) {
  if (kGoodStatsByPriority.contains(key)) return StatSide.good;
  if (kBadStatsByPriority.contains(key)) return StatSide.bad;
  return StatSide.neutral;
}

/// Statistiques de [stats] du [side] demandé, dans l'ordre de priorité de leur colonne (les neutres gardent
/// l'ordre du catalogue).
List<StatDef> statsOfSide(Iterable<StatDef> stats, StatSide side) {
  final List<StatDef> list = <StatDef>[
    for (final StatDef s in stats)
      if (statSide(s.key) == side) s,
  ];
  final List<String> order = switch (side) {
    StatSide.good => kGoodStatsByPriority,
    StatSide.bad => kBadStatsByPriority,
    StatSide.neutral => const <String>[],
  };
  if (order.isNotEmpty) {
    list.sort(
      (StatDef a, StatDef b) =>
          order.indexOf(a.key).compareTo(order.indexOf(b.key)),
    );
  }
  return list;
}

/// Fond d'une stat selon sa nature : vert (gagnée), rouge (perdue), jaune (carton jaune) ; `null` pour une
/// stat neutre. Teintes douces, assorties au thème de l'appli.
Color? statTint(String key) {
  if (key == 'cartonsJaunes') {
    return AppColor.jerseyYellow.withValues(alpha: 0.35);
  }
  return switch (statSide(key)) {
    StatSide.bad => AppColor.destructive.withValues(alpha: 0.24),
    StatSide.good => AppColor.primaryColor.withValues(alpha: 0.30),
    StatSide.neutral => null,
  };
}
