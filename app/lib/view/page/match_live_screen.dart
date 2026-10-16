import 'dart:async';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/match_repository.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/player.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/providers/live_match_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/view/page/live_composition_editor.dart';
import 'package:wina/view/page/match_break_screen.dart';
import 'package:wina/view/page/match_finished_screen.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/confirm_dialog.dart';
import 'package:wina/view/widget/app_loader.dart';
import 'package:wina/view/widget/formation_pitch.dart';
import 'package:wina/view/widget/label_pill.dart';
import 'package:wina/view/widget/match_header.dart';
import 'package:wina/view/widget/player_pick_tile.dart';

const String _kJersey = 'assets/images/shirt-l-blue.png';

/// Écran « Match en cours » : chrono, score, terrain (sélection d'un joueur),
/// compteurs de statistiques en direct du joueur sélectionné, et historique.
class MatchLiveScreen extends ConsumerStatefulWidget {
  const MatchLiveScreen({super.key});

  @override
  ConsumerState<MatchLiveScreen> createState() => _MatchLiveScreenState();
}

class _MatchLiveScreenState extends ConsumerState<MatchLiveScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveMatchProvider.notifier).start(ref.read(matchDraftProvider));
    });
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => ref.read(liveMatchProvider.notifier).tick(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Demande confirmation avant de mettre fin au match (action irréversible).
  void _confirmEndMatch() {
    showDialog<void>(
      context: context,
      barrierColor: AppColor.scrim,
      builder:
          (BuildContext ctx) => AppConfirmDialog(
            title: 'app.match-live.titre-fin-match'.tr(),
            message: 'app.match-live.message-fin-match'.tr(),
            primaryLabel: 'app.match-live.reprendre-match'.tr(),
            onPrimary: () => Navigator.of(ctx).pop(),
            secondaryLabel: 'app.match-live.fin-match'.tr(),
            onSecondary: () {
              Navigator.of(ctx).pop();
              _endMatch();
            },
          ),
    );
  }

  /// Finalise le match. Le récapitulatif n'est affiché qu'une fois le résultat
  /// réellement écrit : sans cela, une coupure réseau au coup de sifflet final
  /// perdrait tout le match sans que le coach en soit averti.
  Future<void> _endMatch() async {
    final LiveMatch? live = ref.read(liveMatchProvider);
    if (live == null) return;
    try {
      final GameMatch draft = ref.read(matchDraftProvider);
      // Le brouillon peut n'avoir jamais été persisté (réseau coupé au coup
      // d'envoi) : on le crée avant d'écrire le résultat.
      final String id = draft.id ?? await MatchRepository.saveDraft(draft);
      if (draft.id == null) ref.read(matchDraftProvider.notifier).setId(id);
      await MatchRepository.finishMatch(
        id,
        live.copyWith(status: MatchStatus.finished),
      );
    } catch (_) {
      if (!mounted) return;
      _showEndMatchFailed();
      return;
    }
    // L'état en mémoire n'est marqué « terminé » qu'après l'écriture : en cas
    // d'échec le match reste en cours et le réessai dispose des données.
    ref.read(liveMatchProvider.notifier).finish();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MatchFinishedScreen()),
    );
  }

  /// Échec de l'enregistrement : on reste sur le match (les données sont
  /// toujours en mémoire) et on propose de réessayer.
  void _showEndMatchFailed() {
    showDialog<void>(
      context: context,
      barrierColor: AppColor.scrim,
      builder:
          (BuildContext ctx) => AppConfirmDialog(
            title: 'app.match-live.titre-enregistrement-impossible'.tr(),
            message: 'app.match-live.message-enregistrement-impossible'.tr(),
            primaryLabel: 'app.match-live.rester-sur-match'.tr(),
            onPrimary: () => Navigator.of(ctx).pop(),
            secondaryLabel: 'app.match-live.reessayer'.tr(),
            onSecondary: () {
              Navigator.of(ctx).pop();
              _endMatch();
            },
            secondaryAccent: AppColor.primaryColor,
          ),
    );
  }

  /// Met le match en pause et ouvre l'écran de coupure (« Pause » / « Mi-temps »).
  void _openBreak({required bool isHalfTime}) {
    final LiveMatch? live = ref.read(liveMatchProvider);
    if (isHalfTime) {
      // Instantané des stats suivies avant la coupure (voir `beginHalfTime`).
      ref.read(liveMatchProvider.notifier).beginHalfTime();
    } else if (live != null && live.isLive) {
      ref.read(liveMatchProvider.notifier).togglePause();
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchBreakScreen(isHalfTime: isHalfTime),
      ),
    );
  }

  void _confirmQuit() {
    showDialog<void>(
      context: context,
      barrierColor: AppColor.scrim,
      builder:
          (BuildContext ctx) => AppConfirmDialog(
            title: 'app.match-live.titre-quitter'.tr(),
            message: 'app.match-live.message-quitter'.tr(),
            primaryLabel: 'app.match-live.reprendre-match'.tr(),
            onPrimary: () => Navigator.of(ctx).pop(),
            secondaryLabel: 'app.match-live.quitter-quand-meme'.tr(),
            onSecondary: () {
              Navigator.of(ctx).pop();
              _quitMatch();
            },
          ),
    );
  }

  /// Quitte sans finaliser : marque le match abandonné (non bloquant), efface
  /// l'état du match en direct et revient à l'accueil.
  void _quitMatch() {
    abandonLiveMatch(ref);
    Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
  }

  /// Ouvre l'éditeur de composition en cours de match (« Modifier
  /// composition ») : réattribue les joueurs déjà sur le terrain, puis applique
  /// la nouvelle composition au direct (stats / score / chrono conservés).
  void _modifyComposition() => openLiveCompositionEditor(context, ref);

  @override
  Widget build(BuildContext context) {
    final LiveMatch? live = ref.watch(liveMatchProvider);
    final List<Player> players =
        ref.watch(playersStreamProvider).valueOrNull ?? const <Player>[];
    final Map<String, Player> byId = <String, Player>{
      for (final Player p in players)
        if (p.id != null) p.id!: p,
    };

    if (live == null) {
      return const Scaffold(
        backgroundColor: AppColor.background,
        body: AppLoader(),
      );
    }

    final LiveMatchNotifier notifier = ref.read(liveMatchProvider.notifier);

    // Maillot porté par l'équipe (étape 2). Le joueur sélectionné passe en noir
    // (ou blanc si le maillot de l'équipe est déjà noir) pour le mettre en avant.
    final JerseyColorOption? kit =
        ref.watch(matchDraftProvider).ownJersey?.color;
    final String jerseyAsset = kit?.asset ?? _kJersey;
    final String selectedJerseyAsset =
        kit == JerseyColorOption.noir
            ? JerseyColorOption.blanc.asset
            : JerseyColorOption.noir.asset;

    final Widget scaffold = Scaffold(
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
                    children: <Widget>[
                      sh(16),
                      MatchHeader(
                        title: 'app.match-live.titre'.tr(),
                        clock: live.clock,
                        scoreUs: live.scoreUs,
                        scoreThem: live.scoreThem,
                        onBack: _confirmQuit,
                        clockFontSize: 26,
                        controls: <Widget>[
                          _HeaderPill(
                            icon:
                                live.isPaused
                                    ? Iconsax.play_circle
                                    : Iconsax.pause_circle,
                            label:
                                live.isPaused
                                    ? 'app.match-live.reprendre'.tr()
                                    : 'app.match-live.pause'.tr(),
                            onTap: () => _openBreak(isHalfTime: false),
                          ),
                          _HeaderPill(
                            icon: Iconsax.timer_1,
                            label:
                                live.half == 1
                                    ? 'app.match-live.mi-temps'.tr()
                                    : 'app.match-live.fin-du-match'.tr(),
                            onTap:
                                live.half == 1
                                    ? () => _openBreak(isHalfTime: true)
                                    : _confirmEndMatch,
                          ),
                        ],
                      ),
                      sh(12),
                      Container(height: 1, color: AppColor.divider),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      formatWidth(40),
                      formatHeight(14),
                      formatWidth(40),
                      formatHeight(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 5,
                          child: _LivePitch(
                            live: live,
                            byId: byId,
                            onSelect: notifier.selectPlayer,
                            onModifyCompo: _modifyComposition,
                            jerseyAsset: jerseyAsset,
                            selectedJerseyAsset: selectedJerseyAsset,
                          ),
                        ),
                        sw(20),
                        Expanded(
                          flex: 9,
                          child: _CenterStats(
                            live: live,
                            byId: byId,
                            notifier: notifier,
                            jerseyAsset: jerseyAsset,
                          ),
                        ),
                        sw(20),
                        Expanded(
                          flex: 3,
                          child: _HistoryFeed(live: live, notifier: notifier),
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

    // Le retour système Android (bouton ou geste de bord) passe par
    // `Navigator.maybePop`, que `canPop: false` intercepte ; le `popUntil` de
    // `_quitMatch`, lui, passe par `pop()` et n'est donc pas bloqué. Sans cette
    // garde, un geste de bord sort du direct sans abandon propre : état en
    // mémoire non vidé et document Firestore jamais marqué abandonné — le match
    // et ses statistiques sont perdus en silence. Les trois sorties in-app
    // (logo Wina, flèche d'entête, bouton « Quitter ») sont déjà gardées.
    // Une seule garde suffit : « Mi-temps » et « Match terminé » sont empilés
    // PAR-DESSUS cet écran (l.109 et l.143), les dépiler revient ici.
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _confirmQuit();
      },
      child: scaffold,
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(r(999)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r(999)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: formatWidth(6),
            vertical: formatHeight(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: sp(25), color: AppColor.primaryLabels),
              sw(6),
              Text(
                label,
                style: AppThemeStyle.boldStyle(13, AppColor.primaryLabels),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePitch extends StatelessWidget {
  const _LivePitch({
    required this.live,
    required this.byId,
    required this.onSelect,
    required this.onModifyCompo,
    required this.jerseyAsset,
    required this.selectedJerseyAsset,
  });

  final LiveMatch live;
  final Map<String, Player> byId;
  final ValueChanged<String> onSelect;
  final VoidCallback onModifyCompo;
  final String jerseyAsset;
  final String selectedJerseyAsset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _ModifyCompoButton(onTap: onModifyCompo),
              ),
            ),
            sw(8),
            LabelPill(
              live.formationLabel,
              color: AppColor.surface,
              verticalPadding: 6,
              fontSize: 13,
            ),
          ],
        ),
        sh(10),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1668 / 2388,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(r(16)),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double w = constraints.maxWidth;
                    final double h = constraints.maxHeight;
                    final double m = w * 0.17;
                    final List<Widget> markers = <Widget>[];
                    for (int i = 0; i < live.slots.length; i++) {
                      final FormationSlot slot = live.slots[i];
                      final String? pid =
                          i < live.assignments.length
                              ? live.assignments[i]
                              : null;
                      if (pid == null) continue;
                      markers.add(
                        Positioned(
                          left: slot.x * w - m / 2,
                          top: slot.y * h - m / 2,
                          width: m,
                          child: _PlayerMarker(
                            // Numéro de maillot attribué dans « Gérer mon
                            // équipe » ; repli sur l'emplacement quand le match
                            // n'en porte pas (même repli que MatchStatsBoard).
                            number: live.numbers[pid] ?? i + 1,
                            name: _short(byId[pid]),
                            size: m,
                            selected: live.selectedPlayerId == pid,
                            jersey:
                                live.selectedPlayerId == pid
                                    ? selectedJerseyAsset
                                    : jerseyAsset,
                            onTap: () => onSelect(pid),
                          ),
                        ),
                      );
                    }
                    return Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: Image.asset(
                            kPitchPortraitAsset,
                            fit: BoxFit.cover,
                          ),
                        ),
                        ...markers,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _short(Player? p) {
    if (p == null) return '';
    final String i = p.lastName.isNotEmpty ? '${p.lastName[0]}.' : '';
    return '${p.firstName} $i';
  }
}

