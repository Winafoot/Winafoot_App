import 'package:flutter_test/flutter_test.dart';
import 'package:wina/data/match_repository.dart';
import 'package:wina/models/app_notification.dart';

/// Contrôle hors ligne du volet « notification de fin de match » : la forme de
/// la charge utile envoyée au callable `addNotification`, et la règle qui
/// décide si le bouton de la carte a une destination.
void main() {
  group('MatchRepository.matchFinishedPayload', () {
    final Map<String, dynamic> payload = MatchRepository.matchFinishedPayload(
      uid: 'coach-1',
      matchId: 'match-42',
      title: 'Match terminé !',
      body: 'Consultez les statistiques.',
      ctaLabel: 'Voir le match',
    );

    test('notifie le coach et porte senderId', () {
      // Sans `senderId`, la variante non authentifiée du callable n'écrit
      // rien et résout quand même : l'échec serait invisible.
      expect(payload['addNotifTo'], <String>['coach-1']);
      expect(payload['senderId'], 'coach-1');
    });

    test('ne demande pas de push', () {
      expect(payload['sendPushNotif'], isFalse);
    });

    test('porte le type, le libellé du bouton et l’id du match', () {
      final Map<String, dynamic> model =
          payload['internalNotifModel'] as Map<String, dynamic>;
      expect(model['title'], 'Match terminé !');
      expect(model['body'], 'Consultez les statistiques.');
      expect(model['type'], kMatchFinishedNotificationType);

      final Map<String, dynamic> metadata =
          model['metadata'] as Map<String, dynamic>;
      expect(metadata['ctaLabel'], 'Voir le match');
      expect(metadata['entityId'], 'match-42');
    });
  });

  group('AppNotification.matchId', () {
    AppNotification build({String? type, Map<String, dynamic>? metadata}) {
      return AppNotification(
        id: 'n1',
        title: 'Match terminé !',
        isRead: false,
        type: type,
        metadata: metadata,
      );
    }

    test('rend l’id porté par une notification « match terminé »', () {
      final AppNotification n = build(
        type: kMatchFinishedNotificationType,
        metadata: <String, dynamic>{'entityId': 'match-42'},
      );
      expect(n.matchId, 'match-42');
    });

    test('null pour un autre type, même avec un entityId', () {
      final AppNotification n = build(
        type: 'commentary',
        metadata: <String, dynamic>{'entityId': 'autre-chose'},
      );
      expect(n.matchId, isNull);
    });

    test('null sans entityId : pas de bouton sans destination', () {
      expect(build(type: kMatchFinishedNotificationType).matchId, isNull);
    });
  });
}
