import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/composition_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/view/page/coup_denvoi_step3_screen.dart';
import 'package:wina/view/page/gerer_equipe_composition_screen.dart';
import 'package:wina/view/page/gerer_equipe_numbers_screen.dart';
import 'package:wina/view/widget/formation_pitch.dart';
import 'package:wina/view/widget/gerer_equipe_scaffold.dart';
import 'package:wina/view/widget/label_pill.dart';
import 'package:wina/view/widget/match_wizard.dart';
import 'package:wina/view/widget/player_pick_tile.dart';

const String _kEmptyJersey = 'assets/images/shirt-empty.png';

/// Sous-flux « Gérer mon équipe » — placement des joueurs sur le schéma choisi.
///
/// Gauche : joueurs à placer (glissables). Centre : terrain avec emplacements
/// (déposer un joueur, ou toucher un emplacement pour choisir / retirer).
/// « Valider » rattache la composition au match et revient au hub.
class GererEquipePlacementScreen extends ConsumerWidget {
  const GererEquipePlacementScreen({super.key, this.allowedPlayerIds});

  /// Restreint les joueurs proposés au placement. Utilisé par « Modifier
  /// composition » en cours de match : seuls les joueurs déjà sur le terrain
  /// sont réattribuables. `null` = tout l'effectif (flux « Coup d'envoi »).
  final Set<String>? allowedPlayerIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CompositionDraft draft = ref.watch(compositionDraftProvider);
    final CompositionDraftNotifier notifier = ref.read(
      compositionDraftProvider.notifier,
    );
    final Formation? formation = draft.formation;

    final List<Player> players = (ref
                .watch(playersStreamProvider)
                .valueOrNull ??
            const <Player>[])
        .where(
          (Player p) =>
              p.id != null &&
              (allowedPlayerIds == null || allowedPlayerIds!.contains(p.id)),
        )
        .toList(growable: false);
    final Map<String, Player> byId = <String, Player>{
      for (final Player p in players) p.id!: p,
    };
    final Set<String> assignedIds = draft.assignments.values.toSet();
    final List<Player> unplaced = players
        .where((Player p) => !assignedIds.contains(p.id))
        .toList(growable: false);

    if (formation == null) {
      return GererEquipeScaffold(
        title: 'app.gerer-equipe-placement.titre'.tr(),
        child: const SizedBox.shrink(),
      );
    }

    void pickForSlot(int slot) {
      showDialog<void>(
        context: context,
        barrierColor: AppColor.scrim,
        // `ctx` (contexte du builder) et non celui de la page : c'est lui qui
        // désigne le navigator portant la modale, quel que soit
        // `useRootNavigator`.
        builder:
            (BuildContext ctx) => _PlayerPickerDialog(
              players: unplaced,
              substituteIds: draft.substituteIds,
              onPick: (Player p) {
                notifier.assign(slot, p.id!);
                Navigator.of(ctx).pop();
              },
            ),
      );
    }

    void validate() {
      final List<FormationSlot> slots = formation.slots;
      final List<String?> list = List<String?>.generate(
        slots.length,
        (int i) => draft.assignments[i],
      );
      ref
          .read(matchDraftProvider.notifier)
          .setComposition(
            MatchComposition(
              formationLabel: formation.label,
              playerCount: formation.playerCount,
              slots: slots,
              assignments: list,
              numbers: draft.numbers,
              captainId: draft.captainId,
              substituteIds: draft.substituteIds.toList(growable: false),
            ),
          );
      Navigator.of(context).popUntil(
        (Route<dynamic> route) => route.settings.name == kCoupDEnvoiHubRoute,
      );
    }

