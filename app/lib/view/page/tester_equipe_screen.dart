import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/career_stats.dart';
import 'package:wina/models/custom_composition.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/player.dart';
import 'package:wina/models/player_stats.dart';
import 'package:wina/models/stat_catalog.dart' show readStat;
import 'package:wina/providers/match_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/custom_back_button.dart';
import 'package:wina/view/widget/formation_pitch.dart';

const String _kJersey = 'assets/images/shirt-l-blue.png';
const String _kEmptyJersey = 'assets/images/shirt-empty.png';

/// Écran « Tester mon équipe » (Figma 1:21515).
///
/// Permet d'essayer une composition avec de vrais joueurs, hors match :
/// gauche = effectif glissable (par poste), centre = terrain de la composition
/// où l'on place les joueurs, droite = statistiques carrière du joueur
/// sélectionné. Les placements sont locaux (rien n'est enregistré).
class TesterEquipeScreen extends ConsumerStatefulWidget {
  const TesterEquipeScreen({super.key, required this.composition});

  final CustomComposition composition;

  @override
  ConsumerState<TesterEquipeScreen> createState() => _TesterEquipeScreenState();
}

class _TesterEquipeScreenState extends ConsumerState<TesterEquipeScreen> {
  /// emplacement (index) → playerId.
  final Map<int, String> _assignments = <int, String>{};

  /// Joueur sélectionné pour l'affichage des statistiques.
  String? _selectedPlayerId;

  Formation get _formation => widget.composition.toFormation();

  void _assign(int slot, String playerId) {
    setState(() {
      _assignments.removeWhere((int _, String id) => id == playerId);
      _assignments[slot] = playerId;
      _selectedPlayerId = playerId;
    });
  }

  void _unassign(int slot) {
    setState(() {
      final String? removed = _assignments.remove(slot);
      if (removed != null && removed == _selectedPlayerId) {
        _selectedPlayerId = null;
      }
    });
  }

  /// Emplacement occupé par [playerId], ou `null` s'il n'est pas placé.
  int? _slotOf(String playerId) {
    for (final MapEntry<int, String> e in _assignments.entries) {
      if (e.value == playerId) return e.key;
    }
    return null;
  }

