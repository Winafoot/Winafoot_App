import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/match_repository.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/live_match_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/view/page/live_composition_editor.dart';
import 'package:wina/view/page/match_finished_screen.dart';
import 'package:wina/view/page/parametrer_stats_screen.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/confirm_dialog.dart';
import 'package:wina/view/widget/match_header.dart';
import 'package:wina/view/widget/match_stats_board.dart';
import 'package:wina/view/widget/stats_pager_arrows.dart';

/// Écran de coupure du match : « Pause » ou « Mi-temps ». Affiche le tableau des
/// statistiques et les actions (reprendre, modifier, mettre fin).
class MatchBreakScreen extends ConsumerStatefulWidget {
  const MatchBreakScreen({super.key, required this.isHalfTime});

  final bool isHalfTime;

  @override
  ConsumerState<MatchBreakScreen> createState() => _MatchBreakScreenState();
}

class _MatchBreakScreenState extends ConsumerState<MatchBreakScreen> {
  /// Défilement horizontal des colonnes de statistiques (flèches ‹ ›).
  final ScrollController _statsController = ScrollController();

  @override
  void dispose() {
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isHalfTime = widget.isHalfTime;
    final LiveMatch? live = ref.watch(liveMatchProvider);
    final List<Player> players =
        ref.watch(playersStreamProvider).valueOrNull ?? const <Player>[];
    final String jerseyAsset =
        ref.watch(matchDraftProvider).ownJersey?.color.asset ??
        'assets/images/shirt-l-blue.png';
    final Map<String, Player> byId = <String, Player>{
      for (final Player p in players)
        if (p.id != null) p.id!: p,
    };

    if (live == null) {
      return const Scaffold(
        backgroundColor: AppColor.background,
        body: SizedBox.shrink(),
      );
    }

    final LiveMatchNotifier notifier = ref.read(liveMatchProvider.notifier);

    void resume() {
      if (isHalfTime) {
        notifier.startSecondHalf();
      } else {
        notifier.togglePause();
      }
      Navigator.of(context).pop();
    }

    // Retour (flèche d'entête ou retour système) : à la mi-temps il ANNULE la
    // mi-temps et laisse le match en 1re mi-temps ; seul le bouton « Démarrer
    // 2e mi-temps » (confirmé) lance la 2e. En pause, il reprend le match.
    void goBack() {
      if (isHalfTime) {
        notifier.cancelHalfTime();
        Navigator.of(context).pop();
      } else {
        resume();
      }
    }

    // Le bouton « Démarrer 2e mi-temps » est irréversible : on confirme pour
    // éviter une erreur de sélection.
    void confirmSecondHalf() {
      showDialog<void>(
        context: context,
        barrierColor: AppColor.scrim,
        builder:
            (BuildContext ctx) => AppConfirmDialog(
              title: 'app.match-break.titre-2e-mi-temps'.tr(),
              message: 'app.match-break.message-2e-mi-temps'.tr(),
              primaryLabel: 'app.match-break.rester-sur-ecran'.tr(),
              onPrimary: () => Navigator.of(ctx).pop(),
              secondaryLabel: 'app.match-break.demarrer-2e-mi-temps'.tr(),
              onSecondary: () {
                Navigator.of(ctx).pop();
                resume();
              },
              secondaryAccent: AppColor.primaryColor,
            ),
      );
    }

    final Widget scaffold = Scaffold(
      backgroundColor: AppColor.background,
      body: AppBackdrop(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: formatWidth(40)),
                  child: Column(
                    children: <Widget>[
                      sh(16),
                      MatchHeader(
                        title:
                            isHalfTime
                                ? 'app.match-break.titre-mi-temps'.tr()
                                : 'app.match-break.titre-pause'.tr(),
                        clock: live.clock,
                        scoreUs: live.scoreUs,
                        scoreThem: live.scoreThem,
                        onBack: goBack,
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
                      formatHeight(16),
                      formatWidth(40),
                      formatHeight(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _BoardHeader(controller: _statsController),
                              sh(7),
                              // Le tableau ne défile pas verticalement de
                              // lui-même : sans cette enveloppe, les dernières
                              // lignes — les remplaçants — sont hors écran et
                              // inatteignables dès un match à 11.
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.only(
                                    bottom: formatHeight(16),
                                  ),
                                  child: MatchStatsBoard(
                                    live: live,
                                    byId: byId,
                                    controller: _statsController,
                                    jerseyAsset: jerseyAsset,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        sw(24),
                        SizedBox(
                          width: formatWidth(240),
                          child: _Actions(
                            resumeLabel:
                                isHalfTime
                                    ? 'app.match-break.demarrer-2e-mi-temps'
                                        .tr()
                                    : 'app.match-break.reprendre-match'.tr(),
                            onResume: isHalfTime ? confirmSecondHalf : resume,
                            onEditStats: () => _editStats(context, ref),
                            onEditCompo:
                                () => openLiveCompositionEditor(context, ref),
                            onEnd: () => _confirmEnd(context, ref),
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

    // Le retour système Android passe par `Navigator.maybePop`, que
    // `canPop: false` intercepte ; le `pop()` de `goBack`, lui, n'est pas
    // bloqué. Sans cette garde, un geste de bord dépilerait l'écran sans
    // remettre le match en cours : il resterait en pause. Le retour système
    // fait donc comme la flèche d'entête (`goBack`).
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) goBack();
      },
      child: scaffold,
    );
  }

  /// « Modifier statistiques » : ouvre le paramétrage des statistiques puis
  /// applique la nouvelle sélection au match en direct (le tableau se met à jour).
  Future<void> _editStats(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ParametrerStatsScreen()),
    );
    ref
        .read(liveMatchProvider.notifier)
        .setEnabledStats(ref.read(matchDraftProvider).enabledStatKeys);
  }

  /// Demande confirmation avant de mettre fin au match (action irréversible).
  void _confirmEnd(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierColor: AppColor.scrim,
      builder:
          (BuildContext ctx) => AppConfirmDialog(
            title: 'app.match-break.titre-fin-match'.tr(),
            message: 'app.match-break.message-fin-match'.tr(),
            primaryLabel: 'app.match-break.reprendre-match'.tr(),
            onPrimary: () => Navigator.of(ctx).pop(),
            secondaryLabel: 'app.match-break.fin-match'.tr(),
            onSecondary: () {
              Navigator.of(ctx).pop();
              _end(context, ref);
            },
          ),
    );
  }

  /// Finalise le match. Le récapitulatif n'est affiché qu'une fois le résultat
  /// réellement écrit : sans cela, une coupure réseau perdrait tout le match
  /// sans que le coach en soit averti.
  Future<void> _end(BuildContext context, WidgetRef ref) async {
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
      if (!context.mounted) return;
      _showEndFailed(context, ref);
      return;
    }
    // L'état en mémoire n'est marqué « terminé » qu'après l'écriture : en cas
    // d'échec le match reste en cours et le réessai dispose des données.
    ref.read(liveMatchProvider.notifier).finish();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MatchFinishedScreen()),
    );
  }

  /// Échec de l'enregistrement : on reste sur l'écran de coupure (les données
  /// sont toujours en mémoire) et on propose de réessayer.
  void _showEndFailed(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierColor: AppColor.scrim,
      builder:
          (BuildContext ctx) => AppConfirmDialog(
            title: 'app.match-break.titre-enregistrement-impossible'.tr(),
            message: 'app.match-break.message-enregistrement-impossible'.tr(),
            primaryLabel: 'app.match-break.rester-sur-ecran'.tr(),
            onPrimary: () => Navigator.of(ctx).pop(),
            secondaryLabel: 'app.match-break.reessayer'.tr(),
            onSecondary: () {
              Navigator.of(ctx).pop();
              _end(context, ref);
            },
            secondaryAccent: AppColor.primaryColor,
          ),
    );
  }
}

