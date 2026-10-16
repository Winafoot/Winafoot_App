import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/testing.dart';
import 'package:wina/data/search/search_key.dart';
import 'package:wina/data/search/search_service.dart';
import 'package:wina/providers/auth_providers.dart';
import 'package:wina/providers/search_providers.dart';

SearchKey _key(String apiKey, {int ttl = 3600}) => SearchKey(
  appId: 'APPTEST',
  apiKey: apiKey,
  ttlSeconds: ttl,
  compositionsIndex: 'idx_compo',
  matchesIndex: 'idx_match',
);

http.Response _hits(List<String> ids) => http.Response(
  jsonEncode(<String, Object>{
    'hits': <Object>[
      for (final String id in ids) <String, String>{'docId': id},
    ],
  }),
  200,
);

/// Banc d'essai : clé servie par un faux callable, réseau par un MockClient,
/// horloge monotone pilotée à la main.
class _Rig {
  _Rig({
    Future<SearchKey> Function(int call)? onFetch,
    http.Response Function(http.Request request)? onRequest,
    String? uid = 'coach-a',
  }) {
    final Future<SearchKey> Function(int) fetch =
        onFetch ?? (int call) async => _key('cle-$call');
    final http.Response Function(http.Request) respond =
        onRequest ?? (http.Request _) => _hits(<String>['d1']);
    service = SearchService(
      fetchKey: () => fetch(++fetchCalls),
      httpClient: MockClient((http.Request r) async {
        requests.add(r);
        return respond(r);
      }),
      clock: () => now,
    )..setUid(uid);
  }

  late final SearchService service;
  Duration now = Duration.zero;
  int fetchCalls = 0;
  final List<http.Request> requests = <http.Request>[];

  String get lastKey => requests.last.headers['X-Algolia-API-Key']!;
  Map<String, dynamic> get lastBody =>
      jsonDecode(requests.last.body) as Map<String, dynamic>;
}

