import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// UID de l'utilisateur connecté, en flux — `null` lorsqu'il est déconnecté.
///
/// Les providers de données rattachées à l'utilisateur (`users/{uid}/…`)
/// écoutent ce flux : à chaque changement d'authentification (déconnexion,
/// reconnexion, changement de compte) ils se reconstruisent et rattachent un
/// listener Firestore neuf. Sans ça, un listener ouvert sous l'ancienne session
/// reçoit un `permission-denied` à la déconnexion et y reste bloqué (les
/// listeners Firestore ne réessaient jamais après un refus) : l'écran conserve
/// alors son erreur (« Impossible de charger l'effectif ») jusqu'à un
/// redémarrage complet de l'application.
final authUidProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance
      .authStateChanges()
      .map((User? user) => user?.uid)
      .distinct();
});