    void push(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));

    bool isSub(Player p) => draft.substituteIds.contains(p.id);
    List<Player> atPos(PlayerPosition pos) =>
        unplaced.where((Player p) => p.position == pos && !isSub(p)).toList();
    final List<Player> subs = unplaced.where(isSub).toList();

    final List<_Section> leftSections = <_Section>[
      _Section(
        'app.gerer-equipe-placement.gardiens'.tr(),
        atPos(PlayerPosition.gardien),
      ),
      _Section(
        'app.gerer-equipe-placement.defenseurs'.tr(),
        atPos(PlayerPosition.defenseur),
      ),
      _Section('app.gerer-equipe-placement.remplacants'.tr(), subs),
    ];
    final List<_Section> rightSections = <_Section>[
      _Section(
        'app.gerer-equipe-placement.milieux'.tr(),
        atPos(PlayerPosition.milieu),
      ),
      _Section(
        'app.gerer-equipe-placement.attaquants'.tr(),
        atPos(PlayerPosition.attaquant),
      ),
    ];

    return GererEquipeScaffold(
      title: 'app.gerer-equipe-placement.titre'.tr(),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ModifierButton(
            label: 'app.gerer-equipe-placement.modifier-numeros'.tr(),
            onTap: () => push(const GererEquipeNumbersScreen()),
          ),
          sw(12),
          _ModifierButton(
            label: 'app.gerer-equipe-placement.modifier-composition'.tr(),
            onTap:
                () => push(
                  GererEquipeCompositionScreen(
                    allowedPlayerIds: allowedPlayerIds,
                  ),
                ),
          ),
        ],
      ),
      action: WizardCtaButton(
        label: 'utils.validate'.tr(),
        enabled: draft.allPlaced,
        onTap: validate,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          formatWidth(40),
          formatHeight(8),
          formatWidth(40),
          formatHeight(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: formatWidth(305),
              child: _RosterColumn(
                header: _LeftRosterHeader(),
                sections: leftSections,
                numbers: draft.numbers,
                captainId: draft.captainId,
                substituteIds: draft.substituteIds,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: formatWidth(360),
              child: _CompositionCard(
                formationLabel: formation.label,
                child: _PlacementPitch(
                  formation: formation,
                  assignments: draft.assignments,
                  numbers: draft.numbers,
                  byId: byId,
                  onAssign: notifier.assign,
                  onRemove: notifier.unassign,
                  onTapEmpty: pickForSlot,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: formatWidth(317),
              child: _RosterColumn(
                header: _RightRosterHeader(
                  onMonEquipe:
                      () => Navigator.of(
                        context,
                      ).popUntil((Route<dynamic> route) => route.isFirst),
                ),
                sections: rightSections,
                numbers: draft.numbers,
                captainId: draft.captainId,
                substituteIds: draft.substituteIds,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un groupe du roster : libellé de poste (ou « Remplaçants ») + joueurs.
class _Section {
  const _Section(this.label, this.players);

  final String label;
  final List<Player> players;
}

/// Colonne de roster : un en-tête libre puis les groupes non vides (barre
/// blanche + lignes glissables). Partagée par les colonnes gauche et droite.
class _RosterColumn extends StatelessWidget {
  const _RosterColumn({
    required this.header,
    required this.sections,
    required this.numbers,
    required this.captainId,
    required this.substituteIds,
  });

  final Widget header;
  final List<_Section> sections;
  final Map<String, int> numbers;
  final String? captainId;

  /// Joueurs remplaçants : rendus avec le maillot bleu (design « Placer 2 »).
  final Set<String> substituteIds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        header,
        sh(14),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final _Section s in sections)
                  if (s.players.isNotEmpty) ...<Widget>[
                    _RosterBar(label: s.label),
                    sh(9),
                    for (final Player p in s.players) ...<Widget>[
                      _DraggableRosterRow(
                        player: p,
                        number: numbers[p.id],
                        isCaptain: p.id != null && p.id == captainId,
                        isSub: p.id != null && substituteIds.contains(p.id),
                      ),
                      sh(5),
                    ],
                    sh(15),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// En-tête de la colonne gauche : titre « Joueurs à placer » + consigne.
class _LeftRosterHeader extends StatelessWidget {
  const _LeftRosterHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: formatHeight(66),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'app.gerer-equipe-placement.joueurs-a-placer'.tr(),
            style: AppThemeStyle.semiBStyle(16, AppColor.primaryLabels),
          ),
          sh(6),
          Flexible(
            child: Text(
              'app.gerer-equipe-placement.consigne'.tr(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.regularStyle(12, AppColor.secondaryLabels),
            ),
          ),
        ],
      ),
    );
  }
}

/// En-tête de la colonne droite : bouton « Mon équipe » aligné en haut à
/// droite (aligne les barres de roster avec la colonne gauche).
class _RightRosterHeader extends StatelessWidget {
  const _RightRosterHeader({required this.onMonEquipe});

  final VoidCallback onMonEquipe;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: formatHeight(66),
      child: Align(
        alignment: Alignment.topRight,
        child: _MonEquipeButton(onTap: onMonEquipe),
      ),
    );
  }
}

/// Bouton « Modifier numéros / composition » : pilule blanche, libellé sur
/// deux lignes + pastille fléchée.
class _ModifierButton extends StatelessWidget {
  const _ModifierButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double badge = sp(16);
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(r(999)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r(999)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r(999)),
            border: Border.all(color: AppColor.divider),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: formatWidth(12),
            vertical: formatHeight(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppThemeStyle.semiBStyle(12, AppColor.primaryLabels),
              ),
              sw(8),
              SizedBox(
                width: badge,
                height: badge,
                child: Icon(
                  Iconsax.arrow_circle_right,
                  size: badge * 0.72,
                  color: AppColor.primaryLabels,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton « Mon équipe » : pilule blanche, icône équipe + libellé.
class _MonEquipeButton extends StatelessWidget {
  const _MonEquipeButton({required this.onTap});

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
          padding: EdgeInsets.symmetric(
            horizontal: formatWidth(14),
            vertical: formatHeight(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Iconsax.people, size: sp(18), color: AppColor.primaryColor),
              sw(8),
              Text(
                'app.gerer-equipe-placement.mon-equipe'.tr(),
                style: AppThemeStyle.semiBStyle(13, AppColor.primaryLabels),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barre d’en-tête d’un poste dans le roster : libellé + colonnes « Pied
/// Fort » / « Numéro » (design « Placer 2 »).
class _RosterBar extends StatelessWidget {
  const _RosterBar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: formatHeight(35),
      padding: EdgeInsets.symmetric(horizontal: formatWidth(16)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(r(12)),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: formatWidth(135),
            child: Text(
              label,
              style: AppThemeStyle.mediumStyle(15, AppColor.primaryLabels),
            ),
          ),
          SizedBox(
            width: formatWidth(68),
            child: Text(
              'app.gerer-equipe-placement.pied-fort'.tr(),
              style: AppThemeStyle.regularStyle(13, AppColor.primaryLabels),
            ),
          ),
          Text(
            'app.gerer-equipe-placement.numero'.tr(),
            style: AppThemeStyle.regularStyle(13, AppColor.primaryLabels),
          ),
        ],
      ),
    );
  }
}

/// Ligne joueur glissable : nom (vert) / pied fort / maillot numéroté. Se
/// glisse sur un emplacement du terrain pour placer le joueur.
class _DraggableRosterRow extends ConsumerWidget {
  const _DraggableRosterRow({
    required this.player,
    required this.number,
    this.isCaptain = false,
    this.isSub = false,
  });

  final Player player;
  final int? number;
  final bool isCaptain;
  final bool isSub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String jerseyAsset = jerseyAssetFor(
      isSub: isSub,
      own: ref.watch(matchDraftProvider).ownJersey?.color,
    );

    final Widget row = Padding(
      padding: EdgeInsets.symmetric(horizontal: formatWidth(16)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: formatWidth(6),
          vertical: formatHeight(4),
        ),
        decoration: BoxDecoration(
          color: AppColor.rosterRowSurface,
          borderRadius: BorderRadius.circular(r(10)),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: formatWidth(135),
              child: Text(
                player.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppThemeStyle.mediumStyle(15, AppColor.rosterName),
              ),
            ),
            SizedBox(
              width: formatWidth(68),
              child: Text(
                player.strongFoot.label,
                style: AppThemeStyle.mediumStyle(15, AppColor.primaryLabels),
              ),
            ),
            _NumberJersey(number: number, isCaptain: isCaptain, isSub: isSub),
          ],
        ),
      ),
    );
    return Draggable<Player>(
      data: player,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Image.asset(jerseyAsset, width: sp(44), height: sp(44)),
      childWhenDragging: Opacity(opacity: 0.4, child: row),
      child: row,
    );
  }
}

