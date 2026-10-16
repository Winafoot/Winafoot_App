import 'package:core_kosmos/core_kosmos.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract class EventController {
  static bool initPushNotifsDone = false;
  static Future<void> initPushNotifs(
      BuildContext mainAppContext,
      FlutterLocalNotificationsPlugin localNotification,
      AndroidNotificationChannel channel,
      [WidgetRef? ref]) async {
    final EventConfiguration config = getAppModel()
            .getDependenciesFromName<EventConfiguration>(
                "kosmos_event_config") ??
        EventConfiguration();
    final enablePushNotif = config.enablePushNotificationConfig;
    final permissionPushNotif = await FirebaseMessaging.instance
        .requestPermission(sound: true, badge: true, alert: true);

    if (enablePushNotif &&
        (permissionPushNotif.authorizationStatus ==
                AuthorizationStatus.authorized ||
            permissionPushNotif.authorizationStatus ==
                AuthorizationStatus.provisional)) {
      // ignore: use_build_context_synchronously
      await NotifPermissionController.initNotifStream(
        soundIos: config.soundIos,
        soundAndroid: config.soundAndroid,
        mainAppContext: mainAppContext,
        localNotification: localNotification,
        channel: channel,
        onMessage: config.onMessage != null
            ? (a, e) => config.onMessage?.call(a, ref, e)
            : null,
        onMessageBackground: (a, e) {
          initPushNotifsDone = true;
          config.onMessageBackground?.call(a, ref, e);
        },
        onSelectNotification: (a, e) =>
            config.onSelectNotification?.call(a, ref, e),
        onDidReceiveBackgroundNotificationResponse: (a, e) =>
            config.onDidReceiveBackgroundNotificationResponse?.call(a, ref, e),
      );
    }
  }

  static Future<void> execInitialNotification(
      BuildContext context, WidgetRef ref,
      {RemoteMessage? initialMessage}) async {
    initialMessage ??= await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null && !initPushNotifsDone) {
      initPushNotifsDone = true;
      printDebug(initialMessage.data);
      final EventConfiguration config = getAppModel()
              .getDependenciesFromName<EventConfiguration>(
                  "kosmos_event_config") ??
          EventConfiguration();
      // ignore: use_build_context_synchronously
      config.onMessageBackground?.call(context, ref, initialMessage);
    }
  }
}
