import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/player_repository.dart';
import 'package:wina/models/career_stats.dart';
import 'package:wina/models/player.dart';
import 'package:wina/models/player_stats.dart';
import 'package:wina/models/stat_catalog.dart' show readStat;
import 'package:wina/providers/match_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/view/page/modifier_joueur_screen.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/confirm_dialog.dart';
import 'package:wina/view/widget/custom_back_button.dart';

/// Joueur à jour dans [squad], ou [seed] s'il n'y figure plus (supprimé
/// pendant que la fiche était ouverte).
@visibleForTesting
Player resolveCurrentPlayer(List<Player> squad, Player seed) =>
    squad.firstWhere((Player p) => p.id == seed.id, orElse: () => seed);

/// Page « Détail joueur » : identité du joueur + ses statistiques regroupées en
/// trois colonnes. Reproduit l'écran tablette du design (1194 x 834).
///
/// Ouverte depuis « Mon équipe » au clic sur l'icône œil d'une ligne joueur.
class DetailJoueurScreen extends ConsumerWidget {
  const DetailJoueurScreen({super.key, required this.player});

  /// Instantané reçu au `push` : sert de graine et de repli.
  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La fiche doit refléter les modifications enregistrées depuis
    // « Modifier le joueur » : on relit l'effectif au lieu de la graine.
    final Player current = resolveCurrentPlayer(
      ref.watch(playersStreamProvider).valueOrNull ?? const <Player>[],
      player,
    );
    return Scaffold(
      backgroundColor: AppColor.background,
      body: AppBackdrop(
        child: Stack(
          children: [
            // La zone de contenu du design occupe x=41..1046 (marge droite 148).
            Padding(
              padding: EdgeInsets.only(
                left: formatWidth(41),
                right: formatWidth(148),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sh(18),
                  _TopBar(player: current),
                  sh(14),
                  Container(height: 1, color: AppColor.divider),
                  sh(16),
                  _StatsHeader(
                    onModifier:
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => ModifierJoueurScreen(player: current),
                          ),
                        ),
                    onSupprimer:
                        () => showSupprimerJoueurDialog(context, current),
                  ),
                  sh(16),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: formatHeight(16)),
                      child: _StatsGrid(player: current),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barre du haut : retour, avatar, nom, puces (poste / pied fort).
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomBackButton(onTap: () => Navigator.of(context).maybePop()),
        sw(7),
        Container(width: 1, height: formatHeight(28), color: AppColor.divider),
        sw(7),
        Icon(Iconsax.profile_2user, size: sp(26), color: AppColor.primaryColor),
        sw(12),
        Flexible(
          child: Text(
            player.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemeStyle.semiBStyle(28, AppColor.primaryLabels),
          ),
        ),
        sw(20),
        _InfoChip(label: player.position.singular),
        sw(8),
        _InfoChip(label: player.strongFoot.adjective),
        const Spacer(),
      ],
    );
  }
}

/// Puce d'information (poste / pied fort) : fond vert pâle, texte sombre.
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: formatWidth(14),
        vertical: formatHeight(6),
      ),
      decoration: BoxDecoration(
        color: AppColor.chipBackground,
        borderRadius: BorderRadius.circular(r(16)),
      ),
      child: Text(
        label,
        style: AppThemeStyle.mediumStyle(15, AppColor.primaryLabels),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Entête des statistiques : titre + actions « Modifier » / « Supprimer ».
// ─────────────────────────────────────────────────────────────────────────────
class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.onModifier, required this.onSupprimer});

  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'app.detail-joueur.titre-statistiques'.tr(),
          style: AppThemeStyle.semiBStyle(18, AppColor.primaryLabels),
        ),
        const Spacer(),
        _ActionPill(
          label: 'app.detail-joueur.action-modifier'.tr(),
          accent: AppColor.primaryLabels,
          onTap: onModifier,
        ),
        sw(16),
        _ActionPill(
          label: 'app.detail-joueur.action-supprimer'.tr(),
          accent: AppColor.destructive,
          onTap: onSupprimer,
        ),
      ],
    );
  }
}

