// Génère les captures brutes des fiches App Store / Google Play avec les vrais écrans de l'app et une
// équipe fictive. Hors suite de tests normale (dossier `tool/`) :
//
//   flutter test tool/store_screenshots/capture_test.dart
//
// Sortie : build/store_screenshots/raw/<appareil>_<écran>.png
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/data/match_repository.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/composition_providers.dart';
import 'package:wina/providers/home_tab_provider.dart';
import 'package:wina/providers/live_match_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/view/page/gerer_equipe_placement_screen.dart';
import 'package:wina/view/page/bilan_collectif_screen.dart';
import 'package:wina/view/page/match_live_screen.dart';
import 'package:wina/view/page/mon_equipe_screen.dart';

import 'harness.dart';

const Jersey _kit = Jersey(name: 'Domicile', color: JerseyColorOption.rouge);

/// Quelques actions réparties sur l'effectif : l'écran de saisie et les bilans ne sont pas vides.
void _play(LiveMatchNotifier n) {
  void stat(String pid, String key, [int times = 1]) {
    for (int i = 0; i < times; i++) {
      n.bumpFor(
        playerId: pid,
        statKey: key,
        statLabel: key,
        playerName: pid,
        delta: 1,
      );
    }
  }

  stat('p0', 'butsSubis');
  stat('p8', 'butsMarques', 2);
  stat('p9', 'butsMarques');
  const Map<String, int> milieu = <String, int>{
    'passesReussies': 14,
    'passesManquees': 3,
    'recuperations': 6,
    'tirsCadres': 2,
    'tirsNonCadres': 1,
    'pertesDeBalle': 2,
    'controlesReussis': 9,
    'controlesManques': 1,
    'fautesCommises': 1,
    'fautesSubies': 3,
    'duelsGagnes': 5,
    'duelsPerdus': 2,
    'passesEnProfondeur': 4,
  };
  milieu.forEach((String k, int v) => stat('p5', k, v));
  for (final String pid in <String>['p1', 'p2', 'p3', 'p4', 'p6', 'p7']) {
    stat(pid, 'passesReussies', 8);
    stat(pid, 'passesManquees', 2);
    stat(pid, 'recuperations', 4);
    stat(pid, 'duelsGagnes', 3);
  }
  for (final String pid in <String>['p8', 'p9', 'p10']) {
    stat(pid, 'tirsCadres', 3);
    stat(pid, 'tirsNonCadres', 2);
    stat(pid, 'passesReussies', 6);
  }
}

LiveMatchNotifier _liveMatch({bool selectPlayer = true}) {
  final GameMatch match = const GameMatch().copyWith(
    composition: demoComposition(),
    enabledStatKeys: defaultEnabledStatKeys(),
    ownJersey: _kit,
  );
  final LiveMatchNotifier n = LiveMatchNotifier()..start(match);
  _play(n);
  // Un match bien avancé : 37e minute.
  for (int i = 0; i < 37 * 60 + 12; i++) {
    n.tick();
  }
  if (selectPlayer) n.selectPlayer('p5');
  return n;
}

GameMatch _finished(String id, String opponent, int us, int them, DateTime d) {
  final LiveMatchNotifier n = _liveMatch(selectPlayer: false);
  final GameMatch draft = const GameMatch().copyWith(
    composition: demoComposition(),
    enabledStatKeys: defaultEnabledStatKeys(),
    ownJersey: _kit,
    opponent: MatchOpponent(
      name: opponent,
      category: TeamCategory.u13,
      division: TeamDivision.d1,
      jerseyColor: JerseyColorOption.bleu,
    ),
  );
  return GameMatch.fromDoc(id, <String, dynamic>{
    ...draft.toJson(),
    ...MatchRepository.finishedPayload(n.state!),
    'scoreUs': us,
    'scoreThem': them,
    'elapsedSeconds': 60 * 60,
    'status': 'finished',
    'finishedAt': Timestamp.fromDate(d),
  });
}

