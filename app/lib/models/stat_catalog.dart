import 'package:flutter/foundation.dart';

/// Thème d'une statistique (9 thèmes du client, dans l'ordre d'affichage) :
/// regroupe les stats en cartes dans l'écran « Match en cours » (maquette
/// Figma) et titre les blocs des bilans.
enum StatCategory {
  passes('Statistiques passes'),
  efficacite("Statistiques d'efficacité"),
  tirs('Statistiques tirs'),
  offensives('Statistiques offensives'),
  coupsDePiedArretes('Coups de pied arrêtés'),
  fautesSanctions('Fautes et sanctions'),
  gardienDefense('Gardien et défense'),
  technique('Technique'),
  duels('Duels et actions spéciales');

  const StatCategory(this.label);

  /// Libellé complet du thème (sous-titre des pages de l'export PDF). Apostrophe
  /// droite : Helvetica, police par défaut des PDF, ne dessine pas la ’.
  final String label;
}

/// Définition d'une statistique paramétrable (écran « Paramétrez les
/// statistiques »).
@immutable
class StatDef {
  const StatDef(
    this.key,
    this.label, {
    required this.category,
    this.defaultOn = false,
    this.bilanOnly = false,
    this.parts = const <String>[],
  });

  /// Clé stable (persistée / utilisée pour le suivi en direct).
  final String key;

  final String label;

  /// Activée par défaut (reprend l'état du design). Jamais pour une stat
  /// calculée : elle n'est pas une bascule.
  final bool defaultOn;

  /// Visible uniquement dans les interfaces de bilan (pas de suivi en direct),
  /// ex. « Réussite de passes ».
  final bool bilanOnly;

  /// Thème de regroupement en carte (écran de match en direct).
  final StatCategory category;

  /// Composantes d'une stat calculée. Vide pour une stat saisie. Une stat
  /// calculée n'est JAMAIS stockée : elle se dérive de ses composantes (voir
  /// [readStat]) et n'apparaît que si toutes sont suivies (voir
  /// [enabledStatsInCatalogOrder]).
  final List<String> parts;

  /// Stat dérivée de ses composantes (total ou pourcentage) : ni saisie ni
  /// bascule du paramétrage.
  bool get isCalculated => parts.isNotEmpty;

  /// Total calculé (somme entière de [parts]) : affiché sans boutons +/- en
  /// direct. Le pourcentage (`bilanOnly`) est calculé à part, voir
  /// [formatPercent].
  bool get isTotal => isCalculated && !bilanOnly;
}