  void _pickForSlot(int slot, List<Player> available) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColor.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(r(20))),
      ),
      // `ctx` (contexte du builder) et non celui de la page : c'est lui qui
      // désigne le navigator portant la feuille, quel que soit
      // `useRootNavigator`.
      builder:
          (BuildContext ctx) => _PlayerPickerSheet(
            players: available,
            onPick: (Player p) {
              _assign(slot, p.id!);
              Navigator.of(ctx).pop();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Player> players =
        (ref.watch(playersStreamProvider).valueOrNull ?? const <Player>[])
            .where((Player p) => p.id != null)
            .toList(growable: false);
    final Map<String, Player> byId = <String, Player>{
      for (final Player p in players) p.id!: p,
    };
    final Set<String> assignedIds = _assignments.values.toSet();
    final List<Player> unplaced = players
        .where((Player p) => !assignedIds.contains(p.id))
        .toList(growable: false);
    final Map<String, Map<String, int>> career = ref.watch(careerStatsProvider);
    final Player? selected =
        _selectedPlayerId != null ? byId[_selectedPlayerId] : null;

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const AppBackground(),
            Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: formatWidth(40)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      sh(18),
                      _header(),
                      sh(14),
                      Container(height: 1, color: AppColor.divider),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      formatWidth(40),
                      formatHeight(16),
                      formatWidth(40),
                      formatHeight(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: formatWidth(320),
                          child: _RosterColumn(unplaced: unplaced),
                        ),
                        sw(24),
                        SizedBox(
                          width: formatWidth(300),
                          child: _CompositionColumn(
                            formation: _formation,
                            label: widget.composition.formationLabel,
                            name: widget.composition.name,
                            assignments: _assignments,
                            byId: byId,
                            selectedId: _selectedPlayerId,
                            onAssign: _assign,
                            onSelect:
                                (int slot) => setState(
                                  () => _selectedPlayerId = _assignments[slot],
                                ),
                            onTapEmpty:
                                (int slot) => _pickForSlot(slot, unplaced),
                          ),
                        ),
                        sw(24),
                        Expanded(
                          child: _StatsPanel(
                            player: selected,
                            stats:
                                selected != null
                                    ? (career[selected.id] ??
                                        const <String, int>{})
                                    : const <String, int>{},
                            onRemove:
                                selected != null
                                    ? () {
                                      final int? slot = _slotOf(selected.id!);
                                      if (slot != null) _unassign(slot);
                                    }
                                    : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: <Widget>[
        CustomBackButton(onTap: () => Navigator.of(context).maybePop()),
        sw(14),
        Icon(Iconsax.people, size: sp(26), color: AppColor.primaryColor),
        sw(10),
        Text(
          'app.tester-equipe.entete'.tr(),
          style: AppThemeStyle.semiBStyle(28, AppColor.primaryLabels),
        ),
        const Spacer(),
        const WinaWordmark(size: 34),
      ],
    );
  }
}

/// Colonne « Joueurs » : effectif glissable regroupé par poste.
class _RosterColumn extends StatelessWidget {
  const _RosterColumn({required this.unplaced});

  final List<Player> unplaced;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'app.tester-equipe.joueurs'.tr(),
          style: AppThemeStyle.semiBStyle(16, AppColor.primaryLabels),
        ),
        sh(10),
        Expanded(
          child:
              unplaced.isEmpty
                  ? Text(
                    'app.tester-equipe.tous-places'.tr(),
                    style: AppThemeStyle.regularStyle(
                      13,
                      AppColor.secondaryLabels,
                    ),
                  )
                  : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (final PlayerPosition pos in PlayerPosition.values)
                          ..._group(pos),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }

  List<Widget> _group(PlayerPosition pos) {
    final List<Player> list = unplaced
        .where((Player p) => p.position == pos)
        .toList(growable: false);
    if (list.isEmpty) return const <Widget>[];
    return <Widget>[
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: formatWidth(10),
          vertical: formatHeight(7),
        ),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(r(10)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                pos.label,
                style: AppThemeStyle.semiBStyle(13, AppColor.primaryLabels),
              ),
            ),
            Text(
              'app.tester-equipe.pied-fort'.tr(),
              style: AppThemeStyle.regularStyle(11, AppColor.secondaryLabels),
            ),
            sw(18),
            Text(
              'app.tester-equipe.numero'.tr(),
              style: AppThemeStyle.regularStyle(11, AppColor.secondaryLabels),
            ),
          ],
        ),
      ),
      sh(6),
      for (final Player p in list) ...<Widget>[
        _DraggablePlayerTile(player: p),
        sh(6),
      ],
      sh(8),
    ];
  }
}

/// Ligne joueur glissable (nom + pied fort + maillot).
class _DraggablePlayerTile extends StatelessWidget {
  const _DraggablePlayerTile({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final Widget tile = Row(
      children: <Widget>[
        Expanded(
          child: Text(
            player.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemeStyle.mediumStyle(14, AppColor.primaryColor),
          ),
        ),
        sw(8),
        SizedBox(
          width: formatWidth(56),
          child: Text(
            player.strongFoot.label,
            style: AppThemeStyle.regularStyle(12, AppColor.secondaryLabels),
          ),
        ),
        Image.asset(_kJersey, width: sp(26), height: sp(26)),
      ],
    );
    return Draggable<Player>(
      data: player,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Image.asset(_kJersey, width: sp(44), height: sp(44)),
      childWhenDragging: Opacity(opacity: 0.4, child: tile),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: formatWidth(10)),
        child: tile,
      ),
    );
  }
}

/// Colonne centrale : nom + schéma + terrain de la composition.
class _CompositionColumn extends StatelessWidget {
  const _CompositionColumn({
    required this.formation,
    required this.label,
    required this.name,
    required this.assignments,
    required this.byId,
    required this.selectedId,
    required this.onAssign,
    required this.onSelect,
    required this.onTapEmpty,
  });