/// Bouton « Modifier composition » de l'entête du terrain (au-dessus du pitch).
class _ModifyCompoButton extends StatelessWidget {
  const _ModifyCompoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(r(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r(12)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: formatWidth(12),
            vertical: formatHeight(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  'app.match-live.modifier-composition'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemeStyle.semiBStyle(13, AppColor.primaryLabels),
                ),
              ),
              sw(6),
              Icon(
                Iconsax.arrow_circle_down,
                size: sp(12),
                color: AppColor.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerMarker extends StatelessWidget {
  const _PlayerMarker({
    required this.number,
    required this.name,
    required this.size,
    required this.selected,
    required this.jersey,
    required this.onTap,
  });

  final int number;
  final String name;
  final double size;
  final bool selected;
  final String jersey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                if (selected)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColor.textLight, width: 2.5),
                    ),
                  ),
                Image.asset(jersey, fit: BoxFit.contain),
                Padding(
                  padding: EdgeInsets.only(top: size * 0.08),
                  child: Text(
                    '$number',
                    style: AppThemeStyle.boldStyle(
                      size * 0.32,
                      numberColorForJerseyAsset(jersey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: formatHeight(2)),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemeStyle.semiBStyle(10, AppColor.textLight),
          ),
        ],
      ),
    );
  }
}

