import 'package:flutter_test/flutter_test.dart';
import 'package:wina/services/coach_registration.dart';
import 'package:wina/services/register_validation.dart';

void main() {
  group('RegisterValidation.isValidEmail', () {
    test('accepts a normal address, with surrounding spaces', () {
      expect(RegisterValidation.isValidEmail(' coach@club.fr '), isTrue);
    });

    for (final String bad in <String>['', 'pas-un-mail', 'a@b', 'a b@club.fr']) {
      test('refuses "$bad"', () {
        expect(RegisterValidation.isValidEmail(bad), isFalse);
      });
    }
  });

  group('RegisterValidation.passwordViolations', () {
    test('accepts a compliant password', () {
      expect(RegisterValidation.passwordViolations('Wina!2345'), isEmpty);
    });

    test('lists every missing requirement', () {
      expect(RegisterValidation.passwordViolations('abc'), <String>[
        'au moins 6 caractères',
        'une majuscule',
        'un chiffre',
        'un caractère spécial',
      ]);
    });

    final Map<String, String> cases = <String, String>{
      'SANSMINUSCULE1!': 'une minuscule',
      'sansmajuscule1!': 'une majuscule',
      'SansChiffre!!': 'un chiffre',
      'SansSpecial12': 'un caractère spécial',
    };
    cases.forEach((String password, String missing) {
      test('flags "$missing" for $password', () {
        expect(RegisterValidation.passwordViolations(password), <String>[
          missing,
        ]);
      });
    });
  });

  group('RegisterValidation.invalidFields', () {
    Set<RegisterField> run({
      String email = 'coach@club.fr',
      String password = 'Wina!2345',
      String confirmation = 'Wina!2345',
      String firstname = 'Ibrahim',
      bool cgu = true,
    }) => RegisterValidation.invalidFields(
      email: email,
      password: password,
      confirmation: confirmation,
      firstname: firstname,
      acceptedCgu: cgu,
    );

    test('is empty when everything is valid', () => expect(run(), isEmpty));

    test('flags each wrong field', () {
      expect(run(email: 'x'), <RegisterField>{RegisterField.email});
      expect(run(password: 'abc', confirmation: 'abc'), <RegisterField>{
        RegisterField.password,
      });
      expect(run(confirmation: 'Autre!2345'), <RegisterField>{
        RegisterField.confirmation,
      });
      expect(run(firstname: '   '), <RegisterField>{RegisterField.firstname});
      expect(run(cgu: false), <RegisterField>{RegisterField.cgu});
    });
  });

  group('CoachRegistration.errorFromCode', () {
    final Map<String, RegistrationError> expected = <String, RegistrationError>{
      'already-exists': RegistrationError.emailTaken,
      'invalid-argument': RegistrationError.invalidInput,
      'failed-precondition': RegistrationError.cguRefused,
      'resource-exhausted': RegistrationError.tooManyAttempts,
      'unavailable': RegistrationError.network,
      'internal': RegistrationError.unknown,
    };
    expected.forEach((String code, RegistrationError error) {
      test('$code -> $error', () {
        expect(CoachRegistration.errorFromCode(code), error);
      });
    });
  });
}
