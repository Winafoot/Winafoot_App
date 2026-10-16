import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseRootController<T extends Object> {
  final String collectionName;

  const FirebaseRootController([this.collectionName = "users"]);

  /// Permet de récupérer la collection de la base de données.
  CollectionReference<Map<String, dynamic>> getCollectionReference() => FirebaseFirestore.instance.collection(collectionName);

  /// Permet de créer un document dans cette collection.
  Future<DocumentReference<Map<String, dynamic>>?> create(dynamic model) async {
    assert(model?.toJson != null, "The model must have a toJson method");
    return await FirebaseFirestore.instance.collection(collectionName).add(model.toJson());
  }

  /// permet de récupérer un document de cette collection.
  Future<T?> get(String uid, T Function(Map<String, dynamic>) constructor) async {
    DocumentSnapshot<Map<String, dynamic>> document = await FirebaseFirestore.instance.collection(collectionName).doc(uid).get();

    if (document.data() == null) return null;

    return constructor(document.data()!);
  }

  /// Permet de supprimer un document de cette collection.
  Future<void> delete(String uid) async => await FirebaseFirestore.instance.collection(collectionName).doc(uid).delete();

  /// Permet de mettre à jour un document de cette collection.
  Future<void> update(String id, dynamic model) async {
    assert(model?.toJson != null, "The model must have a toJson method");
    await FirebaseFirestore.instance.collection(collectionName).doc(id).update(model.toJson());
  }
}
