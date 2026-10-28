import 'dart:math' as math;

import 'package:wina/view/page/gerer_equipe_nav.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/composition_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/view/page/creer_joueur_screen.dart';
import 'package:wina/view/page/gerer_equipe_composition_screen.dart';
import 'package:wina/view/widget/gerer_equipe_scaffold.dart';
import 'package:wina/view/widget/match_wizard.dart';
import 'package:wina/view/widget/phone_category_chip.dart';

/// Taille du pool de numéros titulaires (grille cyan « Attribuer les
/// numéros », design 1:421) — alignée sur le format du match (11/8/5), et à
/// défaut sur la taille max de l'effectif. Test `> 0` et non `??` : une
/// composition relue depuis Firestore sans champ `playerCount` vaut 0
/// (`MatchComposition.fromJson`), ce qu'un `??` ne rattraperait pas.
int _starterPoolSize(CompositionDraft draft) {
  final int n = draft.playerCount ?? 0;
  return n > 0 ? n : kMaxSquadSize;
}

/// Numéros proposés aux titulaires (grille « Attribuer les numéros ») : tous les maillots de l'effectif
/// maximum du format (1 à 9 en foot à 5, 1 à 14 à 8, 1 à 20 à 11), jamais moins que le nombre de joueurs de
/// la composition. Les numéros choisis comme remplaçants y sont grisés et bloqués (voir [CompositionDraft.subNumbers]).
List<int> starterNumbersOf(CompositionDraft draft, int maxSquad) => <int>[
  for (int i = 1; i <= math.max(maxSquad, _starterPoolSize(draft)); i++) i,
];

/// Premier numéro de la grille « Numéros des remplaçants » (design 1:424) :
/// elle enchaîne sur le pool titulaire (12 à 16 dans un 11 contre 11). Les
/// numéros étant uniques dans toute l'équipe (`setNumber`), un pool
/// remplaçant qui repartirait de 1 n'offrirait plus rien dès que les
/// titulaires portent 1 à 5.
int _subPoolFirst(CompositionDraft draft) => _starterPoolSize(draft) + 1;

/// Numéros ouverts aux remplaçants. Le coach les choisit librement dans la
/// popup qui précède cet écran ; tant qu'il n'a rien choisi (brouillon rechargé
/// depuis une composition existante, par exemple) on retombe sur l'ancien
/// intervalle contigu, ce qui laisse l'écran fonctionnel en toutes circonstances.
List<int> subNumbersOf(CompositionDraft draft) =>
    draft.subNumbers.isEmpty
        ? <int>[for (int i = 0; i < kSubPoolSize; i++) _subPoolFirst(draft) + i]
        : (draft.subNumbers.toList()..sort());

/// Étiquette glissée depuis le panneau « Brassard de capitaine ».
const String _kCaptainDragTag = 'captain';

/// Visuel du brassard de capitaine (chip « cap. » à liseré doré).
const String _kCaptainAsset = 'assets/images/captain.png';

/// Charge utile glissée depuis un panneau de droite jusqu'à une ligne joueur.
class _NumberDrag {
  const _NumberDrag(this.number, {required this.isSubstitute});
  final int number;
  final bool isSubstitute;
}

/// Sous-flux « Gérer mon équipe » — étape « Attribuez les numéros » : 3
/// colonnes — postes (+ « Remplaçants », duplicata des joueurs ayant un
/// numéro remplaçant) à gauche/centre, panneaux « Attribuer les numéros » /
/// « Numéros des remplaçants » / « Brassard de capitaine » à droite. Un
/// numéro/le brassard s'attribue en le glissant sur une ligne joueur, ou en
/// touchant le numéro d'un joueur pour ouvrir le sélecteur (design 1:133 /
/// 1:657 / 1:1191). Vient entre le nombre de joueurs et le choix de la
/// composition.
class GererEquipeNumbersScreen extends ConsumerWidget {
  const GererEquipeNumbersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CompositionDraft draft = ref.watch(compositionDraftProvider);
    final CompositionDraftNotifier notifier = ref.read(
      compositionDraftProvider.notifier,
    );
    final List<Player> players =
        (ref.watch(playersStreamProvider).valueOrNull ?? const <Player>[])
            .where((Player p) => p.id != null)
            .toList(growable: false);
    final int maxSquad =
        ref.watch(maxSquadSizeProvider).valueOrNull ?? kMaxSquadSize;

    List<Player> ofPosition(PlayerPosition pos) =>
        players.where((Player p) => p.position == pos).toList(growable: false);
    List<Player> substitutes() => players
        .where((Player p) => draft.substituteIds.contains(p.id))
        .toList(growable: false);

    void openNumberPicker(Player player) {
      showDialog<void>(
        context: context,
        barrierColor: AppColor.scrim,
        builder:
            (BuildContext ctx) => _NumberPickerDialog(
              player: player,
              draft: draft,
              maxSquad: maxSquad,
              onConfirm: (int number, bool isSub) {
                notifier.setNumber(player.id!, number, isSubstitute: isSub);
                Navigator.of(ctx).pop();
              },
              onClear: () {
                notifier.clearNumber(player.id!);
                Navigator.of(ctx).pop();
              },
            ),
      );
    }

    void assignFromDrag(Player player, Object data) {
      if (data is _NumberDrag) {
        notifier.setNumber(
          player.id!,
          data.number,
          isSubstitute: data.isSubstitute,
        );
      } else if (data == _kCaptainDragTag && draft.captainId != player.id) {
        notifier.toggleCaptain(player.id!);
      }
    }

