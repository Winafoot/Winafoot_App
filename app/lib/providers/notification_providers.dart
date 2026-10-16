import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/data/notification_repository.dart';
import 'package:wina/models/app_notification.dart';
import 'package:wina/providers/auth_providers.dart';

/// Flux temps réel des notifications de l'utilisateur connecté. Rattaché à
/// [authUidProvider] pour se reconstruire à chaque changement de session.
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final String? uid = ref.watch(authUidProvider).valueOrNull;
  if (uid == null) {
    return Stream<List<AppNotification>>.value(const <AppNotification>[]);
  }
  return NotificationRepository.watchNotifications();
});

/// Nombre de notifications non lues (badge de la cloche).
final unreadNotificationCountProvider = Provider<int>((ref) {
  final List<AppNotification> notifs =
      ref.watch(notificationsProvider).valueOrNull ?? const <AppNotification>[];
  return notifs.where((AppNotification n) => !n.isRead).length;
});
