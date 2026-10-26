import 'dart:math' as math;

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/orientation_controller.dart';
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

// Sur téléphone (paysage, ~360 dp de haut), la mise à l'échelle de la maquette
// tablette 1194x834 écrase les hauteurs et rend les textes illisibles : on
// bascule sur des dimensions compactes en dp réels. La tablette est inchangée.
bool get _phone => OrientationController.isPhone;
const double _phoneDim = 0.65;
double _w(double v) => _phone ? v * _phoneDim : formatWidth(v);
double _h(double v) => _phone ? v * _phoneDim : formatHeight(v);
double _r(double v) => _phone ? v * _phoneDim : r(v);
double _ic(double v) => _phone ? v * 0.8 : sp(v);
// Les styles de AppThemeStyle appliquent déjà sp() : on pré-divise pour
// obtenir une taille de police réelle sur téléphone.
double _fs(double v) => _phone ? math.max(10.0, v * 0.8) / sp(1) : v;
Widget _sw(double v) => SizedBox(width: _w(v));
Widget _sh(double v) => SizedBox(height: _h(v));

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(_r(20))),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: _phone ? 16 : _w(40),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _sh(_phone ? 10 : 18),
                      _header(),
                      _sh(_phone ? 8 : 14),
                      Container(height: 1, color: AppColor.divider),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      _phone ? 16 : _w(40),
                      _phone ? 8 : _h(16),
                      _phone ? 16 : _w(40),
                      _phone ? 8 : _h(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _col(
                          flex: 5,
                          width: 320,
                          child: _RosterColumn(unplaced: unplaced),
                        ),
                        _sw(_phone ? 12 : 24),
                        _col(
                          flex: 4,
                          width: 300,
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
                        _sw(_phone ? 12 : 24),
                        Expanded(
                          flex: 5,
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

  /// Colonne à largeur fixe sur tablette, proportionnelle sur téléphone.
  Widget _col({
    required int flex,
    required double width,
    required Widget child,
  }) {
    return _phone
        ? Expanded(flex: flex, child: child)
        : SizedBox(width: _w(width), child: child);
  }

  Widget _header() {
    return Row(
      children: <Widget>[
        CustomBackButton(onTap: () => Navigator.of(context).maybePop()),
        _sw(14),
        Icon(Iconsax.people, size: _ic(26), color: AppColor.primaryColor),
        _sw(10),
        Text(
          'app.tester-equipe.entete'.tr(),
          style: AppThemeStyle.semiBStyle(_fs(28), AppColor.primaryLabels),
        ),
        const Spacer(),
        WinaWordmark(size: _phone ? 22 : 34),
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
          style: AppThemeStyle.semiBStyle(_fs(16), AppColor.primaryLabels),
        ),
        _sh(10),
        Expanded(
          child:
              unplaced.isEmpty
                  ? Text(
                    'app.tester-equipe.tous-places'.tr(),
                    style: AppThemeStyle.regularStyle(
                      _fs(13),
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
        padding: EdgeInsets.symmetric(horizontal: _w(10), vertical: _h(7)),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(_r(10)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                pos.label,
                style: AppThemeStyle.semiBStyle(
                  _fs(13),
                  AppColor.primaryLabels,
                ),
              ),
            ),
            Text(
              'app.tester-equipe.pied-fort'.tr(),
              style: AppThemeStyle.regularStyle(
                _fs(11),
                AppColor.secondaryLabels,
              ),
            ),
            _sw(18),
            Text(
              'app.tester-equipe.numero'.tr(),
              style: AppThemeStyle.regularStyle(
                _fs(11),
                AppColor.secondaryLabels,
              ),
            ),
          ],
        ),
      ),
      _sh(6),
      for (final Player p in list) ...<Widget>[
        _DraggablePlayerTile(player: p),
        _sh(6),
      ],
      _sh(8),
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
            style: AppThemeStyle.mediumStyle(_fs(14), AppColor.primaryColor),
          ),
        ),
        _sw(8),
        SizedBox(
          width: _w(56),
          child: Text(
            player.strongFoot.label,
            style: AppThemeStyle.regularStyle(
              _fs(12),
              AppColor.secondaryLabels,
            ),
          ),
        ),
        Image.asset(_kJersey, width: _ic(26), height: _ic(26)),
      ],
    );
    final Widget feedback = Image.asset(
      _kJersey,
      width: _ic(44),
      height: _ic(44),
    );
    final Widget child = Padding(
      padding: EdgeInsets.symmetric(horizontal: _w(10)),
      child: tile,
    );
    // Téléphone : un `Draggable` immédiat bloquerait le défilement de la liste.
    if (_phone) {
      return LongPressDraggable<Player>(
        data: player,
        delay: const Duration(milliseconds: 150),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: feedback,
        childWhenDragging: Opacity(opacity: 0.4, child: tile),
        child: child,
      );
    }
    return Draggable<Player>(
      data: player,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: feedback,
      childWhenDragging: Opacity(opacity: 0.4, child: tile),
      child: child,
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
    if (!_phone) return _tabletCard();
    // Téléphone : seul le terrain, au plus grand format qui tient dans la
    // colonne (la hauteur est la contrainte, le ratio est fixe).
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double ph = math.min(c.maxHeight, c.maxWidth * 699 / 404);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: ph * 404 / 699,
            height: ph,
            child: _AssignPitch(
              formation: formation,
              assignments: assignments,
              byId: byId,
              selectedId: selectedId,
              onAssign: onAssign,
              onSelect: onSelect,
              onTapEmpty: onTapEmpty,
            ),
          ),
        );
      },
    );
  }

  Widget _tabletCard() {
    return Container(
      padding: EdgeInsets.all(_w(12)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(_r(18)),
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
                  style: AppThemeStyle.semiBStyle(
                    _fs(15),
                    AppColor.primaryLabels,
                  ),
                ),
              ),
              _sw(8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _w(12),
                  vertical: _h(5),
                ),
                decoration: BoxDecoration(
                  color: AppColor.chipBackground,
                  borderRadius: BorderRadius.circular(_r(12)),
                ),
                child: Text(
                  label,
                  style: AppThemeStyle.semiBStyle(
                    _fs(12),
                    AppColor.primaryLabels,
                  ),
                ),
              ),
            ],
          ),
          _sh(12),
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
      borderRadius: BorderRadius.circular(_r(14)),
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
          SizedBox(height: _h(4)),
          Text(
            _short(p),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemeStyle.semiBStyle(_fs(11), AppColor.textLight),
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
              style: AppThemeStyle.semiBStyle(_fs(16), AppColor.primaryLabels),
            ),
            if (p != null)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Image.asset(_kJersey, width: _ic(30), height: _ic(30)),
                      _sw(10),
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
                                _fs(15),
                                AppColor.primaryLabels,
                              ),
                            ),
                            Text(
                              p.position.singular,
                              style: AppThemeStyle.regularStyle(
                                _fs(12),
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
        _sh(10),
        if (p == null)
          Text(
            'app.tester-equipe.aucun-joueur-selectionne'.tr(),
            style: AppThemeStyle.regularStyle(
              _fs(13),
              AppColor.secondaryLabels,
            ),
          )
        else ...<Widget>[
          Expanded(child: _details()),
          _sh(16),
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
            if (i > 0) rows[i].hasSpace ? _sh(14) : _sh(6),
            _cell(rows[i].label),
          ],
        ],
      ),
    );
  }

  Widget _cell(String label) {
    final String? key = statKeyForLabel(label);
    return Container(
      height: _h(36),
      padding: EdgeInsets.symmetric(horizontal: _w(16)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(_r(10)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.regularStyle(
                _fs(14),
                AppColor.primaryLabels,
              ),
            ),
          ),
          _sw(10),
          Text(
            '${key == null ? 0 : readStat(stats, key)}',
            style: AppThemeStyle.boldStyle(_fs(14), AppColor.primaryLabels),
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
      borderRadius: BorderRadius.circular(_r(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_r(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_r(12)),
            border: Border.all(color: AppColor.divider),
          ),
          padding: EdgeInsets.symmetric(vertical: _h(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Iconsax.close_circle,
                size: _ic(16),
                color: AppColor.destructive,
              ),
              _sw(8),
              Text(
                'app.tester-equipe.retirer'.tr(),
                style: AppThemeStyle.semiBStyle(_fs(13), AppColor.destructive),
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
        padding: EdgeInsets.symmetric(horizontal: _w(24), vertical: _h(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'app.tester-equipe.choisir-joueur'.tr(),
              style: AppThemeStyle.semiBStyle(_fs(16), AppColor.primaryLabels),
            ),
            _sh(12),
            if (players.isEmpty)
              Text(
                'app.tester-equipe.aucun-joueur-disponible'.tr(),
                style: AppThemeStyle.regularStyle(
                  _fs(13),
                  AppColor.secondaryLabels,
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: _w(10),
                    runSpacing: _h(10),
                    children: <Widget>[
                      for (final Player p in players)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onPick(p),
                          child: Container(
                            width: _phone ? 170 : _w(220),
                            padding: EdgeInsets.symmetric(
                              horizontal: _w(12),
                              vertical: _h(10),
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.background,
                              borderRadius: BorderRadius.circular(_r(12)),
                              border: Border.all(color: AppColor.divider),
                            ),
                            child: Row(
                              children: <Widget>[
                                Image.asset(
                                  _kJersey,
                                  width: _ic(24),
                                  height: _ic(24),
                                ),
                                _sw(10),
                                Expanded(
                                  child: Text(
                                    p.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppThemeStyle.mediumStyle(
                                      _fs(14),
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
