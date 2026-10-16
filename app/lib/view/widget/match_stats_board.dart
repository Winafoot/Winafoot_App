import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/player.dart';
import 'package:wina/models/stat_catalog.dart';

const String _kJersey = 'assets/images/shirt-l-blue.png';

// Métriques du tableau (pixels du design 1194 x 834 — Figma 1:2756).
const double _kLeftWidth = 305;
const double _kZoneGap = 10;
const double _kBarHeight = 35;
const double _kRowHeight = 36;
const double _kBarGap = 9;
const double _kGroupGap = 20;

/// Groupe du roster : libellé du poste (ou « Remplaçants ») + joueurs.
/// `number` est nul quand le joueur n'a pas de numéro attribué (maillot vide).
class _Group {
  const _Group(this.label, this.entries, {this.isSub = false});

  final String label;
  final List<({int? number, Player player})> entries;

  /// Groupe « Remplaçants » : maillot distinct de celui des titulaires.
  final bool isSub;
}

/// Tableau « Joueurs × Statistiques » partagé (bilan individuel, récap fin de
/// match, pause) — design 1:2756 : roster par poste à gauche (barres
/// d'en-tête blanches, nom / pied fort / numéro), colonnes de statistiques
/// défilables horizontalement à droite (barre d'en-tête blanche, valeurs
/// centrées sous leur libellé, filet sous chaque ligne). Les deux zones
/// partagent les mêmes hauteurs de ligne pour rester alignées.
///
/// Ce widget ne défile PAS verticalement : c'est ce qui garantit l'alignement.
/// L'écran hôte doit donc l'envelopper d'un `SingleChildScrollView` vertical
/// dès que la liste peut dépasser la hauteur disponible, sinon les dernières
/// lignes — les remplaçants — deviennent inatteignables.
class MatchStatsBoard extends StatelessWidget {
  const MatchStatsBoard({
    super.key,
    required this.live,
    required this.byId,
    this.controller,
    this.jerseyAsset,
    this.highlightPlayerId,
    this.noValue = false,
  });

  final LiveMatch live;
  final Map<String, Player> byId;

  /// Période sans valeurs (2e mi-temps non jouée) : les colonnes du match
  /// restent, chaque cellule affiche « — » au lieu d'un faux 0.
  final bool noValue;

  /// Joueur à mettre en évidence (choisi dans « Statistiques matchs ») ;
  /// `null` sur les écrans qui n'ont pas de sélection (mi-temps, fin de match).
  final String? highlightPlayerId;

  /// Contrôleur du défilement horizontal des statistiques — fourni par
  /// l'écran hôte pour piloter la pagination (flèches ‹ ›).
  final ScrollController? controller;
  final String? jerseyAsset;

  /// Titulaires groupés par poste (ordre des emplacements) puis remplaçants.
  List<_Group> _groups() {
    final List<_Group> groups = <_Group>[];
    for (final PlayerPosition pos in PlayerPosition.values) {
      final List<({int? number, Player player})> entries = live.startersAt(
        pos,
        byId,
      );
      if (entries.isNotEmpty) groups.add(_Group(pos.label, entries));
    }
    final List<({int? number, Player player})> subs = live.substitutes(byId);
    if (subs.isNotEmpty) {
      groups.add(
        _Group('app.match-stats-board.remplacants'.tr(), subs, isSub: true),
      );
    }
    return groups;
  }

  /// Ligne d'espacement du tableau des statistiques (une cellule par
  /// colonne pour rester carré avec les autres lignes).
  TableRow _spacerRow(int columns, double height) {
    return TableRow(
      children: List<Widget>.generate(
        columns,
        (_) => SizedBox(height: formatHeight(height)),
      ),
    );
  }

