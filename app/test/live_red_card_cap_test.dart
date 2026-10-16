import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/providers/live_match_providers.dart';

void main() {
  group('Plafonds de cartons', () {
    LiveMatchNotifier seeded() =>
        LiveMatchNotifier()
          ..start(const GameMatch())
          ..selectPlayer('p1');

    void red(LiveMatchNotifier n, int delta) => n.bump(
      statKey: 'cartonsRouges',
      statLabel: 'Carton rouge',
      playerName: 'X',
      delta: delta,
    );

    test(
      'deux « + » : la valeur reste à 1 et une seule ligne est journalisée',
      () {
        final LiveMatchNotifier n = seeded();
        red(n, 1);
        red(n, 1);
        expect(n.state!.statValue('p1', 'cartonsRouges'), 1);
        expect(n.state!.events.length, 1);
      },
    );

    test('le « − » redescend à 0', () {
      final LiveMatchNotifier n = seeded();
      red(n, 1);
      red(n, -1);
      expect(n.state!.statValue('p1', 'cartonsRouges'), 0);
    });

    test('le rejeu après suppression d\'événement reste plafonné', () {
      final LiveMatchNotifier n = seeded();
      red(n, 1);
      red(n, -1);
      red(n, 1);
      // Retire le « −1 » : le journal rejoué vaut « +1 puis +1 ».
      n.removeEvent(1);
      expect(n.state!.statValue('p1', 'cartonsRouges'), 1);
    });

    test('trois « + » sur un jaune : la valeur reste à 2', () {
      final LiveMatchNotifier n = seeded();
      for (int i = 0; i < 3; i++) {
        n.bump(
          statKey: 'cartonsJaunes',
          statLabel: 'Cartons jaunes',
          playerName: 'X',
          delta: 1,
        );
      }
      expect(n.state!.statValue('p1', 'cartonsJaunes'), 2);
      // Le 3e tap ne doit journaliser aucune ligne fantôme : c'est la sortie
      // anticipée de `bump`, avant le clamp, qui est vérifiée ici.
      expect(n.state!.events.length, 2);
    });

    test('les autres statistiques gardent le plafond générique', () {
      final LiveMatchNotifier n = seeded();
      for (int i = 0; i < 3; i++) {
        n.bump(
          statKey: 'fautesCommises',
          statLabel: 'Fautes commises',
          playerName: 'X',
          delta: 1,
        );
      }
      expect(n.state!.statValue('p1', 'fautesCommises'), 3);
    });
  });
}
