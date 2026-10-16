import 'package:core_kosmos/core_kosmos.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// {@category Config}
/// {@category Skeleton}
///
/// Permet de définir les événements et callbacks
/// à éxécuter lors de la réception des notifications
/// ou des DynamicLinks.
///
/// Pour le configurer, il faut créer une configuration
/// en utilisant la clé [EventConfiguration.key].
class EventConfiguration extends PackageConfig {
  /// Clé canonique pour l'enregistrement dans AppModel.dependencies.packages
  static const String key = "kosmos_event_config";

  /// Push Notification
  /// Si null, le son par défaut sera utilisé
  final String? soundIos;
  final String? soundAndroid;

  /// Si false, le stream des notifications ne sera initialisé
  final bool enablePushNotificationConfig;

  /// Permet de configurer le callback / événement lorsqu'un
  /// utilisateur clique sur la notification (uniquement quand
  /// l'application est fermé ou en background)
  final void Function(BuildContext, WidgetRef?, RemoteMessage)?
      onMessageBackground;

  /// Permet de configurer le callback / affichage des notifications
  /// lorsque l'application est en foreground.
  /// Par défaut, l'application utilise le package Flutter_local_notification
  /// pour afficher les notifications.
  final void Function(BuildContext, WidgetRef?, RemoteMessage)? onMessage;

  @Deprecated("Do not used that")
  final void Function(BuildContext, WidgetRef?, NotificationResponse)?
      onDidReceiveBackgroundNotificationResponse;

  /// Permet de configurer le callback / événement lorsqu'un
  /// utilisateur clique sur la notification affiché par le
  /// package Flutter_local_notification. (uniquement lorsque
  /// l'application est en foreground)
  final void Function(BuildContext, WidgetRef?, NotificationResponse)?
      onSelectNotification;

  /// Dynamic Links
  /// Not Yet :D

  EventConfiguration({
    /// Push Notification
    this.enablePushNotificationConfig = true,
    this.onMessageBackground,
    this.onMessage,
    this.onDidReceiveBackgroundNotificationResponse,
    this.onSelectNotification,
    this.soundIos,
    this.soundAndroid,
  }) : super(key);
}

/// Récupère la configuration [EventConfiguration] depuis AppModel.
/// Retourne une instance par défaut si non enregistrée.
EventConfiguration getEventConfiguration() {
  final config = getAppModel().dependencies.packages[EventConfiguration.key];
  assert(
    config == null || config is EventConfiguration,
    'Type mismatch for ${EventConfiguration.key}: expected EventConfiguration, got ${config.runtimeType}',
  );
  return (config as EventConfiguration?) ?? EventConfiguration();
}
