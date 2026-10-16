import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// {@category Controller}
///
/// Permet de gérer les données de l'utilisateur dans Firebase Firestore.
/// - [updateData] : Permet de mettre à jour les données de l'utilisateur.
///
abstract class UserFirestoreController {
  /// Permet de mettre à jour les données de l'utilisateur.
  static Future<String?> updateData(Map<String, dynamic> data, [String userCollection = "users"]) async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        return "error";
      }
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection(userCollection).doc(uid).update(data);
      return null;
    } catch (e) {
      printError(e);
      return "error";
    }
  }

  /// Permet de définir l'utilisateur comme "En ligne" ou "Hors ligne".
  static Future<String?> setOnline(bool online, [String userCollection = "users"]) async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        return "error";
      }
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection(userCollection).doc(uid).update({
        "online": online,
        "lastOnline": online ? null : FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      printError(e);
      return "error";
    }
  }
}
