import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/home_tab_provider.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/view/page/coup_denvoi_step1_screen.dart';
import 'package:wina/view/page/creer_joueur_screen.dart';
import 'package:wina/view/page/detail_joueur_screen.dart';
import 'package:wina/view/page/gerer_maillots_screen.dart';
import 'package:wina/view/page/ia_screen.dart';
import 'package:wina/view/page/statistiques_matchs_screen.dart';
import 'package:wina/view/page/test_equipe_screen.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/app_loader.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/empty_state_placeholder.dart';
import 'package:wina/view/widget/jersey_form.dart';
import 'package:wina/view/widget/notification_bell.dart';
import 'package:wina/view/widget/search_field.dart';
import 'package:wina/view/widget/settings_button.dart';
import 'package:wina/view/widget/whistle_icon.dart';

// Dimensions couplées de la barre de navigation basse et du bouton flottant
// « Coup d'envoi » : ce dernier chevauche le haut de la barre, donc son offset
// vertical se déduit de la hauteur et de la marge de la nav.
const double _kNavBarHeight = 62;
const double _kNavBottomMargin = 16;
const double _kNavCenterGap = 210; // creux central réservé au bouton flottant
const double _kCoupDEnvoiHeight =
    52; // hauteur approximative du bouton flottant

/// Page « Mon équipe » : effectif de l'équipe regroupé par poste, avec les
/// actions « Créer un joueur » et « Coup d'envoi », et la barre de navigation
/// basse. Reproduit l'écran tablette du design (1194 x 834).
class MonEquipeScreen extends ConsumerStatefulWidget {
  const MonEquipeScreen({super.key});

  @override
  ConsumerState<MonEquipeScreen> createState() => _MonEquipeScreenState();
}

class _MonEquipeScreenState extends ConsumerState<MonEquipeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Temporise le filtrage (~300 ms) pour ne pas refiltrer à chaque frappe.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value);
    });
  }

  /// Effacement immédiat : annule la temporisation en attente pour ne pas
  /// réappliquer l'ancienne recherche après coup.
  void _clearSearch() {
    _debounce?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      _searchController.clear();
      _query = '';
    });
  }

  /// Filtre LOCAL sur « prénom nom » (contient, sans casse) : l'effectif est
  /// déjà en mémoire (≤ 20 joueurs), aucun nom de joueur ne quitte l'appareil.
  List<Player> _visible(List<Player> roster) {
    final String q = _query.trim().toLowerCase();
    if (q.isEmpty) return roster;
    return roster
        .where((Player p) => p.fullName.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    // Onglet courant tenu dans un provider : le logo « wina » des trois autres
    // onglets doit pouvoir le remettre sur l'accueil (cf. `WinaWordmark`).
    final int index = ref.watch(homeTabProvider);
    // Coquille principale : corps commuté entre onglets (IndexedStack), barre
    // de navigation basse et bouton « Coup d'envoi » persistants.
    return Scaffold(
      backgroundColor: AppColor.background,
      // Fond plein écran (sous l'encoche et la barre système, sans bordures) ; contenu centré dans la zone sûre.
      body: AppBackdrop(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Corps plein écran : les onglets passent derrière la barre de
            // navigation flottante (translucide + flou), qui les recouvre.
            IndexedStack(
              index: index,
              children: [
                _teamTab(),
                const IaScreen(),
                const StatistiquesMatchsScreen(),
                const TestEquipeScreen(),
              ],
            ),
            // Barre de navigation flottante, superposée au bas du contenu.
            Positioned(
              left: isPhoneLayout ? 16 : cW(33),
              right: isPhoneLayout ? 16 : cW(33),
              bottom: cH(_kNavBottomMargin),
              child: _BottomNavBar(
                currentIndex: index,
                onSelect:
                    (int i) => ref.read(homeTabProvider.notifier).state = i,
              ),
            ),
            // Bouton « Coup d'envoi », centré, chevauchant le haut de la nav.
            Positioned(
              left: 0,
              right: 0,
              bottom: cH(
                _kNavBottomMargin + _kNavBarHeight - _kCoupDEnvoiHeight / 2,
              ),
              child: const Center(child: _CoupDEnvoiButton()),
            ),
          ],
        ),
      ),
    );
  }

  /// Onglet « Mon équipe » : effectif (chargé depuis Firestore) + entête.
  Widget _teamTab() {
    final AsyncValue<List<Player>> playersAsync = ref.watch(
      playersStreamProvider,
    );
    final CoachProfile? coach = ref.watch(coachProfileProvider).valueOrNull;
    final List<Jersey> jerseys =
        ref.watch(jerseysProvider).valueOrNull ?? const <Jersey>[];
    return playersAsync.when(
      data: (List<Player> roster) => _teamContent(roster, coach, jerseys),
      loading: () => const AppLoader(),
      error:
          (Object error, _) => Center(
            child: Text(
              'app.mon-equipe.erreur-chargement'.tr(),
              style: AppThemeStyle.mediumStyle(
                cFs(15),
                AppColor.secondaryLabels,
              ),
            ),
          ),
    );
  }

  Widget _teamContent(
    List<Player> roster,
    CoachProfile? coach,
    List<Jersey> jerseys,
  ) {
    final List<Player> visible = _visible(roster);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isPhoneLayout ? 16 : cW(40),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cSh(isPhoneLayout ? 8 : 18),
              _TopBar(coach: coach, jerseys: jerseys),
              cSh(isPhoneLayout ? 6 : 14),
              Container(height: 1, color: AppColor.divider),
              cSh(isPhoneLayout ? 8 : 16),
              _BodyHeader(
                searchField: SearchField(
                  controller: _searchController,
                  hintText: 'app.recherche.joueurs-hint'.tr(),
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
                ),
                playerCount: roster.length,
                maxPlayers:
                    ref.watch(maxSquadSizeProvider).valueOrNull ??
                    kMaxSquadSize,
              ),
              cSh(isPhoneLayout ? 8 : 16),
            ],
          ),
        ),
        // Grille des postes (défilable si l'effectif dépasse la hauteur).
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isPhoneLayout ? 16 : cW(40),
            ),
            child:
                roster.isEmpty
                    ? EmptyStatePlaceholder(
                      icon: Iconsax.profile_2user,
                      title: 'app.mon-equipe.effectif-vide-titre'.tr(),
                      subtitle: 'app.mon-equipe.effectif-vide-sous-titre'.tr(),
                      padding: EdgeInsets.only(bottom: cH(kBottomNavClearance)),
                    )
                    : visible.isEmpty
                    ? EmptyStatePlaceholder(
                      icon: Iconsax.search_normal_1,
                      title: 'app.mon-equipe.aucun-resultat-titre'.tr(),
                      subtitle: 'app.mon-equipe.aucun-resultat-sous-titre'.tr(),
                      padding: EdgeInsets.only(bottom: cH(kBottomNavClearance)),
                    )
                    // 4 colonnes de postes qui défilent chacune dans leur colonne (tablette
                    // comme téléphone), pas de long défilement de page.
                    : Padding(
                      padding: EdgeInsets.only(bottom: cH(kBottomNavClearance)),
                      child: _PositionGrid(roster: visible),
                    ),
          ),
        ),
        if (!isPhoneLayout) cSh(32),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barre du haut : nom d'équipe, puces (catégorie / division / coach),
