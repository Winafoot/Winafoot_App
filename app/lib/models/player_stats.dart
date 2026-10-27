import 'package:flutter/foundation.dart';

/// Définition d'une statistique affichée sur la page « Détail joueur » :
/// le libellé visible et un éventuel espacement avant la cellule.
///
/// Le libellé reprend à l'identique celui de `kStatCatalog` ; c'est lui qui
/// relie la cellule à la clé persistée dans `playerStats` (voir
/// `statKeyForLabel` dans `career_stats.dart`).
@immutable
class StatDef {
  const StatDef(this.label, {this.hasSpace = false});

  /// Libellé affiché à gauche de la cellule.
  final String label;

  /// Ajoute un espacement avant la cellule (séparation visuelle de groupes).
  final bool hasSpace;
}

/// Les 3 colonnes de statistiques de la page « Détail joueur » (12 / 10 / 10
/// lignes, 32 statistiques : celles du catalogue, hors « Réussite de passes »,
/// voir `stat_catalog.dart`). Le lien avec le catalogue se fait par le libellé.
const List<List<StatDef>> kPlayerStatColumns = <List<StatDef>>[
  // ── Colonne 1 ──────────────────────────────────────────────────────────────
  <StatDef>[
    StatDef('Récupérations de ballons'),
    StatDef('Passes réussies'),
    StatDef('Passes manquées'),
    StatDef('Total passes'),
    StatDef('Pertes de ballons'),
    StatDef('Tirs cadrés', hasSpace: true),
    StatDef('Tirs non cadrés'),
    StatDef('Total tirs'),
    StatDef('Passes décisives', hasSpace: true),
    StatDef('Buts marqués'),
    StatDef('Buts subis'),
    StatDef('Arrêts du gardien', hasSpace: true),
  ],
  // ── Colonne 2 ──────────────────────────────────────────────────────────────
  <StatDef>[
    StatDef('Tirs subis hors de la surface'),
    StatDef('Tirs subis dans la surface'),
    StatDef('Total tirs subis'),
    StatDef('Contrôles réussis', hasSpace: true),
    StatDef('Contrôles manqués'),
    StatDef('Hors-jeu'),
    StatDef('Duels aériens gagnés', hasSpace: true),
    StatDef('Duels aériens perdus'),
    StatDef('Penaltys subis'),
    StatDef('Penaltys obtenus'),
  ],
  // ── Colonne 3 ──────────────────────────────────────────────────────────────
  <StatDef>[
    StatDef('Nombre de centres'),
    StatDef('Passes en profondeur'),
    StatDef('Duels gagnés'),
    StatDef('Duels perdus'),
    StatDef('Centres réussis'),
    StatDef('Centres manqués'),
    StatDef('Fautes commises', hasSpace: true),
    StatDef('Fautes subies'),
    StatDef('Cartons jaunes'),
    StatDef('Cartons rouges'),
  ],
];