  final Formation formation;
  final String label;
  final String name;
  final Map<int, String> assignments;
  final Map<String, Player> byId;
  final String? selectedId;
  final void Function(int slot, String playerId) onAssign;
  final void Function(int slot) onSelect;
  final void Function(int slot) onTapEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(formatWidth(12)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(r(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemeStyle.semiBStyle(15, AppColor.primaryLabels),
                ),
              ),
              sw(8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: formatWidth(12),
                  vertical: formatHeight(5),
                ),
                decoration: BoxDecoration(
                  color: AppColor.chipBackground,
                  borderRadius: BorderRadius.circular(r(12)),
                ),
                child: Text(
                  label,
                  style: AppThemeStyle.semiBStyle(12, AppColor.primaryLabels),
                ),
              ),
            ],
          ),
          sh(12),
          _AssignPitch(
            formation: formation,
            assignments: assignments,
            byId: byId,
            selectedId: selectedId,
            onAssign: onAssign,
            onSelect: onSelect,
            onTapEmpty: onTapEmpty,
          ),
        ],
      ),
    );
  }
}

/// Terrain de la composition : un emplacement par slot (glisser pour placer,
/// toucher un emplacement vide pour choisir, toucher un joueur pour le
/// sélectionner).
class _AssignPitch extends StatelessWidget {
  const _AssignPitch({
    required this.formation,
    required this.assignments,
    required this.byId,
    required this.selectedId,
    required this.onAssign,
    required this.onSelect,
    required this.onTapEmpty,
  });

  final Formation formation;
  final Map<int, String> assignments;
  final Map<String, Player> byId;
  final String? selectedId;
  final void Function(int slot, String playerId) onAssign;
  final void Function(int slot) onSelect;
  final void Function(int slot) onTapEmpty;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(r(14)),
      child: AspectRatio(
        aspectRatio: 404 / 699,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;
            final double m = w * 0.155;
            final List<Widget> markers = <Widget>[];
            for (int i = 0; i < formation.slots.length; i++) {
              final FormationSlot slot = formation.slots[i];
              final String? pid = assignments[i];
              final Player? player = pid != null ? byId[pid] : null;
              markers.add(
                Positioned(
                  left: slot.x * w - m / 2,
                  top: slot.y * h - m / 2,
                  width: m,
                  child: DragTarget<Player>(
                    onWillAcceptWithDetails: (_) => true,
                    onAcceptWithDetails:
                        (DragTargetDetails<Player> d) =>
                            onAssign(i, d.data.id!),
                    builder: (
                      BuildContext context,
                      List<Player?> candidates,
                      List<dynamic> rejected,
                    ) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap:
                            () => player == null ? onTapEmpty(i) : onSelect(i),
                        child: _Slot(
                          size: m,
                          player: player,
                          highlighted: candidates.isNotEmpty,
                          selected: player != null && pid == selectedId,
                        ),
                      );
                    },
                  ),
                ),
              );
            }
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Image.asset(kPitchPortraitAsset, fit: BoxFit.cover),
                ),
                ...markers,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.size,
    required this.player,
    required this.highlighted,
    required this.selected,
  });

  final double size;
  final Player? player;
  final bool highlighted;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Player? p = player;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration:
              selected
                  ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColor.primaryColor, width: 2),
                  )
                  : null,
          child:
              p == null
                  ? Opacity(
                    opacity: highlighted ? 1 : 0.9,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Image.asset(_kEmptyJersey, fit: BoxFit.contain),
                        Icon(
                          Iconsax.add_copy,
                          size: size * 0.32,
                          color: AppColor.textLight,
                        ),
                      ],
                    ),
                  )
                  : Image.asset(_kJersey, fit: BoxFit.contain),
        ),
        if (p != null) ...<Widget>[
          SizedBox(height: formatHeight(4)),
          Text(
            _short(p),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemeStyle.semiBStyle(11, AppColor.textLight),
          ),
        ],
      ],
    );
  }

  String _short(Player p) {
    final String initial = p.lastName.isNotEmpty ? '${p.lastName[0]}.' : '';
    return '${p.firstName} $initial';
  }
}