/// Maillot cyan miniature portant le numéro du joueur, avec un badge « Cap. »
/// sous le maillot pour le capitaine.
class _NumberJersey extends ConsumerWidget {
  const _NumberJersey({
    required this.number,
    this.isCaptain = false,
    this.isSub = false,
  });

  final int? number;
  final bool isCaptain;
  final bool isSub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String jerseyAsset = jerseyAssetFor(
      isSub: isSub,
      own: ref.watch(matchDraftProvider).ownJersey?.color,
    );
    final double d = sp(30);
    return SizedBox(
      width: d,
      height: d * 1.2,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: <Widget>[
          SizedBox(
            width: d,
            height: d,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Image.asset(jerseyAsset, fit: BoxFit.contain),
                if (number != null)
                  Padding(
                    padding: EdgeInsets.only(top: d * 0.08),
                    child: Text(
                      '$number',
                      style: AppThemeStyle.semiBStyle(
                        13,
                        numberColorForJerseyAsset(jerseyAsset),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isCaptain)
            Positioned(
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: d * 0.12),
                decoration: BoxDecoration(
                  color: AppColor.primaryLabels,
                  borderRadius: BorderRadius.circular(r(999)),
                ),
                child: Text(
                  'app.gerer-equipe-placement.capitaine-abrege'.tr(),
                  style: AppThemeStyle.mediumStyle(
                    9,
                    AppColor.textLight,
                  ).copyWith(fontSize: d * 0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Carte « Composition choisie » entourant le terrain (design « Placer 2 ») :
/// en-tête (titre + pilule du schéma) puis le terrain.
class _CompositionCard extends StatelessWidget {
  const _CompositionCard({required this.formationLabel, required this.child});

  final String formationLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(formatWidth(14)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(r(16)),
        border: Border.all(color: AppColor.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'app.gerer-equipe-placement.composition-choisie'.tr(),
                style: AppThemeStyle.semiBStyle(16, AppColor.primaryLabels),
              ),
              const Spacer(),
              LabelPill(formationLabel),
            ],
          ),
          sh(10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Pilule du libellé de schéma (« 4-4-1-1 »).
class _PlacementPitch extends StatelessWidget {
  const _PlacementPitch({
    required this.formation,
    required this.assignments,
    required this.numbers,
    required this.byId,
    required this.onAssign,
    required this.onRemove,
    required this.onTapEmpty,
  });

  final Formation formation;
  final Map<int, String> assignments;

  /// Numéro de maillot attribué à chaque joueur (étape précédente) :
  /// playerId → numéro. Le maillot placé affiche ce numéro, pas l'index de
  /// l'emplacement.
  final Map<String, int> numbers;
  final Map<String, Player> byId;
  final void Function(int slot, String playerId) onAssign;
  final void Function(int slot) onRemove;
  final void Function(int slot) onTapEmpty;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1668 / 2388,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r(18)),
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
                              () =>
                                  player == null ? onTapEmpty(i) : onRemove(i),
                          child: _Slot(
                            size: m,
                            number: pid != null ? numbers[pid] : null,
                            player: player,
                            highlighted: candidates.isNotEmpty,
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
      ),
    );
  }
}

class _Slot extends ConsumerWidget {
  const _Slot({
    required this.size,
    required this.number,
    required this.player,
    required this.highlighted,
  });

  final double size;
  final int? number;
  final Player? player;
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Player? p = player;
    // Un remplaçant PEUT tenir un emplacement (feuille « Choisir un joueur »
    // alimentée par `unplaced`, glisser-déposer depuis la section
    // « Remplaçants ») : sans ce test il changerait de couleur entre la feuille
    // et le terrain. Placer un joueur ne change pas son rôle.
    final String jerseyAsset = jerseyAssetFor(
      isSub:
          p != null &&
          ref.watch(compositionDraftProvider).substituteIds.contains(p.id),
      own: ref.watch(matchDraftProvider).ownJersey?.color,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: size,
          height: size,
          child:
              p == null
                  ? Opacity(
                    opacity: highlighted ? 1 : 0.9,
                    child: Image.asset(_kEmptyJersey, fit: BoxFit.contain),
                  )
                  : Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Image.asset(jerseyAsset, fit: BoxFit.contain),
                      if (number != null)
                        Padding(
                          padding: EdgeInsets.only(top: size * 0.08),
                          child: Text(
                            '$number',
                            style: AppThemeStyle.boldStyle(
                              size * 0.32,
                              numberColorForJerseyAsset(jerseyAsset),
                            ),
                          ),
                        ),
                    ],
                  ),
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

/// Popup « Choisissez un joueur à placer » (maquette, écran 4).
///
/// Les joueurs y sont groupés par poste et la sélection est différée : toucher
/// une tuile la retient, c'est « Placer » qui valide. La feuille du bas
/// précédente listait tout le monde à plat et plaçait au premier tap — une
/// erreur de doigt était irrattrapable.
class _PlayerPickerDialog extends ConsumerStatefulWidget {
  const _PlayerPickerDialog({
    required this.players,
    required this.substituteIds,
    required this.onPick,
  });

  final List<Player> players;
  final Set<String> substituteIds;
  final ValueChanged<Player> onPick;

  @override
  ConsumerState<_PlayerPickerDialog> createState() =>
      _PlayerPickerDialogState();
}

class _PlayerPickerDialogState extends ConsumerState<_PlayerPickerDialog> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final JerseyColorOption? own =
        ref.watch(matchDraftProvider).ownJersey?.color;
    bool isSub(Player p) => widget.substituteIds.contains(p.id);
    List<Player> atPos(PlayerPosition pos) =>
        widget.players
            .where((Player p) => p.position == pos && !isSub(p))
            .toList();

    final List<({String label, List<Player> players})> groups =
        <({String label, List<Player> players})>[
          for (final PlayerPosition pos in PlayerPosition.values)
            (label: pos.label, players: atPos(pos)),
          (
            label: 'app.gerer-equipe-placement.remplacants'.tr(),
            players: widget.players.where(isSub).toList(),
          ),
        ];

    Player? selected;
    for (final Player p in widget.players) {
      if (p.id == _selectedId) {
        selected = p;
        break;
      }
    }

    return Dialog(
      backgroundColor: AppColor.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: formatWidth(40)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r(20))),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: formatWidth(560)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            formatWidth(24),
            formatHeight(16),
            formatWidth(24),
            formatHeight(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(width: sp(20)),
                  Expanded(
                    child: Text(
                      'app.gerer-equipe-placement.choisir-joueur'.tr(),
                      textAlign: TextAlign.center,
                      style: AppThemeStyle.semiBStyle(
                        17,
                        AppColor.primaryLabels,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Iconsax.close_circle,
                      size: sp(20),
                      color: AppColor.secondaryLabels,
                    ),
                  ),
                ],
              ),
              sh(14),
              if (widget.players.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: formatHeight(16)),
                  child: Text(
                    'app.gerer-equipe-placement.aucun-joueur-disponible'.tr(),
                    textAlign: TextAlign.center,
                    style: AppThemeStyle.regularStyle(
                      13,
                      AppColor.secondaryLabels,
                    ),
                  ),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (final ({
                              String label,
                              List<Player> players,
                            })
                            g in groups)
                          if (g.players.isNotEmpty) ...<Widget>[
                            Text(
                              g.label,
                              style: AppThemeStyle.semiBStyle(
                                15,
                                AppColor.primaryLabels,
                              ),
                            ),
                            sh(10),
                            Wrap(
                              spacing: formatWidth(12),
                              runSpacing: formatHeight(12),
                              children: <Widget>[
                                for (final Player p in g.players)
                                  PlayerPickTile(
                                    player: p,
                                    selected: _selectedId == p.id,
                                    jerseyAsset: jerseyAssetFor(
                                      isSub: isSub(p),
                                      own: own,
                                    ),
                                    onTap:
                                        () => setState(
                                          () => _selectedId = p.id,
                                        ),
                                  ),
                              ],
                            ),
                            sh(16),
                          ],
                      ],
                    ),
                  ),
                ),
              sh(4),
              WizardCtaButton(
                label: 'app.gerer-equipe-placement.placer'.tr(),
                enabled: selected != null,
                onTap: () => widget.onPick(selected!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
