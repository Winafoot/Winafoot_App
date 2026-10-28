import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/live_match_providers.dart';

/// Après un remplacement, le terrain affiche le numéro du joueur entrant (celui qu'il avait), pas celui
/// du sortant.
void main() {
  test('le remplaçant numéroté garde son numéro sur le terrain', () {
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
        numbers: <String, int>{'p1': 1, 'p2': 9, 'p3': 3, 'pX': 7},
        substituteIds: <String>['pX'],
      ),
    );
    final LiveMatchNotifier n = LiveMatchNotifier()..start(match);
    n.substitute('p2', 'pX');
    final int slot = n.state!.assignments.indexOf('pX');
    expect(slot, 1);
    expect(n.state!.numbers['pX'], 7);
    expect(n.state!.numbers['p2'], 9);
  });
}
