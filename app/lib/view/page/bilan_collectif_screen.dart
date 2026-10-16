import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/career_stats.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_period.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/services/stats_pdf_export.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/bilan_scaffold.dart';

/// Écran « Bilan collectif » d'une [period] du match : en-tête « Équipe du
/// coach / Adversaire » + période, puis les statistiques suivies rangées par
/// thème, deux thèmes par ligne comme dans le bilan du client (design 1:3209).
///
/// [MatchPeriod.total] (par défaut) est le bilan du match entier. Les mi-temps
/// d'un match ancien, enregistré sans découpage, sont indisponibles.
class BilanCollectifScreen extends ConsumerWidget {
  const BilanCollectifScreen({
    super.key,
    required this.match,
    this.period = MatchPeriod.total,
  });

  final GameMatch match;
  final MatchPeriod period;

  String get _periodLabel => switch (period) {
    MatchPeriod.firstHalf => 'app.bilan-collectif.periode-mi-temps-1'.tr(),
    MatchPeriod.secondHalf => 'app.bilan-collectif.periode-mi-temps-2'.tr(),
    MatchPeriod.total => 'app.bilan-collectif.periode-total'.tr(),
  };

  String get _title =>
      period == MatchPeriod.total
          ? 'app.bilan-collectif.titre'.tr()
          : 'app.bilan-collectif.titre-periode'.tr(
            namedArgs: <String, String>{'periode': _periodLabel},
          );

  /// Équipe du coach : nom du profil (lu en direct, donc celui d'aujourd'hui).
  String _ownTeam(CoachProfile? coach) =>
      (coach?.teamName?.trim().isNotEmpty ?? false)
          ? coach!.teamName!.trim()
          : 'app.bilan-collectif.mon-equipe'.tr();

  String get _opponent =>
      match.opponent.name.trim().isEmpty
          ? 'app.bilan-collectif.equipe-adverse'.tr()
          : match.opponent.name.trim();

  Future<void> _export(BuildContext context, String ownTeam) async {
    try {
      await exportBilanCollectifPdf(
        match: match,
        period: period,
        ownTeam: ownTeam,
        opponent: _opponent,
      );
    } catch (_) {
      if (!context.mounted) return;
      showAppNotif(
        context,
        title: 'app.bilan-collectif.export-impossible'.tr(),
        subTitle: 'app.bilan-collectif.export-erreur'.tr(),
        success: false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String ownTeam = _ownTeam(
      ref.watch(coachProfileProvider).valueOrNull,
    );
    final bool unavailable =
        match.statsFor(period).status == PeriodStatus.unavailable;
    final List<CollectifBlock> blocks = collectifBlocks(match, period);
    return BilanScaffold(
      title: _title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              // Le bloc « équipes + période » prend toute la place laissée au
              // bouton : le nom ne se tronque que s'il ne tient vraiment pas,
              // et le bouton reste calé à droite, quelle que soit sa longueur.
              Expanded(
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        '$ownTeam / $_opponent',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppThemeStyle.semiBStyle(
                          20,
                          AppColor.primaryLabels,
                        ),
                      ),
                    ),
                    sw(16),
                    Text(
                      _periodLabel,
                      style: AppThemeStyle.semiBStyle(
                        16,
                        AppColor.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              sw(16),
              // Sans période exploitable, il n'y a rien à exporter pour elle.
              if (!unavailable)
                BilanExportButton(onTap: () => _export(context, ownTeam)),
            ],
          ),
          sh(16),
          Expanded(
            child:
                unavailable
                    ? _Message('app.bilan-collectif.mi-temps-indisponible'.tr())
                    : blocks.isEmpty
                    ? _Message('app.bilan-collectif.aucune-statistique'.tr())
                    : SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: formatHeight(16)),
                      child: _Blocks(blocks: blocks),
                    ),
          ),
        ],
      ),
    );
  }
}

/// Les thèmes deux par ligne (1 | 2, 3 | 4…), l'ordre du catalogue conservé.
class _Blocks extends StatelessWidget {
  const _Blocks({required this.blocks});

  final List<CollectifBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < blocks.length; i += 2) ...<Widget>[
          if (i > 0) sh(20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _ThemeBlock(block: blocks[i])),
              sw(24),
              Expanded(
                child:
                    i + 1 < blocks.length
                        ? _ThemeBlock(block: blocks[i + 1])
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Un thème : son titre puis une carte « libellé | valeur » par statistique.
class _ThemeBlock extends StatelessWidget {
  const _ThemeBlock({required this.block});

  final CollectifBlock block;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          block.category.label,
          style: AppThemeStyle.semiBStyle(15, AppColor.primaryLabels),
        ),
        sh(8),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(r(12)),
          ),
          child: Column(
            children: <Widget>[
              for (int i = 0; i < block.rows.length; i++) ...<Widget>[
                if (i > 0) Container(height: 1, color: AppColor.divider),
                _StatLine(row: block.rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.row});

  final CollectifRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: formatWidth(16),
        vertical: formatHeight(11),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              row.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.mediumStyle(14, AppColor.primaryLabels),
            ),
          ),
          sw(10),
          Text(
            row.value,
            style: AppThemeStyle.boldStyle(15, AppColor.primaryLabels),
          ),
        ],
      ),
    );
  }
}

/// Message centré : période indisponible ou aucune statistique à montrer.
class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: AppThemeStyle.regularStyle(15, AppColor.secondaryLabels),
      ),
    );
  }
}