// sélecteur de maillots, icônes, logo.
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.coach, required this.jerseys});

  final CoachProfile? coach;
  final List<Jersey> jerseys;

  @override
  Widget build(BuildContext context) {
    final String teamName =
        (coach?.teamName?.trim().isNotEmpty ?? false)
            ? coach!.teamName!.trim()
            : 'app.mon-equipe.nom-equipe-defaut'.tr();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          // Le nom prend presque toute la place libre (Flexible + Spacer à parts
          // égales le coupait à la moitié : « Équipe de … » sur tablette).
          flex: 9,
          child: Text(
            teamName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemeStyle.semiBStyle(cFs(30), AppColor.primaryLabels),
          ),
        ),
        cSw(20),
        if (coach?.category != null) ...[
          _Chip(
            label: coach!.category!.label,
            style: AppThemeStyle.mediumStyle(cFs(15), AppColor.primaryLabels),
          ),
          cSw(8),
        ],
        if (coach?.division != null) ...[
          _Chip(
            label: coach!.division!.label,
            style: AppThemeStyle.mediumStyle(cFs(15), AppColor.primaryLabels),
          ),
          cSw(8),
        ],
        if (coach?.coachFirstName != null) ...[
          _Chip(
            label: 'app.mon-equipe.puce-coach'.tr(
              namedArgs: <String, String>{'prenom': coach!.coachFirstName!},
            ),
            style: AppThemeStyle.regularStyle(cFs(15), AppColor.primaryLabels),
          ),
          cSw(8),
        ],
        cSw(6),
        _JerseySelector(
          jerseys: jerseys,
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GererMaillotsScreen(),
                ),
              ),
        ),
        const Spacer(),
        const NotificationBell(),
        cSw(16),
        const SettingsButton(),
        cSw(18),
        const WinaWordmark(),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.style});

  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: cW(14), vertical: cH(6)),
      decoration: BoxDecoration(
        color: AppColor.chipBackground,
        borderRadius: BorderRadius.circular(cR(16)),
      ),
      child: Text(
        label,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Petit conteneur blanc présentant les deux maillots (titulaire en cyan,
/// remplaçant sombre) + crayon d'édition.
class _JerseySelector extends StatelessWidget {
  const _JerseySelector({required this.jerseys, required this.onTap});

  final List<Jersey> jerseys;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final List<Jersey> shown = jerseys.toList(growable: false);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: cW(12), vertical: cH(6)),
        decoration: BoxDecoration(
          color: AppColor.chipBackground,
          borderRadius: BorderRadius.circular(cR(16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < shown.length; i++) ...[
              // Les visuels shirt-*.png intègrent une ombre portée qui ne
              // remplit qu'environ 70-75 % du canevas (mesuré sur
              // shirt-blue.png / shirt-orange.png : 354x354, contenu visible
              // ~248x264) : sans compensation le maillot rendu paraît bien
              // plus petit que `size`. On agrandit le rendu de ~1/0.72 sans
              // toucher à l'empreinte de mise en page (absorbée par les
              // espacements cSw(8) alentour) — même correctif que dans
              // gerer_equipe_numbers_screen.dart.
              ShirtIcon(asset: shown[i].color.asset, size: 22),
              cSw(8),
              // Le trait ne sépare que le maillot titulaire (le premier) du
              // reste (remplaçant(s) + crayon), conformément au design Figma.
              if (i == 0 && shown.length > 1) ...[
                Container(width: 1, height: cH(26), color: AppColor.divider),
                cSw(8),
              ],
            ],
            Icon(Iconsax.edit_2, size: cIc(20), color: AppColor.primaryLabels),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Entête du corps : titre + compteur + bouton « Créer un joueur ».
// ─────────────────────────────────────────────────────────────────────────────
class _BodyHeader extends StatelessWidget {
  const _BodyHeader({
    required this.searchField,
    required this.playerCount,
    required this.maxPlayers,
  });

  /// Barre de recherche des joueurs, à gauche du bouton « Créer un joueur ».
  final Widget searchField;
  final int playerCount;

  /// Plafond effectif (`app_config/config.max_players`), pour que l'affichage
  /// dise la même chose que les règles Firestore.
  final int maxPlayers;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'app.mon-equipe.detail-joueurs'.tr(),
              style: AppThemeStyle.semiBStyle(cFs(18), AppColor.primaryLabels),
            ),
            cSh(6),
            Text(
              'app.mon-equipe.compteur-joueurs'.tr(
                namedArgs: <String, String>{
                  'count': '$playerCount',
                  'max': '$maxPlayers',
                },
              ),
              style: AppThemeStyle.mediumStyle(cFs(13), AppColor.primaryLabels),
            ),
          ],
        ),
        const Spacer(),
        searchField,
        cSw(14),
        _PillButton(
          label: 'app.mon-equipe.creer-joueur'.tr(),
          labelSize: 14,
          icon: Icon(
            Iconsax.arrow_circle_right,
            size: cIc(18),
            // Même bascule que le libellé (cf. _PillButton).
            color:
                isSquadFull(playerCount, max: maxPlayers)
                    ? AppColor.primaryLabels
                    : AppColor.textLight,
          ),
          borderRadius: cR(999),
          onTap:
              isSquadFull(playerCount, max: maxPlayers)
                  ? null
                  : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CreerJoueurScreen(),
                    ),
                  ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grille des postes : 2 colonnes x 2 cartes.
// ─────────────────────────────────────────────────────────────────────────────
class _PositionGrid extends StatelessWidget {
  const _PositionGrid({required this.roster});

  final List<Player> roster;

  List<Player> _of(PlayerPosition p) =>
      roster.where((Player e) => e.position == p).toList();

  @override
  Widget build(BuildContext context) {
    // Même présentation sur tablette et téléphone : 4 colonnes, gardiens à gauche puis défenseurs,
    // milieux et attaquants à droite.
    const List<PlayerPosition> order = <PlayerPosition>[
      PlayerPosition.gardien,
      PlayerPosition.defenseur,
      PlayerPosition.milieu,
      PlayerPosition.attaquant,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < order.length; i++) ...[
          if (i > 0) SizedBox(width: isPhoneLayout ? 8 : cW(14)),
          Expanded(
            child: _PositionCard(position: order[i], players: _of(order[i])),
          ),
        ],
      ],
    );
  }
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({required this.position, required this.players});

  final PlayerPosition position;
  final List<Player> players;

  @override
  Widget build(BuildContext context) => _phoneColumn();
}