/// Pilule blanche « texte + pastille fléchée », déclinée en sombre (modifier)
/// ou rouge (supprimer) via [accent].
class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double badge = sp(22);
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(r(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r(24)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: formatWidth(20),
            vertical: formatHeight(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppThemeStyle.semiBStyle(14, accent)),
              sw(10),
              SizedBox(
                width: badge,
                height: badge,
                child: Icon(
                  Iconsax.arrow_circle_right,
                  size: sp(13),
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grille des statistiques : 3 colonnes (14 / 14 / 13 cellules).
// ─────────────────────────────────────────────────────────────────────────────
class _StatsGrid extends ConsumerWidget {
  const _StatsGrid({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cumul carrière du joueur (somme de tous ses matchs terminés). Vide tant
    // que le flux n'a pas chargé ou si le joueur n'a aucune stat enregistrée.
    final Map<String, int> values =
        ref.watch(careerStatsProvider)[player.id] ?? const <String, int>{};
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _StatColumn(values: values, stats: kPlayerStatColumns[0]),
        ),
        sw(33),
        Expanded(
          child: _StatColumn(values: values, stats: kPlayerStatColumns[1]),
        ),
        sw(33),
        Expanded(
          child: _StatColumn(values: values, stats: kPlayerStatColumns[2]),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.values, required this.stats});

  /// Cumul carrière du joueur, indexé par clé de statistique.
  final Map<String, int> values;
  final List<StatDef> stats;

  int _valueFor(String label) {
    final String? key = statKeyForLabel(label);
    if (key == null) return 0;
    return readStat(values, key);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0) stats[i].hasSpace ? sh(14) : sh(6),
          _StatCell(label: stats[i].label, value: _valueFor(stats[i].label)),
        ],
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: formatHeight(36),
      padding: EdgeInsets.symmetric(horizontal: formatWidth(16)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(r(10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.regularStyle(14, AppColor.primaryLabels),
            ),
          ),
          sw(10),
          Text(
            '$value',
            style: AppThemeStyle.boldStyle(14, AppColor.primaryLabels),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialogue de confirmation « Supprimer ce joueur ».
// ─────────────────────────────────────────────────────────────────────────────

/// Affiche le dialogue de suppression. « Conserver ce joueur » referme ;
/// « Supprimer définitivement » referme puis revient à « Mon équipe ».
///
/// NOTE : l'effectif de démonstration est immuable ; la suppression réelle
/// nécessitera une couche de données.
Future<void> showSupprimerJoueurDialog(
  BuildContext pageContext,
  Player player,
) {
  return showDialog<void>(
    context: pageContext,
    barrierColor: AppColor.scrim,
    builder: (BuildContext dialogContext) {
      return AppConfirmDialog(
        title: 'app.detail-joueur.suppression-titre'.tr(),
        message: 'app.detail-joueur.suppression-message'.tr(),
        primaryLabel: 'app.detail-joueur.suppression-conserver'.tr(),
        onPrimary: () => Navigator.of(dialogContext).pop(),
        secondaryLabel: 'app.detail-joueur.suppression-confirmer'.tr(),
        secondaryAccent: AppColor.destructive,
        onSecondary: () async {
          Navigator.of(dialogContext).pop();
          try {
            if (player.id == null) {
              throw StateError('player id is null');
            }
            await PlayerRepository.deletePlayer(player.id!);
          } catch (_) {
            if (!pageContext.mounted) return;
            showAppNotif(
              pageContext,
              title: 'utils.error'.tr(),
              subTitle: 'app.detail-joueur.suppression-erreur'.tr(),
              success: false,
            );
            return;
          }
          if (!pageContext.mounted) return;
          showAppNotif(
            pageContext,
            title: 'app.detail-joueur.suppression-succes-titre'.tr(),
            subTitle: 'app.detail-joueur.suppression-succes-message'.tr(),
          );
          Navigator.of(pageContext).maybePop();
        },
      );
    },
  );
}

// Le dialogue de suppression utilise [AppConfirmDialog]
// (view/widget/confirm_dialog.dart) via [showSupprimerJoueurDialog] ci-dessus.
