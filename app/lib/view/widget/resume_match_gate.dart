import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/live_match_sync_repository.dart';
import 'package:wina/data/match_repository.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match_sync.dart';
import 'package:wina/providers/live_match_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/view/page/match_live_screen.dart';
import 'package:wina/view/widget/confirm_dialog.dart';

/// Retrouve un match laissé ouvert. L'état du direct est publié sur Firebase à chaque changement : si le coach
/// a fermé l'appli ou si elle a planté en plein match, il lui est proposé de le reprendre (score, statistiques,
/// historique ; chrono en pause) ou de l'abandonner. Une fois par ouverture de l'écran d'accueil.
class ResumeMatchGate extends ConsumerStatefulWidget {
  const ResumeMatchGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ResumeMatchGate> createState() => _ResumeMatchGateState();
}

class _ResumeMatchGateState extends ConsumerState<ResumeMatchGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    // Un match est déjà en cours dans cette session : rien à reprendre.
    if (ref.read(liveMatchProvider) != null) return;
    final LiveMatchSnapshot? snap;
    try {
      snap = await LiveMatchSyncRepository.getCurrent();
    } catch (_) {
      return;
    }
    if (snap == null || !mounted || ref.read(liveMatchProvider) != null) return;
    _ask(snap);
  }

  void _ask(LiveMatchSnapshot snap) {
    final String versus =
        snap.opponentName.trim().isEmpty
            ? 'app.resume-match.sans-adversaire'.tr()
            : snap.opponentName.trim();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColor.scrim,
      builder:
          (BuildContext ctx) => AppConfirmDialog(
            title: 'app.resume-match.titre'.tr(),
            message: 'app.resume-match.message'.tr(
              args: <String>[
                versus,
                '${snap.live.scoreUs}',
                '${snap.live.scoreThem}',
                snap.live.clock,
              ],
            ),
            primaryLabel: 'app.resume-match.reprendre'.tr(),
            onPrimary: () {
              Navigator.of(ctx).pop();
              _resume(snap);
            },
            secondaryLabel: 'app.resume-match.abandonner'.tr(),
            onSecondary: () {
              Navigator.of(ctx).pop();
              _abandon(snap);
            },
          ),
    );
  }

  Future<void> _resume(LiveMatchSnapshot snap) async {
    GameMatch? draft;
    final String? id = snap.matchId;
    if (id != null) {
      try {
        draft = await MatchRepository.getMatch(id);
      } catch (_) {}
    }
    if (!mounted) return;
    // Brouillon introuvable : on repart de ce que l'état publié en sait.
    ref
        .read(matchDraftProvider.notifier)
        .restore(
          draft ??
              GameMatch(
                id: id,
                opponent: MatchOpponent(name: snap.opponentName),
                enabledStatKeys: snap.live.enabledStatKeys,
                status: MatchStatus.live,
              ),
        );
    ref.read(liveMatchProvider.notifier).restore(snap.live);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MatchLiveScreen(resume: true),
      ),
    );
  }

  Future<void> _abandon(LiveMatchSnapshot snap) async {
    final String? id = snap.matchId;
    try {
      await LiveMatchSyncRepository.end();
      if (id != null) await MatchRepository.abandonMatch(id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