/// Catalogue des 42 statistiques (37 saisies + 5 calculées), dans l'ordre des
/// 9 thèmes du client. Les clés sont persistées (`playerStats`,
/// `enabledStatKeys`) : n'en renommer aucune, seuls libellés et thèmes changent.
const List<StatDef> kStatCatalog = <StatDef>[
  // ── Passes ──
  StatDef(
    'passesReussies',
    'Passes réussies',
    defaultOn: true,
    category: StatCategory.passes,
  ),
  StatDef(
    'passesManquees',
    'Passes manquées',
    defaultOn: true,
    category: StatCategory.passes,
  ),
  StatDef(
    'totalPasses',
    'Total passes',
    category: StatCategory.passes,
    parts: <String>['passesReussies', 'passesManquees'],
  ),
  StatDef(
    'pourcentagePasses',
    'Réussite de passes',
    bilanOnly: true,
    category: StatCategory.passes,
    parts: <String>['passesReussies', 'passesManquees'],
  ),
  StatDef(
    'passesProfondeur',
    'Passes en profondeur',
    defaultOn: true,
    category: StatCategory.passes,
  ),
  // ── Efficacité ──
  StatDef(
    'interceptions',
    'Interception de ballons',
    defaultOn: true,
    category: StatCategory.efficacite,
  ),
  StatDef(
    'recuperations',
    'Récupération de ballons',
    defaultOn: true,
    category: StatCategory.efficacite,
  ),
  // ── Tirs ──
  StatDef(
    'tirsCadres',
    'Tirs cadrés',
    defaultOn: true,
    category: StatCategory.tirs,
  ),
  StatDef(
    'tirsNonCadres',
    'Tirs non cadrés',
    defaultOn: true,
    category: StatCategory.tirs,
  ),
  StatDef(
    'tirsBloques',
    'Tirs bloqués',
    defaultOn: true,
    category: StatCategory.tirs,
  ),
  StatDef(
    'totalTirs',
    'Total tirs',
    category: StatCategory.tirs,
    parts: <String>['tirsCadres', 'tirsNonCadres', 'tirsBloques'],
  ),
  // ── Offensives ──
  StatDef(
    'passesDecisives',
    'Passes décisives',
    category: StatCategory.offensives,
  ),
  StatDef('butsMarques', 'Buts marqués', category: StatCategory.offensives),
  StatDef(
    'centresReussis',
    'Centres réussis',
    defaultOn: true,
    category: StatCategory.offensives,
  ),
  StatDef(
    'centresRates',
    'Centres manqués',
    defaultOn: true,
    category: StatCategory.offensives,
  ),
  StatDef(
    'nombreCentres',
    'Nombre de centres',
    category: StatCategory.offensives,
    parts: <String>['centresReussis', 'centresRates'],
  ),
  // ── Coups de pied arrêtés ──
  StatDef(
    'corners',
    'Corners obtenus',
    category: StatCategory.coupsDePiedArretes,
  ),
  StatDef(
    'coupsFrancsCrees',
    'Coups francs obtenus',
    defaultOn: true,
    category: StatCategory.coupsDePiedArretes,
  ),
  StatDef(
    'coupsFrancsSubis',
    'Coups francs subis',
    defaultOn: true,
    category: StatCategory.coupsDePiedArretes,
  ),
  StatDef(
    'penaltysCrees',
    'Penaltys obtenus',
    defaultOn: true,
    category: StatCategory.coupsDePiedArretes,
  ),
  StatDef(
    'penaltysSubis',
    'Penaltys subis',
    category: StatCategory.coupsDePiedArretes,
  ),
  StatDef(
    'nombreTouches',
    'Nombre de touches',
    defaultOn: true,
    category: StatCategory.coupsDePiedArretes,
  ),
  // ── Fautes et sanctions ──
  StatDef(
    'fautesCommises',
    'Fautes commises',
    defaultOn: true,
    category: StatCategory.fautesSanctions,
  ),
  StatDef(
    'fautesSubies',
    'Fautes subies',
    defaultOn: true,
    category: StatCategory.fautesSanctions,
  ),
  StatDef(
    'cartonsJaunes',
    'Cartons jaunes',
    defaultOn: true,
    category: StatCategory.fautesSanctions,
  ),
  StatDef(
    'cartonsRouges',
    'Cartons rouges',
    category: StatCategory.fautesSanctions,
  ),
  StatDef('horsJeu', 'Hors-jeux', category: StatCategory.fautesSanctions),
  // ── Gardien et défense ──
  StatDef('butsSubis', 'Buts subis', category: StatCategory.gardienDefense),
  StatDef(
    'arretsGardien',
    'Arrêts du gardien',
    category: StatCategory.gardienDefense,
  ),
  StatDef(
    'tirsSubisHors',
    'Tirs subis hors surface',
    defaultOn: true,
    category: StatCategory.gardienDefense,
  ),
  StatDef(
    'tirsSubisDans',
    'Tirs subis dans la surface',
    defaultOn: true,
    category: StatCategory.gardienDefense,
  ),
  StatDef(
    'totalTirsSubis',
    'Total tirs subis',
    category: StatCategory.gardienDefense,
    parts: <String>['tirsSubisHors', 'tirsSubisDans'],
  ),
  StatDef(
    'degagements',
    'Dégagements',
    defaultOn: true,
    category: StatCategory.gardienDefense,
  ),
  // ── Technique ──
  StatDef(
    'controleReussi',
    'Contrôles de balle réussis',
    defaultOn: true,
    category: StatCategory.technique,
  ),
  StatDef(
    'controleManque',
    'Contrôles de balle manqués',
    defaultOn: true,
    category: StatCategory.technique,
  ),
  StatDef(
    'pertesBallons',
    'Pertes de ballons',
    defaultOn: true,
    category: StatCategory.technique,
  ),
  // ── Duels et actions spéciales ──
  StatDef('duelsAeriens', 'Duels aériens gagnés', category: StatCategory.duels),
  StatDef(
    'duelsAeriensPerdus',
    'Duels aériens perdus',
    category: StatCategory.duels,
  ),
  StatDef(
    'duelsOffGagnes',
    'Duels offensifs gagnés',
    defaultOn: true,
    category: StatCategory.duels,
  ),
  StatDef(
    'duelsOffPerdus',
    'Duels offensifs perdus',
    defaultOn: true,
    category: StatCategory.duels,
  ),
  StatDef(
    'duelsDefGagnes',
    'Duels défensifs gagnés',
    defaultOn: true,
    category: StatCategory.duels,
  ),
  StatDef(
    'duelsDefPerdus',
    'Duels défensifs perdus',
    defaultOn: true,
    category: StatCategory.duels,
  ),
];

/// Les 37 statistiques saisies : seules à être des bascules du paramétrage
/// (les 5 calculées apparaissent d'elles-mêmes, voir
/// [enabledStatsInCatalogOrder]).
final List<StatDef> kStatToggles = <StatDef>[
  for (final StatDef s in kStatCatalog)
    if (!s.isCalculated) s,
];

