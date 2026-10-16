import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/player.dart';

void main() {
  test('le plafond ferme la création à partir de kMaxSquadSize', () {
    expect(isSquadFull(0), isFalse);
    expect(isSquadFull(kMaxSquadSize - 1), isFalse);
    expect(isSquadFull(kMaxSquadSize), isTrue);
    // Des effectifs à 21 existent en base (créés avant le plafond) : l'ajout
    // est refusé, mais « 21 sur 20 » doit rester affichable.
    expect(isSquadFull(kMaxSquadSize + 1), isTrue);
  });

  test('le plafond suit la valeur transmise, pas la constante', () {
    // Le plafond d'un club vient de son format (teamFormat, cf.
    // team_format_test.dart), à défaut de app_config/config.max_players ;
    // kMaxSquadSize n'est que le repli hors ligne.
    expect(isSquadFull(20, max: 25), isFalse);
    expect(isSquadFull(25, max: 25), isTrue);
    expect(isSquadFull(5, max: 5), isTrue);
  });
}