extension on _PositionCard {
  /// Carte du téléphone : entête fixe + liste des joueurs qui défile dans la
  /// carte (la carte épouse son contenu, jusqu'à la hauteur disponible).
  Widget _phoneColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(cR(12)),
          ),
          padding: EdgeInsets.symmetric(horizontal: cW(10), vertical: cH(8)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  position.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemeStyle.mediumStyle(
                    cFs(15),
                    AppColor.primaryLabels,
                  ),
                ),
              ),
              Text(
                '${players.length}',
                style: AppThemeStyle.semiBStyle(cFs(13), AppColor.primaryColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: cW(10)),
            decoration: BoxDecoration(
              color: AppColor.rosterRowSurface,
              borderRadius: BorderRadius.circular(cR(12)),
            ),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final Player player in players) _PlayerRow(player: player),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isPhoneLayout ? 30 : cH(33),
      child: Row(
        children: [
          Expanded(
            child: Text(
              player.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.mediumStyle(cFs(15), AppColor.rosterName),
            ),
          ),
          // Colonne étroite : le pied fort est dans la fiche joueur.
          cSw(12),
          // Œil : ouvre la fiche « Détail joueur » du joueur de la ligne.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DetailJoueurScreen(player: player),
                  ),
                ),
            child: Padding(
              padding: EdgeInsets.all(isPhoneLayout ? 6 : 0),
              child: Icon(
                Iconsax.eye,
                size: cIc(16),
                color: AppColor.primaryLabels,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bouton « Coup d'envoi » (pilule verte centrée).
// ─────────────────────────────────────────────────────────────────────────────
class _CoupDEnvoiButton extends ConsumerWidget {
  const _CoupDEnvoiButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.surface.withAlpha(128), width: 2),
        color: AppColor.primaryColor,
      ),
      child: _PillButton(
        label: 'app.mon-equipe.coup-denvoi'.tr(),
        labelSize: 15,
        icon: WhistleIcon(size: cIc(18), color: AppColor.textLight),
        iconLeading: true,
        borderRadius: cR(28),
        verticalPadding: 15,
        horizontalPadding: 28,
        onTap: () {
          ref.read(matchDraftProvider.notifier).reset();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CoupDEnvoiStep1Screen(),
            ),
          );
        },
      ),
    );
  }
}

