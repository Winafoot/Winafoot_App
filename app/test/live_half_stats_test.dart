import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wina/data/match_repository.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/match_period.dart';
import 'package:wina/providers/live_match_providers.dart';

/// Découpage par mi-temps, PAR LE VRAI notifier (bump, beginHalfTime,
/// startSecondHalf, removeEvent) puis par le vrai chemin d'écriture
/// (`finishedPayload`) et de relecture (`GameMatch.fromDoc`).
void main() {
  LiveMatchNotifier seeded([
    List<String> keys = const <String>['tirsCadres'],
  ]) =>
      LiveMatchNotifier()
        ..start(GameMatch(enabledStatKeys: keys))
        ..selectPlayer('p1');

  void bump(
    LiveMatchNotifier n,
    String key,
    int delta, {
    String player = 'p1',
  }) {
    n.selectPlayer(player);
    n.bump(statKey: key, statLabel: key, playerName: 'X', delta: delta);
  }

  /// Mi-temps complète comme le fait l'interface : « Mi-temps » puis
  /// « Démarrer 2e mi-temps ».
  void halfTime(LiveMatchNotifier n) {
    n.beginHalfTime();
    n.startSecondHalf();
  }

  /// Le match tel que relu depuis Firestore après `finishMatch`.
  GameMatch persisted(LiveMatchNotifier n) =>
      GameMatch.fromDoc('m1', MatchRepository.finishedPayload(n.state!));

  int of(PeriodStats p, String key, {String player = 'p1'}) =>
      p.playerStats[player]?[key] ?? 0;

  /// 1re + 2e = total pour chaque joueur et chaque clé, aucune valeur négative.
  void expectSplitAddsUp(GameMatch m) {
    final PeriodStats first = m.statsFor(MatchPeriod.firstHalf);
    final PeriodStats second = m.statsFor(MatchPeriod.secondHalf);
    m.playerStats.forEach((String p, Map<String, int> stats) {
      stats.forEach((String key, int total) {
        final int a = of(first, key, player: p);
        final int b = of(second, key, player: p);
        expect(a, greaterThanOrEqualTo(0), reason: '1re $p/$key');
        expect(b, greaterThanOrEqualTo(0), reason: '2e $p/$key');
        expect(a + b, total, reason: '1re + 2e = total pour $p/$key');
      });
    });
  }

  group('MatchEvent.half', () {
    test('un événement porte la mi-temps en cours au moment de la saisie', () {
      final LiveMatchNotifier n = seeded();
      bump(n, 'tirsCadres', 1);
      n.beginHalfTime();
      // Coupure ouverte mais 2e mi-temps pas démarrée : toujours la 1re.
      expect(n.state!.half, 1);
      n.startSecondHalf();
      bump(n, 'tirsCadres', 1);

      expect(n.state!.events.map((MatchEvent e) => e.half).toList(), <int>[
        2,
        1,
      ]);
    });
  });

  group('répartition 1re / 2e mi-temps', () {
    test('saisies des deux mi-temps : 2 puis 1 donne 2 | 1 | 3', () {
      final LiveMatchNotifier n = seeded();
      bump(n, 'tirsCadres', 1);
      bump(n, 'tirsCadres', 1);
      halfTime(n);
      bump(n, 'tirsCadres', 1);

      final GameMatch m = persisted(n);
      expect(of(m.statsFor(MatchPeriod.firstHalf), 'tirsCadres'), 2);
      expect(of(m.statsFor(MatchPeriod.secondHalf), 'tirsCadres'), 1);
      expect(of(m.statsFor(MatchPeriod.total), 'tirsCadres'), 3);
      expect(m.half, 2);
      expectSplitAddsUp(m);
    });

    test('rien saisi en 1re mi-temps : tout est en 2e', () {
      final LiveMatchNotifier n = seeded();
      halfTime(n);
      bump(n, 'tirsCadres', 1);

      final GameMatch m = persisted(n);
      // Découpage connu (carte vide), pas un match ancien.
      expect(m.firstHalfStats, isNotNull);
      expect(m.statsFor(MatchPeriod.firstHalf).isAvailable, isTrue);
      expect(of(m.statsFor(MatchPeriod.firstHalf), 'tirsCadres'), 0);
      expect(of(m.statsFor(MatchPeriod.secondHalf), 'tirsCadres'), 1);
      expectSplitAddsUp(m);
    });

    test('deux joueurs : chacun a sa propre répartition', () {
      final LiveMatchNotifier n = seeded();
      bump(n, 'tirsCadres', 1, player: 'p1');
      bump(n, 'tirsCadres', 1, player: 'p2');
      halfTime(n);
      bump(n, 'tirsCadres', 1, player: 'p2');

      final GameMatch m = persisted(n);
      expect(of(m.statsFor(MatchPeriod.firstHalf), 'tirsCadres'), 1);
      expect(of(m.statsFor(MatchPeriod.secondHalf), 'tirsCadres'), 0);
      expect(
        of(m.statsFor(MatchPeriod.firstHalf), 'tirsCadres', player: 'p2'),
        1,
      );
      expect(
        of(m.statsFor(MatchPeriod.secondHalf), 'tirsCadres', player: 'p2'),
        1,
      );
      expectSplitAddsUp(m);
    });

    test('un événement de 1re mi-temps supprimé pendant la 2e : 1 | 1 | 2', () {
      final LiveMatchNotifier n = seeded();
      bump(n, 'tirsCadres', 1);
      bump(n, 'tirsCadres', 1);
      halfTime(n);
      bump(n, 'tirsCadres', 1);
      // Journal, du plus récent au plus ancien : [2e +1, 1re +1, 1re +1].
      n.removeEvent(2);

      final GameMatch m = persisted(n);
      expect(of(m.statsFor(MatchPeriod.total), 'tirsCadres'), 2);
      expect(of(m.statsFor(MatchPeriod.firstHalf), 'tirsCadres'), 1);
      expect(of(m.statsFor(MatchPeriod.secondHalf), 'tirsCadres'), 1);
      expectSplitAddsUp(m);
    });

    test('« − » en 2e sur une stat de 1re : règle nette, jamais négatif', () {
      final LiveMatchNotifier n = seeded();
      for (int i = 0; i < 3; i++) {
        bump(n, 'tirsCadres', 1);
      }
      halfTime(n);
      bump(n, 'tirsCadres', -1);

      // Total 2 : la 1re est amputée du « − », la 2e reste à 0 (pas −1).
      GameMatch m = persisted(n);
      expect(of(m.statsFor(MatchPeriod.total), 'tirsCadres'), 2);
      expect(of(m.statsFor(MatchPeriod.firstHalf), 'tirsCadres'), 2);
      expect(of(m.statsFor(MatchPeriod.secondHalf), 'tirsCadres'), 0);
      expectSplitAddsUp(m);

      // Puis deux « + » en 2e : total 4, la 1re redevient 3, la 2e vaut 1.
      bump(n, 'tirsCadres', 1);
      bump(n, 'tirsCadres', 1);
      m = persisted(n);
      expect(of(m.statsFor(MatchPeriod.total), 'tirsCadres'), 4);
      expect(of(m.statsFor(MatchPeriod.firstHalf), 'tirsCadres'), 3);
      expect(of(m.statsFor(MatchPeriod.secondHalf), 'tirsCadres'), 1);
      expectSplitAddsUp(m);
    });

    test(
      'le rejeu de la 1re mi-temps a les plafonds de removeEvent (plancher 0)',
      () {
        final LiveMatchNotifier n = seeded();
        bump(n, 'tirsCadres', 1);
        bump(n, 'tirsCadres', -1);
        bump(n, 'tirsCadres', 1);
        // Retire le premier « +1 » : le journal rejoué vaut « −1 (plancher 0)
        // puis +1 », soit 1 (et non 0 sans plancher), comme le total.
        n.removeEvent(2);

        final GameMatch m = persisted(n);
        expect(of(m.statsFor(MatchPeriod.total), 'tirsCadres'), 1);
        expect(of(m.statsFor(MatchPeriod.firstHalf), 'tirsCadres'), 1);
      },
    );

    test('« + » puis « − » en 2e sur une stat de 2e : tout retombe à 0', () {
      final LiveMatchNotifier n = seeded();
      halfTime(n);
      bump(n, 'tirsCadres', 1);
      bump(n, 'tirsCadres', -1);

      final GameMatch m = persisted(n);
      expect(of(m.statsFor(MatchPeriod.firstHalf), 'tirsCadres'), 0);
      expect(of(m.statsFor(MatchPeriod.secondHalf), 'tirsCadres'), 0);
      expectSplitAddsUp(m);
    });
  });

  group('match terminé sans passer par la mi-temps', () {
    test('tout en 1re mi-temps, la 2e « non jouée », le total juste', () {
      final LiveMatchNotifier n = seeded();
      bump(n, 'tirsCadres', 1);
      bump(n, 'tirsCadres', 1);

      final GameMatch m = persisted(n);
      expect(m.half, 1);
      expect(of(m.statsFor(MatchPeriod.firstHalf), 'tirsCadres'), 2);
      expect(m.statsFor(MatchPeriod.secondHalf).status, PeriodStatus.notPlayed);
      expect(m.statsFor(MatchPeriod.secondHalf).playerStats, isEmpty);
      expect(of(m.statsFor(MatchPeriod.total), 'tirsCadres'), 2);
    });

    test('fin depuis l\'écran de mi-temps (2e jamais démarrée) : idem', () {
      final LiveMatchNotifier n = seeded();
      bump(n, 'tirsCadres', 1);
      n.beginHalfTime();

      final GameMatch m = persisted(n);
      expect(m.half, 1);
      expect(m.statsFor(MatchPeriod.secondHalf).status, PeriodStatus.notPlayed);
      expect(of(m.statsFor(MatchPeriod.firstHalf), 'tirsCadres'), 1);
    });
  });

  group('cartons : plafonds par match, pas par mi-temps', () {
    test('un jaune en 1re + un en 2e = 2 ; le 3e est refusé', () {
      final LiveMatchNotifier n = seeded(const <String>['cartonsJaunes']);
      bump(n, 'cartonsJaunes', 1);
      halfTime(n);
      bump(n, 'cartonsJaunes', 1);
      bump(n, 'cartonsJaunes', 1);

      // Le 3e tap ne journalise rien : 2 événements seulement.
      expect(n.state!.events.length, 2);
      final GameMatch m = persisted(n);
      expect(of(m.statsFor(MatchPeriod.total), 'cartonsJaunes'), 2);
      expect(of(m.statsFor(MatchPeriod.firstHalf), 'cartonsJaunes'), 1);
      expect(of(m.statsFor(MatchPeriod.secondHalf), 'cartonsJaunes'), 1);
    });

    test('un rouge en 1re : la 2e mi-temps ne peut pas en ajouter un', () {
      final LiveMatchNotifier n = seeded(const <String>['cartonsRouges']);
      bump(n, 'cartonsRouges', 1);
      halfTime(n);
      bump(n, 'cartonsRouges', 1);

      expect(n.state!.events.length, 1);
      final GameMatch m = persisted(n);
      expect(of(m.statsFor(MatchPeriod.firstHalf), 'cartonsRouges'), 1);
      expect(of(m.statsFor(MatchPeriod.secondHalf), 'cartonsRouges'), 0);
    });

    test(
      'le rejeu de 1re mi-temps garde le plafond de 2 jaunes : 1 | 1 | 2',
      () {
        final LiveMatchNotifier n = seeded(const <String>['cartonsJaunes']);
        // Valeurs successives 1, 2, 1, 2, 1 (le journal ne compte que ce que le
        // plafond laisse passer).
        bump(n, 'cartonsJaunes', 1);
        bump(n, 'cartonsJaunes', 1);
        bump(n, 'cartonsJaunes', -1);
        bump(n, 'cartonsJaunes', 1);
        bump(n, 'cartonsJaunes', -1);
        // Retire le premier « − » (journal du plus récent au plus ancien : 2).
        // Rejeu : 1, 2, 3 -> plafonné à 2, puis 1 : un jaune à la pause. Sans le
        // plafond du rejeu (2 -> 999), la 1re mi-temps vaudrait 2 et la 2e 0.
        n.removeEvent(2);
        halfTime(n);
        bump(n, 'cartonsJaunes', 1);

        final GameMatch m = persisted(n);
        expect(of(m.statsFor(MatchPeriod.total), 'cartonsJaunes'), 2);
        expect(of(m.statsFor(MatchPeriod.firstHalf), 'cartonsJaunes'), 1);
        expect(of(m.statsFor(MatchPeriod.secondHalf), 'cartonsJaunes'), 1);
      },
    );

    test('jaune de 1re retiré en 2e : 0 | 0 | 0', () {
      final LiveMatchNotifier n = seeded(const <String>['cartonsJaunes']);
      bump(n, 'cartonsJaunes', 1);
      halfTime(n);
      bump(n, 'cartonsJaunes', -1);

      final GameMatch m = persisted(n);
      expect(of(m.statsFor(MatchPeriod.total), 'cartonsJaunes'), 0);
      expect(of(m.statsFor(MatchPeriod.firstHalf), 'cartonsJaunes'), 0);
      expect(of(m.statsFor(MatchPeriod.secondHalf), 'cartonsJaunes'), 0);
    });
  });

  group('stats suivies par période', () {
    test(
      'activée à la mi-temps : pas suivie en 1re, suivie en 2e et au total',
      () {
        final LiveMatchNotifier n = seeded(const <String>['tirsCadres']);
        bump(n, 'tirsCadres', 1);
        n.beginHalfTime();
        // « Modifier statistiques » pendant la coupure.
        n.setEnabledStats(const <String>['tirsCadres', 'passesReussies']);
        n.startSecondHalf();
        bump(n, 'passesReussies', 1);

        final GameMatch m = persisted(n);
        expect(m.statsFor(MatchPeriod.firstHalf).statKeys, <String>[
          'tirsCadres',
        ]);
        expect(m.statsFor(MatchPeriod.secondHalf).statKeys, <String>[
          'tirsCadres',
          'passesReussies',
        ]);
        expect(m.statsFor(MatchPeriod.total).statKeys, <String>[
          'tirsCadres',
          'passesReussies',
        ]);
      },
    );

    test('désactivée à la mi-temps : suivie en 1re et au total, pas en 2e', () {
      final LiveMatchNotifier n = seeded(const <String>[
        'tirsCadres',
        'fautesCommises',
      ]);
      bump(n, 'fautesCommises', 1);
      n.beginHalfTime();
      n.setEnabledStats(const <String>['tirsCadres']);
      n.startSecondHalf();

      final GameMatch m = persisted(n);
      expect(
        m.statsFor(MatchPeriod.firstHalf).statKeys,
        contains('fautesCommises'),
      );
      expect(m.statsFor(MatchPeriod.secondHalf).statKeys, <String>[
        'tirsCadres',
      ]);
      // La stat ne disparaît pas du total, avec sa valeur.
      expect(
        m.statsFor(MatchPeriod.total).statKeys,
        contains('fautesCommises'),
      );
      expect(of(m.statsFor(MatchPeriod.total), 'fautesCommises'), 1);
      expect(of(m.statsFor(MatchPeriod.firstHalf), 'fautesCommises'), 1);
    });

    test(
      'désactivée en pause de 2e mi-temps : ses valeurs restent en 2e et au total',
      () {
        final LiveMatchNotifier n = seeded(const <String>[
          'tirsCadres',
          'horsJeu',
        ]);
        bump(n, 'horsJeu', 1);
        halfTime(n);
        bump(n, 'horsJeu', 2);
        // Pause de 2e mi-temps, puis « Modifier statistiques » : horsJeu sort.
        n.togglePause();
        n.setEnabledStats(const <String>['tirsCadres']);

        final GameMatch m = persisted(n);
        expect(of(m.statsFor(MatchPeriod.firstHalf), 'horsJeu'), 1);
        expect(of(m.statsFor(MatchPeriod.secondHalf), 'horsJeu'), 2);
        expect(of(m.statsFor(MatchPeriod.total), 'horsJeu'), 3);
        expect(
          m.statsFor(MatchPeriod.secondHalf).statKeys,
          contains('horsJeu'),
        );
        expect(m.statsFor(MatchPeriod.total).statKeys, contains('horsJeu'));
        expectSplitAddsUp(m);
      },
    );

    test(
      'activée à la mi-temps puis désactivée en 2e : saisies visibles en 2e et au total',
      () {
        final LiveMatchNotifier n = seeded(const <String>['tirsCadres']);
        n.beginHalfTime();
        n.setEnabledStats(const <String>['tirsCadres', 'horsJeu']);
        n.startSecondHalf();
        bump(n, 'horsJeu', 1);
        bump(n, 'horsJeu', 1);
        n.setEnabledStats(const <String>['tirsCadres']);

        final GameMatch m = persisted(n);
        expect(m.statsFor(MatchPeriod.firstHalf).statKeys, <String>[
          'tirsCadres',
        ]);
        expect(
          m.statsFor(MatchPeriod.secondHalf).statKeys,
          contains('horsJeu'),
        );
        expect(m.statsFor(MatchPeriod.total).statKeys, contains('horsJeu'));
        expect(of(m.statsFor(MatchPeriod.secondHalf), 'horsJeu'), 2);
        expect(of(m.statsFor(MatchPeriod.total), 'horsJeu'), 2);
      },
    );

    test(
      'rouvrir la mi-temps ne remplace pas l\'instantané des stats suivies',
      () {
        final LiveMatchNotifier n = seeded(const <String>['tirsCadres']);
        n.beginHalfTime();
        n.setEnabledStats(const <String>['tirsCadres', 'horsJeu']);
        n.beginHalfTime();

        expect(n.state!.halfTimeStatKeys, <String>['tirsCadres']);
        expect(n.state!.firstHalfStatKeys, <String>['tirsCadres']);
      },
    );

    test('finishMatch enregistre la sélection en vigueur à la fin (B3)', () {
      final LiveMatchNotifier n = seeded(const <String>['tirsCadres']);
      n.beginHalfTime();
      n.setEnabledStats(const <String>['tirsCadres', 'passesReussies']);
      n.startSecondHalf();

      final Map<String, dynamic> payload = MatchRepository.finishedPayload(
        n.state!,
      );
      expect(payload['enabledStatKeys'], <String>[
        'tirsCadres',
        'passesReussies',
      ]);
      expect(payload['status'], 'finished');
      expect(payload['half'], 2);
    });

    test(
      'désactivée en pause de 1re mi-temps : ses valeurs restent visibles',
      () {
        final LiveMatchNotifier n = seeded(const <String>[
          'tirsCadres',
          'fautesCommises',
        ]);
        bump(n, 'fautesCommises', 1);
        // Pause (pas la mi-temps) puis désactivation, match fini sans mi-temps.
        n.setEnabledStats(const <String>['tirsCadres']);

        final GameMatch m = persisted(n);
        expect(
          m.statsFor(MatchPeriod.firstHalf).statKeys,
          contains('fautesCommises'),
        );
        expect(of(m.statsFor(MatchPeriod.firstHalf), 'fautesCommises'), 1);
      },
    );

    test(
      'sans beginHalfTime, startSecondHalf fige la sélection à la reprise',
      () {
        final LiveMatchNotifier n = seeded(const <String>['tirsCadres']);
        n.startSecondHalf();
        n.setEnabledStats(const <String>['tirsCadres', 'passesReussies']);

        expect(n.state!.firstHalfStatKeys, <String>['tirsCadres']);
      },
    );
  });

  group('invariants sur des séquences quelconques', () {
    test('1re + 2e = total et jamais négatif (saisies + suppressions)', () {
      const List<String> keys = <String>[
        'tirsCadres',
        'cartonsJaunes',
        'cartonsRouges',
        'butsMarques',
      ];
      final math.Random rnd = math.Random(20260930);
      final LiveMatchNotifier n = seeded(keys);

      for (int step = 0; step < 400; step++) {
        if (step == 180) halfTime(n);
        if (n.state!.events.isNotEmpty && rnd.nextInt(6) == 0) {
          n.removeEvent(rnd.nextInt(n.state!.events.length));
        } else {
          bump(
            n,
            keys[rnd.nextInt(keys.length)],
            rnd.nextBool() ? 1 : -1,
            player: 'p${1 + rnd.nextInt(3)}',
          );
        }
        expectSplitAddsUp(persisted(n));
      }
    });
  });

  group('GameMatch.statsFor : ancien document (sans découpage)', () {
    final GameMatch legacy = GameMatch.fromDoc('old', <String, dynamic>{
      'status': 'finished',
      'enabledStatKeys': <String>['tirsCadres'],
      'playerStats': <String, dynamic>{
        'p1': <String, dynamic>{'tirsCadres': 4},
      },
    });

    test('pas de découpage : firstHalfStats est null, pas une carte vide', () {
      expect(legacy.firstHalfStats, isNull);
      expect(legacy.firstHalfStatKeys, isEmpty);
    });

    test('1re et 2e mi-temps indisponibles, valeur explicite', () {
      for (final MatchPeriod p in <MatchPeriod>[
        MatchPeriod.firstHalf,
        MatchPeriod.secondHalf,
      ]) {
        final PeriodStats s = legacy.statsFor(p);
        expect(s.status, PeriodStatus.unavailable, reason: '$p');
        expect(s.isAvailable, isFalse);
      }
    });

    test('le total reste consultable', () {
      final PeriodStats s = legacy.statsFor(MatchPeriod.total);
      expect(s.isAvailable, isTrue);
      expect(of(s, 'tirsCadres'), 4);
      expect(s.statKeys, <String>['tirsCadres']);
    });
  });

  test('2e mi-temps jamais négative, même sur un document incohérent', () {
    // Document écrit à la main (1re > total) : la lecture se protège.
    final GameMatch m = GameMatch.fromDoc('bad', <String, dynamic>{
      'half': 2,
      'playerStats': <String, dynamic>{
        'p1': <String, dynamic>{'tirsCadres': 2},
      },
      'firstHalfStats': <String, dynamic>{
        'p1': <String, dynamic>{'tirsCadres': 3},
      },
    });
    expect(of(m.statsFor(MatchPeriod.secondHalf), 'tirsCadres'), 0);
  });

  group('GameMatch.fromDoc : écriture puis relecture', () {
    test('le découpage écrit par finishMatch est relu à l\'identique', () {
      final LiveMatchNotifier n = seeded(const <String>[
        'tirsCadres',
        'passesReussies',
      ]);
      bump(n, 'tirsCadres', 1);
      bump(n, 'passesReussies', 1);
      halfTime(n);
      bump(n, 'tirsCadres', 1);

      final GameMatch m = persisted(n);
      expect(m.half, 2);
      expect(m.firstHalfStats, <String, Map<String, int>>{
        'p1': <String, int>{'tirsCadres': 1, 'passesReussies': 1},
      });
      expect(m.firstHalfStatKeys, <String>['tirsCadres', 'passesReussies']);
      expect(m.playerStats, <String, Map<String, int>>{
        'p1': <String, int>{'tirsCadres': 2, 'passesReussies': 1},
      });
      expect(m.enabledStatKeys, <String>['tirsCadres', 'passesReussies']);
    });
  });
}
