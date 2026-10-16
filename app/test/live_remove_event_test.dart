import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/live_match_providers.dart';

void main() {
  group('LiveMatchNotifier.removeEvent', () {
    LiveMatchNotifier seeded() {
      final GameMatch match = const GameMatch().copyWith(
        composition: const MatchComposition(
          formationLabel: '1-1-1',
          playerCount: 3,
          slots: <FormationSlot>[
            FormationSlot(role: PlayerPosition.gardien, x: 0.5, y: 0.9),
            FormationSlot(role: PlayerPosition.defenseur, x: 0.5, y: 0.6),
            FormationSlot(role: PlayerPosition.attaquant, x: 0.5, y: 0.2),
          ],
          assignments: <String?>['p1', 'p2', 'p3'],
        ),
        enabledStatKeys: const <String>['butsMarques'],
      );
      return LiveMatchNotifier()..start(match);
    }

    void goal(LiveMatchNotifier n, int delta) => n.bump(
      statKey: 'butsMarques',
      statLabel: 'Buts marqués',
      playerName: 'X',
      delta: delta,
    );

    test('défait la stat du bon joueur et le score, sans nouvelle ligne', () {
      final LiveMatchNotifier n = seeded();
      n.selectPlayer('p2');
      goal(n, 1);
      n.selectPlayer('p3');
      goal(n, 1);

      // L'événement le plus récent (celui de p3) est en tête de liste.
      n.removeEvent(0);

      expect(n.state!.statValue('p3', 'butsMarques'), 0);
      expect(n.state!.statValue('p2', 'butsMarques'), 1);
      expect(n.state!.scoreUs, 1);
      expect(n.state!.events.length, 1);
    });

    test('stat déjà ramenée à zéro : le retrait ne passe pas sous zéro', () {
      final LiveMatchNotifier n = seeded();
      n.selectPlayer('p2');
      goal(n, 1);
      goal(n, -1);

      // Retire le « +1 » (en bas de pile) alors que la stat est déjà à 0.
      n.removeEvent(1);

      expect(n.state!.statValue('p2', 'butsMarques'), 0);
      expect(n.state!.scoreUs, 0);
      expect(n.state!.events.length, 1);

      // Puis le « -1 » restant : un journal vide ne peut pas affirmer un but.
      n.removeEvent(0);

      expect(n.state!.events, isEmpty);
      expect(n.state!.statValue('p2', 'butsMarques'), 0);
      expect(n.state!.scoreUs, 0);
    });

    test('index hors bornes → aucun changement', () {
      final LiveMatchNotifier n = seeded();
      n.selectPlayer('p2');
      goal(n, 1);

      n.removeEvent(-1);
      n.removeEvent(1);

      expect(n.state!.statValue('p2', 'butsMarques'), 1);
      expect(n.state!.scoreUs, 1);
      expect(n.state!.events.length, 1);
    });
  });
}
