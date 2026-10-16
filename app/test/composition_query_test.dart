import 'package:flutter_test/flutter_test.dart';
import 'package:wina/view/page/test_equipe_screen.dart';

void main() {
  group('matchesCompositionQuery', () {
    test('requête vide : tout passe', () {
      expect(matchesCompositionQuery('  ', 'Ma compo', '4-3-3'), isTrue);
    });

    test('chiffres seuls (pavé numérique) : « 433 » trouve « 4-3-3 »', () {
      expect(matchesCompositionQuery('433', '', '4-3-3'), isTrue);
      expect(matchesCompositionQuery('44', '', '4-4-2'), isTrue);
      expect(matchesCompositionQuery('433', '', '4-4-2'), isFalse);
    });

    test('recherche par nom conservée', () {
      expect(matchesCompositionQuery('compo', 'Ma compo', '4-3-3'), isTrue);
    });

    test('requête sans chiffre ne matche pas tout', () {
      expect(matchesCompositionQuery('xyz', 'Ma compo', '4-3-3'), isFalse);
    });
  });
}