/// Panneau droit « Statistiques joueur ».
class _StatsPanel extends StatelessWidget {
  const _StatsPanel({
    required this.player,
    required this.stats,
    required this.onRemove,
  });

  final Player? player;
  final Map<String, int> stats;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final Player? p = player;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'app.tester-equipe.stats-titre'.tr(),
              style: AppThemeStyle.semiBStyle(16, AppColor.primaryLabels),
            ),
            if (p != null)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Image.asset(_kJersey, width: sp(30), height: sp(30)),
                      sw(10),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              p.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppThemeStyle.semiBStyle(
                                15,
                                AppColor.primaryLabels,
                              ),
                            ),
                            Text(
                              p.position.singular,
                              style: AppThemeStyle.regularStyle(
                                12,
                                AppColor.secondaryLabels,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        sh(10),
        if (p == null)
          Text(
            'app.tester-equipe.aucun-joueur-selectionne'.tr(),
            style: AppThemeStyle.regularStyle(13, AppColor.secondaryLabels),
          )
        else ...<Widget>[
          Expanded(child: _details()),
          sh(16),
          if (onRemove != null) _RemoveButton(onTap: onRemove!),
        ],
      ],
    );
  }

  /// Cumul carrière du joueur, une pilule par statistique (0 si aucun match).
  Widget _details() {
    final List<StatDef> rows = <StatDef>[
      for (final List<StatDef> column in kPlayerStatColumns) ...column,
    ];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) rows[i].hasSpace ? sh(14) : sh(6),
            _cell(rows[i].label),
          ],
        ],
      ),
    );
  }

  Widget _cell(String label) {
    final String? key = statKeyForLabel(label);
    return Container(
      height: formatHeight(36),
      padding: EdgeInsets.symmetric(horizontal: formatWidth(16)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(r(10)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.regularStyle(14, AppColor.primaryLabels),
            ),
          ),
          sw(10),
          Text(
            '${key == null ? 0 : readStat(stats, key)}',
            style: AppThemeStyle.boldStyle(14, AppColor.primaryLabels),
          ),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(r(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r(12)),
            border: Border.all(color: AppColor.divider),
          ),
          padding: EdgeInsets.symmetric(vertical: formatHeight(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Iconsax.close_circle,
                size: sp(16),
                color: AppColor.destructive,
              ),
              sw(8),
              Text(
                'app.tester-equipe.retirer'.tr(),
                style: AppThemeStyle.semiBStyle(13, AppColor.destructive),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Feuille de sélection d'un joueur pour un emplacement vide.
class _PlayerPickerSheet extends StatelessWidget {
  const _PlayerPickerSheet({required this.players, required this.onPick});

  final List<Player> players;
  final ValueChanged<Player> onPick;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: formatWidth(24),
          vertical: formatHeight(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'app.tester-equipe.choisir-joueur'.tr(),
              style: AppThemeStyle.semiBStyle(16, AppColor.primaryLabels),
            ),
            sh(12),
            if (players.isEmpty)
              Text(
                'app.tester-equipe.aucun-joueur-disponible'.tr(),
                style: AppThemeStyle.regularStyle(13, AppColor.secondaryLabels),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: formatWidth(10),
                    runSpacing: formatHeight(10),
                    children: <Widget>[
                      for (final Player p in players)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onPick(p),
                          child: Container(
                            width: formatWidth(220),
                            padding: EdgeInsets.symmetric(
                              horizontal: formatWidth(12),
                              vertical: formatHeight(10),
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.background,
                              borderRadius: BorderRadius.circular(r(12)),
                              border: Border.all(color: AppColor.divider),
                            ),
                            child: Row(
                              children: <Widget>[
                                Image.asset(
                                  _kJersey,
                                  width: sp(24),
                                  height: sp(24),
                                ),
                                sw(10),
                                Expanded(
                                  child: Text(
                                    p.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppThemeStyle.mediumStyle(
                                      14,
                                      AppColor.primaryLabels,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