class _CenterStats extends StatelessWidget {
  const _CenterStats({
    required this.live,
    required this.byId,
    required this.notifier,
    required this.jerseyAsset,
  });

  final LiveMatch live;
  final Map<String, Player> byId;
  final LiveMatchNotifier notifier;
  final String jerseyAsset;

  @override
  Widget build(BuildContext context) {
    final String? pid = live.selectedPlayerId;
    final Player? player = pid != null ? byId[pid] : null;

    final List<StatDef> stats = <StatDef>[
      for (final StatDef s in enabledStatsInCatalogOrder(live.enabledStatKeys))
        if (!s.bilanOnly) s,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'app.match-live.statistiques-joueur'.tr(),
              style: AppThemeStyle.semiBStyle(16, AppColor.primaryLabels),
            ),
            if (player != null)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Image.asset(jerseyAsset, width: sp(30), height: sp(30)),
                      sw(10),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              player.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppThemeStyle.semiBStyle(
                                15,
                                AppColor.primaryLabels,
                              ),
                            ),
                            Text(
                              player.position.singular,
                              style: AppThemeStyle.regularStyle(
                                12,
                                AppColor.secondaryLabels,
                              ),
                            ),
                          ],
                        ),
                      ),
                      sw(12),
                      _ReplaceButton(
                        onTap: () => _openSubstitute(context, pid!, player),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        sh(12),
        if (player == null)
          Expanded(
            child: Center(
              child: Text(
                'app.match-live.selectionnez-joueur'.tr(),
                style: AppThemeStyle.regularStyle(14, AppColor.secondaryLabels),
              ),
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              child: _StatGrid(
                stats: stats,
                live: live,
                pid: pid!,
                player: player,
                notifier: notifier,
              ),
            ),
          ),
      ],
    );
  }

  /// Ouvre la popup « Remplacer un joueur » : sortant + remplaçants du banc.
  void _openSubstitute(BuildContext context, String outId, Player outPlayer) {
    // Seuls les remplaçants désignés (banc), pas encore entrés en jeu, sont
    // proposés — et jamais le joueur sortant.
    final Set<String> subIds = live.substituteIds.toSet();
    final List<Player> bench = byId.values
        .where(
          (Player p) =>
              p.id != null &&
              p.id != outId &&
              subIds.contains(p.id) &&
              !live.assignments.contains(p.id),
        )
        .toList(growable: false);
    final int slot = live.assignments.indexOf(outId);
    showDialog<void>(
      context: context,
      barrierColor: AppColor.scrim,
      builder:
          (_) => _SubstituteDialog(
            outPlayer: outPlayer,
            outNumber: live.numbers[outId] ?? (slot >= 0 ? slot + 1 : null),
            bench: bench,
            jerseyAsset: jerseyAsset,
            onConfirm: (String inId) => notifier.substitute(outId, inId),
          ),
    );
  }
}

