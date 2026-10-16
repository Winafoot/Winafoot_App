import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wina/models/custom_composition.dart';

/// Persistance des compositions **personnalisées** du coach, dans la
/// sous-collection `users/{uid}/compositions`.
///
/// Les compositions *standards* restent des constantes de l'app (cf.
/// `formation.dart`) ; seules les compositions « custom » créées par le coach
/// sont stockées ici.
abstract class CompositionRepository {
  static CollectionReference<Map<String, dynamic>> _collection() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError(
        'Aucun utilisateur connecté : compositions inaccessibles.',
      );
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('compositions');
  }

  /// Flux temps réel des compositions personnalisées (les plus récemment créées
  /// d'abord). Le tri est fait côté client pour éviter un index sur `createdAt`.
  static Stream<List<CustomComposition>> watchCustomCompositions() {
    return _collection().snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snap,
    ) {
      final List<CustomComposition> list = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                CustomComposition.fromDoc(d.id, d.data()),
          )
          .toList();
      // `createdAt` est un horodatage serveur : il vaut `null` sur l'écriture
      // locale tant que le serveur n'a pas répondu. Une composition tout juste
      // créée est la plus récente : elle doit rester en tête, et non retomber
      // en fin de liste le temps de l'aller-retour.
      final DateTime pending = DateTime.utc(9999);
      list.sort(
        (CustomComposition a, CustomComposition b) =>
            (b.createdAt ?? pending).compareTo(a.createdAt ?? pending),
      );
      return list;
    });
  }

  /// Crée une composition personnalisée (id auto-généré).
  static Future<void> addComposition(CustomComposition composition) async {
    await _collection().add(<String, dynamic>{
      ...composition.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Met à jour une composition existante (schéma, nom, emplacements). Conserve
  /// `createdAt` grâce au merge.
  static Future<void> updateComposition(CustomComposition composition) async {
    final String? id = composition.id;
    if (id == null) return;
    await _collection().doc(id).set(<String, dynamic>{
      ...composition.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Supprime définitivement une composition personnalisée.
  static Future<void> deleteComposition(String id) async {
    await _collection().doc(id).delete();
  }

  /// Bascule l'état favori d'une composition.
  static Future<void> setFavorite(String id, bool isFavorite) async {
    await _collection().doc(id).update(<String, dynamic>{
      'isFavorite': isFavorite,
    });
  }
}
