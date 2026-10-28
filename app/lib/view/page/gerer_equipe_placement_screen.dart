import 'package:wina/view/page/gerer_equipe_nav.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/phone_scale.dart';
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
import 'package:wina/view/widget/phone_category_chip.dart';
import 'package:wina/view/widget/player_pick_tile.dart';

const String _kEmptyJersey = 'assets/images/shirt-empty.png';

/// Sous-flux « Gérer mon équipe » — placement des joueurs sur le schéma choisi.
///
/// Gauche : joueurs à placer (glissables). Centre : terrain avec emplacements
/// (déposer un joueur, ou toucher un emplacement pour choisir / retirer).
/// « Valider » rattache la composition au match et revient au hub.
class GererEquipePlacementScreen extends ConsumerStatefulWidget {
  const GererEquipePlacementScreen({super.key, this.allowedPlayerIds});

  /// Restreint les joueurs proposés au placement. Utilisé par « Modifier
  /// composition » en cours de match : seuls les joueurs déjà sur le terrain
  /// sont réattribuables. `null` = tout l'effectif (flux « Coup d'envoi »).
  final Set<String>? allowedPlayerIds;

  @override
  ConsumerState<GererEquipePlacementScreen> createState() =>
      _GererEquipePlacementScreenState();
}

class _GererEquipePlacementScreenState
    extends ConsumerState<GererEquipePlacementScreen> {
  /// Téléphone : joueur retenu par un appui (à poser ensuite d'un appui sur un
  /// emplacement), alternative au glisser-déposer.
  String? _selectedId;

  /// Téléphone : catégorie affichée dans le panneau de droite.
  int _category = 0;

  @override
  Widget build(BuildContext context) {
    final Set<String>? allowedPlayerIds = widget.allowedPlayerIds;
    final CompositionDraft draft = ref.watch(compositionDraftProvider);
    final CompositionDraftNotifier notifier = ref.read(
      compositionDraftProvider.notifier,
    );
    final Formation? formation = draft.formation;

    // Un joueur sans numéro ne joue pas ce match (titulaires et remplaçants ont tous un numéro) : il
    // n'est pas proposé. Sans aucun numéro attribué (composition reprise sans numéros), on ne filtre pas.
    final bool hasNumbers = draft.numbers.isNotEmpty;
    final List<Player> players =
        (ref.watch(playersStreamProvider).valueOrNull ?? const <Player>[])
            .where(
              (Player p) =>
                  p.id != null &&
                  (allowedPlayerIds == null || allowedPlayerIds.contains(p.id)) &&
                  (!hasNumbers || draft.numbers.containsKey(p.id)),
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

    // Téléphone : un joueur retenu est posé directement sur l'emplacement
    // touché ; sans joueur retenu, on ouvre la fenêtre de choix.
    void tapEmpty(int slot) {
      final String? id = _selectedId;
      if (isPhoneLayout &&
          id != null &&
          unplaced.any((Player p) => p.id == id)) {
        notifier.assign(slot, id);
        setState(() => _selectedId = null);
        return;
      }
      pickForSlot(slot);
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

    // Téléphone : terrain à gauche ; à droite, les catégories en une ligne de
    // pastilles et les joueurs de la catégorie choisie en dessous.
    final List<_Section> phoneSections = <_Section>[
      _Section(
        'app.gerer-equipe-placement.gardiens'.tr(),
        atPos(PlayerPosition.gardien),
      ),
      _Section(
        'app.gerer-equipe-placement.defenseurs'.tr(),
        atPos(PlayerPosition.defenseur),
      ),
      _Section(
        'app.gerer-equipe-placement.milieux'.tr(),
        atPos(PlayerPosition.milieu),
      ),
      _Section(
        'app.gerer-equipe-placement.attaquants'.tr(),
        atPos(PlayerPosition.attaquant),
      ),
      _Section('app.gerer-equipe-placement.remplacants'.tr(), subs),
    ].where((_Section s) => s.players.isNotEmpty).toList(growable: false);
    final String? selectedId =
        unplaced.any((Player p) => p.id == _selectedId) ? _selectedId : null;

    return GererEquipeScaffold(
      title: 'app.gerer-equipe-placement.titre'.tr(),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ModifierButton(
            label: 'app.gerer-equipe-placement.modifier-numeros'.tr(),
            onTap:
                () => openGererScreen(
                  context,
                  kGererNumbersRoute,
                  () => const GererEquipeNumbersScreen(),
                ),
          ),
          cSw(12),
          _ModifierButton(
            label: 'app.gerer-equipe-placement.modifier-composition'.tr(),
            onTap:
                () => openGererScreen(
                  context,
                  kGererCompositionRoute,
                  () => GererEquipeCompositionScreen(
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
      child:
          isPhoneLayout
              ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _pitchCol(
                      child: _CompositionCard(
                        formationLabel: formation.label,
                        child: _PlacementPitch(
                          formation: formation,
                          assignments: draft.assignments,
                          numbers: draft.numbers,
                          byId: byId,
                          onAssign: notifier.assign,
                          onRemove: notifier.unassign,
                          onTapEmpty: tapEmpty,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PhoneRoster(
                        sections: phoneSections,
                        category: _category,
                        selectedId: selectedId,
                        numbers: draft.numbers,
                        captainId: draft.captainId,
                        substituteIds: draft.substituteIds,
                        onCategory: (int i) => setState(() => _category = i),
                        onSelect:
                            (Player p) => setState(
                              () =>
                                  _selectedId =
                                      selectedId == p.id ? null : p.id,
                            ),
                      ),
                    ),
                  ],
                ),
              )
              : Padding(
                padding: EdgeInsets.fromLTRB(
                  isPhoneLayout ? 16 : cW(40),
                  cH(8),
                  isPhoneLayout ? 16 : cW(40),
                  isPhoneLayout ? 8 : cH(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _col(
                      flex: 1,
                      width: 305,
                      child: _RosterColumn(
                        header: _LeftRosterHeader(),
                        sections: leftSections,
                        numbers: draft.numbers,
                        captainId: draft.captainId,
                        substituteIds: draft.substituteIds,
                      ),
                    ),
                    _gap(),
                    _pitchCol(
                      child: _CompositionCard(
                        formationLabel: formation.label,
                        child: _PlacementPitch(
                          formation: formation,
                          assignments: draft.assignments,
                          numbers: draft.numbers,
                          byId: byId,
                          onAssign: notifier.assign,
                          onRemove: notifier.unassign,
                          onTapEmpty: tapEmpty,
                        ),
                      ),
                    ),
                    _gap(),
                    _col(
                      flex: 1,
                      width: 317,
                      child: _RosterColumn(
                        header: SizedBox(height: _rosterHeaderHeight),
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

/// Colonne à largeur fixe sur tablette, proportionnelle sur téléphone.
Widget _col({required int flex, required double width, required Widget child}) {
  return isPhoneLayout
      ? Expanded(flex: flex, child: child)
      : SizedBox(width: cW(width), child: child);
}

/// Colonne du terrain : largeur fixe sur tablette ; sur téléphone, largeur
/// déduite de la hauteur disponible (ratio du terrain) pour que le terrain
/// soit le plus grand possible et que les listes gardent le reste.
Widget _pitchCol({required Widget child}) {
  if (!isPhoneLayout) return SizedBox(width: cW(360), child: child);
  return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints c) {
      const double pad = 8; // padding de la carte
      const double head = 0; // la pastille du schéma recouvre le terrain
      final double pitchH = c.maxHeight - pad * 2 - head;
      final double w = pitchH * 1668 / 2388 + pad * 2;
      return SizedBox(width: w, child: child);
    },
  );
}

/// Cellule « nom » d'une ligne de roster : largeur fixe sur tablette, souple
/// sur téléphone (les colonnes de listes y sont plus larges que le contenu).
Widget _nameCell({required Widget child}) =>
    isPhoneLayout
        ? Expanded(child: child)
        : SizedBox(width: cW(135), child: child);

/// Espace entre colonnes : extensible sur tablette, fixe sur téléphone.
Widget _gap() => isPhoneLayout ? const SizedBox(width: 12) : const Spacer();

/// Un groupe du roster : libellé de poste (ou « Remplaçants ») + joueurs.
class _Section {
  const _Section(this.label, this.players);

  final String label;
  final List<Player> players;
}

/// Téléphone : panneau de droite. Une ligne de pastilles (une par catégorie
/// non vide, avec son effectif), puis les joueurs de la catégorie choisie en
/// dessous. Un appui retient un joueur (à poser d'un appui sur un
/// emplacement) ; un appui long le rend glissable vers le terrain.
class _PhoneRoster extends StatelessWidget {
  const _PhoneRoster({
    required this.sections,
    required this.category,
    required this.selectedId,
    required this.numbers,
    required this.captainId,
    required this.substituteIds,
    required this.onCategory,
    required this.onSelect,
  });

  final List<_Section> sections;
  final int category;
  final String? selectedId;
  final Map<String, int> numbers;
  final String? captainId;
  final Set<String> substituteIds;
  final ValueChanged<int> onCategory;
  final ValueChanged<Player> onSelect;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return Center(
        child: Text(
          'app.gerer-equipe-placement.tous-places'.tr(),
          textAlign: TextAlign.center,
          style: AppThemeStyle.mediumStyle(cFs(16), AppColor.secondaryLabels),
        ),
      );
    }
    final int current = category.clamp(0, sections.length - 1);
    final List<Player> players = sections[current].players;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'app.gerer-equipe-placement.consigne-telephone'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppThemeStyle.regularStyle(cFs(14), AppColor.secondaryLabels),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder:
                (BuildContext context, int i) => PhoneCategoryChip(
                  label: sections[i].label,
                  count: sections[i].players.length,
                  selected: i == current,
                  onTap: () => onCategory(i),
                ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: players.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder:
                (BuildContext context, int i) => _PhoneRosterRow(
                  player: players[i],
                  number: numbers[players[i].id],
                  isCaptain:
                      players[i].id != null && players[i].id == captainId,
                  isSub:
                      players[i].id != null &&
                      substituteIds.contains(players[i].id),
                  selected: players[i].id == selectedId,
                  onTap: () => onSelect(players[i]),
                ),
          ),
        ),
      ],
    );
  }
}

/// Ligne joueur du téléphone : maillot numéroté, nom, pied fort. Hauteur
/// tactile de 52 ; surlignée quand le joueur est retenu.
class _PhoneRosterRow extends ConsumerWidget {
  const _PhoneRosterRow({
    required this.player,
    required this.number,
    required this.isCaptain,
    required this.isSub,
    required this.selected,
    required this.onTap,
  });

  final Player player;
  final int? number;
  final bool isCaptain;
  final bool isSub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String jerseyAsset = jerseyAssetFor(
      isSub: isSub,
      own: ref.watch(matchDraftProvider).ownJersey?.color,
    );
    final Widget row = Material(
      color: AppColor.rosterRowSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColor.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: <Widget>[
              _NumberJersey(
                number: number,
                isCaptain: isCaptain,
                isSub: isSub,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      player.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemeStyle.semiBStyle(
                        cFs(18),
                        AppColor.rosterName,
                      ),
                    ),
                    Text(
                      '${'app.gerer-equipe-placement.pied-fort'.tr()} : ${player.strongFoot.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemeStyle.regularStyle(
                        cFs(14),
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
    );
    return LongPressDraggable<Player>(
      data: player,
      delay: const Duration(milliseconds: 150),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Image.asset(jerseyAsset, width: 48, height: 48),
      childWhenDragging: Opacity(opacity: 0.4, child: row),
      child: row,
    );
  }
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
        cSh(14),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final _Section s in sections)
                  if (s.players.isNotEmpty) ...<Widget>[
                    _RosterBar(label: s.label),
                    cSh(9),
                    for (final Player p in s.players) ...<Widget>[
                      _DraggableRosterRow(
                        player: p,
                        number: numbers[p.id],
                        isCaptain: p.id != null && p.id == captainId,
                        isSub: p.id != null && substituteIds.contains(p.id),
                      ),
                      cSh(5),
                    ],
                    cSh(15),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Hauteur de l'en-tête des colonnes de joueurs : celle de la colonne gauche (titre + consigne en entier)
/// et de l'espace équivalent à droite, pour que les deux listes restent alignées.
double get _rosterHeaderHeight => isPhoneLayout ? 54 : cH(96);

/// En-tête de la colonne gauche : titre « Joueurs à placer » + consigne.
class _LeftRosterHeader extends StatelessWidget {
  const _LeftRosterHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rosterHeaderHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'app.gerer-equipe-placement.joueurs-a-placer'.tr(),
            style: AppThemeStyle.semiBStyle(cFs(16), AppColor.primaryLabels),
          ),
          cSh(6),
          Flexible(
            child: Text(
              'app.gerer-equipe-placement.consigne'.tr(),
              // Tablette : la consigne s'affiche en entier (4 lignes au plus), sans « … ».
              maxLines: isPhoneLayout ? 2 : 4,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.regularStyle(
                cFs(12),
                AppColor.secondaryLabels,
              ),
            ),
          ),
        ],
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
    if (isPhoneLayout) {
      // Téléphone : pilule d'une ligne, hauteur tactile de 36.
      return Material(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColor.divider),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: AppThemeStyle.semiBStyle(cFs(16), AppColor.primaryLabels),
            ),
          ),
        ),
      );
    }
    final double badge = cIc(28);
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(cR(999)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cR(999)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cR(999)),
            border: Border.all(color: AppColor.divider),
          ),
          padding: EdgeInsets.symmetric(horizontal: cW(24), vertical: cH(14)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: AppThemeStyle.semiBStyle(
                  cFs(17),
                  AppColor.primaryLabels,
                ),
              ),
              cSw(12),
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

/// Barre d’en-tête d’un poste dans le roster : libellé + colonnes « Pied
/// Fort » / « Numéro » (design « Placer 2 »).
class _RosterBar extends StatelessWidget {
  const _RosterBar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: cH(35),
      padding: EdgeInsets.symmetric(horizontal: cW(16)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(12)),
      ),
      child: Row(
        children: <Widget>[
          _nameCell(
            child: Text(
              label,
              style: AppThemeStyle.mediumStyle(cFs(15), AppColor.primaryLabels),
            ),
          ),
          SizedBox(
            width: isPhoneLayout ? 60 : cW(68),
            child: Text(
              'app.gerer-equipe-placement.pied-fort'.tr(),
              style: AppThemeStyle.regularStyle(
                cFs(13),
                AppColor.primaryLabels,
              ),
            ),
          ),
          Text(
            'app.gerer-equipe-placement.numero'.tr(),
            style: AppThemeStyle.regularStyle(cFs(13), AppColor.primaryLabels),
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
      padding: EdgeInsets.symmetric(horizontal: cW(16)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: cW(6), vertical: cH(4)),
        decoration: BoxDecoration(
          color: AppColor.rosterRowSurface,
          borderRadius: BorderRadius.circular(cR(10)),
        ),
        child: Row(
          children: <Widget>[
            _nameCell(
              child: Text(
                player.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppThemeStyle.mediumStyle(cFs(15), AppColor.rosterName),
              ),
            ),
            SizedBox(
              width: isPhoneLayout ? 60 : cW(68),
              child: Text(
                player.strongFoot.label,
                style: AppThemeStyle.mediumStyle(
                  cFs(15),
                  AppColor.primaryLabels,
                ),
              ),
            ),
            _NumberJersey(number: number, isCaptain: isCaptain, isSub: isSub),
          ],
        ),
      ),
    );
    final Widget feedback = Image.asset(
      jerseyAsset,
      width: cIc(44),
      height: cIc(44),
    );
    final Widget whenDragging = Opacity(opacity: 0.4, child: row);
    // Téléphone : la liste défile ; un `Draggable` immédiat capterait le doigt
    // et empêcherait de la faire défiler. Appui bref avant de glisser.
    if (isPhoneLayout) {
      return LongPressDraggable<Player>(
        data: player,
        delay: const Duration(milliseconds: 150),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: feedback,
        childWhenDragging: whenDragging,
        child: row,
      );
    }
    return Draggable<Player>(
      data: player,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: feedback,
      childWhenDragging: whenDragging,
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
    this.size,
  });

  final int? number;
  final bool isCaptain;
  final bool isSub;

  /// Côté du maillot en dp réels ; par défaut, l'échelle de la maquette.
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String jerseyAsset = jerseyAssetFor(
      isSub: isSub,
      own: ref.watch(matchDraftProvider).ownJersey?.color,
    );
    final double d = size ?? cIc(30);
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
                        size != null ? cFs(d * 0.4 / 0.8) : cFs(13),
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
                  borderRadius: BorderRadius.circular(cR(999)),
                ),
                child: Text(
                  'app.gerer-equipe-placement.capitaine-abrege'.tr(),
                  style: AppThemeStyle.mediumStyle(
                    cFs(9),
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
    if (isPhoneLayout) {
      // Téléphone : toute la hauteur au terrain ; le schéma (« 4-4-2 ») s'y
      // superpose en bas à gauche, hors des emplacements.
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(cR(16)),
          border: Border.all(color: AppColor.divider),
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: child),
            Positioned(left: 6, bottom: 6, child: LabelPill(formationLabel)),
          ],
        ),
      );
    }
    return Container(
      padding: EdgeInsets.all(isPhoneLayout ? 8 : cW(14)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(16)),
        border: Border.all(color: AppColor.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (isPhoneLayout)
            // Téléphone : seul le schéma (« 4-4-2 »), le titre prendrait la
            // hauteur et la largeur du terrain.
            Center(child: LabelPill(formationLabel))
          else
            Row(
              children: <Widget>[
                Text(
                  'app.gerer-equipe-placement.composition-choisie'.tr(),
                  style: AppThemeStyle.semiBStyle(
                    cFs(16),
                    AppColor.primaryLabels,
                  ),
                ),
                const Spacer(),
                LabelPill(formationLabel),
              ],
            ),
          cSh(isPhoneLayout ? 6 : 10),
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
          borderRadius: BorderRadius.circular(cR(18)),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double w = constraints.maxWidth;
              final double h = constraints.maxHeight;
              // Téléphone : terrain étroit, maillots agrandis pour rester
              // lisibles et faciles à toucher.
              final double m = w * (isPhoneLayout ? 0.19 : 0.155);
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
                              cFs(size * 0.32),
                              numberColorForJerseyAsset(jerseyAsset),
                            ),
                          ),
                        ),
                    ],
                  ),
        ),
        if (p != null) ...<Widget>[
          SizedBox(height: cH(4)),
          Text(
            _short(p),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemeStyle.semiBStyle(
              isPhoneLayout ? cFs(14) : cFs(11),
              AppColor.textLight,
            ),
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
      insetPadding: EdgeInsets.symmetric(horizontal: cW(40)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cR(20)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cW(560)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(cW(24), cH(16), cW(24), cH(22)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(width: cIc(20)),
                  Expanded(
                    child: Text(
                      'app.gerer-equipe-placement.choisir-joueur'.tr(),
                      textAlign: TextAlign.center,
                      style: AppThemeStyle.semiBStyle(
                        cFs(17),
                        AppColor.primaryLabels,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Iconsax.close_circle,
                      size: cIc(20),
                      color: AppColor.secondaryLabels,
                    ),
                  ),
                ],
              ),
              cSh(14),
              if (widget.players.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: cH(16)),
                  child: Text(
                    'app.gerer-equipe-placement.aucun-joueur-disponible'.tr(),
                    textAlign: TextAlign.center,
                    style: AppThemeStyle.regularStyle(
                      cFs(13),
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
                        for (final ({String label, List<Player> players}) g
                            in groups)
                          if (g.players.isNotEmpty) ...<Widget>[
                            Text(
                              g.label,
                              style: AppThemeStyle.semiBStyle(
                                cFs(15),
                                AppColor.primaryLabels,
                              ),
                            ),
                            cSh(10),
                            Wrap(
                              spacing: cW(12),
                              runSpacing: cH(12),
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
                                        () =>
                                            setState(() => _selectedId = p.id),
                                  ),
                              ],
                            ),
                            cSh(16),
                          ],
                      ],
                    ),
                  ),
                ),
              cSh(4),
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