final Map<String, StatDef> _statByKey = <String, StatDef>{
  for (final StatDef s in kStatCatalog) s.key: s,
};

/// Valeur de [key] dans [raw] (compteurs bruts `clé → valeur` d'un joueur,
/// d'une équipe ou d'un cumul). SEUL endroit qui calcule un total : il se
/// dérive de ses composantes, une valeur qui traînerait sous sa clé (anciens
/// matchs) est ignorée. Pour une période ou un cumul, sommer les compteurs
/// bruts PUIS appeler ceci, jamais l'inverse.
int readStat(Map<String, int>? raw, String key) {
  final StatDef? s = _statByKey[key];
  if (s != null && s.isTotal) {
    return s.parts.fold<int>(0, (int sum, String k) => sum + (raw?[k] ?? 0));
  }
  return raw?[key] ?? 0;
}

/// Valeur affichée quand une statistique n'a pas de sens (aucune passe pour un
/// pourcentage) ou pas de valeur (2e mi-temps non jouée). Tiret cadratin :
/// Poppins, police de l'app et du PDF collectif, le dessine ; le Helvetica par
/// défaut des autres PDF ne le dessinerait pas (aucun ne l'affiche).
const String kStatNoValue = '—';

/// Pourcentage [part] / [whole] au centième, demi vers le haut, virgule et
/// deux décimales toujours (« 75,00 % », espace insécable avant « % ») ;
/// [kStatNoValue] quand [whole] est nul. Arithmétique entière : `toStringAsFixed`
/// se trompe sur les demis (23/160 donne 14,37).
String formatPercent(int part, int whole) {
  if (whole <= 0) return kStatNoValue;
  final int centiemes = (part * 20000 + whole) ~/ (2 * whole);
  final String decimales = (centiemes % 100).toString().padLeft(2, '0');
  return '${centiemes ~/ 100},$decimales\u00A0%';
}

/// Texte affiché pour la stat [s] d'après les compteurs bruts [raw] : le nombre
/// (total calculé compris, voir [readStat]) ou, pour la stat en %
/// (`bilanOnly`, « Réussite de passes »), le pourcentage de passes réussies.
/// SEUL endroit qui assemble ce %, pour le bilan collectif comme pour le
/// tableau et le PDF individuels.
String formatStat(Map<String, int>? raw, StatDef s) =>
    s.bilanOnly
        ? formatPercent(
          readStat(raw, 'passesReussies'),
          readStat(raw, 'totalPasses'),
        )
        : '${readStat(raw, s.key)}';

/// Valeur maximale saisissable en direct pour [key], par match et par joueur.
/// Un joueur ne peut prendre qu'un seul carton rouge, et au plus deux jaunes
/// (au 2e, l'arbitre sort le rouge) ; les autres statistiques gardent le
/// plafond générique.
///
/// Plafond de SAISIE uniquement : les matchs déjà enregistrés au-dessus du
/// plafond restent affichés et cumulés tels quels (voir `career_stats.dart`).
int maxStatValue(String key) => switch (key) {
  'cartonsRouges' => 1,
  'cartonsJaunes' => 2,
  _ => 999,
};

/// Clés activées par défaut.
List<String> defaultEnabledStatKeys() => <String>[
  for (final StatDef s in kStatCatalog)
    if (s.defaultOn) s.key,
];

/// Clés de [keys] qui sont des bascules du paramétrage : écarte les stats
/// calculées et les clés inconnues que d'anciens matchs portent encore
/// (`enabledStatKeys` d'avant les stats calculées). C'est ce qui se compte
/// dans « X / 37 » et dans les pastilles « N statistiques ».
List<String> toggleKeys(Iterable<String> keys) => <String>[
  for (final String k in keys)
    if (_statByKey[k]?.isCalculated == false) k,
];

/// Statistiques suivies d'après [keys], **dans l'ordre du catalogue** (et non
/// celui du stockage : `enabledStatKeys` suit l'ordre de clic de l'écran de
/// paramétrage, une stat activée après coup partirait en fin de liste). Une
/// stat calculée est suivie quand TOUTES ses composantes le sont, que sa
/// propre clé figure ou non dans [keys] (anciens matchs). Les clés inconnues
/// du catalogue sont ignorées. Aucun filtre `bilanOnly` : chaque lecteur
/// applique le sien.
List<StatDef> enabledStatsInCatalogOrder(Iterable<String> keys) {
  final Set<String> enabled = keys.toSet();
  return <StatDef>[
    for (final StatDef s in kStatCatalog)
      if (s.isCalculated
          ? s.parts.every(enabled.contains)
          : enabled.contains(s.key))
        s,
  ];
}