void main() {
  group('normalisation', () {
    test('uniquement chiffres, tirets, espaces → chiffres seuls', () {
      expect(normalizeFormationQuery('4-3-3'), '433');
      expect(normalizeFormationQuery(' 4 3 3 '), '433');
      expect(normalizeFormationQuery('433'), '433');
      expect(normalizeFormationQuery('4-3'), '43');
    });

    test('dès qu\'une lettre apparaît, la saisie est gardée (rognée)', () {
      expect(normalizeFormationQuery('  Attaque 4-3 '), 'Attaque 4-3');
      expect(normalizeFormationQuery('4-3-3x'), '4-3-3x');
    });

    test('vide ou sans chiffre → vide', () {
      expect(normalizeFormationQuery(''), '');
      expect(normalizeFormationQuery('   '), '');
      expect(normalizeFormationQuery('- -'), '');
    });
  });

  group('recherche', () {
    test(
      'compositions : bon index, saisie avec lettres envoyée rognée',
      () async {
        final _Rig rig = _Rig();

        final Set<String>? ids = await rig.service.searchCompositions(
          ' attaque ',
        );

        expect(ids, <String>{'d1'});
        expect(rig.requests.single.url.path, '/1/indexes/idx_compo/query');
        expect(rig.lastBody['query'], 'attaque');
      },
    );

    test(
      'compositions : chiffres seuls → aucun appel (le local suffit)',
      () async {
        final _Rig rig = _Rig();

        expect(await rig.service.searchCompositions('433'), isNull);
        expect(await rig.service.searchCompositions('4-3-3'), isNull);
        expect(await rig.service.searchCompositions(' 4 3 '), isNull);

        expect(rig.fetchCalls, 0);
        expect(rig.requests, isEmpty);
      },
    );

    test('matchs : une saisie de chiffres part bien vers Algolia', () async {
      final _Rig rig = _Rig();

      expect(await rig.service.searchMatches('14'), <String>{'d1'});
      expect(rig.requests, hasLength(1));
    });

    test('matchs : bon index, saisie envoyée telle quelle (rognée)', () async {
      final _Rig rig = _Rig();

      await rig.service.searchMatches(' 14 10 ');

      expect(rig.requests.single.url.path, '/1/indexes/idx_match/query');
      expect(rig.lastBody['query'], '14 10');
    });

    test(
      'requête vide ou sans chiffre exploitable : aucun appel du tout',
      () async {
        final _Rig rig = _Rig();

        expect(await rig.service.searchCompositions(''), isNull);
        expect(await rig.service.searchCompositions('   '), isNull);
        expect(await rig.service.searchCompositions('- -'), isNull);
        expect(await rig.service.searchMatches('  '), isNull);

        expect(rig.fetchCalls, 0);
        expect(rig.requests, isEmpty);
      },
    );

    test('pas de session : aucun appel, résultat indisponible', () async {
      final _Rig rig = _Rig(uid: null);

      expect(await rig.service.searchCompositions('abc'), isNull);

      expect(rig.fetchCalls, 0);
      expect(rig.requests, isEmpty);
    });

    test('hits vides : ensemble vide (distinct de « indisponible »)', () async {
      final _Rig rig = _Rig(onRequest: (_) => _hits(<String>[]));
      expect(await rig.service.searchMatches('x'), isEmpty);
    });

    test('non-2xx → null', () async {
      final _Rig rig = _Rig(onRequest: (_) => http.Response('{}', 500));
      expect(await rig.service.searchMatches('x'), isNull);
    });
  });

  group('cache de clé', () {
    test('la clé est réutilisée tant qu\'elle n\'est pas à échéance', () async {
      final _Rig rig = _Rig();

      await rig.service.searchMatches('a');
      await rig.service.searchMatches('b');
      await rig.service.searchCompositions('c');

      expect(rig.fetchCalls, 1);
      expect(rig.requests, hasLength(3));
    });

    test('échéance = réception + ttlSeconds - 300 s', () async {
      final _Rig rig = _Rig();
      await rig.service.searchMatches('a');
      expect(rig.lastKey, 'cle-1');

      // 3299 s : la clé de 3600 s tient encore.
      rig.now = const Duration(seconds: 3299);
      await rig.service.searchMatches('b');
      expect(rig.fetchCalls, 1);

      // 3300 s : renouvelée.
      rig.now = const Duration(seconds: 3300);
      await rig.service.searchMatches('c');
      expect(rig.fetchCalls, 2);
      expect(rig.lastKey, 'cle-2');
    });

    test('l\'échéance suit le ttl reçu, pas une durée codée en dur', () async {
      final _Rig rig = _Rig(onFetch: (int n) async => _key('cle-$n', ttl: 900));
      await rig.service.searchMatches('a');

      rig.now = const Duration(seconds: 599);
      await rig.service.searchMatches('b');
      expect(rig.fetchCalls, 1);

      rig.now = const Duration(seconds: 600);
      await rig.service.searchMatches('c');
      expect(rig.fetchCalls, 2);
    });

    test(
      'l\'échéance part de la réception, pas du démarrage de l\'appel',
      () async {
        final Completer<SearchKey> gate = Completer<SearchKey>();
        final _Rig rig = _Rig(onFetch: (_) => gate.future);

        final Future<Set<String>?> pending = rig.service.searchMatches('a');
        await pumpEventQueue();
        rig.now = const Duration(seconds: 1000); // l'appel dure 1000 s
        gate.complete(_key('lente'));
        await pending;

        rig.now = const Duration(seconds: 1000 + 3299);
        await rig.service.searchMatches('b');
        expect(rig.fetchCalls, 1);
      },
    );

    test('un seul appel en vol pour des recherches simultanées', () async {
      final Completer<SearchKey> gate = Completer<SearchKey>();
      final _Rig rig = _Rig(onFetch: (_) => gate.future);

      final List<Future<Set<String>?>> all = <Future<Set<String>?>>[
        rig.service.searchMatches('a'),
        rig.service.searchCompositions('b'),
        rig.service.searchMatches('c'),
      ];
      await pumpEventQueue();
      expect(rig.fetchCalls, 1);

      gate.complete(_key('unique'));
      await Future.wait(all);

      expect(rig.fetchCalls, 1);
      expect(rig.requests, hasLength(3));
    });

    test(
      'changement d\'uid PENDANT l\'appel : la clé n\'est pas mise en cache',
      () async {
        final Completer<SearchKey> gate = Completer<SearchKey>();
        final _Rig rig = _Rig(
          onFetch: (int n) => n == 1 ? gate.future : Future.value(_key('de-b')),
        );

        final Future<Set<String>?> pending = rig.service.searchMatches('a');
        await pumpEventQueue();
        rig.service.setUid('coach-b');
        gate.complete(_key('de-a'));

        // La réponse de A est jetée : aucune requête n'est partie avec sa clé.
        expect(await pending, isNull);
        expect(rig.requests, isEmpty);

        // La session de B ne réutilise jamais la clé de A.
        await rig.service.searchMatches('b');
        expect(rig.fetchCalls, 2);
        expect(rig.lastKey, 'de-b');
      },
    );

    test('changement d\'uid : la clé en cache est jetée', () async {
      final _Rig rig = _Rig();
      await rig.service.searchMatches('a');

      rig.service.setUid('coach-b');
      await rig.service.searchMatches('b');

      expect(rig.fetchCalls, 2);
    });

    test('déconnexion : clé jetée, plus aucun appel', () async {
      final _Rig rig = _Rig();
      await rig.service.searchMatches('a');

      rig.service.setUid(null);
      expect(await rig.service.searchMatches('b'), isNull);

      expect(rig.fetchCalls, 1);
      expect(rig.requests, hasLength(1));
    });

    test(
      'callable en erreur → null, puis plus aucun appel pendant 5 min',
      () async {
        final _Rig rig = _Rig(
          onFetch: (int n) async {
            if (n == 1) throw StateError('callable HS');
            return _key('cle-$n');
          },
        );

        expect(await rig.service.searchMatches('a'), isNull);
        // Deux recherches de plus : le callable n'est pas rappelé, aucun réseau.
        expect(await rig.service.searchMatches('b'), isNull);
        expect(await rig.service.searchCompositions('abc'), isNull);
        expect(rig.fetchCalls, 1);
        expect(rig.requests, isEmpty);

        // 4 min 59 s : toujours en pause ; 5 min : reprise.
        rig.now = const Duration(minutes: 4, seconds: 59);
        expect(await rig.service.searchMatches('c'), isNull);
        expect(rig.fetchCalls, 1);

        rig.now = const Duration(minutes: 5);
        expect(await rig.service.searchMatches('d'), <String>{'d1'});
        expect(rig.fetchCalls, 2);
      },
    );

    test(
      'changement d\'uid : la pause après échec est remise à zéro',
      () async {
        final _Rig rig = _Rig(
          onFetch: (int n) async {
            if (n == 1) throw StateError('callable HS');
            return _key('cle-$n');
          },
        );
        expect(await rig.service.searchMatches('a'), isNull);

        rig.service.setUid('coach-b');

        expect(await rig.service.searchMatches('b'), <String>{'d1'});
        expect(rig.fetchCalls, 2);
      },
    );
  });

  group('rejet 401 / 403', () {
    http.Response rejectFirstKey(http.Request r) =>
        r.headers['X-Algolia-API-Key'] == 'cle-1'
            ? http.Response('{}', 403)
            : _hits(<String>['d9']);

    test('un seul renouvellement puis la recherche aboutit', () async {
      final _Rig rig = _Rig(onRequest: rejectFirstKey);

      final Set<String>? ids = await rig.service.searchMatches('a');

      expect(ids, <String>{'d9'});
      expect(rig.fetchCalls, 2);
      expect(rig.requests, hasLength(2));
      expect(rig.lastKey, 'cle-2');
    });

    test('nouveau rejet : abandon, pas de boucle', () async {
      final _Rig rig = _Rig(onRequest: (_) => http.Response('{}', 401));

      expect(await rig.service.searchMatches('a'), isNull);

      expect(rig.fetchCalls, 2);
      expect(rig.requests, hasLength(2));
    });

    test(
      'double rejet : plus aucun appel pendant 5 min, puis reprise',
      () async {
        final _Rig rig = _Rig(onRequest: (_) => http.Response('{}', 403));
        expect(await rig.service.searchMatches('a'), isNull);
        expect(rig.fetchCalls, 2);
        expect(rig.requests, hasLength(2));

        // Pause : ni callable ni requête Algolia (même avec la clé en cache).
        expect(await rig.service.searchMatches('b'), isNull);
        expect(await rig.service.searchCompositions('abc'), isNull);
        expect(rig.fetchCalls, 2);
        expect(rig.requests, hasLength(2));

        rig.now = const Duration(minutes: 5);
        expect(await rig.service.searchMatches('c'), isNull);
        expect(rig.fetchCalls, 4); // reprise : clé redemandée, puis renouvelée
      },
    );

    test('double rejet : changement d\'uid remet la pause à zéro', () async {
      final _Rig rig = _Rig(onRequest: (_) => http.Response('{}', 403));
      await rig.service.searchMatches('a');

      rig.service.setUid('coach-b');
      await rig.service.searchMatches('b');

      expect(rig.fetchCalls, 4);
    });

    test('la clé renouvelée sert aux recherches suivantes', () async {
      final _Rig rig = _Rig(onRequest: rejectFirstKey);
      await rig.service.searchMatches('a');

      await rig.service.searchMatches('b');

      expect(rig.fetchCalls, 2);
      expect(rig.lastKey, 'cle-2');
    });
  });

  group('searchServiceProvider', () {
    test(
      'se construit sans Firebase ni réseau (rien pendant le build)',
      () async {
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            authUidProvider.overrideWith((ref) => Stream<String?>.value(null)),
          ],
        );
        addTearDown(container.dispose);

        final SearchService service = container.read(searchServiceProvider);

        // Sans session et sans requête, aucun accès au callable (Firebase n'est
        // pas initialisé ici : un accès lèverait).
        expect(await service.searchMatches('abc'), isNull);
        expect(await service.searchMatches(''), isNull);
      },
    );

    test('le uid d\'auth est transmis au service (a → null → b)', () async {
      final StreamController<String?> auth = StreamController<String?>();
      addTearDown(auth.close);
      int fetchCalls = 0;
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          authUidProvider.overrideWith((ref) => auth.stream),
          searchKeyFetcherProvider.overrideWithValue(
            () async => _key('cle-${++fetchCalls}'),
          ),
          searchHttpClientProvider.overrideWithValue(
            MockClient((http.Request r) async => _hits(<String>['d1'])),
          ),
        ],
      );
      addTearDown(container.dispose);
      final SearchService service = container.read(searchServiceProvider);

      auth.add('a');
      await pumpEventQueue();
      expect(await service.searchMatches('x'), <String>{'d1'});
      expect(fetchCalls, 1);

      auth.add(null);
      await pumpEventQueue();
      expect(await service.searchMatches('x'), isNull);
      expect(fetchCalls, 1);

      auth.add('b');
      await pumpEventQueue();
      expect(await service.searchMatches('x'), <String>{'d1'});
      expect(fetchCalls, 2); // la clé de « a » n'est pas réutilisée
    });

    test(
      'avec une session, un callable en erreur → repli (null), pas de crash',
      () async {
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            authUidProvider.overrideWith(
              (ref) => Stream<String?>.value('coach-a'),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.listen(authUidProvider, (_, _) {});
        await container.read(authUidProvider.future);

        // Firebase non initialisé : le callable échoue, le service le contient.
        expect(
          await container.read(searchServiceProvider).searchMatches('abc'),
          isNull,
        );
      },
    );
  });
}
