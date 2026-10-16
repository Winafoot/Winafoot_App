import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wina/models/app_notification.dart';

/// Accès aux notifications internes de l'utilisateur connecté
/// (`users/{uid}/notifications`).
abstract class NotificationRepository {
  static CollectionReference<Map<String, dynamic>> _collection() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Aucun utilisateur connecté.');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications');
  }

  /// Nombre maximal de notifications relues par le flux.
  static const int _feedLimit = 50;

  /// Nombre d'écritures par lot : un [WriteBatch] est plafonné à 500
  /// opérations, au-delà `commit()` échoue.
  static const int _batchSize = 450;

  /// Flux temps réel des [_feedLimit] notifications les plus récentes.
  static Stream<List<AppNotification>> watchNotifications() {
    return _collection()
        .orderBy('sendAt', descending: true)
        .limit(_feedLimit)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map((doc) => AppNotification.fromDoc(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  /// Marque une notification comme lue.
  static Future<void> markAsRead(String id) async {
    await _collection().doc(id).update(<String, dynamic>{
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Supprime une notification de l'utilisateur connecté.
  static Future<void> deleteNotification(String id) async {
    await _collection().doc(id).delete();
  }

  /// Supprime toutes les notifications de l'utilisateur, par lots de
  /// [_batchSize] pour ne pas dépasser la limite d'un [WriteBatch].
  static Future<void> deleteAll() async {
    final QuerySnapshot<Map<String, dynamic>> all = await _collection().get();
    for (int i = 0; i < all.docs.length; i += _batchSize) {
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in all.docs.skip(i).take(_batchSize)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// Marque toutes les notifications non lues comme lues, par lots de
  /// [_batchSize] pour ne pas dépasser la limite d'un [WriteBatch].
  static Future<void> markAllAsRead() async {
    final QuerySnapshot<Map<String, dynamic>> unread =
        await _collection().where('isRead', isEqualTo: false).get();
    for (int i = 0; i < unread.docs.length; i += _batchSize) {
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in unread.docs
          .skip(i)
          .take(_batchSize)) {
        batch.update(doc.reference, <String, dynamic>{
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }
}
