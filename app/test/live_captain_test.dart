import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match_sync.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/live_match_providers.dart';

/// Le brassard du capitaine, attribué à la préparation, doit rester sur le maillot pendant tout le match.
void main() {
  const List<FormationSlot> slots = <FormationSlot>[
    FormationSlot(role: PlayerPosition.gardien, x: 0.5, y: 0.9),
    FormationSlot(role: PlayerPosition.attaquant, x: 0.5, y: 0.2),
  ];

  MatchComposition comp({String? captain}) => MatchComposition(
    formationLabel: '1-1',
    playerCount: 2,
    slots: slots,
    assignments: const <String?>['p1', 'p2'],
    captainId: captain,
  );

  LiveMatchNotifier started({String? captain}) =>
      LiveMatchNotifier()
        ..start(const GameMatch().copyWith(composition: comp(captain: captain)));

  test('le match en direct reprend le capitaine de la composition', () {
    expect(started(captain: 'p2').state!.captainId, 'p2');
    expect(started().state!.captainId, isNull);
  });

  test('« Modifier composition » garde ou retire le brassard selon la composition', () {
    final LiveMatchNotifier n = started(captain: 'p2');
    n.applyComposition(comp(captain: 'p1'));
    expect(n.state!.captainId, 'p1');
    n.applyComposition(comp());
    expect(n.state!.captainId, isNull);
  });

  test('le capitaine est publié pour l\'adjoint et relu à l\'identique', () {
    final Map<String, dynamic> json = LiveMatchSnapshot.toJson(
      started(captain: 'p2').state!,
      players: const <String, Player>{},
      kit: null,
      opponentName: '',
      matchId: null,
    );
    expect(json['captainId'], 'p2');
    expect(LiveMatchSnapshot.fromJson(json).live.captainId, 'p2');
  });
}
