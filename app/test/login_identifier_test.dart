import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/skeleton.dart' show LoginIdentifier, SkeletonAuthentificationConfig;

void main() {
  const String domain = 'equipes.wina.invalid';

  test('un identifiant devient l\'adresse technique, en minuscules', () {
    expect(LoginIdentifier.toEmail('U15-Lyon', domain), 'u15-lyon@$domain');
    expect(LoginIdentifier.toEmail('  u15  ', domain), 'u15@$domain');
  });

  test('une adresse e-mail reste inchangée (espaces retirés)', () {
    expect(LoginIdentifier.toEmail(' Coach@Club.fr ', domain), 'Coach@Club.fr');
  });

  test('la config d\'authentification conserve le domaine d\'identifiant', () {
    expect(const SkeletonAuthentificationConfig().identifierEmailDomain, isNull);
    expect(
      const SkeletonAuthentificationConfig(identifierEmailDomain: 'x.invalid')
          .identifierEmailDomain,
      'x.invalid',
    );
  });
}
