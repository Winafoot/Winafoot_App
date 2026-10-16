import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/player.dart';
import 'package:wina/view/page/detail_joueur_screen.dart';

const Player _seed = Player(
  id: 'p1',
  firstName: 'Edwin',
  lastName: 'Van der sar',
  strongFoot: StrongFoot.droit,
  position: PlayerPosition.gardien,
);

void main() {
  group('resolveCurrentPlayer', () {
    test('reprend la version à jour de l’effectif', () {
      final Player updated = _seed.copyWith(
        firstName: 'Edwinn',
        position: PlayerPosition.defenseur,
      );
      final Player current = resolveCurrentPlayer(<Player>[updated], _seed);
      expect(current.firstName, 'Edwinn');
      expect(current.position, PlayerPosition.defenseur);
    });

    test('retombe sur la graine si le joueur a été supprimé', () {
      expect(resolveCurrentPlayer(const <Player>[], _seed), _seed);
    });
  });
}
