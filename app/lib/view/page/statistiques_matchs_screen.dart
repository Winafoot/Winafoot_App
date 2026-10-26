import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/search/union_search.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/match_period.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/providers/search_providers.dart';
import 'package:wina/view/page/bilan_collectif_screen.dart';
import 'package:wina/view/page/bilan_individuel_screen.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/app_loader.dart';
import 'package:wina/view/widget/empty_state_placeholder.dart';
import 'package:wina/view/widget/formation_pitch.dart';
import 'package:wina/view/widget/notification_bell.dart';
import 'package:wina/view/widget/page_header.dart';
import 'package:wina/view/widget/phone_category_chip.dart';
import 'package:wina/view/widget/settings_button.dart';
import 'package:wina/view/widget/team_crest.dart';

/// Maillot cyan (titulaire) : numéro du roster et marqueurs du terrain.
const String _kJerseyAsset = 'assets/images/shirt-l-blue.png';

/// Maillot noir : joueur sélectionné sur le terrain (design « choix 2 »).
const String _kJerseyBlackAsset = 'assets/images/shirt-black.png';

// Ce format de date est dupliqué côté serveur (Wina-server/functions/src/search/
// date_label.ts, `dateLabel` indexé dans Algolia) : garder les deux identiques.
const List<String> _kMonths = <String>[
  'Janv.',
  'Févr.',
  'Mars',
  'Avr.',
  'Mai',
  'Juin',
  'Juil.',
  'Août',
  'Sept.',
  'Oct.',
  'Nov.',
  'Déc.',
];

String _formatDate(DateTime? d) {
  if (d == null) return '';
  return '${d.day.toString().padLeft(2, '0')} ${_kMonths[d.month - 1]} ${d.year}';
}

/// Cellule « nom » d'une ligne de roster : largeur fixe sur tablette, souple sur
/// téléphone (la colonne est bien plus étroite que la maquette).
Widget _rosterNameCell({required Widget child}) =>
    isPhoneLayout
        ? Expanded(child: child)
        : SizedBox(width: cW(183), child: child);

/// Onglet « Statistiques Matchs » (design 1:3394) : historique des matchs
/// joués (avec recherche) + détail du match sélectionné (score, bilans,
/// joueurs) + terrain de la composition utilisée.
class StatistiquesMatchsScreen extends ConsumerStatefulWidget {
  const StatistiquesMatchsScreen({super.key});

  @override
  ConsumerState<StatistiquesMatchsScreen> createState() =>
      _StatistiquesMatchsScreenState();
}

