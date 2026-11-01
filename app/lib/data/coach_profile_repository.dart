import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/formation.dart' show PlayerCount;

/// Persistance du profil coach renseigné aux écrans « Finalisez votre profil »
/// (Check profil step 1 & 2), et bascule de l'indicateur `profilCompleted`.
abstract class CoachProfileRepository {
  static DocumentReference<Map<String, dynamic>> _userDoc() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Aucun utilisateur connecté.');
    }
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  /// Étape 1 : nom du coach, nom d'équipe, catégorie, division et format.
  /// Fusionné dans le document de l'utilisateur.
  ///
  /// [teamFormat] n'est écrit que pour un compte qui n'en a pas encore (coach
  /// inscrit depuis l'app) : les règles Firestore refusent de le modifier ensuite.
  /// Les comptes du back-office l'ont déjà, on passe alors `null`.
  static Future<void> saveTeamInfo({
    required String coachName,
    required String teamName,
    required TeamCategory category,
    required TeamDivision division,
    PlayerCount? teamFormat,
  }) async {
    await _userDoc().set(<String, dynamic>{
      'coachName': coachName,
      'teamName': teamName,
      'category': category.name,
      'division': division.name,
      if (teamFormat != null) 'teamFormat': teamFormat.value,
    }, SetOptions(merge: true));
  }

  /// Nom pré-rempli à l'étape 1 « Finalisez votre profil » : le `coachName`
  /// déjà saisi s'il existe, sinon le `firstname` posé par le back-office lors
  /// de la création du compte. `null` si aucun nom n'est disponible.
  static Future<String?> loadInitialCoachName() async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _userDoc().get();
    final Map<String, dynamic> data = doc.data() ?? const <String, dynamic>{};
    for (final String key in <String>['coachName', 'firstname']) {
      final String? value = (data[key] as String?)?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  /// Flux temps réel du profil coach / équipe (entête de « Mon équipe »).
  static Stream<CoachProfile> watchCoachProfile() {
    return _userDoc().snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> doc) =>
          CoachProfile.fromJson(doc.data() ?? const <String, dynamic>{}),
    );
  }

  /// Flux temps réel des maillots de l'équipe.
  static Stream<List<Jersey>> watchJerseys() {
    return _userDoc()
        .collection('jerseys')
        .orderBy('order')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map((doc) => Jersey.fromDoc(doc.data()))
              .toList(growable: false),
        );
  }

  /// Ajoute des maillots dans `users/{uid}/jerseys`, à la suite de ceux déjà
  /// enregistrés (étape 2 de la complétion de profil, « Modifier les
  /// maillots »).
  static Future<void> addJerseys(List<Jersey> jerseys) async {
    if (jerseys.isEmpty) return;
    final CollectionReference<Map<String, dynamic>> col = _userDoc().collection(
      'jerseys',
    );
    final QuerySnapshot<Map<String, dynamic>> last =
        await col.orderBy('order', descending: true).limit(1).get();
    final int start =
        last.docs.isEmpty
            ? 0
            : ((last.docs.first.data()['order'] as num?)?.toInt() ?? -1) + 1;
    final WriteBatch batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < jerseys.length; i++) {
      batch.set(col.doc(), <String, dynamic>{
        ...jerseys[i].toJson(),
        'order': start + i,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Référence du maillot occupant la position [index] de la liste ordonnée
  /// (celle affichée par [watchJerseys] / [getJerseys]). `null` si cette
  /// position n'existe plus.
  static Future<DocumentReference<Map<String, dynamic>>?> _jerseyRefAt(
    int index,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _userDoc().collection('jerseys').orderBy('order').get();
    if (index < 0 || index >= snap.docs.length) return null;
    return snap.docs[index].reference;
  }

  /// Met à jour le nom et la couleur du maillot à la position [index].
  static Future<void> updateJersey(int index, Jersey jersey) async {
    final DocumentReference<Map<String, dynamic>>? ref = await _jerseyRefAt(
      index,
    );
    if (ref == null) throw StateError('Maillot introuvable.');
    await ref.update(jersey.toJson());
  }

  /// Supprime le maillot à la position [index].
  static Future<void> deleteJersey(int index) async {
    final DocumentReference<Map<String, dynamic>>? ref = await _jerseyRefAt(
      index,
    );
    if (ref == null) throw StateError('Maillot introuvable.');
    await ref.delete();
  }

  /// Charge les maillots existants (ordonnés).
  static Future<List<Jersey>> getJerseys() async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _userDoc().collection('jerseys').orderBy('order').get();
    return snap.docs
        .map((doc) => Jersey.fromDoc(doc.data()))
        .toList(growable: false);
  }

  /// Marque le profil comme complété (`metadata/security.profilCompleted`),
  /// ce qui lève la redirection vers la complétion de profil.
  static Future<void> markProfilCompleted() async {
    await _userDoc().collection('metadata').doc('security').update(
      <String, dynamic>{'profilCompleted': true},
    );
  }
}