/// Grille des statistiques du joueur : cartes regroupées par catégorie
/// (maquette « Match en cours »), réparties sur deux colonnes équilibrées.
class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.stats,
    required this.live,
    required this.pid,
    required this.player,
    required this.notifier,
  });

  final List<StatDef> stats;
  final LiveMatch live;
  final String pid;
  final Player player;
  final LiveMatchNotifier notifier;

  @override
  Widget build(BuildContext context) {
    // Regroupe les stats par catégorie (contiguës dans le catalogue).
    final List<List<StatDef>> groups = <List<StatDef>>[];
    for (final StatDef s in stats) {
      if (groups.isEmpty || groups.last.first.category != s.category) {
        groups.add(<StatDef>[s]);
      } else {
        groups.last.add(s);
      }
    }
    // Choisit le point de coupe entre deux cartes qui équilibre le mieux les
    // lignes entre les deux colonnes.
    final int total = stats.length;
    int acc = 0;
    int splitK = 0;
    int bestDiff = 1 << 30;
    for (int k = 0; k <= groups.length; k++) {
      final int diff = (2 * acc - total).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        splitK = k;
      }
      if (k < groups.length) acc += groups[k].length;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: _column(groups.sublist(0, splitK))),
        sw(12),
        Expanded(child: _column(groups.sublist(splitK))),
      ],
    );
  }

  Widget _column(List<List<StatDef>> groups) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < groups.length; i++) ...<Widget>[
          if (i > 0) sh(12),
          _StatCard(
            stats: groups[i],
            live: live,
            pid: pid,
            player: player,
            notifier: notifier,
          ),
        ],
      ],
    );
  }
}

