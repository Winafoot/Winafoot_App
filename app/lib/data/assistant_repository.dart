import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wina/config/skeleton_config.dart';

/// Adjoint du coach (`users/{coach}/assistant/current`, écrit par le serveur).
class Assistant {
  const Assistant({required this.uid, required this.identifier});

  final String uid;
  final String identifier;
}

enum AssistantError { identifierTaken, invalid, alreadyExists, other }

class AssistantException implements Exception {
  const AssistantException(this.error);
  final AssistantError error;
}

abstract class AssistantRepository {
  static HttpsCallable _callable(String name) =>
      FirebaseFunctions.instanceFor(region: kCloudRegion).httpsCallable(name);

  /// Adjoint du coach connecté, en temps réel ; `null` s'il n'en a pas.
  static Stream<Assistant?> watch(String coachUid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(coachUid)
        .collection('assistant')
        .doc('current')
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> s) {
          final Map<String, dynamic>? d = s.data();
          if (d == null) return null;
          return Assistant(
            uid: (d['uid'] as String?) ?? '',
            identifier: (d['identifier'] as String?) ?? '',
          );
        });
  }

  static Future<void> create({
    required String identifier,
    required String password,
  }) async {
    try {
      await _callable('createAssistant').call<dynamic>(<String, dynamic>{
        'identifier': identifier,
        'password': password,
      });
    } on FirebaseFunctionsException catch (e) {
      throw AssistantException(_mapError(e.code, e.message));
    }
  }

  static Future<void> resetPassword(String password) async {
    try {
      await _callable(
        'resetAssistantPassword',
      ).call<dynamic>(<String, dynamic>{'password': password});
    } on FirebaseFunctionsException catch (e) {
      throw AssistantException(_mapError(e.code, e.message));
    }
  }

  static Future<void> delete() async {
    await _callable('deleteAssistant').call<dynamic>();
  }

  static AssistantError _mapError(String code, String? message) {
    if (code == 'already-exists') return AssistantError.identifierTaken;
    if (code == 'failed-precondition' && message == 'assistant-exists') {
      return AssistantError.alreadyExists;
    }
    if (code == 'invalid-argument') return AssistantError.invalid;
    return AssistantError.other;
  }

  /// Uid du coach dont le compte connecté est l'adjoint (custom claim `assistantOf`), ou `null`.
  static Future<String?> currentAssistantOf() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final IdTokenResult token = await user.getIdTokenResult();
    final Object? v = token.claims?['assistantOf'];
    return v is String && v.isNotEmpty ? v : null;
  }
}