List<Override> _common() {
  final List<GameMatch> matches = <GameMatch>[
    _finished('m1', 'AS Les Lions', 3, 1, DateTime(2026, 10, 25, 15)),
    _finished('m2', 'US Cheminots', 2, 2, DateTime(2026, 10, 18, 15)),
    _finished('m3', 'FC Bords de Seine', 4, 0, DateTime(2026, 10, 11, 15)),
    _finished('m4', 'Olympique du Val', 1, 2, DateTime(2026, 10, 4, 15)),
  ];
  return <Override>[
    playersStreamProvider.overrideWith(
      (Ref ref) => Stream<List<Player>>.value(demoPlayers),
    ),
    coachProfileProvider.overrideWith(
      (Ref ref) => Stream<CoachProfile>.value(demoCoach),
    ),
    jerseysProvider.overrideWith(
      (Ref ref) => Stream<List<Jersey>>.value(const <Jersey>[
        _kit,
        Jersey(name: 'Extérieur', color: JerseyColorOption.vert),
      ]),
    ),
    finishedMatchesProvider.overrideWith(
      (Ref ref) => Stream<List<GameMatch>>.value(matches),
    ),
    matchDraftProvider.overrideWith(
      (Ref ref) => MatchDraftNotifier()..setOwnJersey(_kit),
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadFonts);

  for (final Device device in <Device>[kTablet, kPhone]) {
    testWidgets('01 match en direct – ${device.name}', (WidgetTester tester) async {
      final LiveMatchNotifier live = _liveMatch();
      await shoot(
        tester,
        device: device,
        name: '01_match_direct',
        home: const MatchLiveScreen(resume: true),
        overrides: <Override>[
          ..._common(),
          liveMatchProvider.overrideWith((Ref ref) => live),
        ],
      );
    });

    testWidgets('02 placement – ${device.name}', (WidgetTester tester) async {
      await shoot(
        tester,
        device: device,
        name: '02_composition',
        home: const GererEquipePlacementScreen(),
        overrides: <Override>[
          ..._common(),
          compositionDraftProvider.overrideWith((Ref ref) {
            final CompositionDraftNotifier n = CompositionDraftNotifier()
              ..loadFromComposition(demoComposition(), maxSquad: 20);
            // Quelques joueurs restent à placer : l'écran montre le glisser-déposer.
            for (final int slot in <int>[2, 6, 9]) {
              n.unassign(slot);
            }
            return n;
          }),
        ],
      );
    });

    testWidgets('03 accueil – ${device.name}', (WidgetTester tester) async {
      await shoot(
        tester,
        device: device,
        name: '03_mon_equipe',
        home: const MonEquipeScreen(),
        overrides: _common(),
      );
    });

    testWidgets('04 statistiques – ${device.name}', (WidgetTester tester) async {
      await shoot(
        tester,
        device: device,
        name: '04_statistiques',
        home: const MonEquipeScreen(),
        overrides: <Override>[
          ..._common(),
          homeTabProvider.overrideWith((Ref ref) => 2),
        ],
        // Téléphone : la liste seule ne montre rien ; on ouvre le premier match (page détail).
        afterPump:
            device == kPhone
                ? (WidgetTester t) async {
                  await t.tap(find.text('AS Les Lions').first);
                  for (int i = 0; i < 6; i++) {
                    await t.runAsync(
                      () => Future<void>.delayed(const Duration(milliseconds: 250)),
                    );
                    await t.pump(const Duration(milliseconds: 150));
                  }
                }
                : null,
      );
    });

    testWidgets('05 bilan collectif – ${device.name}', (WidgetTester tester) async {
      await shoot(
        tester,
        device: device,
        name: '05_bilan_collectif',
        home: BilanCollectifScreen(
          match: _finished('m1', 'AS Les Lions', 3, 1, DateTime(2026, 10, 25, 15)),
        ),
        overrides: _common(),
      );
    });
  }
}
