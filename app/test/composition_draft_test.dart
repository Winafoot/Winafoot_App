import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/providers/composition_providers.dart';

void main() {
  group('CompositionDraftNotifier — numéros des remplaçants', () {
    test('setSubNumbers retient le choix libre du coach', () {
      final n = CompositionDraftNotifier()..setCount(5);
      n.setSubNumbers(<int>{9, 17, 23});
      expect(n.state.subNumbers, <int>{9, 17, 23});
    });

    test(
      'setSubNumbers accepte un numéro que la grille titulaire propose aussi',
      () {
        // La grille de la maquette offre les 36 numéros : le coach peut
        // réserver aux remplaçants un numéro qui figure aussi côté titulaire.
        // L'unicité reste tenue à l'attribution, pas au choix du pool.
        final n = CompositionDraftNotifier()..setCount(5);
        n.setSubNumbers(<int>{3, 5, 12});
        expect(n.state.subNumbers, <int>{3, 5, 12});
      },
    );

    test(
      'setSubNumbers retire au remplaçant un numéro qui sort du choix',
      () {
        // Sans cela le joueur garderait un numéro que plus aucune grille
        // n'affiche : invisible et impossible à modifier.
        final n = CompositionDraftNotifier()..setCount(5);
        n.setSubNumbers(<int>{9, 17});
        n.setNumber('p1', 9, isSubstitute: true);
        n.setNumber('p2', 2, isSubstitute: false);
        n.setSubNumbers(<int>{17});
        expect(n.state.numbers.containsKey('p1'), isFalse);
        expect(n.state.substituteIds.contains('p1'), isFalse);
        // Le titulaire n'est pas touché.
        expect(n.state.numbers['p2'], 2);
      },
    );

    test('setCount réinitialise le choix des numéros remplaçants', () {
      final n = CompositionDraftNotifier()..setCount(5);
      n.setSubNumbers(<int>{9});
      n.setCount(11);
      expect(n.state.subNumbers, isEmpty);
    });
  });

  group('CompositionDraftNotifier — numéros / capitaine / remplaçants', () {
    test(
      'setNumber attribue et garantit l\'unicité du numéro dans toute l\'équipe',
      () {
        final n = CompositionDraftNotifier();
        n.setNumber('p1', 10, isSubstitute: false);
        expect(n.state.numbers['p1'], 10);
        n.setNumber('p2', 10, isSubstitute: false); // retiré de p1
        expect(n.state.numbers['p2'], 10);
        expect(n.state.numbers.containsKey('p1'), isFalse);
      },
    );

    test(
      'setNumber : un remplaçant qui prend le numéro d\'un titulaire le lui retire',
      () {
        final n = CompositionDraftNotifier()
          ..setNumber('p1', 10, isSubstitute: false)
          ..setNumber('p2', 10, isSubstitute: true);
        expect(n.state.numbers.containsKey('p1'), isFalse);
        expect(n.state.numbers['p2'], 10);
      },
    );

    test(
      'setNumber : un titulaire qui prend le numéro d\'un remplaçant le lui '
      'retire et le sort du bloc « Remplaçants »',
      () {
        final n = CompositionDraftNotifier()
          ..setNumber('p1', 10, isSubstitute: true)
          ..setNumber('p2', 10, isSubstitute: false);
        expect(n.state.numbers.containsKey('p1'), isFalse);
        expect(n.state.substituteIds, isNot(contains('p1')));
        expect(n.state.numbers['p2'], 10);
      },
    );

    test('setNumber marque/retire le statut remplaçant selon le pool', () {
      final n = CompositionDraftNotifier();
      n.setNumber('p1', 3, isSubstitute: true);
      expect(n.state.substituteIds, contains('p1'));
      n.setNumber('p1', 5, isSubstitute: false);
      expect(n.state.substituteIds, isNot(contains('p1')));
    });

    test('clearNumber retire le numéro et le statut remplaçant', () {
      final n = CompositionDraftNotifier()
        ..setNumber('p1', 9, isSubstitute: true);
      n.clearNumber('p1');
      expect(n.state.numbers.containsKey('p1'), isFalse);
      expect(n.state.substituteIds, isNot(contains('p1')));
    });

    test('toggleCaptain est exclusif et réversible', () {
      final n = CompositionDraftNotifier();
      n.toggleCaptain('p1');
      expect(n.state.captainId, 'p1');
      n.toggleCaptain('p2');
      expect(n.state.captainId, 'p2');
      n.toggleCaptain('p2');
      expect(n.state.captainId, isNull);
    });

    test('setFormation conserve numéros, capitaine et remplaçants', () {
      final n = CompositionDraftNotifier()
        ..setCount(11)
        ..setNumber('p1', 7, isSubstitute: false)
        ..toggleCaptain('p1')
        ..setNumber('p2', 2, isSubstitute: true);
      n.setFormation(standardFormations(11).first);
      expect(n.state.numbers['p1'], 7);
      expect(n.state.captainId, 'p1');
      expect(n.state.substituteIds, contains('p2'));
      expect(n.state.assignments, isEmpty); // les placements, eux, sont remis à zéro
    });

    test('setCount réinitialise tout', () {
      final n = CompositionDraftNotifier()
        ..setNumber('p1', 7, isSubstitute: false)
        ..toggleCaptain('p1');
      n.setCount(8);
      expect(n.state.numbers, isEmpty);
      expect(n.state.captainId, isNull);
      expect(n.state.substituteIds, isEmpty);
      expect(n.state.playerCount, 8);
    });
  });
}
