import 'package:flutter_test/flutter_test.dart';
import 'package:wina/data/coach_profile_repository.dart';
import 'package:wina/services/social_sign_in.dart';

void main() {
  group('Se connecter avec Apple : le nom reçu est enregistré, pas redemandé', () {
    test('prénom et nom sont réunis', () {
      expect(SocialSignIn.joinAppleName('Marie', 'Dupont'), 'Marie Dupont');
      expect(SocialSignIn.joinAppleName('  Marie ', ' Dupont  '), 'Marie Dupont');
    });

    test('un seul des deux suffit', () {
      expect(SocialSignIn.joinAppleName('Marie', null), 'Marie');
      expect(SocialSignIn.joinAppleName(null, 'Dupont'), 'Dupont');
      expect(SocialSignIn.joinAppleName('Marie', ''), 'Marie');
    });

    test('nom masqué par la personne : rien n\'est envoyé', () {
      expect(SocialSignIn.joinAppleName(null, null), '');
      expect(SocialSignIn.joinAppleName('', '  '), '');
    });
  });

  group('knownCoachName : étape « Finalisez votre profil coach »', () {
    test('un vrai nom est connu : le champ n\'est pas redemandé', () {
      expect(CoachProfileRepository.knownCoachName(' Marie Dupont '), 'Marie Dupont');
    });

    test('vide, absent ou prénom de secours posé par le serveur : pas un vrai nom', () {
      expect(CoachProfileRepository.knownCoachName(null), isNull);
      expect(CoachProfileRepository.knownCoachName('   '), isNull);
      expect(CoachProfileRepository.knownCoachName(CoachProfileRepository.fallbackCoachName), isNull);
    });
  });
}
