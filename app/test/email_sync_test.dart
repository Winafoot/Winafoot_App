import 'package:flutter_test/flutter_test.dart';
import 'package:wina/services/email_sync.dart';

void main() {
  group('EmailSync.emailToWrite', () {
    test('adresse changée dans Firebase Auth : recopiée', () {
      expect(
        EmailSync.emailToWrite(
          authEmail: 'nouvelle@example.com',
          storedEmail: 'ancienne@example.com',
        ),
        'nouvelle@example.com',
      );
    });

    test('champ absent dans Firestore : recopiée', () {
      expect(
        EmailSync.emailToWrite(
          authEmail: 'coach@example.com',
          storedEmail: null,
        ),
        'coach@example.com',
      );
    });

    test('adresses identiques : rien à écrire', () {
      expect(
        EmailSync.emailToWrite(
          authEmail: 'coach@example.com',
          storedEmail: 'coach@example.com',
        ),
        isNull,
      );
    });

    test('pas d\'adresse dans Firebase Auth : rien à écrire', () {
      expect(
        EmailSync.emailToWrite(
          authEmail: null,
          storedEmail: 'coach@example.com',
        ),
        isNull,
      );
      expect(
        EmailSync.emailToWrite(authEmail: '', storedEmail: 'coach@example.com'),
        isNull,
      );
    });
  });
}