  /// Cellule du tableau des statistiques : retrait gauche pour la première
  /// colonne, 20 px d'écart après chaque colonne.
  Widget _cell(int index, double height, Widget child) {
    return SizedBox(
      height: formatHeight(height),
      child: Padding(
        padding: EdgeInsets.only(
          left: index == 0 ? formatWidth(15) : 0,
          right: formatWidth(20),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_Group> groups = _groups();
    // Toutes les stats suivies, calculées comprises : totaux et « Réussite de
    // passes » (en %) se dérivent des compteurs du joueur (voir `formatStat`).
    final List<StatDef> stats = enabledStatsInCatalogOrder(
      live.enabledStatKeys,
    );

    final List<Widget> left = <Widget>[];
    final List<TableRow> right = <TableRow>[];
    for (int g = 0; g < groups.length; g++) {
      if (g > 0) {
        left.add(sh(_kGroupGap));
        if (stats.isNotEmpty) right.add(_spacerRow(stats.length, _kGroupGap));
      }
      left.add(_GroupBar(label: groups[g].label));
      if (stats.isNotEmpty) {
        right.add(
          g == 0
              ? TableRow(
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(r(12)),
                ),
                children: <Widget>[
                  for (int i = 0; i < stats.length; i++)
                    _cell(
                      i,
                      _kBarHeight,
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          stats[i].label,
                          maxLines: 1,
                          style: AppThemeStyle.regularStyle(
                            13,
                            AppColor.primaryLabels,
                          ),
                        ),
                      ),
                    ),
                ],
              )
              : _spacerRow(stats.length, _kBarHeight),
        );
      }
      left.add(sh(_kBarGap));
      if (stats.isNotEmpty) right.add(_spacerRow(stats.length, _kBarGap));
      for (final ({int? number, Player player}) e in groups[g].entries) {
        final bool hl =
            highlightPlayerId != null && e.player.id == highlightPlayerId;
        left.add(
          _PlayerCell(
            number: e.number,
            player: e.player,
            // Le repli `?? _kJersey` est appliqué AVANT la règle, pas après :
            // `subJerseyAsset(x)` garantit un asset différent de `x`, mais
            // seulement si les deux rôles partent du même `x`. Le calculer sur
            // le nullable brut ferait tenir la distinction par coïncidence
            // entre `_kJersey` et le repli de la règle, et changer l'un des
            // deux recollerait les rôles sans qu'aucun test ne tombe.
            jerseyAsset:
                groups[g].isSub
                    ? subJerseyAsset(jerseyAsset ?? _kJersey)
                    : jerseyAsset,
            highlighted: hl,
          ),
        );
        if (stats.isNotEmpty) {
          right.add(
            TableRow(
              decoration: BoxDecoration(
                color: hl ? AppColor.rosterRowHighlight : null,
                border: Border(
                  bottom: BorderSide(
                    color: AppColor.primaryLabels.withValues(alpha: .10),
                  ),
                ),
              ),
              children: <Widget>[
                for (int i = 0; i < stats.length; i++)
                  _cell(
                    i,
                    _kRowHeight,
                    Center(
                      child: Text(
                        noValue
                            ? kStatNoValue
                            : formatStat(
                              live.playerStats[e.player.id!],
                              stats[i],
                            ),
                        style: AppThemeStyle.mediumStyle(
                          15,
                          AppColor.primaryLabels,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: formatWidth(_kLeftWidth),
          // Aucun défilement vertical ICI, et il ne faut pas en remettre : le
          // volet droit n'en a pas (il ne défile qu'à l'horizontale), donc un
          // scroll propre à la colonne des noms les laisse dériver l'un par
          // rapport à l'autre. Le tableau affiche alors les statistiques d'un
          // joueur en face du nom d'un autre, sans le moindre indice visuel.
          // Le défilement vertical appartient à l'écran hôte, qui fait défiler
          // la carte entière — cf. bilan_individuel_screen.dart.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: left,
          ),
        ),
        sw(_kZoneGap),
        Expanded(
          child: SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: right,
            ),
          ),
        ),
      ],
    );
  }
}

/// Barre d'en-tête d'un poste : libellé + colonnes « Pied Fort » / « Numéro ».
class _GroupBar extends StatelessWidget {
  const _GroupBar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: formatHeight(_kBarHeight),
      padding: EdgeInsets.symmetric(horizontal: formatWidth(16)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(r(12)),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: formatWidth(130),
            child: Text(
              label,
              style: AppThemeStyle.mediumStyle(15, AppColor.primaryLabels),
            ),
          ),
          SizedBox(
            width: formatWidth(87),
            child: Text(
              'app.match-stats-board.pied-fort'.tr(),
              style: AppThemeStyle.regularStyle(13, AppColor.primaryLabels),
            ),
          ),
          Text(
            'app.match-stats-board.numero'.tr(),
            style: AppThemeStyle.regularStyle(13, AppColor.primaryLabels),
          ),
        ],
      ),
    );
  }
}

/// Ligne joueur du roster : nom (vert) / pied fort / maillot numéroté.
class _PlayerCell extends StatelessWidget {
  const _PlayerCell({
    required this.number,
    required this.player,
    this.jerseyAsset,
    this.highlighted = false,
  });

  final int? number;
  final String? jerseyAsset;
  final Player player;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: formatHeight(_kRowHeight),
      // Fond opaque : sans lui la ligne est posée nue sur la pelouse
      // d'AppBackground et le nom y descend sous 2:1.
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: formatWidth(16)),
        decoration: BoxDecoration(
          color:
              highlighted
                  ? AppColor.rosterRowHighlight
                  : AppColor.rosterRowSurface,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: formatWidth(130),
              child: Text(
                player.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppThemeStyle.mediumStyle(15, AppColor.rosterName),
              ),
            ),
            SizedBox(
              width: formatWidth(87),
              child: Text(
                player.strongFoot.label,
                style: AppThemeStyle.mediumStyle(15, AppColor.primaryLabels),
              ),
            ),
            _NumberJersey(number: number, jerseyAsset: jerseyAsset),
          ],
        ),
      ),
    );
  }
}

/// Maillot miniature portant le numéro du joueur (colonne « Numéro »), vide
/// quand aucun numéro ne lui est attribué.
class _NumberJersey extends StatelessWidget {
  const _NumberJersey({required this.number, this.jerseyAsset});

  final int? number;
  final String? jerseyAsset;

  @override
  Widget build(BuildContext context) {
    final double d = sp(30);
    return SizedBox(
      width: d,
      height: d,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Image.asset(jerseyAsset ?? _kJersey, fit: BoxFit.contain),
          if (number != null)
            Padding(
              padding: EdgeInsets.only(top: d * 0.08),
              child: Text(
                '$number',
                style: AppThemeStyle.semiBStyle(
                  13,
                  numberColorForJerseyAsset(jerseyAsset ?? _kJersey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