/// Carte blanche regroupant les statistiques d'une catégorie (maquette).
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.stats,
    required this.live,
    required this.pid,
    required this.player,
    required this.notifier,
  });

  final List<StatDef> stats;
  final LiveMatch live;
  final String pid;
  final Player player;
  final LiveMatchNotifier notifier;

  /// Valeur affichée : pour un total, `statValue` somme ses composantes.
  int _value(StatDef s) => live.statValue(pid, s.key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: formatWidth(16),
        vertical: formatHeight(4),
      ),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(r(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final StatDef s in stats)
            _StatRow(
              label: s.label,
              value: _value(s),
              editable: !s.isTotal,
              onMinus:
                  _value(s) <= 0
                      ? null
                      : () => notifier.bump(
                        statKey: s.key,
                        statLabel: s.label,
                        playerName: player.fullName,
                        delta: -1,
                      ),
              onPlus:
                  _value(s) >= maxStatValue(s.key)
                      ? null
                      : () => notifier.bump(
                        statKey: s.key,
                        statLabel: s.label,
                        playerName: player.fullName,
                        delta: 1,
                      ),
            ),
        ],
      ),
    );
  }
}

/// Ligne d'une statistique dans une carte : libellé + valeur (verte) et, sauf
/// pour un total calculé, les boutons − / +.
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.editable,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final int value;
  final bool editable;

  /// `null` à 0 : le « − » est grisé, comme le « + » à son plafond — un bouton
  /// coloré qui ne fait rien se lit comme un bug.
  final VoidCallback? onMinus;

  /// `null` quand la statistique a atteint son plafond : le « + » est grisé.
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: formatHeight(4)),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.regularStyle(13, AppColor.primaryLabels),
            ),
          ),
          if (editable) _StepButton(icon: Iconsax.minus_cirlce, onTap: onMinus),
          SizedBox(
            width: formatWidth(40),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppThemeStyle.mediumStyle(20, AppColor.primaryColor),
            ),
          ),
          if (editable) _StepButton(icon: Iconsax.add_circle, onTap: onPlus),
        ],
      ),
    );
  }
}

