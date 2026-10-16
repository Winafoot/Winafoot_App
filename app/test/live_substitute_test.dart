import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/live_match_providers.dart';

void main() {
  group('LiveMatchNotifier.substitute', () {
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
          substituteIds: <String>['pX'],
        ),
        enabledStatKeys: const <String>['butsMarques'],
      );
      return LiveMatchNotifier()..start(match);
    }

    test('échange le titulaire et sélectionne le remplaçant', () {
      final LiveMatchNotifier n = seeded();
      n.selectPlayer('p2');
      n.bump(
        statKey: 'butsMarques',
        statLabel: 'Buts',
        playerName: 'X',
        delta: 1,
      );
      n.substitute('p2', 'pX');
      expect(n.state!.assignments, <String?>['p1', 'pX', 'p3']);
      expect(n.state!.selectedPlayerId, 'pX');
    });

    test('conserve les statistiques du sortant', () {
      final LiveMatchNotifier n = seeded();
      n.selectPlayer('p2');
      n.bump(
        statKey: 'butsMarques',
        statLabel: 'Buts',
        playerName: 'X',
        delta: 1,
      );
      n.substitute('p2', 'pX');
      expect(n.state!.statValue('p2', 'butsMarques'), 1);
      expect(n.state!.statValue('pX', 'butsMarques'), 0);
    });

    test('sortant introuvable → aucun changement', () {
      final LiveMatchNotifier n = seeded();
      n.substitute('inconnu', 'pX');
      expect(n.state!.assignments, <String?>['p1', 'p2', 'p3']);
    });

    test('sortant == entrant → aucun changement', () {
      final LiveMatchNotifier n = seeded();
      n.substitute('p2', 'p2');
      expect(n.state!.assignments, <String?>['p1', 'p2', 'p3']);
    });

    test('un joueur remplacé peut rentrer à nouveau', () {
      final LiveMatchNotifier n = seeded();
      n.substitute('p2', 'pX');
      // Le sortant rejoint le banc, l'entrant le quitte.
      expect(n.state!.substituteIds, <String>['p2']);
      n.substitute('pX', 'p2');
      expect(n.state!.assignments, <String?>['p1', 'p2', 'p3']);
      expect(n.state!.substituteIds, <String>['pX']);
      expect(n.state!.selectedPlayerId, 'p2');
    });

    test('un sortant déjà présent au banc n\'y est pas dupliqué', () {
      // `p2` tient un emplacement ET figure au banc : un `add` nu le doublerait.
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
          substituteIds: <String>['pX', 'p2'],
        ),
      );
      final LiveMatchNotifier n = LiveMatchNotifier()..start(match);
      n.substitute('p2', 'pX');
      expect(n.state!.substituteIds, <String>['p2']);
    });
  });
}