    Widget group(
      String title,
      List<Player> groupPlayers, {
      String? emptyLabel,
    }) => _PositionGroup(
      title: title,
      players: groupPlayers,
      draft: draft,
      emptyLabel: emptyLabel,
      onOpenPicker: openNumberPicker,
      onAccept: assignFromDrag,
    );

    // Téléphone : joueurs par catégorie à gauche (pastilles puis lignes), numéros
    // et brassard à droite. Plus de défilement de toute la page.
    final Widget phoneBody = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: _PhoneNumbersList(
              sections: <_PhoneSection>[
                _PhoneSection(
                  PlayerPosition.gardien.label,
                  ofPosition(PlayerPosition.gardien),
                ),
                _PhoneSection(
                  PlayerPosition.defenseur.label,
                  ofPosition(PlayerPosition.defenseur),
                ),
                _PhoneSection(
                  PlayerPosition.milieu.label,
                  ofPosition(PlayerPosition.milieu),
                ),
                _PhoneSection(
                  PlayerPosition.attaquant.label,
                  ofPosition(PlayerPosition.attaquant),
                ),
                _PhoneSection(
                  'app.gerer-equipe-numbers.remplacants'.tr(),
                  substitutes(),
                ),
              ],
              draft: draft,
              playerCount: players.length,
              maxPlayers: maxSquad,
              onOpenPicker: openNumberPicker,
              onAccept: assignFromDrag,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 230,
            child: SingleChildScrollView(
              child: _RightRail(draft: draft, maxSquad: maxSquad),
            ),
          ),
        ],
      ),
    );

    return GererEquipeScaffold(
      title: 'app.gerer-equipe-numbers.titre'.tr(),
      action: WizardCtaButton(
        label: 'app.gerer-equipe-numbers.suivant'.tr(),
        onTap:
            () => openGererScreen(
              context,
              kGererCompositionRoute,
              () => const GererEquipeCompositionScreen(),
            ),
      ),
      child:
          isPhoneLayout
              ? phoneBody
              : Padding(
                padding: EdgeInsets.fromLTRB(cW(40), cH(8), cW(40), cH(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _Header(playerCount: players.length, maxPlayers: maxSquad),
                    cSh(14),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                children: <Widget>[
                                  group(
                                    PlayerPosition.gardien.label,
                                    ofPosition(PlayerPosition.gardien),
                                  ),
                                  cSh(20),
                                  group(
                                    PlayerPosition.milieu.label,
                                    ofPosition(PlayerPosition.milieu),
                                  ),
                                  cSh(20),
                                  group(
                                    'app.gerer-equipe-numbers.remplacants'.tr(),
                                    substitutes(),
                                    emptyLabel:
                                        'app.gerer-equipe-numbers.aucun-remplacant'
                                            .tr(),
                                  ),
                                ],
                              ),
                            ),
                            cSw(24),
                            Expanded(
                              child: Column(
                                children: <Widget>[
                                  group(
                                    PlayerPosition.defenseur.label,
                                    ofPosition(PlayerPosition.defenseur),
                                  ),
                                  cSh(20),
                                  group(
                                    PlayerPosition.attaquant.label,
                                    ofPosition(PlayerPosition.attaquant),
                                  ),
                                ],
                              ),
                            ),
                            cSw(24),
                            SizedBox(
                              width: isPhoneLayout ? 175 : cW(230),
                              child: _RightRail(draft: draft, maxSquad: maxSquad),
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

/// Une catégorie du panneau joueurs sur téléphone.
class _PhoneSection {
  const _PhoneSection(this.label, this.players);

  final String label;
  final List<Player> players;
}

/// Téléphone : effectif + « Créer un joueur », pastilles de catégorie, puis les
/// joueurs de la catégorie choisie. Toucher le maillot d'un joueur ouvre le
/// choix du numéro ; un numéro ou le brassard du panneau de droite se glisse
/// aussi sur sa ligne.
class _PhoneNumbersList extends StatefulWidget {
  const _PhoneNumbersList({
    required this.sections,
    required this.draft,
    required this.playerCount,
    required this.maxPlayers,
    required this.onOpenPicker,
    required this.onAccept,
  });

  final List<_PhoneSection> sections;
  final CompositionDraft draft;
  final int playerCount;
  final int maxPlayers;
  final ValueChanged<Player> onOpenPicker;
  final void Function(Player player, Object data) onAccept;

  @override
  State<_PhoneNumbersList> createState() => _PhoneNumbersListState();
}

class _PhoneNumbersListState extends State<_PhoneNumbersList> {
  int _category = 0;

  @override
  Widget build(BuildContext context) {
    final int current = _category.clamp(0, widget.sections.length - 1);
    final _PhoneSection section = widget.sections[current];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'app.gerer-equipe-numbers.effectif'.tr(
                  args: <String>[
                    '${widget.playerCount}',
                    '${widget.maxPlayers}',
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppThemeStyle.mediumStyle(
                  cFs(16),
                  AppColor.primaryLabels,
                ),
              ),
            ),
            _CreerJoueurButton(
              playerCount: widget.playerCount,
              maxPlayers: widget.maxPlayers,
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.sections.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder:
                (BuildContext context, int i) => PhoneCategoryChip(
                  label: widget.sections[i].label,
                  count: widget.sections[i].players.length,
                  selected: i == current,
                  onTap: () => setState(() => _category = i),
                ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child:
              section.players.isEmpty
                  ? Center(
                    child: Text(
                      section.label ==
                              'app.gerer-equipe-numbers.remplacants'.tr()
                          ? 'app.gerer-equipe-numbers.aucun-remplacant'.tr()
                          : 'app.gerer-equipe-numbers.aucun-joueur-poste'.tr(),
                      textAlign: TextAlign.center,
                      style: AppThemeStyle.mediumStyle(
                        cFs(16),
                        AppColor.secondaryLabels,
                      ),
                    ),
                  )
                  : ListView.separated(
                    itemCount: section.players.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (BuildContext context, int i) {
                      final Player p = section.players[i];
                      return _PhoneNumberRow(
                        player: p,
                        number: widget.draft.numbers[p.id],
                        isSub: widget.draft.substituteIds.contains(p.id),
                        isCaptain: widget.draft.captainId == p.id,
                        onTap: () => widget.onOpenPicker(p),
                        onAccept: (Object data) => widget.onAccept(p, data),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

/// Ligne joueur du téléphone : nom et pied fort à gauche, maillot numéroté (zone
/// tactile de 52) à droite. Cible de dépôt d'un numéro ou du brassard.
class _PhoneNumberRow extends StatelessWidget {
  const _PhoneNumberRow({
    required this.player,
    required this.number,
    required this.isSub,
    required this.isCaptain,
    required this.onTap,
    required this.onAccept,
  });

  final Player player;
  final int? number;
  final bool isSub;
  final bool isCaptain;
  final VoidCallback onTap;
  final void Function(Object data) onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Object>(
      onWillAcceptWithDetails:
          (DragTargetDetails<Object> details) =>
              details.data is _NumberDrag || details.data == _kCaptainDragTag,
      onAcceptWithDetails:
          (DragTargetDetails<Object> details) => onAccept(details.data),
      builder: (BuildContext context, List<Object?> candidates, _) {
        return Material(
          color:
              candidates.isNotEmpty
                  ? AppColor.rosterRowHovered
                  : AppColor.rosterRowSurface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Row(
                  children: <Widget>[
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
                            '${'app.gerer-equipe-numbers.pied-fort'.tr()} : ${player.strongFoot.label}',
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
                    if (isCaptain) ...<Widget>[
                      Image.asset(_kCaptainAsset, width: 30),
                      const SizedBox(width: 6),
                    ],
                    _JerseyIcon(size: 40, isSub: isSub, number: number),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Entête : titre + compteur d'effectif (« X sur N joueurs ») + bouton
/// « Créer un joueur » (design 1:151 ; même pattern que `_BodyHeader` de
/// `mon_equipe_screen.dart`).
class _Header extends StatelessWidget {
  const _Header({required this.playerCount, required this.maxPlayers});

  final int playerCount;

  /// Plafond effectif (`app_config/config.max_players`), pour que l'affichage
  /// dise la même chose que les règles Firestore.
  final int maxPlayers;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'app.gerer-equipe-numbers.detail-joueurs'.tr(),
              style: AppThemeStyle.semiBStyle(cFs(18), AppColor.primaryLabels),
            ),
            cSh(6),
            Text(
              'app.gerer-equipe-numbers.effectif'.tr(
                args: <String>['$playerCount', '$maxPlayers'],
              ),
              style: AppThemeStyle.mediumStyle(cFs(13), AppColor.primaryLabels),
            ),
          ],
        ),
        cSw(16),
        _CreerJoueurButton(playerCount: playerCount, maxPlayers: maxPlayers),
      ],
    );
  }
}

/// Bouton pilule blanche « Créer un joueur » (design 1:151/1:680).
class _CreerJoueurButton extends StatelessWidget {
  const _CreerJoueurButton({
    required this.playerCount,
    required this.maxPlayers,
  });

  final int playerCount;
  final int maxPlayers;

  @override
  Widget build(BuildContext context) {
    final bool full = isSquadFull(playerCount, max: maxPlayers);
    if (isPhoneLayout) {
      return Material(
        color: full ? AppColor.disabled : AppColor.surface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap:
              full
                  ? null
                  : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CreerJoueurScreen(),
                    ),
                  ),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColor.divider),
            ),
            child: Text(
              'app.gerer-equipe-numbers.creer-joueur'.tr(),
              maxLines: 1,
              style: AppThemeStyle.semiBStyle(cFs(16), AppColor.primaryLabels),
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(cR(999)),
        onTap:
            full
                ? null
                : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CreerJoueurScreen(),
                  ),
                ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: cW(16), vertical: cH(11)),
          decoration: BoxDecoration(
            color: full ? AppColor.disabled : AppColor.surface,
            borderRadius: BorderRadius.circular(cR(999)),
            border: Border.all(color: AppColor.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'app.gerer-equipe-numbers.creer-joueur'.tr(),
                style: AppThemeStyle.semiBStyle(
                  cFs(14),
                  AppColor.primaryLabels,
                ),
              ),
              cSw(6),
              Icon(
                Iconsax.arrow_circle_right,
                size: cIc(18),
                color: AppColor.primaryLabels,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte d'un poste (ou des remplaçants) : bandeau blanc arrondi (titre +
/// « Pied Fort » / « Numéro »), puis une pilule blanche par ligne joueur.
///
/// Le design 1:133 ne met un fond QUE sur l'entête ; l'écart est volontaire —
/// posées nues, les lignes tombaient sous 2:1 de contraste sur la pelouse
/// d'`AppBackground`. Ne pas « réaligner sur Figma ».
class _PositionGroup extends StatelessWidget {
  const _PositionGroup({
    required this.title,
    required this.players,
    required this.draft,
    required this.onOpenPicker,
    required this.onAccept,
    this.emptyLabel,
  });

  final String title;
  final List<Player> players;
  final CompositionDraft draft;
  final ValueChanged<Player> onOpenPicker;
  final void Function(Player player, Object data) onAccept;

  /// `null` → message par défaut « Aucun joueur à ce poste. ».
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(horizontal: cW(16), vertical: cH(9)),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(cR(20)),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: AppThemeStyle.mediumStyle(
                    cFs(15),
                    AppColor.primaryLabels,
                  ),
                ),
              ),
              SizedBox(
                width: cW(70),
                child: Text(
                  'app.gerer-equipe-numbers.pied-fort'.tr(),
                  textAlign: TextAlign.right,
                  style: AppThemeStyle.regularStyle(
                    cFs(13),
                    AppColor.primaryLabels,
                  ),
                ),
              ),
              cSw(16),
              SizedBox(
                width: cW(80),
                child: Text(
                  'app.gerer-equipe-numbers.numero'.tr(),
                  textAlign: TextAlign.right,
                  style: AppThemeStyle.regularStyle(
                    cFs(13),
                    AppColor.primaryLabels,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (players.isEmpty) ...<Widget>[
          cSh(8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cW(16)),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: cW(6), vertical: cH(4)),
              decoration: BoxDecoration(
                color: AppColor.rosterRowSurface,
                borderRadius: BorderRadius.circular(cR(10)),
              ),
              child: Text(
                emptyLabel ??
                    'app.gerer-equipe-numbers.aucun-joueur-poste'.tr(),
                style: AppThemeStyle.regularStyle(
                  cFs(12),
                  AppColor.secondaryLabels,
                ),
              ),
            ),
          ),
        ],
        for (final Player p in players) ...<Widget>[
          cSh(10),
          _PlayerRow(
            player: p,
            number: draft.numbers[p.id],
            isSub: draft.substituteIds.contains(p.id),
            isCaptain: draft.captainId == p.id,
            onTap: () => onOpenPicker(p),
            onAccept: (Object data) => onAccept(p, data),
          ),
        ],
      ],
    );
  }
}

/// Ligne d'un joueur : nom, pied fort, badge numéro (glissable/tapable) et
/// éventuellement le tag « Cap. ». Toute la ligne est une cible de dépôt pour
/// un numéro ou le brassard de capitaine (design 1:133).
class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.number,
    required this.isSub,
    required this.isCaptain,
    required this.onTap,
    required this.onAccept,
  });

  final Player player;
  final int? number;
  final bool isSub;
  final bool isCaptain;
  final VoidCallback onTap;
  final void Function(Object data) onAccept;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: cW(16)),
      child: DragTarget<Object>(
        onWillAcceptWithDetails:
            (DragTargetDetails<Object> details) =>
                details.data is _NumberDrag || details.data == _kCaptainDragTag,
        onAcceptWithDetails:
            (DragTargetDetails<Object> details) => onAccept(details.data),
        builder: (BuildContext context, List<Object?> candidates, _) {
          final bool hovering = candidates.isNotEmpty;
          return Container(
            padding: EdgeInsets.symmetric(horizontal: cW(6), vertical: cH(4)),
            decoration: BoxDecoration(
              color:
                  hovering
                      ? AppColor.rosterRowHovered
                      : AppColor.rosterRowSurface,
              borderRadius: BorderRadius.circular(cR(10)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    player.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeStyle.mediumStyle(
                      cFs(15),
                      AppColor.rosterName,
                    ),
                  ),
                ),
                SizedBox(
                  width: cW(70),
                  child: Text(
                    player.strongFoot.label,
                    textAlign: TextAlign.right,
                    style: AppThemeStyle.mediumStyle(
                      cFs(15),
                      AppColor.primaryLabels,
                    ),
                  ),
                ),
                cSw(16),
                SizedBox(
                  width: cW(80),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      if (isCaptain) ...<Widget>[const _CaptainTag(), cSw(4)],
                      GestureDetector(
                        onTap: onTap,
                        child: _JerseyIcon(
                          size: cIc(30),
                          isSub: isSub,
                          number: number,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Tag « Cap. » (image `captain.png`), affiché près du numéro du capitaine
/// (design : chip « Brassard de capitaine » posée sur la ligne).
class _CaptainTag extends StatelessWidget {
  const _CaptainTag();

  @override
  Widget build(BuildContext context) {
    return Image.asset(_kCaptainAsset, width: cIc(28));
  }
}

/// Colonne de droite : les 3 panneaux « Attribuer les numéros » / « Numéros
/// des remplaçants » / « Brassard de capitaine » (design 1:421/1:424/1:427).
class _RightRail extends StatelessWidget {
  const _RightRail({required this.draft, required this.maxSquad});

  final CompositionDraft draft;

  /// Effectif maximum du format : borne haute de la grille titulaires.
  final int maxSquad;

  @override
  Widget build(BuildContext context) {
    // Unicité globale : un numéro porté par un titulaire est aussi « pris »
    // pour la grille des remplaçants, et réciproquement.
    final Set<int> taken = draft.numbers.values.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _RailPanel(
          title: 'app.gerer-equipe-numbers.attribuer-numeros'.tr(),
          child: _RailJerseyGrid(
            numbers: starterNumbersOf(draft, maxSquad),
            taken: taken,
            // Numéros réservés aux remplaçants : grisés et impossibles à glisser.
            blocked: draft.subNumbers,
            isSub: false,
          ),
        ),
        cSh(16),
        _AddSubstitutesButton(hasSubs: draft.subNumbers.isNotEmpty),
        if (draft.subNumbers.isNotEmpty) ...<Widget>[
          cSh(16),
          _RailPanel(
            title: 'app.gerer-equipe-numbers.numeros-remplacants'.tr(),
            child: _RailJerseyGrid(
              numbers: subNumbersOf(draft),
              taken: taken,
              isSub: true,
            ),
          ),
        ],
        cSh(16),
        _RailPanel(
          title: 'app.gerer-equipe-numbers.brassard-capitaine'.tr(),
          child: _CaptainDraggable(assigned: draft.captainId != null),
        ),
      ],
    );
  }
}

/// Bouton « Ajouter les remplaçants » : ouvre le choix des numéros réservés aux
/// remplaçants (ils apparaissent ensuite dans leur panneau, à glisser sur un
/// joueur).
class _AddSubstitutesButton extends ConsumerWidget {
  const _AddSubstitutesButton({required this.hasSubs});

  final bool hasSubs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColor.primaryColor,
      borderRadius: BorderRadius.circular(cR(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(cR(20)),
        onTap: () => showSubNumbersDialog(context, ref),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: cW(14), vertical: cH(11)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Iconsax.add_circle,
                size: cIc(18),
                color: AppColor.textLight,
              ),
              cSw(8),
              Flexible(
                child: Text(
                  hasSubs
                      ? 'app.gerer-equipe-numbers.modifier-remplacants'.tr()
                      : 'app.gerer-equipe-numbers.ajouter-remplacants'.tr(),
                  textAlign: TextAlign.center,
                  style: AppThemeStyle.semiBStyle(
                    isPhoneLayout ? cFs(17) : cFs(13),
                    AppColor.textLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailPanel extends StatelessWidget {
  const _RailPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(horizontal: cW(14), vertical: cH(9)),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(cR(20)),
          ),
          child: Text(
            title,
            style: AppThemeStyle.mediumStyle(
              isPhoneLayout ? cFs(18) : cFs(14),
              AppColor.primaryLabels,
            ),
          ),
        ),
        cSh(10),
        child,
      ],
    );
  }
}

/// Grille de puces numéro glissables (panneaux de droite), 4 par ligne.
class _RailJerseyGrid extends StatelessWidget {
  const _RailJerseyGrid({
    required this.numbers,
    required this.taken,
    required this.isSub,
    this.blocked = const <int>{},
  });

  /// Numéros affichés, dans l'ordre. Une liste plutôt qu'un intervalle : les
  /// numéros remplaçants sont un choix libre du coach, pas forcément contigus.
  final List<int> numbers;
  final Set<int> taken;
  final bool isSub;

  /// Numéros non attribuables dans cette grille (réservés aux remplaçants) : grisés, non glissables.
  final Set<int> blocked;

  /// 4 puces par ligne quand la largeur le permet (design 1:421/1:424) ; un
  /// `Wrap` replie sur moins de colonnes dans un panneau étroit (téléphone)
  /// au lieu de déborder.
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: isPhoneLayout ? 6 : 8,
      runSpacing: isPhoneLayout ? 8 : cH(8),
      children: <Widget>[
        for (final int n in numbers)
          _DraggableJerseyTile(
            number: n,
            isSub: isSub,
            taken: taken.contains(n),
            blocked: blocked.contains(n),
          ),
      ],
    );
  }
}

class _DraggableJerseyTile extends StatelessWidget {
  const _DraggableJerseyTile({
    required this.number,
    required this.isSub,
    required this.taken,
    this.blocked = false,
  });

  final int number;
  final bool isSub;
  final bool taken;

  /// Numéro réservé aux remplaçants : grisé, on ne peut pas le glisser sur un titulaire.
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final Widget tile = _JerseyIcon(
      size: isPhoneLayout ? 40 : 44,
      isSub: isSub,
      number: number,
      opacity: taken || blocked ? 0.36 : 1,
    );
    if (blocked) return tile;
    // Téléphone : le panneau défile ; un glisser immédiat empêcherait de le
    // faire défiler. Appui bref avant de glisser.
    if (isPhoneLayout) {
      return LongPressDraggable<_NumberDrag>(
        data: _NumberDrag(number, isSubstitute: isSub),
        delay: const Duration(milliseconds: 150),
        feedback: Material(
          color: Colors.transparent,
          child: _JerseyIcon(size: 48, isSub: isSub, number: number),
        ),
        childWhenDragging: Opacity(opacity: 0.25, child: tile),
        child: tile,
      );
    }
    return Draggable<_NumberDrag>(
      data: _NumberDrag(number, isSubstitute: isSub),
      feedback: Material(
        color: Colors.transparent,
        child: _JerseyIcon(size: 44, isSub: isSub, number: number),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: tile),
      child: tile,
    );
  }
}

/// Chip « Cap. » glissable depuis le panneau (design 1:427/1:1175).
class _CaptainDraggable extends StatelessWidget {
  const _CaptainDraggable({required this.assigned});

  final bool assigned;

  @override
  Widget build(BuildContext context) {
    if (isPhoneLayout) {
      return Align(
        alignment: Alignment.centerLeft,
        child: LongPressDraggable<String>(
          data: _kCaptainDragTag,
          delay: const Duration(milliseconds: 150),
          feedback: const Material(
            color: Colors.transparent,
            child: _CapChip(),
          ),
          childWhenDragging: const Opacity(opacity: 0.25, child: _CapChip()),
          child: Opacity(opacity: assigned ? 0.5 : 1, child: const _CapChip()),
        ),
      );
    }
    return SizedBox(
      height: 17,
      child: Draggable<String>(
        data: _kCaptainDragTag,
        feedback: const Material(color: Colors.transparent, child: _CapChip()),
        childWhenDragging: const Opacity(opacity: 0.25, child: _CapChip()),
        child: Opacity(opacity: assigned ? 0.5 : 1, child: const _CapChip()),
      ),
    );
  }
}

class _CapChip extends StatelessWidget {
  const _CapChip();

  @override
  Widget build(BuildContext context) {
    return Image.asset(_kCaptainAsset, width: 44);
  }
}

/// Popup « Attribuer un numéro » : grilles titulaires (cyan) et remplaçants
/// (bleu) au tap, croix de fermeture (design 1:1191).
/// Popup « Sélectionnez les numéros des remplaçants » (maquette, écran 6).
/// Elle s'ouvre juste après le choix du nombre de joueurs, avant
/// l'écran « Attribuez les numéros », comme l'annote la maquette.
///
/// Elle remplace un intervalle contigu imposé (`kSubPoolSize` numéros à la
/// suite du pool titulaire) par un choix libre sur les 36 numéros de la
/// maquette. Une puce non retenue porte le maillot de l'ÉQUIPE ; retenue, elle
/// prend celui des remplaçants (`jerseyAssetFor`, soit le bleu foncé tant que
/// l'équipe ne le porte pas déjà). La couleur EST le signal de sélection.
Future<void> showSubNumbersDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColor.scrim,
    builder: (BuildContext ctx) => const _SubNumbersDialog(),
  );
}

class _SubNumbersDialog extends ConsumerStatefulWidget {
  const _SubNumbersDialog();

  @override
  ConsumerState<_SubNumbersDialog> createState() => _SubNumbersDialogState();
}

class _SubNumbersDialogState extends ConsumerState<_SubNumbersDialog> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    final CompositionDraft draft = ref.read(compositionDraftProvider);
    // Pré-sélection : le choix déjà fait, sinon l'ancien intervalle contigu —
    // le coach retrouve le comportement historique s'il valide sans rien
    // toucher, plutôt qu'un banc sans aucun numéro.
    _selected = Set<int>.from(subNumbersOf(draft));
  }

  @override
  Widget build(BuildContext context) {
    final List<int> pool = <int>[for (int n = 1; n <= kJerseyGridMax; n++) n];

    return Dialog(
      backgroundColor: AppColor.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: cW(40)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cR(20)),
      ),
      child: ConstrainedBox(
        // La coquille des autres popups (560) laissait une large bande vide à
        // droite de la grille, qui ne fait que 6 puces de cIc(42). On la cale
        // sur son contenu. Le titre passe alors sur deux lignes — mesuré, il
        // faudrait remonter au-delà de 460 pour le tenir sur une seule, ce qui
        // ramènerait la largeur au défaut qu'on corrige ici.
        constraints: BoxConstraints(maxWidth: isPhoneLayout ? 520 : cW(430)),
        child: Padding(
          padding:
              isPhoneLayout
                  ? const EdgeInsets.fromLTRB(20, 12, 20, 14)
                  : EdgeInsets.fromLTRB(cW(24), cH(16), cW(24), cH(22)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(width: cIc(20)),
                  Expanded(
                    child: Text(
                      'app.gerer-equipe-numbers.selectionner-numeros-remplacants'
                          .tr(),
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
              cSh(16),
              // « Scroll si besoin de joueurs » (annotation de la maquette) :
              // la grille descend jusqu'à 36, elle ne tient pas toujours.
              Flexible(
                child: SingleChildScrollView(
                  child: Center(
                    child: _PickerJerseyGrid(
                      isSub: false,
                      subOnSelect: true,
                      centered: true,
                      perRow: isPhoneLayout ? 9 : 6,
                      numbers: pool,
                      taken: const <int>{},
                      isSelected: _selected.contains,
                      onTap:
                          (int n) => setState(() {
                            if (!_selected.remove(n)) _selected.add(n);
                          }),
                    ),
                  ),
                ),
              ),
              cSh(18),
              WizardCtaButton(
                label: 'app.gerer-equipe-numbers.valider'.tr(),
                enabled: _selected.isNotEmpty,
                onTap: () {
                  ref
                      .read(compositionDraftProvider.notifier)
                      .setSubNumbers(_selected);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberPickerDialog extends StatefulWidget {
  const _NumberPickerDialog({
    required this.player,
    required this.draft,
    required this.maxSquad,
    required this.onConfirm,
    required this.onClear,
  });

  final Player player;
  final CompositionDraft draft;

  /// Effectif maximum du format : borne haute de la grille titulaires.
  final int maxSquad;
  final void Function(int number, bool isSub) onConfirm;
  final VoidCallback onClear;

  @override
  State<_NumberPickerDialog> createState() => _NumberPickerDialogState();
}

class _NumberPickerDialogState extends State<_NumberPickerDialog> {
  int? _selectedNumber;
  bool _selectedIsSub = false;

  @override
  void initState() {
    super.initState();
    final int? current = widget.draft.numbers[widget.player.id];
    final bool sub = widget.draft.substituteIds.contains(widget.player.id);
    // Pas de présélection hors pool : un numéro hérité (18 dans un 11vs11)
    // n'aurait aucune tuile allumée mais laisserait « Attribuer » actif, donc
    // réécrirait en silence un numéro que la grille dit ne pas exister.
    final bool inPool =
        sub
            ? subNumbersOf(widget.draft).contains(current)
            : (current != null &&
                starterNumbersOf(widget.draft, widget.maxSquad).contains(current));
    if (current != null && inPool) {
      _selectedNumber = current;
      _selectedIsSub = sub;
    }
  }

  void _select(int number, bool isSub) => setState(() {
    _selectedNumber = number;
    _selectedIsSub = isSub;
  });

  @override
  Widget build(BuildContext context) {
    final String playerId = widget.player.id!;
    final Set<int> taken = <int>{
      for (final MapEntry<String, int> e in widget.draft.numbers.entries)
        if (e.key != playerId) e.value,
    };
    // Numéros de la grille des remplaçants : grisés et bloqués côté titulaires.
    final Set<int> reserved = subNumbersOf(widget.draft).toSet();

    return Dialog(
      backgroundColor: AppColor.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: cW(40)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cR(20)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isPhoneLayout ? 560 : cW(560)),
        child: Padding(
          padding:
              isPhoneLayout
                  ? const EdgeInsets.fromLTRB(20, 12, 20, 14)
                  : EdgeInsets.fromLTRB(cW(24), cH(16), cW(24), cH(22)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(width: cIc(20)),
                  Expanded(
                    child: Text(
                      'app.gerer-equipe-numbers.attribuer-numero'.tr(),
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
              cSh(10),
              Row(
                children: <Widget>[
                  Text(
                    widget.player.fullName,
                    style: AppThemeStyle.mediumStyle(
                      cFs(15),
                      AppColor.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.player.strongFoot.adjective} - '
                    '${widget.player.position.singular}',
                    style: AppThemeStyle.mediumStyle(
                      cFs(15),
                      AppColor.primaryLabels,
                    ),
                  ),
                ],
              ),
              cSh(12),
              Container(height: 1, color: AppColor.divider),
              cSh(16),
              if (isPhoneLayout)
                _phoneBody(playerId, taken)
              else ...<Widget>[
                _PickerJerseyGrid(
                  isSub: false,
                  numbers: starterNumbersOf(widget.draft, widget.maxSquad),
                  taken: taken,
                  blocked: reserved,
                  isSelected:
                      (int n) => !_selectedIsSub && _selectedNumber == n,
                  onTap: (int n) => _select(n, false),
                ),
                cSh(14),
                _PickerJerseyGrid(
                  isSub: true,
                  numbers: subNumbersOf(widget.draft),
                  taken: taken,
                  isSelected: (int n) => _selectedIsSub && _selectedNumber == n,
                  onTap: (int n) => _select(n, true),
                ),
                cSh(18),
                WizardCtaButton(
                  label: 'app.gerer-equipe-numbers.attribuer'.tr(),
                  enabled: _selectedNumber != null,
                  onTap:
                      () => widget.onConfirm(_selectedNumber!, _selectedIsSub),
                ),
                if (widget.draft.numbers.containsKey(playerId)) ...<Widget>[
                  cSh(8),
                  TextButton(
                    onPressed: widget.onClear,
                    child: Text(
                      'app.gerer-equipe-numbers.retirer-numero'.tr(),
                      style: AppThemeStyle.semiBStyle(
                        cFs(13),
                        AppColor.secondaryLabels,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Téléphone : les deux grilles à gauche, l'action à droite — tient dans la
  /// hauteur du paysage sans défiler.
  Widget _phoneBody(String playerId, Set<int> taken) {
    final Set<int> reserved = subNumbersOf(widget.draft).toSet();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _PickerJerseyGrid(
                isSub: false,
                perRow: 7,
                numbers: starterNumbersOf(widget.draft, widget.maxSquad),
                taken: taken,
                blocked: reserved,
                isSelected: (int n) => !_selectedIsSub && _selectedNumber == n,
                onTap: (int n) => _select(n, false),
              ),
              _PickerJerseyGrid(
                isSub: true,
                perRow: 7,
                numbers: subNumbersOf(widget.draft),
                taken: taken,
                isSelected: (int n) => _selectedIsSub && _selectedNumber == n,
                onTap: (int n) => _select(n, true),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 150,
          child: Column(
            children: <Widget>[
              WizardCtaButton(
                label: 'app.gerer-equipe-numbers.attribuer'.tr(),
                enabled: _selectedNumber != null,
                onTap: () => widget.onConfirm(_selectedNumber!, _selectedIsSub),
              ),
              if (widget.draft.numbers.containsKey(playerId))
                TextButton(
                  onPressed: widget.onClear,
                  child: Text(
                    'app.gerer-equipe-numbers.retirer-numero'.tr(),
                    style: AppThemeStyle.semiBStyle(
                      cFs(16),
                      AppColor.secondaryLabels,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Grille de puces numéro sélectionnables au tap (popup), 6 par ligne.
class _PickerJerseyGrid extends StatelessWidget {
  const _PickerJerseyGrid({
    required this.isSub,
    required this.numbers,
    required this.taken,
    required this.isSelected,
    required this.onTap,
    this.blocked = const <int>{},
    this.subOnSelect = false,
    this.centered = false,
    this.perRow = 6,
  });

  final bool isSub;

  /// Quand vrai, chaque puce porte le maillot de l'ÉQUIPE tant qu'elle n'est
  /// pas retenue, et celui des remplaçants une fois retenue — c'est ainsi que
  /// la maquette signale la sélection, sans liseré.
  final bool subOnSelect;

  /// Centre la grille dans sa boîte. Sans cela les `Row` prennent toute la
  /// largeur disponible (`MainAxisSize.max`) et la grille reste collée à
  /// gauche : l'envelopper dans un `Center` n'y change rien, il faut faire
  /// rétrécir les rangées elles-mêmes.
  final bool centered;

  /// Numéros affichés, dans l'ordre (choix libre côté remplaçants).
  final List<int> numbers;
  final Set<int> taken;

  /// Numéros réservés (remplaçants) : grisés, non sélectionnables.
  final Set<int> blocked;

  /// Permet la sélection simple (un seul numéro) comme multiple (la popup de
  /// choix des numéros remplaçants).
  final bool Function(int number) isSelected;
  final ValueChanged<int> onTap;

  /// Puces par ligne : 6 (design 1:1191) ; davantage sur téléphone, où la
  /// hauteur manque plus que la largeur.
  final int perRow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: <Widget>[
        for (int start = 0; start < numbers.length; start += perRow)
          Padding(
            padding: EdgeInsets.only(bottom: cH(10)),
            child: Row(
              mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
              children: <Widget>[
                for (
                  int i = start;
                  i < (start + perRow).clamp(0, numbers.length);
                  i++
                ) ...<Widget>[
                  if (i != start) cSw(10),
                  _SelectableJerseyTile(
                    number: numbers[i],
                    isSub: subOnSelect ? isSelected(numbers[i]) : isSub,
                    taken: taken.contains(numbers[i]),
                    blocked: blocked.contains(numbers[i]),
                    selected: isSelected(numbers[i]),
                    onTap: () => onTap(numbers[i]),
                    showBorder: !subOnSelect,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SelectableJerseyTile extends StatelessWidget {
  const _SelectableJerseyTile({
    required this.number,
    required this.isSub,
    required this.taken,
    required this.selected,
    required this.onTap,
    this.blocked = false,
    this.showBorder = true,
  });

  final int number;
  final bool isSub;
  final bool taken;
  final bool blocked;
  final bool selected;
  final VoidCallback onTap;

  /// Popup « numéros des remplaçants » : la sélection s'y lit à la COULEUR du
  /// maillot (celle de l'équipe → celle des remplaçants), pas à un liseré.
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final Widget tile = _JerseyIcon(
      size: isPhoneLayout ? 40 : cIc(42),
      isSub: isSub,
      number: number,
      opacity: taken || blocked ? 0.36 : 1,
    );
    if (blocked) return tile;
    return InkResponse(
      onTap: onTap,
      radius: isPhoneLayout ? 26 : cIc(30),
      child:
          selected && showBorder
              ? Container(
                padding: EdgeInsets.all(cW(2)),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColor.primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(cR(8)),
                ),
                child: tile,
              )
              : tile,
    );
  }
}

/// Maillot « vide » (contour pointillé + « + ») des lignes sans numéro.
const String _kEmptyJerseyAsset = 'assets/images/shirt-empty-green.png';

/// Icône maillot : maillot numéroté quand un numéro est attribué (couleur
/// portée par l'équipe pour les titulaires, bleu pour les remplaçants, cf.
/// `jerseyAssetFor`), `shirt-empty` + « + » sinon (mêmes visuels que
/// `gerer_equipe_placement_screen.dart` / `match_live_screen.dart`, design
/// 1:133 / 1:421 / 1:424).
class _JerseyIcon extends ConsumerWidget {
  const _JerseyIcon({
    required this.size,
    required this.isSub,
    this.number,
    this.opacity = 1,
  });

  final double size;
  final bool isSub;
  final int? number;
  final double opacity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool empty = number == null;
    final String jersey = jerseyAssetFor(
      isSub: isSub,
      own: ref.watch(matchDraftProvider).ownJersey?.color,
    );

    // `shirt-empty-green` a déjà son propre contour pointillé vert + « + »
    // dessinés dedans : pas besoin d'un second glyphe par-dessus. Il remplit
    // ~99% de son canevas — c'est la référence de taille voulue.
    final Widget shirtImage = Image.asset(
      empty ? _kEmptyJerseyAsset : jersey,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
    final Widget content = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Opacity(opacity: empty ? 0.9 : 1, child: shirtImage),
          if (!empty)
            Padding(
              padding: EdgeInsets.only(top: size * 0.08),
              child: Text(
                '$number',
                style: AppThemeStyle.boldStyle(
                  // Téléphone : taille réelle (≈ 40 % du maillot), sans la
                  // réduction de l'échelle de la maquette.
                  isPhoneLayout ? cFs(size * 0.5) : cFs(size * 0.32),
                  numberColorForJerseyAsset(jersey),
                ),
              ),
            ),
        ],
      ),
    );
    return opacity == 1 ? content : Opacity(opacity: opacity, child: content);
  }
}
