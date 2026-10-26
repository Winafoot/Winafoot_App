import 'dart:async';
import 'dart:math' as math;

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeleton/controller/user_controller.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/match_repository.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/player.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/providers/assistant_providers.dart';
import 'package:wina/providers/live_match_providers.dart';
import 'package:wina/providers/live_match_coach_sync.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/view/page/live_composition_editor.dart';
import 'package:wina/view/page/match_break_screen.dart';
import 'package:wina/view/page/match_finished_screen.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/confirm_dialog.dart';
import 'package:wina/view/widget/app_loader.dart';
import 'package:wina/view/widget/formation_pitch.dart';
import 'package:wina/view/widget/match_header.dart';
import 'package:wina/view/widget/player_pick_tile.dart';
import 'package:wina/view/widget/stat_tone.dart';

const String _kJersey = 'assets/images/shirt-l-blue.png';

/// Écran « Match en cours » : chrono, score, terrain (sélection d'un joueur),
/// compteurs de statistiques en direct du joueur sélectionné, et historique.
///
/// [assistant] : écran de l'adjoint. L'état vient du coach (voir `AssistantLiveNotifier`) : il voit le
/// match et saisit des statistiques, mais n'a ni chrono, ni pause, ni fin de match, ni composition, ni
/// remplacement.
class MatchLiveScreen extends ConsumerStatefulWidget {
  const MatchLiveScreen({super.key, this.assistant = false, this.resume = false});

  final bool assistant;

  /// Reprise d'un match laissé ouvert : l'état est déjà restauré, on ne le réinitialise pas.
  final bool resume;

  @override
  ConsumerState<MatchLiveScreen> createState() => _MatchLiveScreenState();
}

class _MatchLiveScreenState extends ConsumerState<MatchLiveScreen> {
  Timer? _timer;
  LiveMatchCoachSync? _sync;


