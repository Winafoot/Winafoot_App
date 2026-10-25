import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/services/social_sign_in.dart';

void main() {
  group('SocialSignInResult', () {
    test('un compte existant et un compte créé sont connectés', () {
      expect(
        const SocialSignInResult(SocialSignInOutcome.signedIn).isSignedIn,
        isTrue,
      );
      expect(
        const SocialSignInResult(SocialSignInOutcome.created).isSignedIn,
        isTrue,
      );
    });

    test('annulation, CGU refusées et échec ne connectent pas', () {
      for (final SocialSignInOutcome o in <SocialSignInOutcome>[
        SocialSignInOutcome.cancelled,
        SocialSignInOutcome.cguRefused,
        SocialSignInOutcome.failed,
      ]) {
        expect(SocialSignInResult(o).isSignedIn, isFalse, reason: '$o');
      }
    });
  });

  group('SocialSignIn.messageFor', () {
    test('trop de tentatives', () {
      expect(
        SocialSignIn.messageFor(
          FirebaseFunctionsException(code: 'resource-exhausted', message: 'x'),
        ),
        'Trop de tentatives. Réessayez dans un moment.',
      );
    });

    test('reprend le motif du serveur pour un refus de précondition', () {
      expect(
        SocialSignIn.messageFor(
          FirebaseFunctionsException(
            code: 'failed-precondition',
            message: ' Adresse e-mail indisponible pour ce compte. ',
          ),
        ),
        'Adresse e-mail indisponible pour ce compte.',
      );
    });

    test('message générique (null) pour les autres erreurs', () {
      expect(
        SocialSignIn.messageFor(
          FirebaseFunctionsException(code: 'internal', message: 'boom'),
        ),
        isNull,
      );
    });
  });
}
