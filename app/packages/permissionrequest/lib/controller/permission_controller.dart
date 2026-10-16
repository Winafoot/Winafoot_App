import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// {@category Controller}
/// {@category Permission}
///
/// Permet d'intéragir avec les permissions de l'utilisateur.
/// - [setPermissionAsComplete] permet de définir que l'utilisateur
/// a déjà complété les permissions.
///
class PermissionController {
  /// Défini que l'utilisateur a déjà complété les permissions.
  static Future<void> setPermissionAsComplete() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser!.uid).collection("metadata").doc("metadata").update({"permissionLaunched": true});
    }
    LocalConfigController.setData("permission_already_launched", boolValue: true);
  }

  /// Défini locallement que l'utilisateur a autorisé les pushs notifications.
  static Future<void> setPushNotifications(bool val) async {
    LocalConfigController.setData("authorized_push_notif", boolValue: val);
  }
}
