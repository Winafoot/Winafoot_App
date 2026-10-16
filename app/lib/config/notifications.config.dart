import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:skeleton/skeleton.dart';
import 'package:wina/config/maintenance_gate.dart';
import 'package:wina/view/page/notifications_screen.dart';

EventConfiguration initNotificationPush() {
  return EventConfiguration(
    enablePushNotificationConfig: true,

    /// App en arrière-plan ou fermée : l'utilisateur a tapé la notification
    /// système, on ouvre directement l'écran cible.
    onMessageBackground: (
      BuildContext context,
      WidgetRef? ref,
      RemoteMessage message,
    ) {
      _openFromNotification(context, message.data);
    },

    /// App au premier plan : la notification locale est déjà affichée par le
    /// package (Android comme iOS), il n'y a rien de plus à faire ici — le
    /// deeplink part de [onSelectNotification], au tap de l'utilisateur.
    onMessage: (BuildContext context, WidgetRef? ref, RemoteMessage message) {
      printDebug("EventConfiguration::onMessage->data = ${message.data}");
    },
    onSelectNotification: (
      BuildContext context,
      WidgetRef? ref,
      NotificationResponse payload,
    ) async {
      if (payload.payload == null || payload.payload!.isEmpty) {
        return;
      }
      _openFromNotification(
        context,
        jsonDecode(payload.payload!) as Map<String, dynamic>,
      );
    },
  );
}

/// Deeplink : ouvre l'écran cible au tap sur une notification push.
///
/// Contrat de payload produit par le back-end (`on_create_notification.ts`) :
/// `route` porte la destination (à défaut, le `type` de la notification) et
/// `entityId` l'identifiant de l'entité concernée.
///
/// Toute route inconnue ou absente retombe sur la liste des notifications,
/// destination universelle où l'utilisateur retrouve le message tapé (et son
/// éventuel CTA).
void _openFromNotification(BuildContext context, Map<String, dynamic> data) {
  if (!context.mounted) return;
  // Écran de maintenance ou de mise à jour affiché : rien ne doit le recouvrir.
  if (MaintenanceGate.blocksNavigation) return;
  final String route = (data["route"] as String?) ?? "";
  switch (route) {
    // Toute notification ouvre la liste des notifications : destination
    // universelle où l'utilisateur retrouve le message tapé. Le contrat de
    // payload (`route`, `entityId`) émis par le serveur permet d'ajouter un
    // `case` par écran cible.
    default:
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      );
  }
}
