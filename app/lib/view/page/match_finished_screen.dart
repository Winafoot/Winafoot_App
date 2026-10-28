import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/live_match_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/view/page/bilan_collectif_screen.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/match_header.dart';
import 'package:wina/view/widget/match_stats_board.dart';

/// Écran « Match terminé » : récapitulatif (score + tableau des statistiques
/// par joueur) et actions de fin de match.
class MatchFinishedScreen extends ConsumerStatefulWidget {
  const MatchFinishedScreen({super.key});

  @override
  ConsumerState<MatchFinishedScreen> createState() =>
      _MatchFinishedScreenState();
}

class _MatchFinishedScreenState extends ConsumerState<MatchFinishedScreen> {
  @override
  void initState() {
    super.initState();
    // Cet écran n'est ouvert (pushReplacement) qu'une fois le match enregistré
    // comme terminé : y entrer marque la fin effective du match.
    final LiveMatch? live = ref.read(liveMatchProvider);
    if (live == null) return;
    AnalyticsController.logEvent(
      'match_finished',
      parameters: <String, Object>{
        'score_us': live.scoreUs,
        'score_them': live.scoreThem,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final LiveMatch? live = ref.watch(liveMatchProvider);
    final List<Player> players =
        ref.watch(playersStreamProvider).valueOrNull ?? const <Player>[];
    final GameMatch draft = ref.watch(matchDraftProvider);
    final String jerseyAsset =
        draft.ownJersey?.color.asset ?? 'assets/images/shirt-l-blue.png';
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

    // Match terminé reconstitué pour le bilan collectif (totaux d'équipe), qui
    // s'ouvre sur le Total : il compte aussi les stats suivies seulement en 1re
    // mi-temps, comme le match relu depuis l'historique. `half` et
    // `firstHalfStats` sont indispensables : sans eux le match passe pour un
    // match ancien (1re et 2e mi-temps indisponibles) et l'export PDF n'a
    // que la page Total.
    final GameMatch finishedMatch = GameMatch(
      opponent: draft.opponent,
      enabledStatKeys: live.enabledStatKeys,
      firstHalfStatKeys: live.firstHalfStatKeys,
      half: live.half,
      firstHalfStats: live.firstHalfStats,
      status: MatchStatus.finished,
      scoreUs: live.scoreUs,
      scoreThem: live.scoreThem,
      elapsedSeconds: live.elapsedSeconds,
      playerStats: live.playerStats,
    );

    return Scaffold(
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
                        title: 'app.match-finished.titre'.tr(),
                        clock: live.clock,
                        scoreUs: live.scoreUs,
                        scoreThem: live.scoreThem,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Le tableau ne défile pas verticalement de lui-même :
                        // sans cette enveloppe, les dernières lignes — les
                        // remplaçants — sont hors écran et inatteignables dès
                        // un match à 11.
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(bottom: formatHeight(16)),
                            child: MatchStatsBoard(
                              live: live,
                              byId: byId,
                              jerseyAsset: jerseyAsset,
                            ),
                          ),
                        ),
                        sw(24),
                        SizedBox(
                          width: formatWidth(240),
                          child: _Actions(
                            onHome:
                                () => Navigator.of(
                                  context,
                                ).popUntil((Route<dynamic> r) => r.isFirst),
                            onStats:
                                () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder:
                                        (_) => BilanCollectifScreen(
                                          match: finishedMatch,
                                        ),
                                  ),
                                ),
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
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onHome, required this.onStats});

  final VoidCallback onHome;
  final VoidCallback onStats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'app.match-finished.actions-match'.tr(),
          style: AppThemeStyle.semiBStyle(15, AppColor.primaryLabels),
        ),
        sh(14),
        CpButton(label: 'app.match-finished.accueil'.tr(), onTap: onHome),
        sh(12),
        CpButton(
          label: 'app.match-finished.voir-statistiques'.tr(),
          onTap: onStats,
          soft: true,
        ),
      ],
    );
  }
}
