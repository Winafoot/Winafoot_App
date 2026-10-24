import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// `type` des notifications émises à la fin d'un match
/// (`MatchRepository.finishMatch`). Il désigne les seules notifications dont
/// `metadata['entityId']` est un identifiant de match.
const String kMatchFinishedNotificationType = 'match-finished';

/// Notification interne reçue par l'utilisateur, stockée dans
/// `users/{uid}/notifications` (cf. InternalNotificationModel côté serveur).
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.isRead,
    this.body,
    this.sentAt,
    this.type,
    this.metadata,
  });

  final String id;
  final String title;
  final bool isRead;
  final String? body;
  final DateTime? sentAt;
  final String? type;
  final Map<String, dynamic>? metadata;

  /// Libellé d'un éventuel bouton d'action (piloté par le serveur via metadata).
  String? get ctaLabel {
    final Object? label = metadata?['ctaLabel'];
    return label is String && label.isNotEmpty ? label : null;
  }

  /// Identifiant du match auquel mène le bouton d'action, ou `null` si la
  /// notification n'en désigne aucun. Le contrôle du [type] évite d'interpréter
  /// comme un match l'`entityId` d'une notification d'une autre nature.
  String? get matchId {
    if (type != kMatchFinishedNotificationType) return null;
    final Object? id = metadata?['entityId'];
    return id is String && id.isNotEmpty ? id : null;
  }

  /// Horodatage relatif court à la française (« à l'instant », « 40 min »,
  /// « 3 h », « 2 j », sinon date courte).
  String get relativeTime {
    final DateTime? at = sentAt;
    if (at == null) return '';
    final Duration d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return "à l'instant";
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours} h';
    if (d.inDays < 7) return '${d.inDays} j';
    return '${at.day.toString().padLeft(2, '0')}/'
        '${at.month.toString().padLeft(2, '0')}';
  }

  factory AppNotification.fromDoc(String id, Map<String, dynamic> json) {
    final Object? sentAt = json['sendAt'];
    return AppNotification(
      id: id,
      title: (json['title'] as String?) ?? '',
      body: json['body'] as String?,
      sentAt: sentAt is Timestamp ? sentAt.toDate() : null,
      type: json['type'] as String?,
      metadata:
          (json['metadata'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>(),
      isRead: (json['isRead'] as bool?) ?? false,
    );
  }
}
