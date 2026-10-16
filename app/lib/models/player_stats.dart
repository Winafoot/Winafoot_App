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

/// Les 3 colonnes de statistiques de la page « Détail joueur », dans l'ordre
/// EXACT du design Figma (14 / 14 / 13 lignes, 41 statistiques au total).
const List<List<StatDef>> kPlayerStatColumns = <List<StatDef>>[
  // ── Colonne 1 ──────────────────────────────────────────────────────────────
  <StatDef>[
    StatDef('Interception de ballons'),
    StatDef('Récupération de ballons'),
    StatDef('Passes réussies'),
    StatDef('Passes manquées'),
    StatDef('Total passes'),
    StatDef('Pertes de ballons'),
    StatDef('Tirs cadrés', hasSpace: true),
    StatDef('Tirs non cadrés'),
    StatDef('Tirs bloqués'),
    StatDef('Total tirs'),
    StatDef('Passes décisives', hasSpace: true),
    StatDef('Buts marqués'),
    StatDef('Buts subis'),
    StatDef('Arrêts du gardien', hasSpace: true),
  ],
  // ── Colonne 2 ──────────────────────────────────────────────────────────────
  <StatDef>[
    StatDef('Tirs subis hors surface'),
    StatDef('Tirs subis dans la surface'),
    StatDef('Total tirs subis'),
    StatDef('Contrôles de balle réussis', hasSpace: true),
    StatDef('Contrôles de balle manqués'),
    StatDef('Hors-jeux'),
    StatDef('Duels aériens gagnés', hasSpace: true),
    StatDef('Duels aériens perdus'),
    StatDef('Corners obtenus'),
    StatDef('Penaltys subis'),
    StatDef('Coups francs subis'),
    StatDef('Penaltys obtenus'),
    StatDef('Coups francs obtenus'),
    StatDef('Nombre de touches'),
  ],
  // ── Colonne 3 ──────────────────────────────────────────────────────────────
  <StatDef>[
    StatDef('Nombre de centres'),
    StatDef('Passes en profondeur'),
    StatDef('Duels défensifs gagnés'),
    StatDef('Duels défensifs perdus'),
    StatDef('Duels offensifs gagnés'),
    StatDef('Duels offensifs perdus'),
    StatDef('Dégagements'),
    StatDef('Centres réussis'),
    StatDef('Centres manqués'),
    StatDef('Fautes commises', hasSpace: true),
    StatDef('Fautes subies'),
    StatDef('Cartons jaunes'),
    StatDef('Cartons rouges'),
  ],
];
