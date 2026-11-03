import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/providers/match_providers.dart';

ProviderContainer _container(List<GameMatch> matches) {
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[
      finishedMatchesProvider.overrideWith(
        (ref) => Stream<List<GameMatch>>.value(matches),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  final String toggleA = kStatToggles[0].key;
  final String toggleB = kStatToggles[1].key;
  final String calculated =
      kStatCatalog.firstWhere((StatDef s) => s.isCalculated).key;

  test('aucun match joué : pas de point de départ, le paramétrage prend les 19 de base', () async {
    final ProviderContainer c = _container(const <GameMatch>[]);
    await c.read(finishedMatchesProvider.future);

    expect(c.read(lastMatchStatKeysProvider), isNull);
    expect(defaultEnabledStatKeys(), hasLength(19));
  });

  test('reprend les statistiques du dernier match, bascules seules', () async {
    // Le flux est trié du plus récent au plus ancien : le premier est le dernier match joué.
    final ProviderContainer c = _container(<GameMatch>[
      GameMatch(enabledStatKeys: <String>[toggleA, calculated, toggleB]),
      GameMatch(enabledStatKeys: <String>[toggleB]),
    ]);
    await c.read(finishedMatchesProvider.future);

    expect(c.read(lastMatchStatKeysProvider), <String>[toggleA, toggleB]);
  });

  test('dernier match sans statistique reconnue : retour aux statistiques par défaut', () async {
    final ProviderContainer c = _container(<GameMatch>[
      GameMatch(enabledStatKeys: <String>[calculated, 'cle-inconnue']),
    ]);
    await c.read(finishedMatchesProvider.future);

    expect(c.read(lastMatchStatKeysProvider), isNull);
  });
}
