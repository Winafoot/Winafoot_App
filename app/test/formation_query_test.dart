import 'package:flutter_test/flutter_test.dart';
import 'package:wina/view/page/gerer_equipe_composition_screen.dart';

void main() {
  group('dashifyFormationQuery', () {
    test('insère un tiret entre chaque chiffre', () {
      expect(dashifyFormationQuery('433'), '4-3-3');
      expect(dashifyFormationQuery('442'), '4-4-2');
      expect(dashifyFormationQuery('4411'), '4-4-1-1');
      expect(dashifyFormationQuery('4231'), '4-2-3-1');
    });

    test('est idempotent (saisie déjà formatée)', () {
      expect(dashifyFormationQuery('4-3-3'), '4-3-3');
    });

    test('ignore les caractères non numériques', () {
      expect(dashifyFormationQuery('4a3b3'), '4-3-3');
      expect(dashifyFormationQuery(''), '');
      expect(dashifyFormationQuery('-'), '');
    });

    test('un seul chiffre reste tel quel', () {
      expect(dashifyFormationQuery('4'), '4');
    });
  });
}
