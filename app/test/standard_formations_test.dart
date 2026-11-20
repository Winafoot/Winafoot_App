import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/player.dart';

List<String> _labels(int count) =>
    standardFormations(count).map((Formation f) => f.label).toList();

void main() {
  group('compositions standards', () {
    test('chaque composition a autant d\'emplacements que de joueurs', () {
      for (final int count in <int>[5, 8, 11]) {
        for (final Formation f in standardFormations(count)) {
          expect(f.slots.length, count, reason: '${f.label} à $count');
          expect(f.playerCount, count, reason: f.label);
          expect(
            f.slots.where((s) => s.role == PlayerPosition.gardien).length,
            1,
            reason: '${f.label} : un seul gardien',
          );
        }
      }
    });

    test('aucun libellé en double par format', () {
      for (final int count in <int>[5, 8, 11]) {
        final List<String> labels = _labels(count);
        expect(labels.toSet().length, labels.length, reason: 'à $count');
      }
    });

    test('compositions retirées', () {
      expect(_labels(5), isNot(contains('2-0-2')));
      expect(_labels(5), isNot(contains('2-2-0')));
      expect(_labels(8), isNot(contains('2-2-2-2')));
      expect(_labels(8), isNot(contains('2-1-4')));
    });

    test('compositions ajoutées', () {
      expect(_labels(8), contains('3-1-2-1'));
      expect(
        _labels(11),
        containsAll(<String>[
          '5-2-2-1',
          '5-3-1-1',
          '3-2-4-1',
          '3-1-2-1-3',
          '3-3-1-3',
          '3-2-2-3',
        ]),
      );
    });

    test(
      'le repère des planches (y depuis son but) est inversé pour l\'app',
      () {
        final Formation f = standardFormations(
          11,
        ).firstWhere((Formation f) => f.label == '5-2-2-1');
        // GB à (50, 7) sur la planche : en bas du terrain de l'app.
        expect(f.slots.first.role, PlayerPosition.gardien);
        expect(f.slots.first.x, closeTo(0.5, 1e-9));
        expect(f.slots.first.y, closeTo(0.93, 1e-9));
        // Buteur à (50, 84) : en haut, près du but adverse.
        expect(f.slots.last.role, PlayerPosition.attaquant);
        expect(f.slots.last.y, closeTo(0.16, 1e-9));
      },
    );
  });
}
