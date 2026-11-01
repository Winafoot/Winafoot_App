import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeleton/controller/user_controller.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/live_match_sync.dart';
import 'package:wina/providers/assistant_providers.dart';
import 'package:wina/view/page/match_live_screen.dart';
import 'package:wina/view/widget/app_background.dart';

/// Vrai tant que l'adjoint a suivi un match qui n'est pas terminé pour lui : seule une fin de match qu'il a vue
/// en direct est annoncée (pas un vieux match resté sur Firebase à sa connexion).
final assistantFollowedMatchProvider = StateProvider<bool>((ref) => false);

/// Accueil de l'adjoint : l'écran du match dès que le coach l'a lancé, sinon une attente. Les données
/// arrivent par un flux Firestore : l'écran s'ouvre et se met à jour tout seul, sans rechargement.
class AssistantHomePage extends ConsumerWidget {
  const AssistantHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LiveMatchSnapshot? snap =
        ref.watch(assistantSnapshotProvider).valueOrNull;
    if (snap != null && !snap.ended) {
      if (!ref.read(assistantFollowedMatchProvider)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(assistantFollowedMatchProvider.notifier).state = true;
        });
      }
      return const MatchLiveScreen(assistant: true);
    }
    // Le coach a mis fin au match : l'adjoint en est averti et voit le score final, jusqu'à ce qu'il valide.
    if (snap != null && ref.watch(assistantFollowedMatchProvider)) {
      return _MatchEndedView(snap: snap);
    }
    return Scaffold(
      backgroundColor: AppColor.background,
      body: Stack(
        children: <Widget>[
          const AppBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'app.assistant.waiting-title'.tr(),
                        textAlign: TextAlign.center,
                        style: AppThemeStyle.boldStyle(
                          26,
                          AppColor.primaryLabels,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'app.assistant.waiting-message'.tr(),
                        textAlign: TextAlign.center,
                        style: AppThemeStyle.regularStyle(
                          16,
                          AppColor.secondaryLabels,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => UserController.logoutUser(context, ref),
                        child: Text('app.assistant.logout'.tr()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// « Match terminé » : prévient l'adjoint (vibration comprise) et affiche le score final.
class _MatchEndedView extends ConsumerStatefulWidget {
  const _MatchEndedView({required this.snap});

  final LiveMatchSnapshot snap;

  @override
  ConsumerState<_MatchEndedView> createState() => _MatchEndedViewState();
}

class _MatchEndedViewState extends ConsumerState<_MatchEndedView> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final String versus = widget.snap.opponentName.trim();
    return Scaffold(
      backgroundColor: AppColor.background,
      body: Stack(
        children: <Widget>[
          const AppBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'app.assistant.ended-title'.tr(),
                        textAlign: TextAlign.center,
                        style: AppThemeStyle.boldStyle(
                          28,
                          AppColor.primaryLabels,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.snap.live.scoreUs} - ${widget.snap.live.scoreThem}',
                        style: AppThemeStyle.boldStyle(
                          44,
                          AppColor.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        versus.isEmpty
                            ? 'app.assistant.ended-message-solo'.tr()
                            : 'app.assistant.ended-message'.tr(
                              args: <String>[versus],
                            ),
                        textAlign: TextAlign.center,
                        style: AppThemeStyle.regularStyle(
                          16,
                          AppColor.secondaryLabels,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed:
                            () =>
                                ref
                                    .read(assistantFollowedMatchProvider.notifier)
                                    .state = false,
                        child: Text('app.assistant.ended-ok'.tr()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