  @override
  void initState() {
    super.initState();
    if (!widget.assistant) {
      if (!widget.resume) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(liveMatchProvider.notifier)
              .start(ref.read(matchDraftProvider));
        });
      }
      // Partage le match avec l'adjoint éventuel, en tâche de fond.
      _sync = LiveMatchCoachSync(ref)..start();
    }
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => ref.read(liveMatchProvider.notifier).tick(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sync?.dispose();
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

  /// Historique des actions en fenêtre (téléphone). `Consumer` : la liste se
  /// met à jour quand on annule une action depuis la fenêtre.
  /// Historique : volet qui glisse depuis le bord droit de l écran.
  void _openHistory() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'app.match-live.historique'.tr(),
      barrierColor: AppColor.scrim,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (BuildContext ctx, _, _) {
        final double width = math.min(MediaQuery.sizeOf(ctx).width * 0.45, 380);
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: AppColor.background,
            child: SafeArea(
              child: SizedBox(
                width: width,
                height: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Consumer(
                    builder: (BuildContext context, WidgetRef ref, _) {
                      final LiveMatch? live = ref.watch(liveMatchProvider);
                      if (live == null) return const SizedBox.shrink();
                      return _HistoryFeed(
                        live: live,
                        notifier: ref.read(liveMatchProvider.notifier),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder:
          (_, Animation<double> anim, _, Widget child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
    );
  }

  /// Message d'annonce pour l'adjoint quand le coach change l'état du match, `null` sinon.
  String? _coachEventMessage(LiveMatch? prev, LiveMatch? next) {
    if (prev == null || next == null) return null;
    if (next.half > prev.half) return 'app.assistant.toast-second-half'.tr();
    if (prev.isLive && next.isPaused) {
      return (next.half == 1 && next.halfTimeStatKeys != null)
          ? 'app.assistant.toast-half-time'.tr()
          : 'app.assistant.toast-pause'.tr();
    }
    if (prev.isPaused && next.isLive) return 'app.assistant.toast-resume'.tr();
    if (!identical(prev.assignments, next.assignments) ||
        !identical(prev.slots, next.slots)) {
      return 'app.assistant.toast-compo'.tr();
    }
    return null;
  }

  /// Ouvre l'éditeur de composition en cours de match (« Modifier
  /// composition ») : réattribue les joueurs déjà sur le terrain, puis applique
  /// la nouvelle composition au direct (stats / score / chrono conservés).
  void _modifyComposition() => openLiveCompositionEditor(context, ref);

  @override
  Widget build(BuildContext context) {
    final LiveMatch? live = ref.watch(liveMatchProvider);
    if (widget.assistant) {
      // Ce que fait le coach (pause, mi-temps, reprise, composition) est annoncé à l'adjoint.
      ref.listen<LiveMatch?>(liveMatchProvider, (LiveMatch? prev, LiveMatch? next) {
        final String? message = _coachEventMessage(prev, next);
        if (message == null || !mounted) return;
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
      });
    }
    final List<Player> players =
        widget.assistant
            ? ref.watch(assistantPlayersProvider)
            : ref.watch(playersStreamProvider).valueOrNull ?? const <Player>[];
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
        widget.assistant
            ? ref.watch(assistantKitProvider)
            : ref.watch(matchDraftProvider).ownJersey?.color;
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
                  padding: EdgeInsets.symmetric(
                    horizontal: isPhoneLayout ? 16 : cW(40),
                  ),
                  child: Column(
                    children: <Widget>[
                      cSh(isPhoneLayout ? 6 : 16),
                      MatchHeader(
                        title: 'app.match-live.titre'.tr(),
                        clock: live.clock,
                        scoreUs: live.scoreUs,
                        scoreThem: live.scoreThem,
                        onBack: widget.assistant ? null : _confirmQuit,
                        clockFontSize: 26,
                        // Historique : bouton « burger » en bout d entête.
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              onPressed: _openHistory,
                              tooltip: 'app.match-live.historique'.tr(),
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.menu,
                                size: 30,
                                color: AppColor.primaryLabels,
                              ),
                            ),
                            // L'adjoint n'a pas d'autre écran où se déconnecter.
                            if (widget.assistant)
                              IconButton(
                                onPressed:
                                    () =>
                                        UserController.logoutUser(context, ref),
                                tooltip: 'app.assistant.logout'.tr(),
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.logout,
                                  size: 26,
                                  color: AppColor.secondaryLabels,
                                ),
                              ),
                          ],
                        ),
                        controls:
                            widget.assistant
                                ? <Widget>[
                                  // Le coach a mis le match en pause (ou à la mi-temps) : l'adjoint le voit.
                                  if (ref.watch(assistantCoachAwayProvider))
                                    _HeaderPill(
                                      icon: Iconsax.timer_pause,
                                      label: 'app.assistant.coach-away'.tr(),
                                      onTap: () {},
                                    )
                                  else if (live.isPaused)
                                    _HeaderPill(
                                      icon: Iconsax.pause_circle,
                                      label:
                                          (live.half == 1 &&
                                                  live.halfTimeStatKeys != null)
                                              ? 'app.match-live.mi-temps'.tr()
                                              : 'app.match-live.en-pause'.tr(),
                                      onTap: () {},
                                    ),
                                ]
                                : <Widget>[
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
                                            : 'app.match-live.fin-du-match'
                                                .tr(),
                                    onTap:
                                        live.half == 1
                                            ? () => _openBreak(isHalfTime: true)
                                            : _confirmEndMatch,
                                  ),
                                ],
                      ),
                      cSh(isPhoneLayout ? 6 : 12),
                      Container(height: 1, color: AppColor.divider),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isPhoneLayout ? 16 : cW(40),
                      isPhoneLayout ? 6 : cH(14),
                      isPhoneLayout ? 16 : cW(40),
                      isPhoneLayout ? 6 : cH(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: isPhoneLayout ? 5 : 7,
                          child: _LivePitch(
                            live: live,
                            onSubstitute:
                                widget.assistant
                                    ? null
                                    : (String pid, Player player) =>
                                        _openSubstituteDialog(
                                          context,
                                          live: live,
                                          byId: byId,
                                          jerseyAsset: jerseyAsset,
                                          notifier: notifier,
                                          outId: pid,
                                          outPlayer: player,
                                        ),
                            byId: byId,
                            onSelect: notifier.selectPlayer,
                            onModifyCompo:
                                widget.assistant ? null : _modifyComposition,
                            jerseyAsset: jerseyAsset,
                            selectedJerseyAsset: selectedJerseyAsset,
                            swapSides: live.swapSides,
                            onSwapSides: notifier.toggleSwapSides,
                          ),
                        ),
                        cSw(isPhoneLayout ? 12 : 20),
                        Expanded(
                          flex: isPhoneLayout ? 6 : 9,
                          child: _CenterStats(
                            live: live,
                            byId: byId,
                            notifier: notifier,
                            jerseyAsset: jerseyAsset,
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
        if (!didPop && !widget.assistant) _confirmQuit();
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
      borderRadius: BorderRadius.circular(cR(999)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cR(999)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: cIc(32), color: AppColor.primaryLabels),
              cSw(6),
              Text(
                label,
                style: AppThemeStyle.boldStyle(cFs(17), AppColor.primaryLabels),
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
    required this.onSubstitute,
    required this.byId,
    required this.onSelect,
    required this.onModifyCompo,
    required this.jerseyAsset,
    required this.selectedJerseyAsset,
    required this.swapSides,
    required this.onSwapSides,
  });

  final bool swapSides;
  final VoidCallback onSwapSides;
  final void Function(String pid, Player player)? onSubstitute;
  final LiveMatch live;
  final Map<String, Player> byId;
  final ValueChanged<String> onSelect;
  final VoidCallback? onModifyCompo;
  final String jerseyAsset;
  final String selectedJerseyAsset;

  @override
  Widget build(BuildContext context) {
    final Player? sel = selectedPlayer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 2388 / 1668,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cR(16)),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double w = constraints.maxWidth;
                    final double h = constraints.maxHeight;
                    // Téléphone : terrain horizontal (l image portrait pivote), notre but a
                    // gauche en 1re mi-temps, à droite en 2e (changement de côté).
                    final bool flipped = (live.half == 2) != swapSides;
                    final double m = h * 0.17;
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
                          left: (flipped ? slot.y : 1 - slot.y) * w - m / 2,
                          top: (flipped ? 1 - slot.x : slot.x) * h - m / 2,
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
                        Positioned.fill(child: _pitchImage(flipped)),
                        ...markers,
                        // Inverse les côtés du terrain si le match ne commence pas du bon côté.
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Tooltip(
                            message: 'app.match-live.changer-de-cote'.tr(),
                            child: Material(
                              color: AppColor.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: onSwapSides,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.swap_horiz,
                                    size: cIc(24),
                                    color: AppColor.primaryLabels,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Composition (schéma) affichée sur le terrain.
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              live.formationLabel,
                              style: AppThemeStyle.boldStyle(
                                cFs(14),
                                AppColor.primaryLabels,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        // « Modifier composition » et « Remplacer » sous le terrain.
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            if (onModifyCompo != null)
              _ModifyCompoButton(onTap: onModifyCompo!),
            if (sel != null && onSubstitute != null)
              _ReplaceButton(
                onTap: () => onSubstitute!(live.selectedPlayerId!, sel),
              ),
          ],
        ),
      ],
    );
  }

  Widget _pitchImage(bool flipped) {
    final Widget image = Image.asset(kPitchPortraitAsset, fit: BoxFit.cover);
    return RotatedBox(quarterTurns: flipped ? 3 : 1, child: image);
  }

  /// Joueur sélectionné sur le terrain, s'il est connu.
  Player? get selectedPlayer {
    final String? pid = live.selectedPlayerId;
    return pid == null ? null : byId[pid];
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
      borderRadius: BorderRadius.circular(cR(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cR(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  'app.match-live.modifier-composition'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemeStyle.semiBStyle(
                    cFs(17),
                    AppColor.primaryLabels,
                  ),
                ),
              ),
              cSw(6),
              Icon(
                Iconsax.arrow_circle_down,
                size: cIc(22),
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
                      cFs(size * 0.32),
                      numberColorForJerseyAsset(jersey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: cH(2)),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemeStyle.semiBStyle(cFs(10), AppColor.textLight),
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
    if (isPhoneLayout) {
      return _PhoneStatsPanel(
        live: live,
        byId: byId,
        notifier: notifier,
        jerseyAsset: jerseyAsset,
      );
    }
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
              style: AppThemeStyle.semiBStyle(cFs(16), AppColor.primaryLabels),
            ),
            if (player != null)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Image.asset(jerseyAsset, width: cIc(30), height: cIc(30)),
                      cSw(10),
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
                                cFs(15),
                                AppColor.primaryLabels,
                              ),
                            ),
                            Text(
                              player.position.singular,
                              style: AppThemeStyle.regularStyle(
                                cFs(12),
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
        cSh(12),
        if (player == null)
          Expanded(
            child: Center(
              child: Text(
                'app.match-live.selectionnez-joueur'.tr(),
                style: AppThemeStyle.regularStyle(
                  cFs(14),
                  AppColor.secondaryLabels,
                ),
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
}

/// Ouvre la popup « Remplacer un joueur » : sortant + remplaçants du banc.
void _openSubstituteDialog(
  BuildContext context, {
  required LiveMatch live,
  required Map<String, Player> byId,
  required String jerseyAsset,
  required LiveMatchNotifier notifier,
  required String outId,
  required Player outPlayer,
}) {
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

/// Saisie des statistiques sur téléphone : mêmes cartes en lignes que sur tablette (perdus à gauche,
/// gagnés à droite), sans sous-catégories. Un appui sur une ligne ajoute 1 ; une erreur se corrige dans
/// l'historique.
class _PhoneStatsPanel extends StatefulWidget {
  const _PhoneStatsPanel({
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
  State<_PhoneStatsPanel> createState() => _PhoneStatsPanelState();
}

class _PhoneStatsPanelState extends State<_PhoneStatsPanel> {
  @override
  Widget build(BuildContext context) {
    final String? pid = widget.live.selectedPlayerId;
    final Player? player = pid != null ? widget.byId[pid] : null;

    final List<StatDef> stats = <StatDef>[
      for (final StatDef s in enabledStatsInCatalogOrder(
        widget.live.enabledStatKeys,
      ))
        if (!s.bilanOnly) s,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _playerBar(pid, player),
        const SizedBox(height: 6),
        if (player == null)
          Expanded(
            child: Center(
              child: Text(
                'app.match-live.selectionnez-joueur'.tr(),
                textAlign: TextAlign.center,
                style: AppThemeStyle.regularStyle(
                  cFs(14),
                  AppColor.secondaryLabels,
                ),
              ),
            ),
          )
        else ...<Widget>[
          // Même présentation que sur tablette : cartes en lignes, perdus à gauche et gagnés à droite,
          // sans sous-catégories ; ça défile si tout ne tient pas.
          Expanded(
            child: SingleChildScrollView(
              child: _StatGrid(
                stats: stats,
                live: widget.live,
                pid: pid!,
                player: player,
                notifier: widget.notifier,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Ligne du haut : joueur sélectionné, historique, remplacement.
  Widget _playerBar(String? pid, Player? player) {
    return SizedBox(
      height: 34,
      child: Row(
        children: <Widget>[
          if (player != null) ...<Widget>[
            Image.asset(widget.jerseyAsset, width: 26, height: 26),
            const SizedBox(width: 8),
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
                      cFs(15),
                      AppColor.primaryLabels,
                    ),
                  ),
                  Text(
                    player.position.singular,
                    style: AppThemeStyle.regularStyle(
                      cFs(12),
                      AppColor.secondaryLabels,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Expanded(
              child: Text(
                'app.match-live.statistiques-joueur'.tr(),
                style: AppThemeStyle.semiBStyle(
                  cFs(16),
                  AppColor.primaryLabels,
                ),
              ),
            ),
        ],
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
    // Perdus (rouge) à gauche, gagnés (vert) à droite, chacun dans son ordre de
    // priorité ; un seul côté choisi : une seule colonne. Neutres dessous.
    final List<StatDef> good = statsOfSide(stats, StatSide.good);
    final List<StatDef> bad = statsOfSide(stats, StatSide.bad);
    final List<StatDef> neutral = statsOfSide(stats, StatSide.neutral);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (good.isNotEmpty && bad.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _card(bad)),
              cSw(12),
              Expanded(child: _card(good)),
            ],
          )
        else if (good.isNotEmpty || bad.isNotEmpty)
          _card(good.isNotEmpty ? good : bad),
        if (neutral.isNotEmpty) ...<Widget>[cSh(12), _card(neutral)],
      ],
    );
  }

  Widget _card(List<StatDef> list) => _StatCard(
    stats: list,
    live: live,
    pid: pid,
    player: player,
    notifier: notifier,
  );
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
      padding: EdgeInsets.symmetric(horizontal: cW(16), vertical: cH(4)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final StatDef s in stats)
            _StatRow(
              label: s.label,
              tint: statTint(s.key),
              value: _value(s),
              onPlus:
                  s.isTotal || _value(s) >= maxStatValue(s.key)
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

/// Ligne d'une statistique dans une carte : libellé + valeur (verte). Toute la
/// ligne est cliquable (+1) ; `onPlus` est `null` pour un total calculé ou au
/// plafond. Une erreur se corrige depuis l'historique.
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.onPlus,
    this.tint,
  });

  final String label;
  final int value;
  final VoidCallback? onPlus;

  /// Fond selon la nature de la stat (voir [_statTint]).
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: cH(3)),
      child: Material(
        color: tint ?? Colors.transparent,
        borderRadius: BorderRadius.circular(cR(8)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPlus,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: cH(8)),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeStyle.regularStyle(
                      cFs(13),
                      AppColor.primaryLabels,
                    ),
                  ),
                ),
                Text(
                  '$value',
                  style: AppThemeStyle.mediumStyle(
                    cFs(20),
                    AppColor.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
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
      borderRadius: BorderRadius.circular(cR(999)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cR(999)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cR(999)),
            border: Border.all(color: AppColor.divider),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'app.match-live.remplacer'.tr(),
                style: AppThemeStyle.mediumStyle(
                  cFs(17),
                  AppColor.primaryLabels,
                ),
              ),
              cSw(6),
              Icon(
                Iconsax.arrow_circle_right,
                size: cIc(26),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cR(20)),
      ),
      // Téléphone (~360 dp de haut) : des marges de 110 maquette ne laisseraient
      // que ~170 dp au contenu.
      insetPadding:
          isPhoneLayout
              ? const EdgeInsets.symmetric(horizontal: 80, vertical: 12)
              : EdgeInsets.symmetric(horizontal: cW(320), vertical: cH(110)),
      child: Padding(
        padding:
            isPhoneLayout
                ? const EdgeInsets.fromLTRB(20, 8, 20, 12)
                : EdgeInsets.fromLTRB(cW(28), cH(16), cW(28), cH(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: InkResponse(
                onTap: () => Navigator.of(context).pop(),
                radius: cIc(20),
                child: Icon(
                  Iconsax.close_circle,
                  size: cIc(20),
                  color: AppColor.secondaryLabels,
                ),
              ),
            ),
            Center(
              child: Text(
                'app.match-live.remplacer-joueur'.tr(),
                style: AppThemeStyle.semiBStyle(
                  cFs(18),
                  AppColor.primaryLabels,
                ),
              ),
            ),
            cSh(18),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    outTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeStyle.semiBStyle(
                      cFs(15),
                      AppColor.primaryColor,
                    ),
                  ),
                ),
                cSw(8),
                Text(
                  '${out.strongFoot.adjective} - ${out.position.singular}',
                  style: AppThemeStyle.regularStyle(
                    cFs(13),
                    AppColor.secondaryLabels,
                  ),
                ),
              ],
            ),
            cSh(16),
            if (widget.bench.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: cH(16)),
                child: Text(
                  'app.match-live.aucun-remplacant'.tr(),
                  textAlign: TextAlign.center,
                  style: AppThemeStyle.regularStyle(
                    cFs(13),
                    AppColor.secondaryLabels,
                  ),
                ),
              )
            else
              // Flexible : la liste cède de la hauteur au lieu de déborder.
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: cH(170)),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: cW(12),
                      runSpacing: cH(12),
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
              ),
            cSh(isPhoneLayout ? 10 : 20),
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
      borderRadius: BorderRadius.circular(cR(28)),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(cR(28)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: cH(15)),
          child: Center(
            child: Text(
              'app.match-live.remplacer'.tr(),
              style: AppThemeStyle.semiBStyle(cFs(15), AppColor.textLight),
            ),
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
          style: AppThemeStyle.semiBStyle(cFs(16), AppColor.primaryLabels),
        ),
        cSh(12),
        Expanded(
          child:
              live.events.isEmpty
                  ? Text(
                    'app.match-live.aucune-action'.tr(),
                    style: AppThemeStyle.regularStyle(
                      cFs(13),
                      AppColor.secondaryLabels,
                    ),
                  )
                  : ListView.separated(
                    // Les 20 plus récentes : `events` va du plus récent au plus
                    // ancien, l'index affiché est donc aussi celui de `removeEvent`.
                    itemCount: math.min(
                      live.events.length,
                      kMatchHistoryDisplayLimit,
                    ),
                    separatorBuilder: (_, _) => cSh(8),
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
      padding: EdgeInsets.symmetric(horizontal: cW(12), vertical: cH(8)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(10)),
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
                    cFs(11),
                    AppColor.secondaryLabels,
                  ),
                ),
                cSh(2),
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: event.playerName,
                        style: AppThemeStyle.semiBStyle(
                          cFs(13),
                          AppColor.primaryLabels,
                        ),
                      ),
                      TextSpan(
                        text: ' · ${event.statLabel} ',
                        style: AppThemeStyle.regularStyle(
                          cFs(13),
                          AppColor.secondaryLabels,
                        ),
                      ),
                      TextSpan(
                        text: sign,
                        style: AppThemeStyle.boldStyle(
                          cFs(13),
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
              padding: EdgeInsets.all(cIc(8)),
              child: Icon(
                Iconsax.close_circle,
                size: cIc(15),
                color: AppColor.secondaryLabels,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