class _StatistiquesMatchsScreenState
    extends ConsumerState<StatistiquesMatchsScreen> {
  String? _selectedId;
  String _query = '';

  /// Joueur mis en évidence (roster, terrain, bilan). `null` = aucun.
  String? _selectedPlayerId;

  /// Vrai quand ce joueur a été désigné sur le terrain. Un joueur choisi dans
  /// le popup reste surligné mais ne verrouille PAS le popup : sans ce drapeau,
  /// tout accès suivant au bilan repartirait en silence sur le même joueur.
  bool _fromPitch = false;

  /// Identifiants des matchs trouvés par Algolia pour [_query] : ils s'ajoutent
  /// au filtre local (sur les matchs déjà chargés), jamais ne le remplacent.
  Set<String> _remoteIds = const <String>{};

  /// Réponse d'Algolia attendue : l'état vide n'est pas affiché avant elle.
  bool _pending = false;

  /// Temporise la saisie (300 ms) puis cumule filtre local et Algolia.
  late final UnionSearch _union = UnionSearch(
    search: (String q) => ref.read(searchServiceProvider).searchMatches(q),
    onChange: (String query, Set<String> remoteIds) {
      if (!mounted) return;
      setState(() {
        _query = query;
        _remoteIds = remoteIds;
      });
    },
    onPending: (bool pending) {
      if (mounted) setState(() => _pending = pending);
    },
  );

  @override
  void dispose() {
    _union.dispose();
    super.dispose();
  }

  // Index des joueurs et liste filtrée mémorisés : `build` repart à chaque
  // sélection de joueur, de match ou de frappe, et ne doit pas les recalculer
  // tant que leurs sources (liste, requête, résultats Algolia) n'ont pas changé.
  List<Player>? _playersSrc;
  Map<String, Player> _byId = const <String, Player>{};

  Map<String, Player> _indexPlayers(List<Player> players) {
    if (identical(players, _playersSrc)) return _byId;
    _playersSrc = players;
    return _byId = <String, Player>{
      for (final Player p in players)
        if (p.id != null) p.id!: p,
    };
  }

  List<GameMatch>? _filterSrc;
  String _filterQuery = '';
  Set<String>? _filterRemote;
  List<GameMatch> _filtered = const <GameMatch>[];

  List<GameMatch> _visibleMatches(List<GameMatch> matches, String q) {
    if (q.isEmpty) return matches;
    if (identical(matches, _filterSrc) &&
        q == _filterQuery &&
        identical(_remoteIds, _filterRemote)) {
      return _filtered;
    }
    _filterSrc = matches;
    _filterQuery = q;
    _filterRemote = _remoteIds;
    return _filtered = unionVisible<GameMatch>(
      items: matches,
      matchesLocally:
          (GameMatch m) =>
              m.opponent.name.toLowerCase().contains(q) ||
              _formatDate(m.finishedAt).toLowerCase().contains(q),
      idOf: (GameMatch m) => m.id,
      remoteIds: _remoteIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<GameMatch>> matchesAsync = ref.watch(
      finishedMatchesProvider,
    );
    // Seul le nom d'équipe compte ici : `select` évite de reconstruire l'écran
    // à chaque autre changement du profil du coach.
    final String? coachTeamName = ref.watch(
      coachProfileProvider.select(
        (AsyncValue<CoachProfile> a) => a.valueOrNull?.teamName?.trim(),
      ),
    );
    final Map<String, Player> byId = _indexPlayers(
      ref.watch(playersStreamProvider).valueOrNull ?? const <Player>[],
    );
    final String teamName =
        (coachTeamName?.isNotEmpty ?? false)
            ? coachTeamName!
            : 'app.statistiques-matchs.mon-equipe'.tr();

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isPhoneLayout ? 16 : cW(40),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              cSh(isPhoneLayout ? 8 : 18),
              PageHeader(
                icon: Iconsax.chart_21,
                title: 'app.statistiques-matchs.titre'.tr(),
                actions: <Widget>[
                  const NotificationBell(),
                  cSw(16),
                  const SettingsButton(),
                  cSw(18),
                ],
              ),
              cSh(isPhoneLayout ? 6 : 14),
              VerticalDivider(),
            ],
          ),
        ),
        Expanded(
          child: matchesAsync.when(
            data: (List<GameMatch> matches) {
              if (matches.isEmpty) {
                return EmptyStatePlaceholder(
                  icon: Iconsax.chart_21,
                  title: 'app.statistiques-matchs.aucun-match'.tr(),
                  subtitle: 'app.statistiques-matchs.aucun-match-detail'.tr(),
                );
              }
              final GameMatch selected = matches.firstWhere(
                (GameMatch m) => m.id == _selectedId,
                orElse: () => matches.first,
              );
              final String q = _query.trim().toLowerCase();
              final List<GameMatch> visible = _visibleMatches(matches, q);
              final MatchComposition? comp =
                  selected.compositionsUsed.isEmpty
                      ? null
                      : selected.compositionsUsed.first;
              Player? selectedPlayer;
              int? selectedNumber;
              if (comp != null && _selectedPlayerId != null) {
                for (int i = 0; i < comp.assignments.length; i++) {
                  if (comp.assignments[i] != _selectedPlayerId) continue;
                  selectedPlayer = byId[_selectedPlayerId!];
                  selectedNumber = comp.numbers[_selectedPlayerId] ?? i + 1;
                  break;
                }
                // Sans cette seconde passe, choisir un remplaçant dans le
                // popup laissait `selectedPlayer` nul : la carte de bilan
                // restait vide et la ligne ne s'allumait nulle part.
                if (selectedPlayer == null &&
                    comp.substituteIds.contains(_selectedPlayerId)) {
                  selectedPlayer = byId[_selectedPlayerId!];
                  selectedNumber = comp.numbers[_selectedPlayerId];
                }
              }
              if (isPhoneLayout) {
                // Téléphone : la liste occupe l'écran ; toucher un match ouvre
                // sa page (Résumé / Terrain).
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    cH(kBottomNavClearance),
                  ),
                  child: _MatchList(
                    matches: visible,
                    pending: _pending,
                    selectedId: selected.id,
                    teamName: teamName,
                    onSelect: (String id) {
                      setState(() {
                        _selectedId = id;
                        _selectedPlayerId = null;
                        _fromPitch = false;
                      });
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _PhoneMatchPage(matchId: id),
                        ),
                      );
                    },
                    onQuery: _union.input,
                  ),
                );
              }
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  isPhoneLayout ? 16 : cW(40),
                  isPhoneLayout ? 8 : cH(16),
                  isPhoneLayout ? 16 : cW(40),
                  cH(kBottomNavClearance),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: cW(309),
                      child: _MatchList(
                        matches: visible,
                        pending: _pending,
                        selectedId: selected.id,
                        teamName: teamName,
                        onSelect:
                            (String id) => setState(() {
                              _selectedId = id;
                              _selectedPlayerId = null;
                              _fromPitch = false;
                            }),
                        onQuery: _union.input,
                      ),
                    ),
                    cSw(27),
                    Expanded(
                      child: _Detail(
                        match: selected,
                        composition: comp,
                        byId: byId,
                        selectedPlayer: selectedPlayer,
                        selectedNumber: selectedNumber,
                        selectedFromPitch: _fromPitch,
                        onPickPlayer:
                            (String pid) => setState(() {
                              _selectedPlayerId = pid;
                              _fromPitch = false;
                            }),
                      ),
                    ),
                    cSw(31),
                    SizedBox(
                      width: cW(354),
                      height: double.infinity,
                      child: _PitchCard(
                        composition: comp,
                        byId: byId,
                        jerseyAsset:
                            selected.ownJersey?.color.asset ?? _kJerseyAsset,
                        selectedPlayerId: _selectedPlayerId,
                        onPlayerTap:
                            (String pid) => setState(() {
                              _selectedPlayerId =
                                  _selectedPlayerId == pid ? null : pid;
                              _fromPitch = _selectedPlayerId != null;
                            }),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const _LoadingSkeleton(),
            error:
                (Object e, _) => Center(
                  child: Text(
                    'app.statistiques-matchs.erreur-chargement'.tr(),
                    style: AppThemeStyle.mediumStyle(
                      cFs(15),
                      AppColor.secondaryLabels,
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

// L'état vide « Aucun match joué » utilise [EmptyStatePlaceholder].

/// Squelette affiché pendant le chargement des matchs : reproduit les trois
/// colonnes de l'onglet (historique, détail, terrain) pour que la page ne
/// bouge plus une fois les données arrivées.
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    if (isPhoneLayout) {
      // Même découpage que le téléphone : liste de 250 + onglets et contenu.
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, cH(kBottomNavClearance)),
        child: AppSkeleton(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SkeletonBox(height: 40, radius: 999),
                    const SizedBox(height: 8),
                    for (int i = 0; i < 3; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: 8),
                      const SkeletonBox(height: 64),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const <Widget>[
                    SkeletonBox(height: 36, width: 220, radius: 999),
                    SizedBox(height: 8),
                    SkeletonBox(height: 70),
                    SizedBox(height: 8),
                    SkeletonBox(height: 84),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        cW(40),
        cH(16),
        cW(40),
        cH(kBottomNavClearance),
      ),
      child: AppSkeleton(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: cW(309),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SkeletonBox(height: 18, width: 140, radius: 4),
                  cSh(6),
                  const SkeletonBox(height: 31, radius: 999),
                  cSh(15),
                  for (int i = 0; i < 4; i++) ...<Widget>[
                    if (i > 0) cSh(7),
                    const SkeletonBox(height: 114),
                  ],
                ],
              ),
            ),
            cSw(27),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SkeletonBox(height: 18, width: 180, radius: 4),
                  cSh(6),
                  const SkeletonBox(height: 66),
                  cSh(8),
                  const SkeletonBox(height: 88),
                  cSh(7),
                  const SkeletonBox(height: 88),
                ],
              ),
            ),
            cSw(31),
            SizedBox(
              width: cW(354),
              height: double.infinity,
              child: const SkeletonBox(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pilule translucide verte (date d'un match, résultat) — dégradé de marque
/// à 12 % d'opacité sur fond blanc.
class _GreenChip extends StatelessWidget {
  const _GreenChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: cW(11), vertical: cH(5)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cR(999)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColor.chipGradientTop,
            AppColor.chipGradientBottom,
          ],
        ),
      ),
      child: Text(
        label,
        style: AppThemeStyle.regularStyle(cFs(13), AppColor.primaryLabels),
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList({
    required this.matches,
    required this.pending,
    required this.selectedId,
    required this.teamName,
    required this.onSelect,
    required this.onQuery,
  });

  final List<GameMatch> matches;

  /// Réponse d'Algolia attendue : pas d'état vide « aucun résultat » avant elle.
  final bool pending;
  final String? selectedId;
  final String teamName;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onQuery;

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(cR(999)),
    borderSide: BorderSide(color: color, width: width),
  );

  /// Champ de recherche, épinglé en haut de la liste pendant le défilement.
  Widget _searchField() {
    return SizedBox(
      height: isPhoneLayout ? 40 : cH(31),
      child: TextField(
        onChanged: onQuery,
        style: AppThemeStyle.regularStyle(
          isPhoneLayout ? cFs(18) : cFs(12),
          AppColor.inkNavy,
        ),
        cursorColor: AppColor.primaryColor,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          hintText: 'app.statistiques-matchs.rechercher'.tr(),
          hintStyle: AppThemeStyle.regularStyle(
            isPhoneLayout ? cFs(18) : cFs(12),
            AppColor.inkNavy.withValues(alpha: .4),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: cW(8)),
          prefixIcon: Padding(
            // 20 px : la loupe s'aligne sur l'écusson des cartes de match
            // juste en dessous, dans la même colonne (voir _MatchCard).
            padding: EdgeInsets.only(
              left: isPhoneLayout ? 14 : cW(20),
              right: cW(7),
            ),
            child: Icon(
              Iconsax.search_normal_copy,
              size: cIc(16),
              color: AppColor.inkNavy.withValues(alpha: .4),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(),
          border: _border(AppColor.primaryLabels.withValues(alpha: .3), 0.5),
          enabledBorder: _border(
            AppColor.primaryLabels.withValues(alpha: .3),
            0.5,
          ),
          focusedBorder: _border(AppColor.primaryColor, 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Slivers plutôt qu'un Column figé : le titre défile sous le champ de
    // recherche (qui, lui, reste épinglé), ce qui rend visibles ~30 px de
    // cartes supplémentaires dès que le coach fait défiler l'historique.
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'app.statistiques-matchs.tous-les-matchs'.tr(),
                style: AppThemeStyle.semiBStyle(
                  cFs(18),
                  AppColor.primaryLabels,
                ),
              ),
              cSh(4),
            ],
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedSearchHeader(child: _searchField()),
        ),
        if (matches.isEmpty && pending)
          const SliverToBoxAdapter(child: SizedBox.shrink())
        else if (matches.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStatePlaceholder(
              title: 'app.statistiques-matchs.aucun-resultat'.tr(),
              subtitle: 'app.statistiques-matchs.aucun-resultat-detail'.tr(),
            ),
          )
        else
          SliverList.separated(
            itemCount: matches.length,
            separatorBuilder:
                (_, _) => isPhoneLayout ? const SizedBox(height: 10) : cSh(7),
            itemBuilder: (BuildContext context, int i) {
              final GameMatch m = matches[i];
              return _MatchCard(
                match: m,
                teamName: teamName,
                selected: m.id == selectedId,
                onTap: () => onSelect(m.id!),
              );
            },
          ),
      ],
    );
  }
}

/// En-tête épinglé du champ de recherche de [_MatchList] : hauteur du champ
/// (31) plus l'écart avec la première carte (15). Le fond opaque évite que les
/// cartes défilent visiblement dessous.
class _PinnedSearchHeader extends SliverPersistentHeaderDelegate {
  const _PinnedSearchHeader({required this.child});

  final Widget child;

  double get _height => isPhoneLayout ? 48 : cH(31 + 15);

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return ColoredBox(
      color: AppColor.background,
      child: Align(alignment: Alignment.topCenter, child: child),
    );
  }

  @override
  bool shouldRebuild(_PinnedSearchHeader oldDelegate) =>
      oldDelegate.child != child;
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.teamName,
    required this.selected,
    required this.onTap,
  });

  final GameMatch match;
  final String teamName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String date = _formatDate(match.finishedAt);
    if (isPhoneLayout) {
      // Téléphone : une ligne lisible (adversaire, date, score) plutôt que le
      // face-à-face à trois lignes de la maquette tablette.
      return RepaintBoundary(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.circular(12),
              border:
                  selected
                      ? Border.all(color: AppColor.primaryColor, width: 2)
                      : null,
            ),
            child: Row(
              children: <Widget>[
                TeamCrest(size: 28, color: match.opponent.jerseyColor?.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        match.opponent.name.isEmpty
                            ? 'app.statistiques-matchs.equipe-adverse'.tr()
                            : match.opponent.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppThemeStyle.semiBStyle(
                          cFs(19),
                          AppColor.primaryLabels,
                        ),
                      ),
                      if (date.isNotEmpty)
                        Text(
                          date,
                          maxLines: 1,
                          style: AppThemeStyle.regularStyle(
                            cFs(15),
                            AppColor.secondaryLabels,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${match.scoreUs}-${match.scoreThem}',
                  style: AppThemeStyle.semiBStyle(
                    cFs(24),
                    AppColor.primaryLabels,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: isPhoneLayout ? 80 : cH(114),
        padding: EdgeInsets.fromLTRB(cW(20), cH(14), cW(12), cH(10)),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(cR(12)),
          border:
              selected
                  ? Border.all(color: AppColor.primaryColor, width: 2)
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                TeamCrest(size: 19, color: match.ownJersey?.color.color),
                cSw(11),
                Expanded(
                  child: Text(
                    teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeStyle.mediumStyle(
                      cFs(15),
                      AppColor.primaryLabels,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: cW(8)),
                  child: Text(
                    '${match.scoreUs}-${match.scoreThem}',
                    style: AppThemeStyle.mediumStyle(
                      cFs(15),
                      AppColor.primaryLabels,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: cW(3)),
              child: Text(
                'VS',
                style: AppThemeStyle.mediumStyle(
                  cFs(15),
                  AppColor.primaryColor,
                ),
              ),
            ),
            Row(
              children: <Widget>[
                TeamCrest(size: 19, color: match.opponent.jerseyColor?.color),
                cSw(11),
                Expanded(
                  child: Text(
                    match.opponent.name.isEmpty
                        ? 'app.statistiques-matchs.equipe-adverse'.tr()
                        : match.opponent.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeStyle.mediumStyle(
                      cFs(15),
                      AppColor.primaryLabels,
                    ),
                  ),
                ),
                if (date.isNotEmpty) _GreenChip(label: date),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Colonne centrale : score, accès aux bilans par période et roster.
class _Detail extends StatelessWidget {
  const _Detail({
    required this.match,
    required this.composition,
    required this.byId,
    required this.selectedPlayer,
    required this.selectedNumber,
    required this.selectedFromPitch,
    required this.onPickPlayer,
    this.view = _DetailView.full,
  });

  final GameMatch match;
  final MatchComposition? composition;
  final Map<String, Player> byId;

  /// Partie affichée (tout, sur tablette ; un onglet, sur téléphone).
  final _DetailView view;

  /// Joueur mis en évidence (`null` = aucun) et son numéro.
  final Player? selectedPlayer;
  final int? selectedNumber;

  /// Vrai si [selectedPlayer] a été désigné sur le terrain : seul ce cas
  /// dispense du popup de choix.
  final bool selectedFromPitch;

  /// Suppression du match en cours (bouton remplacé par un chargement).

  /// Remonte le joueur choisi dans le popup à l'état de l'écran, pour que sa
  /// ligne de roster, son maillot sur le terrain et le badge de la carte
  /// « Bilan individuel » s'allument.
  final ValueChanged<String> onPickPlayer;

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  /// Joueurs de la composition dont on peut consulter le bilan : titulaires
  /// dans l'ordre des emplacements, puis remplaçants. Alimente le sélecteur du
  /// popup « Consulter un bilan ». Les remplaçants y figurent parce que leurs
  /// statistiques sont collectées comme celles des titulaires ; les en exclure
  /// rendait leur bilan inatteignable.
  List<({int? number, Player player})> get _starters {
    final MatchComposition? comp = composition;
    if (comp == null) return const <({int? number, Player player})>[];
    final List<({int? number, Player player})> out =
        <({int? number, Player player})>[];
    for (int i = 0; i < comp.slots.length; i++) {
      final String? pid =
          i < comp.assignments.length ? comp.assignments[i] : null;
      final Player? p = pid != null ? byId[pid] : null;
      if (p == null) continue;
      out.add((number: comp.numbers[pid] ?? i + 1, player: p));
    }
    for (final String pid in comp.substituteIds) {
      final Player? p = byId[pid];
      if (p == null) continue;
      out.add((number: comp.numbers[pid], player: p));
    }
    return out;
  }

  /// Ouvre le bilan individuel pour la période donnée. Sans joueur
  /// sélectionné sur le terrain, propose d'abord le popup de choix du joueur
  /// (design « choix – 1 »).
  Future<void> _openIndividuel(BuildContext context, MatchPeriod period) async {
    Player? player = selectedFromPitch ? selectedPlayer : null;
    if (player == null) {
      final List<({int? number, Player player})> starters = _starters;
      if (starters.isNotEmpty) {
        player = await showDialog<Player>(
          context: context,
          barrierColor: AppColor.scrim,
          builder: (_) => _BilanIndividuelPicker(starters: starters),
        );
        if (player == null) return;
        final String? pickedId = player.id;
        if (pickedId != null) onPickPlayer(pickedId);
      }
    }
    if (!context.mounted) return;
    _push(
      context,
      BilanIndividuelScreen(match: match, period: period, playerId: player?.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MatchComposition? comp = composition;
    final String jerseyAsset = match.ownJersey?.color.asset ?? _kJerseyAsset;
    // Match ancien, sans découpage : seul le Total est consultable.
    final bool halvesAvailable =
        match.statsFor(MatchPeriod.firstHalf).status !=
        PeriodStatus.unavailable;
    final Widget collectif = BilanCard(
      title: 'app.statistiques-matchs.bilan-collectif'.tr(),
      halvesAvailable: halvesAvailable,
      onPeriod:
          (MatchPeriod period) => _push(
            context,
            BilanCollectifScreen(match: match, period: period),
          ),
    );
    final Widget individuel = BilanCard(
      title: 'app.statistiques-matchs.bilan-individuel'.tr(),
      halvesAvailable: halvesAvailable,
      helper:
          selectedPlayer == null
              ? 'app.statistiques-matchs.selectionner-joueur'.tr()
              : 'app.statistiques-matchs.joueur-selectionne'.tr(),
      helperColor:
          selectedPlayer == null
              ? AppColor.primaryLabels
              : AppColor.secondaryLabels,
      trailing:
          selectedPlayer == null
              ? null
              : Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _JerseyNumber(
                    number: selectedNumber,
                    size: 21,
                    fontSize: 9,
                    asset: _kJerseyBlackAsset,
                  ),
                  cSw(8),
                  Text(
                    selectedPlayer!.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeStyle.mediumStyle(
                      cFs(12),
                      AppColor.primaryColor,
                    ),
                  ),
                ],
              ),
      onPeriod: (MatchPeriod period) => _openIndividuel(context, period),
    );
    switch (view) {
      case _DetailView.score:
        return _PhoneScoreCard(match: match);
      case _DetailView.bilans:
        return ListView(
          padding: const EdgeInsets.only(bottom: 8),
          children: <Widget>[
            collectif,
            const SizedBox(height: 12),
            individuel,
          ],
        );
      case _DetailView.individual:
        return ListView(
          padding: const EdgeInsets.only(bottom: 8),
          children: <Widget>[individuel],
        );
      case _DetailView.full:
        break;
    }
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: cH(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'app.statistiques-matchs.statistiques-globales'.tr(),
            style: AppThemeStyle.semiBStyle(cFs(18), AppColor.primaryLabels),
          ),
          cSh(3),
          _ScoreCard(match: match),
          cSh(8),
          collectif,
          cSh(7),
          individuel,
          if (comp != null) ...<Widget>[
            cSh(13),
            Text(
              'app.statistiques-matchs.joueurs'.tr(),
              style: AppThemeStyle.semiBStyle(cFs(18), AppColor.primaryLabels),
            ),
            cSh(2),
            Roster(
              composition: comp,
              byId: byId,
              jerseyAsset: jerseyAsset,
              selectedPlayerId: selectedPlayer?.id,
            ),
          ],
        ],
      ),
    );
  }
}

/// Parties du détail d'un match. Tablette : tout d'un bloc ([full]). Téléphone :
/// [_PhoneMatchPage] les assemble ([score], [bilans], [individual]).
enum _DetailView { full, score, bilans, individual }

/// Joueur retenu et son numéro dans [comp] : titulaire, puis remplaçant.
({Player? player, int? number}) _resolveSelected(
  MatchComposition? comp,
  String? id,
  Map<String, Player> byId,
) {
  if (comp == null || id == null) return (player: null, number: null);
  for (int i = 0; i < comp.assignments.length; i++) {
    if (comp.assignments[i] != id) continue;
    return (player: byId[id], number: comp.numbers[id] ?? i + 1);
  }
  if (comp.substituteIds.contains(id)) {
    return (player: byId[id], number: comp.numbers[id]);
  }
  return (player: null, number: null);
}

/// Téléphone : page d'un match, ouverte depuis la liste. Deux onglets seulement,
/// pour ne montrer qu'une chose à la fois : « Résumé » (score, puis les deux
/// bilans) et « Terrain » (composition et bilan du joueur touché). Elle lit
/// elle-même le match et les joueurs : elle suit les mises à jour sans état
/// recopié de la liste.
class _PhoneMatchPage extends ConsumerStatefulWidget {
  const _PhoneMatchPage({required this.matchId});

  final String matchId;

  @override
  ConsumerState<_PhoneMatchPage> createState() => _PhoneMatchPageState();
}

class _PhoneMatchPageState extends ConsumerState<_PhoneMatchPage> {
  int _tab = 0;
  String? _selectedPlayerId;
  bool _fromPitch = false;

  List<Player>? _playersSrc;
  Map<String, Player> _byId = const <String, Player>{};

  @override
  Widget build(BuildContext context) {
    final List<GameMatch> matches =
        ref.watch(finishedMatchesProvider).valueOrNull ?? const <GameMatch>[];
    GameMatch? match;
    for (final GameMatch candidate in matches) {
      if (candidate.id == widget.matchId) {
        match = candidate;
        break;
      }
    }
    final List<Player> players =
        ref.watch(playersStreamProvider).valueOrNull ?? const <Player>[];
    if (!identical(players, _playersSrc)) {
      _playersSrc = players;
      _byId = <String, Player>{
        for (final Player p in players)
          if (p.id != null) p.id!: p,
      };
    }

    final GameMatch? m = match;
    final MatchComposition? comp =
        m == null || m.compositionsUsed.isEmpty
            ? null
            : m.compositionsUsed.first;
    final ({Player? player, int? number}) sel = _resolveSelected(
      comp,
      _selectedPlayerId,
      _byId,
    );
    final String date = m == null ? '' : _formatDate(m.finishedAt);
    final String title =
        m == null
            ? ''
            : (m.opponent.name.isEmpty
                ? 'app.statistiques-matchs.equipe-adverse'.tr()
                : m.opponent.name);

    Widget detail(_DetailView view) => _Detail(
      match: m!,
      composition: comp,
      byId: _byId,
      view: view,
      selectedPlayer: sel.player,
      selectedNumber: sel.number,
      selectedFromPitch: _fromPitch,
      onPickPlayer:
          (String pid) => setState(() {
            _selectedPlayerId = pid;
            _fromPitch = false;
          }),
    );

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const AppBackground(),
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
                  child: Row(
                    children: <Widget>[
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => Navigator.of(context).maybePop(),
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Iconsax.arrow_circle_left,
                              size: 26,
                              color: AppColor.primaryLabels,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (date.isNotEmpty)
                              Text(
                                date,
                                maxLines: 1,
                                style: AppThemeStyle.regularStyle(
                                  cFs(15),
                                  AppColor.secondaryLabels,
                                ),
                              ),
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppThemeStyle.semiBStyle(
                                cFs(24),
                                AppColor.primaryLabels,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: AppColor.divider,
                ),
                if (m == null)
                  Expanded(
                    child: Center(
                      child: Text(
                        'app.statistiques-matchs.erreur-chargement'.tr(),
                        style: AppThemeStyle.mediumStyle(
                          cFs(17),
                          AppColor.secondaryLabels,
                        ),
                      ),
                    ),
                  )
                else ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: <Widget>[
                        PhoneCategoryChip(
                          label: 'app.statistiques-matchs.onglet-resume'.tr(),
                          selected: _tab == 0,
                          onTap: () => setState(() => _tab = 0),
                        ),
                        const SizedBox(width: 10),
                        PhoneCategoryChip(
                          label: 'app.statistiques-matchs.onglet-terrain'.tr(),
                          selected: _tab == 1,
                          onTap: () => setState(() => _tab = 1),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child:
                          _tab == 0
                              ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Expanded(child: detail(_DetailView.score)),
                                  const SizedBox(width: 16),
                                  Expanded(child: detail(_DetailView.bilans)),
                                ],
                              )
                              : LayoutBuilder(
                                builder: (BuildContext _, BoxConstraints c) {
                                  // Le terrain prend toute la hauteur ; le
                                  // bilan du joueur garde le reste.
                                  final double pitchW = (c.maxHeight *
                                          1668 /
                                          2388)
                                      .clamp(0.0, c.maxWidth * 0.55);
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      SizedBox(
                                        width: pitchW,
                                        child: _PitchCard(
                                          composition: comp,
                                          byId: _byId,
                                          jerseyAsset:
                                              m.ownJersey?.color.asset ??
                                              _kJerseyAsset,
                                          selectedPlayerId: _selectedPlayerId,
                                          onPlayerTap:
                                              (String pid) => setState(() {
                                                _selectedPlayerId =
                                                    _selectedPlayerId == pid
                                                        ? null
                                                        : pid;
                                                _fromPitch =
                                                    _selectedPlayerId != null;
                                              }),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: detail(_DetailView.individual),
                                      ),
                                    ],
                                  );
                                },
                              ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Téléphone : score en grand, résultat et durée, sur une seule carte.
class _PhoneScoreCard extends StatelessWidget {
  const _PhoneScoreCard({required this.match});

  final GameMatch match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'app.statistiques-matchs.score-final'.tr(),
            style: AppThemeStyle.regularStyle(
              cFs(17),
              AppColor.secondaryLabels,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${match.scoreUs}-${match.scoreThem}',
            style: AppThemeStyle.semiBStyle(cFs(54), AppColor.primaryLabels),
          ),
          if (match.resultLabel != null) ...<Widget>[
            const SizedBox(height: 6),
            _GreenChip(label: match.resultLabel!),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: AppColor.divider),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'app.statistiques-matchs.temps-total'.tr(),
                style: AppThemeStyle.regularStyle(
                  cFs(17),
                  AppColor.secondaryLabels,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                match.durationLabel,
                style: AppThemeStyle.semiBStyle(
                  cFs(22),
                  AppColor.primaryLabels,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Carte « Score final / Temps total » (deux lignes).
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.match});

  final GameMatch match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          isPhoneLayout
              ? const EdgeInsets.fromLTRB(16, 14, 16, 14)
              : EdgeInsets.fromLTRB(cW(19), cH(8), cW(17), cH(8)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(12)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'app.statistiques-matchs.score-final'.tr(),
                style: AppThemeStyle.mediumStyle(
                  isPhoneLayout ? cFs(19) : cFs(15),
                  AppColor.primaryLabels,
                ),
              ),
              const Spacer(),
              if (match.resultLabel != null) ...<Widget>[
                _GreenChip(label: match.resultLabel!),
                cSw(13),
              ],
              Padding(
                padding: EdgeInsets.only(right: cW(8)),
                child: Text(
                  '${match.scoreUs}-${match.scoreThem}',
                  style: AppThemeStyle.mediumStyle(
                    isPhoneLayout ? cFs(30) : cFs(22),
                    AppColor.primaryLabels,
                  ),
                ),
              ),
            ],
          ),
          cSh(2),
          Row(
            children: <Widget>[
              Text(
                'app.statistiques-matchs.temps-total'.tr(),
                style: AppThemeStyle.mediumStyle(
                  isPhoneLayout ? cFs(19) : cFs(15),
                  AppColor.primaryLabels,
                ),
              ),
              const Spacer(),
              Text(
                match.durationLabel,
                style: AppThemeStyle.semiBStyle(
                  isPhoneLayout ? cFs(21) : cFs(17),
                  AppColor.primaryLabels,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Carte « Bilan » : titre, texte d'aide optionnel et liens par période
/// (Mi-Temps 1 / Mi-Temps 2 / Final) séparés par des filets verticaux.
@visibleForTesting
class BilanCard extends StatelessWidget {
  const BilanCard({
    super.key,
    required this.title,
    this.helper,
    this.helperColor = AppColor.primaryLabels,
    this.trailing,
    this.halvesAvailable = true,
    required this.onPeriod,
  });

  final String title;
  final String? helper;
  final Color helperColor;

  /// Contenu aligné à droite de la ligne de titre (joueur sélectionné).
  final Widget? trailing;

  /// Faux : les liens « Mi-temps 1 » et « Mi-temps 2 » sont grisés et inertes.
  final bool halvesAvailable;

  /// Appelé avec la période choisie.
  final ValueChanged<MatchPeriod> onPeriod;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          isPhoneLayout
              ? const EdgeInsets.fromLTRB(16, 14, 16, 16)
              : EdgeInsets.fromLTRB(cW(16), cH(11), cW(16), cH(12)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: AppThemeStyle.mediumStyle(
                    isPhoneLayout ? cFs(19) : cFs(15),
                    AppColor.primaryLabels,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (helper != null)
            Text(
              helper!,
              style: AppThemeStyle.regularStyle(
                isPhoneLayout ? cFs(15) : cFs(12),
                helperColor,
              ),
            ),
          SizedBox(height: isPhoneLayout ? 10 : cH(helper == null ? 6 : 9)),
          // Téléphone : trois boutons de même largeur (Mi-temps 1, Mi-temps 2,
          // Final), faciles à toucher ; tablette : ligne de liens inchangée.
          if (isPhoneLayout)
            Row(
              children: <Widget>[
                Expanded(
                  child: _PeriodButton(
                    label: 'app.statistiques-matchs.mi-temps-1'.tr(),
                    enabled: halvesAvailable,
                    onTap: () => onPeriod(MatchPeriod.firstHalf),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PeriodButton(
                    label: 'app.statistiques-matchs.mi-temps-2'.tr(),
                    enabled: halvesAvailable,
                    onTap: () => onPeriod(MatchPeriod.secondHalf),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PeriodButton(
                    label: 'app.statistiques-matchs.final'.tr(),
                    onTap: () => onPeriod(MatchPeriod.total),
                  ),
                ),
              ],
            )
          else
            Row(children: _periodLinks()),
        ],
      ),
    );
  }

  List<Widget> _periodLinks() => <Widget>[
    _PeriodLink(
      label: 'app.statistiques-matchs.mi-temps-1'.tr(),
      enabled: halvesAvailable,
      onTap: () => onPeriod(MatchPeriod.firstHalf),
    ),
    const _PeriodDivider(),
    _PeriodLink(
      label: 'app.statistiques-matchs.mi-temps-2'.tr(),
      enabled: halvesAvailable,
      onTap: () => onPeriod(MatchPeriod.secondHalf),
    ),
    const _PeriodDivider(),
    _PeriodLink(
      label: 'app.statistiques-matchs.final'.tr(),
      onTap: () => onPeriod(MatchPeriod.total),
    ),
  ];
}

class _PeriodLink extends StatelessWidget {
  const _PeriodLink({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;

  /// Faux : lien grisé, sans effet au toucher.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color color =
        enabled ? AppColor.primaryLabels : AppColor.secondaryLabels;
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: AppThemeStyle.semiBStyle(
            isPhoneLayout ? cFs(22) : cFs(14),
            color,
          ),
        ),
        SizedBox(width: isPhoneLayout ? 8 : cW(7)),
        Icon(
          Iconsax.arrow_circle_right,
          size: isPhoneLayout ? 24 : cIc(13),
          color: color,
        ),
      ],
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      // Téléphone : zone tactile d'au moins 48 px de haut (recommandation Material),
      // bien plus que le texte seul.
      child:
          isPhoneLayout
              ? ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Center(widthFactor: 1, child: content),
              )
              : content,
    );
  }
}

/// Téléphone : bouton de période (44 dp de haut), grisé quand la période n'est
/// pas disponible.
class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColor.chipBackground : AppColor.divider,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppThemeStyle.semiBStyle(
                cFs(17),
                enabled ? AppColor.primaryLabels : AppColor.secondaryLabels,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodDivider extends StatelessWidget {
  const _PeriodDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isPhoneLayout ? 10 : cW(19)),
      child: Container(
        width: 0.5,
        height: isPhoneLayout ? 36 : cH(25),
        color: AppColor.inkNavy.withValues(alpha: .2),
      ),
    );
  }
}

/// Roster « Joueurs » : par poste, une barre d'en-tête blanche
/// (poste / Pied Fort / Numéro) puis une ligne par titulaire, et enfin un
/// groupe « Remplaçants » bâti sur `substituteIds`.
@visibleForTesting
class Roster extends StatelessWidget {
  const Roster({
    super.key,
    required this.composition,
    required this.byId,
    required this.jerseyAsset,
    required this.selectedPlayerId,
  });

  final MatchComposition composition;
  final Map<String, Player> byId;
  final String jerseyAsset;

  /// Joueur sélectionné (terrain ou popup) : sa ligne est surlignée.
  final String? selectedPlayerId;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    for (final PlayerPosition pos in PlayerPosition.values) {
      final List<Widget> rows = <Widget>[];
      for (int i = 0; i < composition.slots.length; i++) {
        if (composition.slots[i].role != pos) continue;
        final String? pid =
            i < composition.assignments.length
                ? composition.assignments[i]
                : null;
        final Player? p = pid != null ? byId[pid] : null;
        if (p == null) continue;
        if (rows.isNotEmpty) rows.add(cSh(5));
        rows.add(
          _RosterRow(
            player: p,
            number: composition.numbers[pid] ?? i + 1,
            jerseyAsset: jerseyAsset,
            selected: pid == selectedPlayerId,
          ),
        );
      }
      if (rows.isEmpty) continue;
      if (children.isNotEmpty) children.add(cSh(20));
      children.add(_RosterHeader(label: pos.label));
      children.add(cSh(9));
      children.addAll(rows);
    }
    // Un remplacant n'occupe aucun emplacement de schema : il est absent de
    // `slots`/`assignments` et n'apparaissait donc dans aucun groupe de poste.
    // Il est lu depuis `substituteIds`, sur le meme modele que
    // `match_stats_board`. Deux regles y sont reprises telles quelles :
    // aucun repli `i + 1` sur le numero (l'index n'est pas un numero de
    // maillot plausible hors emplacement), et `subJerseyAsset` pour que la
    // couleur distingue le remplacant du titulaire.
    final List<Widget> subRows = <Widget>[];
    for (final String pid in composition.substituteIds) {
      final Player? p = byId[pid];
      if (p == null) continue;
      if (subRows.isNotEmpty) subRows.add(cSh(5));
      subRows.add(
        _RosterRow(
          player: p,
          number: composition.numbers[pid],
          jerseyAsset: subJerseyAsset(jerseyAsset),
          selected: pid == selectedPlayerId,
        ),
      );
    }
    if (subRows.isNotEmpty) {
      if (children.isNotEmpty) children.add(cSh(20));
      children.add(
        _RosterHeader(label: 'app.match-stats-board.remplacants'.tr()),
      );
      children.add(cSh(9));
      children.addAll(subRows);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _RosterHeader extends StatelessWidget {
  const _RosterHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isPhoneLayout ? 40 : cH(35),
      padding: EdgeInsets.symmetric(horizontal: cW(16)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(12)),
      ),
      child: Row(
        children: <Widget>[
          _rosterNameCell(
            child: Text(
              label,
              style: AppThemeStyle.mediumStyle(
                (isPhoneLayout ? cFs(18) : cFs(15)),
                AppColor.primaryLabels,
              ),
            ),
          ),
          SizedBox(
            width: isPhoneLayout ? 100 : cW(121),
            child: Text(
              'app.statistiques-matchs.pied-fort'.tr(),
              style: AppThemeStyle.regularStyle(
                (isPhoneLayout ? cFs(16) : cFs(13)),
                AppColor.primaryLabels,
              ),
            ),
          ),
          Text(
            'app.statistiques-matchs.numero'.tr(),
            style: AppThemeStyle.regularStyle(
              (isPhoneLayout ? cFs(16) : cFs(13)),
              AppColor.primaryLabels,
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({
    required this.player,
    required this.number,
    required this.jerseyAsset,
    required this.selected,
  });

  final Player player;

  /// Nul pour un remplacant sans numero attribue.
  final int? number;
  final String jerseyAsset;

  /// Ligne du joueur consulté : surlignée dans le vert de marque.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhoneLayout ? 12 : cW(16),
        vertical: isPhoneLayout ? 6 : cH(4),
      ),
      // Sans fond, le nom vert devient illisible sur la photo de pelouse du
      // bas de page (AppBackground).
      decoration: BoxDecoration(
        color:
            selected ? AppColor.rosterRowHighlight : AppColor.rosterRowSurface,
        borderRadius: BorderRadius.circular(cR(12)),
      ),
      child: Row(
        children: <Widget>[
          _rosterNameCell(
            child: Text(
              player.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.mediumStyle(
                (isPhoneLayout ? cFs(18) : cFs(15)),
                AppColor.rosterName,
              ),
            ),
          ),
          SizedBox(
            width: isPhoneLayout ? 100 : cW(121),
            child: Text(
              player.strongFoot.label,
              style: AppThemeStyle.mediumStyle(
                (isPhoneLayout ? cFs(18) : cFs(15)),
                AppColor.primaryLabels,
              ),
            ),
          ),
          _JerseyNumber(number: number, asset: jerseyAsset),
        ],
      ),
    );
  }
}

/// Maillot miniature portant le numéro du joueur (colonne « Numéro »,
/// joueur sélectionné de la carte « Bilan Individuel »).
class _JerseyNumber extends StatelessWidget {
  const _JerseyNumber({
    required this.number,
    this.size = 30,
    this.fontSize = 13,
    this.asset = _kJerseyAsset,
  });

  /// Nul pour un remplacant sans numero attribue : le maillot est alors
  /// affiche vide plutot que de porter un numero invente.
  final int? number;

  /// Dimensions en pixels du design (échelle `sp` appliquée).
  final double size;
  final double fontSize;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final double d = isPhoneLayout ? size * 1.3 : cIc(size);
    return SizedBox(
      width: d,
      height: d,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Image.asset(
            asset,
            fit: BoxFit.contain,
            cacheWidth: (d * MediaQuery.devicePixelRatioOf(context)).round(),
          ),
          if (number != null)
            Padding(
              padding: EdgeInsets.only(top: d * 0.08),
              child: Text(
                '$number',
                style: AppThemeStyle.semiBStyle(
                  isPhoneLayout ? cFs(d * 0.5) : fontSize,
                  numberColorForJerseyAsset(asset),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Colonne de droite : carte blanche pleine hauteur contenant le terrain de la
/// composition utilisée, la pilule du schéma (« 4-4-1-1 ») en surimpression et
/// les joueurs (numéro, nom, badge capitaine). Un appui sur un joueur le
/// sélectionne (maillot noir agrandi, design « choix 2 ») pour le bilan
/// individuel ; un second appui le désélectionne.
class _PitchCard extends StatelessWidget {
  const _PitchCard({
    required this.composition,
    required this.byId,
    required this.jerseyAsset,
    required this.selectedPlayerId,
    required this.onPlayerTap,
  });

  final MatchComposition? composition;
  final Map<String, Player> byId;
  final String jerseyAsset;
  final String? selectedPlayerId;
  final ValueChanged<String> onPlayerTap;

  Player? _playerAt(MatchComposition c, int i) {
    final String? pid = i < c.assignments.length ? c.assignments[i] : null;
    return pid == null ? null : byId[pid];
  }

  String _shortName(Player p) =>
      p.lastName.isEmpty ? p.firstName : '${p.firstName} ${p.lastName[0]}.';

  Widget _marker(MatchComposition comp, int i, double w, double h, double m) {
    final bool selected =
        selectedPlayerId != null && comp.assignments[i] == selectedPlayerId;
    final double jerseyWidth = selected ? m * 1.2 : m;
    return Positioned(
      // Largeur double du maillot pour laisser le nom dépasser de part et
      // d'autre sans troncature ; maillot centré sur l'emplacement du schéma.
      left: comp.slots[i].x * w - m,
      top: comp.slots[i].y * h - jerseyWidth * 0.93 / 2,
      width: m * 2,
      child: PlayerMarker(
        size: m,
        selected: selected,
        jerseyAsset: jerseyAsset,
        number: comp.numbers[comp.assignments[i]] ?? i + 1,
        name: _shortName(_playerAt(comp, i)!),
        isCaptain:
            comp.captainId != null && comp.assignments[i] == comp.captainId,
        onTap: () => onPlayerTap(comp.assignments[i]!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MatchComposition? comp = composition;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: cW(9), vertical: cH(6)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cR(10)),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;
            // Téléphone : terrain étroit, maillots agrandis.
            final double m = w * (isPhoneLayout ? 0.19 : 0.145);
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Image.asset(
                    kPitchPortraitAsset,
                    fit: BoxFit.cover,
                    // Décodé à la taille affichée, pas en pleine résolution.
                    cacheWidth:
                        (w * MediaQuery.devicePixelRatioOf(context)).round(),
                  ),
                ),
                if (comp != null) ...<Widget>[
                  for (int i = 0; i < comp.slots.length; i++)
                    if (_playerAt(comp, i) != null) _marker(comp, i, w, h, m),
                  Positioned(
                    top: cH(8),
                    right: cW(9),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: cW(15),
                        vertical: cH(4),
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.surface,
                        borderRadius: BorderRadius.circular(cR(999)),
                      ),
                      child: Text(
                        comp.formationLabel,
                        style: AppThemeStyle.regularStyle(
                          cFs(15),
                          AppColor.primaryLabels,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Marqueur d'un titulaire sur le terrain : maillot + numéro, badge « Cap. »
/// pour le capitaine, puis prénom + initiale. Sélectionné : maillot noir
/// agrandi de 20 % (design « choix 2 »). Dimensions proportionnelles à la
/// largeur du maillot [size] (en pixels physiques → tailles de police via
/// `copyWith`, hors échelle `sp`). Le numéro suit l'encre du maillot réellement
/// peint (`numberColorForJerseyAsset`), comme le roster.
@visibleForTesting
class PlayerMarker extends StatelessWidget {
  const PlayerMarker({
    super.key,
    required this.size,
    required this.selected,
    required this.jerseyAsset,
    required this.number,
    required this.name,
    required this.isCaptain,
    required this.onTap,
  });

  final double size;
  final bool selected;
  final String jerseyAsset;
  final int number;
  final String name;
  final bool isCaptain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double m = size;
    final double jw = selected ? m * 1.2 : m;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: jw,
            height: jw * 0.93,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned.fill(
                  child: Image.asset(
                    selected ? _kJerseyBlackAsset : jerseyAsset,
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: jw * 0.10),
                  child: Text(
                    '$number',
                    style: AppThemeStyle.semiBStyle(
                      cFs(14),
                      numberColorForJerseyAsset(
                        selected ? _kJerseyBlackAsset : jerseyAsset,
                      ),
                    ).copyWith(fontSize: jw * 0.42),
                  ),
                ),
              ],
            ),
          ),
          if (isCaptain)
            Transform.translate(
              offset: Offset(0, -jw * 0.075),
              child: _CaptainBadge(m: jw),
            )
          else
            SizedBox(height: m * 0.05),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemeStyle.mediumStyle(
              cFs(10),
              AppColor.textLight,
            ).copyWith(fontSize: isPhoneLayout ? m * 0.26 : m * 0.21),
          ),
        ],
      ),
    );
  }
}

/// Badge « Cap. » du capitaine : pilule sombre au liseré jaune, posée sous le
/// maillot.
class _CaptainBadge extends StatelessWidget {
  const _CaptainBadge({required this.m});

  /// Largeur du maillot associé (pixels physiques).
  final double m;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: m * 0.35,
      padding: EdgeInsets.only(left: m * 0.08, right: m * 0.05),
      decoration: BoxDecoration(
        color: AppColor.primaryLabels,
        borderRadius: BorderRadius.circular(cR(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'app.statistiques-matchs.capitaine-abrege'.tr(),
            style: AppThemeStyle.mediumStyle(
              cFs(10),
              AppColor.textLight,
            ).copyWith(fontSize: m * 0.21),
          ),
          SizedBox(width: m * 0.06),
          Container(
            width: m * 0.072,
            height: m * 0.30,
            color: AppColor.captainLine,
          ),
        ],
      ),
    );
  }
}

/// Popup « Consulter un bilan individuel » (design 1:5387) : sélection du
/// joueur quand aucun n'est choisi sur le terrain, puis bouton « Consulter ».
/// Rend le [Player] choisi via `Navigator.pop`, `null` si fermé.
class _BilanIndividuelPicker extends StatefulWidget {
  const _BilanIndividuelPicker({required this.starters});

  final List<({int? number, Player player})> starters;

  @override
  State<_BilanIndividuelPicker> createState() => _BilanIndividuelPickerState();
}

class _BilanIndividuelPickerState extends State<_BilanIndividuelPicker> {
  int _index = 0;

  String _label(({int? number, Player player}) e) =>
      e.number == null
          ? e.player.fullName
          : '${e.number}. ${e.player.fullName}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColor.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cR(12)),
      ),
      child: SizedBox(
        width: cW(461),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(cW(71), cH(47), cW(71), cH(30)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'app.statistiques-matchs.consulter-bilan-titre'.tr(),
                    textAlign: TextAlign.center,
                    style: AppThemeStyle.semiBStyle(
                      cFs(17),
                      AppColor.primaryLabels,
                    ),
                  ),
                  cSh(20),
                  Text(
                    'app.statistiques-matchs.champ-joueur'.tr(),
                    style: AppThemeStyle.mediumStyle(
                      cFs(11),
                      AppColor.primaryLabels,
                    ),
                  ),
                  cSh(2),
                  _playerField(),
                  cSh(35),
                  _consulterButton(context),
                  cSh(16),
                  Text(
                    'app.statistiques-matchs.champs-obligatoires'.tr(),
                    textAlign: TextAlign.center,
                    style: AppThemeStyle.regularStyle(
                      cFs(13),
                      AppColor.primaryLabels,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: cH(14),
              right: cW(14),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Iconsax.close_circle,
                  size: cIc(21),
                  color: AppColor.primaryLabels.withValues(alpha: .25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Champ « Joueur » : pilule bordée ouvrant la liste des titulaires.
  Widget _playerField() {
    return PopupMenuButton<int>(
      initialValue: _index,
      color: AppColor.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cR(12)),
      ),
      onSelected: (int i) => setState(() => _index = i),
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<int>>[
            for (int i = 0; i < widget.starters.length; i++)
              PopupMenuItem<int>(
                value: i,
                child: Text(
                  _label(widget.starters[i]),
                  style: AppThemeStyle.regularStyle(cFs(13), AppColor.inkNavy),
                ),
              ),
          ],
      child: Container(
        height: cH(47),
        padding: EdgeInsets.symmetric(horizontal: cW(19)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cR(999)),
          border: Border.all(
            color: AppColor.primaryLabels.withValues(alpha: .3),
            width: 0.5,
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _label(widget.starters[_index]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppThemeStyle.regularStyle(cFs(13), AppColor.inkNavy),
              ),
            ),
            Icon(
              Iconsax.arrow_down_1,
              size: cIc(13),
              color: AppColor.primaryLabels,
            ),
          ],
        ),
      ),
    );
  }

  /// Bouton « Consulter » : pilule pleine au dégradé vert de marque.
  Widget _consulterButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(widget.starters[_index].player),
      child: Container(
        height: cH(45),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cR(999)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppColor.buttonGradientTop,
              AppColor.buttonGradientBottom,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'app.statistiques-matchs.consulter'.tr(),
              style: AppThemeStyle.semiBStyle(cFs(14), AppColor.textLight),
            ),
            cSw(7),
            Icon(
              Iconsax.arrow_circle_right,
              size: cIc(11),
              color: AppColor.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