/// Bouton vert réutilisable (texte + icône), utilisé pour « Créer un joueur »
/// et « Coup d'envoi ».
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.labelSize,
    required this.icon,
    required this.borderRadius,
    required this.onTap,
    this.iconLeading = false,
    this.verticalPadding = 12,
    this.horizontalPadding = 18,
  });

  final String label;
  final double labelSize;
  final Widget icon;
  final double borderRadius;

  /// Nul = bouton désactivé (fond grisé, InkWell inerte).
  final VoidCallback? onTap;
  final bool iconLeading;
  final double verticalPadding;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    // Le fond bascule sur `disabled` (#D9D9D9) quand le bouton est inerte :
    // le premier plan doit suivre, blanc sur ce gris ne fait que 1,4:1.
    final Color fg =
        onTap == null ? AppColor.primaryLabels : AppColor.textLight;
    final Widget text = Text(
      label,
      style: AppThemeStyle.semiBStyle(labelSize, fg),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: cW(horizontalPadding),
            vertical: cH(verticalPadding),
          ),
          decoration: BoxDecoration(
            color: onTap == null ? AppColor.disabled : AppColor.primaryColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children:
                iconLeading ? [icon, cSw(10), text] : [text, cSw(10), icon],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barre de navigation basse (sombre, 4 onglets avec un creux central).
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    // Fond à 60% d'opacité + background blur du Figma (blur 30 = rayon,
    // soit un sigma Gaussien de 15 : rayon ≈ 2 × sigma).
    return ClipRRect(
      borderRadius: BorderRadius.circular(cR(999)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: cH(_kNavBarHeight),
          decoration: BoxDecoration(
            color: AppColor.navBar.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(cR(999)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(
                      icon: Iconsax.profile_2user,
                      label: 'app.mon-equipe.nav-mon-equipe'.tr(),
                      active: currentIndex == 0,
                      onTap: () => onSelect(0),
                    ),
                    _NavItem(
                      icon: Iconsax.messages_2,
                      label: 'app.mon-equipe.nav-ia'.tr(),
                      active: currentIndex == 1,
                      onTap: () => onSelect(1),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isPhoneLayout ? 150 : cW(_kNavCenterGap)),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(
                      icon: Iconsax.chart_21,
                      label: 'app.mon-equipe.nav-statistiques'.tr(),
                      active: currentIndex == 2,
                      onTap: () => onSelect(2),
                    ),
                    _NavItem(
                      icon: Iconsax.people,
                      label: 'app.mon-equipe.nav-test-equipe'.tr(),
                      active: currentIndex == 3,
                      onTap: () => onSelect(3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: active ? 1 : 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: cIc(22), color: AppColor.textLight),
            cSh(4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.mediumStyle(cFs(8), AppColor.textLight),
            ),
          ],
        ),
      ),
    );
  }
}
