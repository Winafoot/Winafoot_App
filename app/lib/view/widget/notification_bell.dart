import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/providers/notification_providers.dart';
import 'package:wina/view/page/notifications_screen.dart';

/// Cloche de notifications des entêtes : ouvre la page Notifications et affiche
/// une pastille rouge avec le nombre de notifications non lues.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int unread = ref.watch(unreadNotificationCountProvider);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const NotificationsScreen(),
            ),
          ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Iconsax.notification_bing,
            size: sp(24),
            color: AppColor.primaryLabels,
          ),
          if (unread > 0)
            Positioned(
              right: -formatWidth(4),
              top: -formatHeight(4),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: formatWidth(4)),
                constraints: BoxConstraints(minWidth: sp(15)),
                height: sp(15),
                decoration: BoxDecoration(
                  color: AppColor.destructive,
                  borderRadius: BorderRadius.circular(r(8)),
                  border: Border.all(color: AppColor.background, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: AppThemeStyle.boldStyle(9, AppColor.textLight),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
