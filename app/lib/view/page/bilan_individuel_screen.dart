import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/match_period.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/services/stats_pdf_export.dart';
import 'package:wina/view/widget/app_loader.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/bilan_scaffold.dart';
import 'package:wina/view/widget/match_stats_board.dart';
import 'package:wina/view/widget/stats_pager_arrows.dart';

/// Écran « Bilan individuel » : tableau « Joueurs × Statistiques » d'un match
/// (design 1:2756). Réutilise [MatchStatsBoard] (roster fixe + statistiques
/// défilables horizontalement, paginées par les flèches ‹ ›).
///
/// [period] est la période du bilan : le match entier par défaut, ou une
/// mi-temps (indisponible pour un match ancien, enregistré sans découpage).
/// [playerId] est le joueur choisi dans le popup (ou sélectionné sur le
/// terrain) de l'onglet « Statistiques matchs ».
class BilanIndividuelScreen extends ConsumerStatefulWidget {
  const BilanIndividuelScreen({
    super.key,
    required this.match,
    this.period = MatchPeriod.total,
    this.playerId,
  });

  final GameMatch match;
  final MatchPeriod period;
  final String? playerId;

  @override
  ConsumerState<BilanIndividuelScreen> createState() =>
      _BilanIndividuelScreenState();
}

class _BilanIndividuelScreenState extends ConsumerState<BilanIndividuelScreen> {
  /// Défilement horizontal des colonnes de statistiques (flèches ‹ ›).
  final ScrollController _statsController = ScrollController();

  @override
  void dispose() {
    _statsController.dispose();
    super.dispose();
  }

  // Mêmes libellés de période que le bilan collectif.
  String get _periodLabel => switch (widget.period) {
    MatchPeriod.firstHalf => 'app.bilan-collectif.periode-mi-temps-1'.tr(),
    MatchPeriod.secondHalf => 'app.bilan-collectif.periode-mi-temps-2'.tr(),
    MatchPeriod.total => 'app.bilan-collectif.periode-total'.tr(),
  };

  String get _titleWithPeriod => 'app.bilan-individuel.titre-periode'.tr(
    namedArgs: <String, String>{'periode': _periodLabel},
  );

  String get _title =>
      widget.period == MatchPeriod.total
          ? 'app.bilan-individuel.titre'.tr()
          : _titleWithPeriod;

  Future<void> _export(BuildContext context, Map<String, Player> byId) async {
    try {
      await exportBilanIndividuelPdf(
        match: widget.match,
        byId: byId,
        // Le PDF nomme toujours sa période, le Total compris.
        title: _titleWithPeriod,
        period: widget.period,
      );
    } catch (_) {
      if (!context.mounted) return;
      showAppNotif(
        context,
        title: 'app.bilan-individuel.export-impossible'.tr(),
        subTitle: 'app.bilan-individuel.export-erreur'.tr(),
        success: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Player>> playersAsync = ref.watch(
      playersStreamProvider,
    );
    final List<Player> players = playersAsync.valueOrNull ?? const <Player>[];
    final Map<String, Player> byId = <String, Player>{
      for (final Player p in players)
        if (p.id != null) p.id!: p,
    };
    final PeriodStatus status = widget.match.statsFor(widget.period).status;
    final LiveMatch live = LiveMatch.fromFinished(widget.match, widget.period);
    final String jerseyAsset =
        widget.match.ownJersey?.color.asset ?? 'assets/images/shirt-l-blue.png';

    return BilanScaffold(
      title: _title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: formatWidth(315),
                child: Text(
                  'app.bilan-individuel.joueurs'.tr(),
                  style: AppThemeStyle.semiBStyle(18, AppColor.primaryLabels),
                ),
              ),
              Text(
                'app.bilan-individuel.statistiques'.tr(),
                style: AppThemeStyle.semiBStyle(18, AppColor.primaryLabels),
              ),
              const Spacer(),
              // Sans période exploitable, il n'y a rien à exporter pour elle.
              if (status != PeriodStatus.unavailable) ...<Widget>[
                BilanExportButton(onTap: () => _export(context, byId)),
                sw(27),
                StatsPagerArrows(controller: _statsController),
              ],
            ],
          ),
          sh(2),
          Expanded(
            child:
                status == PeriodStatus.unavailable
                    ? Center(
                      child: Text(
                        'app.bilan-collectif.mi-temps-indisponible'.tr(),
                        style: AppThemeStyle.regularStyle(
                          15,
                          AppColor.secondaryLabels,
                        ),
                      ),
                    )
                    // Sans le roster, le tableau serait entièrement vide : on
                    // montre son squelette plutôt qu'une page blanche le temps
                    // du chargement.
                    : players.isEmpty && playersAsync.isLoading
                    ? const _BoardSkeleton()
                    : SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: formatHeight(16)),
                      child: MatchStatsBoard(
                        live: live,
                        byId: byId,
                        controller: _statsController,
                        jerseyAsset: jerseyAsset,
                        highlightPlayerId: widget.playerId,
                        noValue: status == PeriodStatus.notPlayed,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

/// Squelette du tableau « Joueurs × Statistiques » : barre d'en-tête puis
/// quelques lignes, sur les deux zones (roster à gauche, statistiques à
/// droite) aux dimensions du design.
class _BoardSkeleton extends StatelessWidget {
  const _BoardSkeleton();

  Widget _zone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SkeletonBox(height: 35),
        sh(9),
        for (int i = 0; i < 6; i++) ...<Widget>[
          if (i > 0) sh(6),
          const SkeletonBox(height: 36, radius: 8),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: formatWidth(305), child: _zone()),
          sw(10),
          Expanded(child: _zone()),
        ],
      ),
    );
  }
}