/// Entête « Joueurs » / « Statistiques » au-dessus du tableau (maquette « Si
/// Pause 2 »), alignée avec « Actions sur le match » de la colonne d'actions.
class _BoardHeader extends StatelessWidget {
  const _BoardHeader({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: formatWidth(315),
          child: Text(
            'app.match-break.joueurs'.tr(),
            style: AppThemeStyle.boldStyle(18, AppColor.primaryLabels),
          ),
        ),
        Text(
          'app.match-break.statistiques'.tr(),
          style: AppThemeStyle.boldStyle(18, AppColor.primaryLabels),
        ),
        const Spacer(),
        StatsPagerArrows(controller: controller),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.resumeLabel,
    required this.onResume,
    required this.onEditStats,
    required this.onEditCompo,
    required this.onEnd,
  });

  final String resumeLabel;
  final VoidCallback onResume;
  final VoidCallback onEditStats;
  final VoidCallback onEditCompo;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'app.match-break.actions-match'.tr(),
          style: AppThemeStyle.boldStyle(18, AppColor.primaryLabels),
        ),
        sh(7),
        CpButton(label: resumeLabel, onTap: onResume),
        sh(12),
        CpButton(
          label: 'app.match-break.modifier-statistiques'.tr(),
          onTap: onEditStats,
          soft: true,
        ),
        sh(12),
        CpButton(
          label: 'app.match-break.modifier-composition'.tr(),
          onTap: onEditCompo,
          soft: true,
        ),
        sh(12),
        _DestructiveButton(
          label: 'app.match-break.fin-match'.tr(),
          onTap: onEnd,
        ),
      ],
    );
  }
}

class _DestructiveButton extends StatelessWidget {
  const _DestructiveButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(r(999)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r(999)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: formatHeight(15)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                label,
                style: AppThemeStyle.semiBStyle(15, AppColor.destructive),
              ),
              sw(10),
              Icon(
                Iconsax.close_circle,
                size: sp(18),
                color: AppColor.destructive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
