// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// {@category Controller}
///
/// Permet de gérer les permissions des notifications (Email + Push).
/// - [setPushNotificationPermission] : Permet d'activer ou non les notifications push.
/// - [setEmailNotificationPermission] : Permet d'activer ou non les notifications email.
///
abstract class NotifPermissionController {
  static StreamSubscription<RemoteMessage>? messageBackGroundStreamSub;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;

  static DocumentReference<Map<String, dynamic>> _userMetadataRef(
    String userCollection,
    String userUid,
  ) {
    return FirebaseFirestore.instance
        .collection(userCollection)
        .doc(userUid)
        .collection("metadata")
        .doc("metadata");
  }

  static Future<void> _syncPushNotificationState({
    required String userCollection,
    required String userUid,
    required bool enable,
    String? fcmToken,
    String? debugField,
  }) async {
    final data = <String, dynamic>{
      "enablePushNotification": enable,
      "fcmToken": enable ? fcmToken : null,
    };

    if (debugField != null) {
      data[debugField] = enable;
    }

    await _userMetadataRef(userCollection, userUid)
        .set(data, SetOptions(merge: true));
    await LocalConfigController.setData(
      "authorized_push_notif",
      boolValue: enable,
    );
  }

  static Future<bool> _enablePushNotification(
    WidgetRef ref,
    bool fromSettings,
    String userCollection,
    String userUid, {
    String? debugField,
  }) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    await _syncPushNotificationState(
      userCollection: userCollection,
      userUid: userUid,
      enable: true,
      fcmToken: fcmToken,
      debugField: debugField,
    );
    if (fromSettings) {
      ref.read(notificationStreamProvider.notifier).state = false;
    }
    return true;
  }

  /// Send Notification to specified user
  static Future<bool> sendNotification(
    List<String>? usersId, {
    required String title,
    String? body,
    String type = "default",
    bool toTopic = false,
    String? topic,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final model = NotificationModel(
        sendToIds: usersId ?? [],
        title: title,
        body: body,
        type: type,
        toTopic: toTopic,
        topic: topic,
        metadata: metadata,
      );

      final _ = await FirebaseFirestore.instance
          .collection("notifications")
          .add(model.toJson());
      return true;
    } catch (e) {
      printExcept(e);
      return false;
    }
  }

  /// Permet d'activer ou non les notifications push.
  static Future<bool> setPushNotificationPermission(
      BuildContext context, WidgetRef ref, bool enable, String userUid,
      [bool fromSettings = true,
      String userCollection = "users",
      bool alreadyRequest = false]) async {
    try {
      if (fromSettings) {
        // ignore app already opened and to avoid duplicate notification redirection
        await FirebaseMessaging.instance.getInitialMessage();
      }
      if (!enable) {
        await _syncPushNotificationState(
          userCollection: userCollection,
          userUid: userUid,
          enable: false,
        );
        return false;
      }

      final permissionStatus =
          (await FirebaseMessaging.instance.requestPermission())
              .authorizationStatus;
      if (permissionStatus == AuthorizationStatus.authorized ||
          permissionStatus == AuthorizationStatus.provisional) {
        return _enablePushNotification(
          ref,
          fromSettings,
          userCollection,
          userUid,
          debugField: "authorized_push_notif_1",
        );
      } else if (permissionStatus == AuthorizationStatus.notDetermined) {
        NotificationSettings notificationSettings =
            await FirebaseMessaging.instance.requestPermission();
        if (notificationSettings.authorizationStatus ==
                AuthorizationStatus.authorized ||
            notificationSettings.authorizationStatus ==
                AuthorizationStatus.provisional) {
          return _enablePushNotification(
            ref,
            fromSettings,
            userCollection,
            userUid,
            debugField: "authorized_push_notif_2",
          );
        }
      } else if (Platform.isIOS &&
          permissionStatus == AuthorizationStatus.denied &&
          !fromSettings) {
        await _syncPushNotificationState(
          userCollection: userCollection,
          userUid: userUid,
          enable: false,
        );
        return false;
      } else {
        PermissionStatus permissionStatus =
            await Permission.notification.status;
        switch (permissionStatus) {
          case PermissionStatus.granted:
            return _enablePushNotification(
              ref,
              fromSettings,
              userCollection,
              userUid,
              debugField: "authorized_push_notif_7",
            );
          case PermissionStatus.denied:
            await _syncPushNotificationState(
              userCollection: userCollection,
              userUid: userUid,
              enable: false,
              debugField: "authorized_push_notif_8",
            );
            return false;
          case PermissionStatus.permanentlyDenied:
            await _syncPushNotificationState(
              userCollection: userCollection,
              userUid: userUid,
              enable: false,
              debugField: "authorized_push_notif_9",
            );
            if (!fromSettings) {
              await SettingsController.permissionToRedirectToSettings(
                  context, "notification");
            }
            return false;
          default:
            break;
        }
      }

      // else if (permissionStatus == AuthorizationStatus.denied) {
      //   return ((await SettingsController.permissionToRedirectToSettings(
      //           context, "notification")) &&
      //       !fromSettings);
      // }
    } catch (e) {
      printExcept(e);
      return false;
    }
    return false;
  }

  /// Permet d'activer ou non les notifications email.
  static Future<bool> setEmailNotificationPermission(
      bool enable, String userUid,
      [String userCollection = "users"]) async {
    try {
      FirebaseFirestore.instance
          .collection(userCollection)
          .doc(userUid)
          .collection("metadata")
          .doc("metadata")
          .update({"enableEmailNotification": enable});
      return enable;
    } catch (e) {
      printExcept(e);
    }
    return false;
  }

  /// Permet de refresh le FCM Token.
  static Future<void> refreshFcmToken(WidgetRef ref,
      [String userCollection = "users"]) async {
    final enable = (ref.read(userProvider).metadata?.enablePushNotification ??
            false) &&
        (await LocalConfigController.getData<bool>("authorized_push_notif") ??
            false);

    if (enable) {
      return await FirebaseFirestore.instance
          .collection(userCollection)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection("metadata")
          .doc("metadata")
          .update({
        "fcmToken": await FirebaseMessaging.instance.getToken(),
        "authorized_push_notif_3": true,
      });
    }

    if (!enable) return;

    final status = await FirebaseMessaging.instance.requestPermission();

    if (status.authorizationStatus == AuthorizationStatus.authorized ||
        status.authorizationStatus == AuthorizationStatus.provisional ||
        status.authorizationStatus == AuthorizationStatus.notDetermined) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection("metadata")
          .doc("metadata")
          .update({
        "fcmToken": await FirebaseMessaging.instance.getToken(),
        "authorized_push_notif_6": true,
      });
    } else if (status.authorizationStatus == AuthorizationStatus.denied) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection("metadata")
          .doc("metadata")
          .update({
        "fcmToken": null,
        "enablePushNotification": false,
        "authorized_push_notif_4": false,
      });
    }
  }

  /// Initialise le stream des notifications.
  static Future<void> initNotifStream({
    required BuildContext mainAppContext,
    required FlutterLocalNotificationsPlugin localNotification,
    required AndroidNotificationChannel channel,
    void Function(BuildContext mainAppContext, RemoteMessage)?
        onMessageBackground,
    void Function(BuildContext mainAppContext, RemoteMessage)? onMessage,
    void Function(BuildContext mainAppContext, NotificationResponse details)?
        onSelectNotification,
    void Function(BuildContext mainAppContext, NotificationResponse details)?
        onDidReceiveBackgroundNotificationResponse,
    WidgetRef? ref,
    String? soundIos,
    String? soundAndroid,
  }) async {
    printDebug("Init Notification Stream");

    /// Init event when app is in background and we opened it from a notification
    _onMessageOpenedAppSub?.cancel();
    _onMessageOpenedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onMessageBackground?.call(mainAppContext, message);
    });

    /// Init event when app is in foreground
    /// Petite icône Android des notifications : l'icône de l'app (`@mipmap/launcher_icon`,
    /// déclarée dans AndroidManifest.xml).
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    localNotification.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (v) {
        onSelectNotification?.call(mainAppContext, v);
      },
      // onDidReceiveBackgroundNotificationResponse: (v) {
      //   onDidReceiveBackgroundNotificationResponse?.call(mainAppContext, v);
      // },
    );
    await localNotification
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    messageBackGroundStreamSub?.cancel();

    messageBackGroundStreamSub = FirebaseMessaging.onMessage.listen((v) {
      RemoteNotification? notification = v.notification;
      AndroidNotification? android = v.notification?.android;

      if (notification != null && android != null) {
        localNotification.show(
          notification.hashCode,
          notification.title?.tr(),
          notification.body?.tr(),
          NotificationDetails(
              android: AndroidNotificationDetails(channel.id, channel.name,
                  channelDescription: channel.description,
                  icon: android.smallIcon,
                  playSound: true,
                  sound: soundAndroid == null
                      ? null
                      : RawResourceAndroidNotificationSound(soundAndroid),
                  priority: Priority.high,
                  importance: Importance.max)),
          payload: jsonEncode(v.data),
        );
      } else if (notification != null) {
        localNotification.show(
          notification.hashCode,
          notification.title?.tr(),
          notification.body?.tr(),
          NotificationDetails(
              iOS: DarwinNotificationDetails(
            presentAlert: true, presentSound: true, presentBadge: true,
            // interruptionLevel: InterruptionLevel.active,
            sound: soundIos,
          )),
          payload: jsonEncode(v.data),
        );
      }
      onMessage?.call(mainAppContext, v);
    });
  }
}