/// Bouton « ⇄ Remplacer » (entête du panneau joueur).
class _ReplaceButton extends StatelessWidget {
  const _ReplaceButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
            vertical: formatHeight(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'app.match-live.remplacer'.tr(),
                style: AppThemeStyle.mediumStyle(13, AppColor.primaryLabels),
              ),
              sw(6),
              Icon(
                Iconsax.arrow_circle_right,
                size: sp(18),
                color: AppColor.primaryLabels,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Popup « Remplacer un joueur » : affiche le sortant et la liste des
/// remplaçants disponibles (banc) ; « Remplacer » applique la substitution.
class _SubstituteDialog extends StatefulWidget {
  const _SubstituteDialog({
    required this.outPlayer,
    required this.outNumber,
    required this.bench,
    required this.jerseyAsset,
    required this.onConfirm,
  });

  final Player outPlayer;
  final int? outNumber;
  final List<Player> bench;
  final String jerseyAsset;
  final ValueChanged<String> onConfirm;

  @override
  State<_SubstituteDialog> createState() => _SubstituteDialogState();
}

class _SubstituteDialogState extends State<_SubstituteDialog> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final Player out = widget.outPlayer;
    final String outTitle =
        widget.outNumber != null
            ? '${widget.outNumber}. ${out.fullName}'
            : out.fullName;
    return Dialog(
      backgroundColor: AppColor.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r(20))),
      insetPadding: EdgeInsets.symmetric(
        horizontal: formatWidth(320),
        vertical: formatHeight(110),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          formatWidth(28),
          formatHeight(16),
          formatWidth(28),
          formatHeight(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: InkResponse(
                onTap: () => Navigator.of(context).pop(),
                radius: sp(20),
                child: Icon(
                  Iconsax.close_circle,
                  size: sp(20),
                  color: AppColor.secondaryLabels,
                ),
              ),
            ),
            Center(
              child: Text(
                'app.match-live.remplacer-joueur'.tr(),
                style: AppThemeStyle.semiBStyle(18, AppColor.primaryLabels),
              ),
            ),
            sh(18),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    outTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeStyle.semiBStyle(15, AppColor.primaryColor),
                  ),
                ),
                sw(8),
                Text(
                  '${out.strongFoot.adjective} - ${out.position.singular}',
                  style: AppThemeStyle.regularStyle(
                    13,
                    AppColor.secondaryLabels,
                  ),
                ),
              ],
            ),
            sh(16),
            if (widget.bench.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: formatHeight(16)),
                child: Text(
                  'app.match-live.aucun-remplacant'.tr(),
                  textAlign: TextAlign.center,
                  style: AppThemeStyle.regularStyle(
                    13,
                    AppColor.secondaryLabels,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: formatHeight(170)),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: formatWidth(12),
                    runSpacing: formatHeight(12),
                    children: <Widget>[
                      for (final Player p in widget.bench)
                        PlayerPickTile(
                          player: p,
                          selected: _selectedId == p.id,
                          jerseyAsset: subJerseyAsset(widget.jerseyAsset),
                          onTap: () => setState(() => _selectedId = p.id),
                        ),
                    ],
                  ),
                ),
              ),
            sh(20),
            _ConfirmReplaceButton(
              enabled: _selectedId != null,
              onTap: () {
                final String? id = _selectedId;
                if (id != null) {
                  widget.onConfirm(id);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Vignette d'un remplaçant sélectionnable (maillot + nom).
/// Bouton vert « Remplacer » de la popup (désactivé tant qu'aucun remplaçant
/// n'est choisi).
class _ConfirmReplaceButton extends StatelessWidget {
  const _ConfirmReplaceButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          enabled
              ? AppColor.primaryColor
              : AppColor.primaryColor.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(r(28)),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(r(28)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: formatHeight(15)),
          child: Center(
            child: Text(
              'app.match-live.remplacer'.tr(),
              style: AppThemeStyle.semiBStyle(15, AppColor.textLight),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;

  /// `null` : bouton grisé et inerte.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double d = sp(26);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: d,
          height: d,
          child: Icon(
            icon,
            size: sp(22),
            color:
                onTap == null
                    ? AppColor.primaryLabels.withValues(alpha: 0.3)
                    : AppColor.primaryLabels,
          ),
        ),
      ),
    );
  }
}

class _HistoryFeed extends StatelessWidget {
  const _HistoryFeed({required this.live, required this.notifier});

  final LiveMatch live;
  final LiveMatchNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'app.match-live.historique'.tr(),
          style: AppThemeStyle.semiBStyle(16, AppColor.primaryLabels),
        ),
        sh(12),
        Expanded(
          child:
              live.events.isEmpty
                  ? Text(
                    'app.match-live.aucune-action'.tr(),
                    style: AppThemeStyle.regularStyle(
                      13,
                      AppColor.secondaryLabels,
                    ),
                  )
                  : ListView.separated(
                    itemCount: live.events.length,
                    separatorBuilder: (_, _) => sh(8),
                    itemBuilder:
                        (BuildContext context, int i) => _EventTile(
                          event: live.events[i],
                          now: live.elapsedSeconds,
                          onRemove: () => notifier.removeEvent(i),
                        ),
                  ),
        ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.now,
    required this.onRemove,
  });

  final MatchEvent event;
  final int now;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final int ago = ((now - event.atSeconds) / 60).floor();
    final String when =
        ago < 1
            ? 'app.match-live.a-l-instant'.tr()
            : 'app.match-live.il-y-a-min'.tr(
              namedArgs: <String, String>{'minutes': '$ago'},
            );
    final String sign = event.delta > 0 ? '+1' : '-1';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: formatWidth(12),
        vertical: formatHeight(8),
      ),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(r(10)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  when,
                  style: AppThemeStyle.regularStyle(
                    11,
                    AppColor.secondaryLabels,
                  ),
                ),
                sh(2),
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: event.playerName,
                        style: AppThemeStyle.semiBStyle(
                          13,
                          AppColor.primaryLabels,
                        ),
                      ),
                      TextSpan(
                        text: ' · ${event.statLabel} ',
                        style: AppThemeStyle.regularStyle(
                          13,
                          AppColor.secondaryLabels,
                        ),
                      ),
                      TextSpan(
                        text: sign,
                        style: AppThemeStyle.boldStyle(
                          13,
                          AppColor.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // `opaque` indispensable : un `Padding` seul n'élargit pas la zone
          // testée (`RenderPadding.hitTestSelf` renvoie false). L'icône de
          // 15 dp était intapable au doigt.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: Padding(
              padding: EdgeInsets.all(sp(8)),
              child: Icon(
                Iconsax.close_circle,
                size: sp(15),
                color: AppColor.secondaryLabels,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
