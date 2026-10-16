import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/match_repository.dart';
import 'package:wina/data/notification_repository.dart';
import 'package:wina/models/app_notification.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/providers/notification_providers.dart';
import 'package:wina/view/page/bilan_collectif_screen.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/app_loader.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/confirm_dialog.dart';
import 'package:wina/view/widget/empty_state_placeholder.dart';
import 'package:wina/view/widget/page_header.dart';

/// Page « Notifications » : liste des notifications de l'utilisateur
/// (`users/{uid}/notifications`). Les non lues sont mises en avant ; toucher
/// une notification la marque comme lue.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppNotification>> notifsAsync = ref.watch(
      notificationsProvider,
    );
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Stack(
          children: [
            const AppBackground(),
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: formatWidth(40)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sh(18),
                      PageHeader(
                        icon: Iconsax.notification_bing,
                        iconSize: 34,
                        title: 'app.notifications.titre'.tr(),
                        onBack: () => Navigator.of(context).maybePop(),
                        backDivider: true,
                      ),
                      sh(14),
                      Container(height: 1, color: AppColor.divider),
                    ],
                  ),
                ),
                Expanded(
                  child: notifsAsync.when(
                    data:
                        (List<AppNotification> list) =>
                            list.isEmpty
                                ? EmptyStatePlaceholder(
                                  icon: Iconsax.notification_bing,
                                  title: 'app.notifications.vide-titre'.tr(),
                                  subtitle:
                                      'app.notifications.vide-sous-titre'.tr(),
                                )
                                : _List(notifications: list),
                    loading: () => const AppLoader(),
                    error:
                        (Object e, _) => Center(
                          child: Text(
                            'app.notifications.erreur-chargement'.tr(),
                            style: AppThemeStyle.mediumStyle(
                              15,
                              AppColor.secondaryLabels,
                            ),
                          ),
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

class _List extends StatelessWidget {
  const _List({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: formatWidth(40),
        vertical: formatHeight(16),
      ),
      itemCount: notifications.length,
      separatorBuilder: (_, _) => sh(12),
      itemBuilder: (BuildContext context, int i) {
        final AppNotification n = notifications[i];
        final String? matchId = n.matchId;
        return _NotificationTile(
          notif: n,
          onTap: () => NotificationRepository.markAsRead(n.id),
          // Le bouton d'action n'est affiché que s'il mène quelque part.
          onCta: matchId == null ? null : () => _openMatch(context, n, matchId),
          onDelete: () => showSupprimerNotificationDialog(context, n),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notif,
    required this.onTap,
    required this.onCta,
    required this.onDelete,
  });

  final AppNotification notif;
  final VoidCallback onTap;

  /// Action du bouton de la carte. `null` quand la notification ne désigne
  /// aucune destination : le bouton n'est alors pas dessiné.
  final VoidCallback? onCta;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bool unread = !notif.isRead;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: formatWidth(16),
          vertical: formatHeight(unread ? 16 : 12),
        ),
        decoration:
            unread
                ? BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(r(12)),
                )
                : BoxDecoration(
                  color: AppColor.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(r(12)),
                ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    notif.title,
                    style:
                        unread
                            ? AppThemeStyle.semiBStyle(
                              15,
                              AppColor.primaryLabels,
                            )
                            : AppThemeStyle.mediumStyle(
                              15,
                              AppColor.primaryLabels,
                            ),
                  ),
                ),
                sw(10),
                Text(
                  notif.relativeTime,
                  style: AppThemeStyle.regularStyle(
                    12,
                    AppColor.secondaryLabels,
                  ),
                ),
                sw(6),
                // Cible tactile portée au minimum ergonomique de 48 dp sans
                // grossir l'icône, comme les flèches de pagination.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDelete,
                  child: SizedBox(
                    width: kMinInteractiveDimension,
                    height: kMinInteractiveDimension,
                    child: Center(
                      child: Icon(
                        Iconsax.trash,
                        size: sp(18),
                        color: AppColor.secondaryLabels,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (notif.body != null && notif.body!.isNotEmpty) ...[
              sh(6),
              Text(
                notif.body!,
                style: AppThemeStyle.regularStyle(13, AppColor.secondaryLabels),
              ),
            ],
            if (notif.ctaLabel != null && onCta != null) ...[
              sh(12),
              Align(
                alignment: Alignment.centerLeft,
                child: _CtaButton(label: notif.ctaLabel!, onTap: onCta!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Marque la notification comme lue puis ouvre le bilan du match qu'elle
/// désigne. Le match a pu être supprimé de l'historique entre-temps : on le
/// dit plutôt que d'ouvrir un écran vide.
Future<void> _openMatch(
  BuildContext context,
  AppNotification notif,
  String matchId,
) async {
  NotificationRepository.markAsRead(notif.id);
  GameMatch? match;
  try {
    match = await MatchRepository.getMatch(matchId);
  } catch (_) {
    match = null;
  }
  if (!context.mounted) return;
  if (match == null) {
    showAppNotif(
      context,
      title: 'utils.error'.tr(),
      subTitle: 'app.notifications.match-indisponible'.tr(),
      success: false,
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => BilanCollectifScreen(match: match!)),
  );
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double badge = sp(20);
    return Material(
      color: AppColor.primaryColor,
      borderRadius: BorderRadius.circular(r(999)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r(10)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: formatWidth(16),
            vertical: formatHeight(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppThemeStyle.semiBStyle(13, AppColor.textLight),
              ),
              sw(8),
              SizedBox(
                width: badge,
                height: badge,
                child: Icon(
                  Iconsax.arrow_circle_right,
                  size: sp(12),
                  color: AppColor.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// L'état vide « Aucune notification » utilise [EmptyStatePlaceholder].

// ─────────────────────────────────────────────────────────────────────────────
// Dialogue de confirmation « Supprimer cette notification ».
// ─────────────────────────────────────────────────────────────────────────────

/// Affiche le dialogue de suppression. « Conserver » referme ; « Supprimer
/// définitivement » supprime la notification puis notifie le résultat réel.
///
/// La suppression ne porte que sur la copie personnelle
/// (`users/{uid}/notifications`) : la trace d'envoi conservée dans la
/// collection racine `notifications` n'est pas touchée.
Future<void> showSupprimerNotificationDialog(
  BuildContext pageContext,
  AppNotification notif,
) {
  return showDialog<void>(
    context: pageContext,
    barrierColor: AppColor.scrim,
    builder: (BuildContext dialogContext) {
      return AppConfirmDialog(
        title: 'app.notifications.suppression-titre'.tr(),
        message: 'app.notifications.suppression-message'.tr(),
        primaryLabel: 'app.notifications.suppression-conserver'.tr(),
        onPrimary: () => Navigator.of(dialogContext).pop(),
        secondaryLabel: 'app.notifications.suppression-confirmer'.tr(),
        secondaryAccent: AppColor.destructive,
        onSecondary: () async {
          Navigator.of(dialogContext).pop();
          try {
            await NotificationRepository.deleteNotification(notif.id);
          } catch (e) {
            if (!pageContext.mounted) return;
            showAppNotif(
              pageContext,
              title: 'utils.error'.tr(),
              subTitle: '$e',
              success: false,
            );
            return;
          }
          if (!pageContext.mounted) return;
          showAppNotif(
            pageContext,
            title: 'app.notifications.suppression-succes-titre'.tr(),
            subTitle: 'app.notifications.suppression-succes-message'.tr(),
          );
        },
      );
    },
  );
}
