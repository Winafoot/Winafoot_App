import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wina/data/search/algolia_client.dart';
import 'package:wina/data/search/search_key.dart';

const SearchKey _key = SearchKey(
  appId: 'APPTEST',
  apiKey: 'cle-factice-pour-test',
  ttlSeconds: 3600,
  compositionsIndex: 'idx_compo',
  matchesIndex: 'idx_match',
);

AlgoliaClient _client(
  Future<http.Response> Function(http.Request) handler, {
  Duration timeout = const Duration(seconds: 3),
}) => AlgoliaClient(MockClient(handler), timeout: timeout);

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: <String, String>{'content-type': 'application/json'},
);

void main() {
  group('requête', () {
    test("POST sur l'hôte DSN, clé en en-tête et jamais dans l'URL", () async {
      late http.Request seen;
      final AlgoliaClient client = _client((http.Request r) async {
        seen = r;
        return _json(<String, Object>{'hits': <Object>[]});
      });

      await client.search(_key, 'idx_compo', 'attaque');

      expect(seen.method, 'POST');
      expect(
        seen.url.toString(),
        'https://apptest-dsn.algolia.net/1/indexes/idx_compo/query',
      );
      expect(seen.headers['X-Algolia-Application-Id'], 'APPTEST');
      expect(seen.headers['X-Algolia-API-Key'], 'cle-factice-pour-test');
      expect(seen.headers['content-type'], contains('application/json'));
      expect(seen.url.toString(), isNot(contains('cle-factice')));
    });

    test('corps JSON plat exact', () async {
      late http.Request seen;
      final AlgoliaClient client = _client((http.Request r) async {
        seen = r;
        return _json(<String, Object>{'hits': <Object>[]});
      });

      await client.search(_key, 'idx_match', 'villemoisson');

      expect(jsonDecode(seen.body), <String, Object>{
        'query': 'villemoisson',
        'hitsPerPage': 100,
        'attributesToRetrieve': <String>['docId'],
        'attributesToHighlight': <String>[],
        'analytics': false,
      });
    });
  });

  group('réponse', () {
    test('extrait les docId des hits, ignore les entrées invalides', () async {
      final AlgoliaClient client = _client(
        (_) async => _json(<String, Object>{
          'hits': <Object>[
            <String, Object>{'docId': 'a', 'objectID': 'x1'},
            <String, Object>{'docId': 'b'},
            <String, Object>{'objectID': 'sans-docid'},
            <String, Object>{'docId': 3},
            'pas-un-objet',
          ],
        }),
      );

      final AlgoliaReply reply = await client.search(_key, 'i', 'q');

      expect(reply.ids, <String>{'a', 'b'});
      expect(reply.authRejected, isFalse);
    });

    test('200 sans aucun hit : ensemble vide, pas null', () async {
      final AlgoliaClient client = _client(
        (_) async => _json(<String, Object>{'hits': <Object>[]}),
      );

      final AlgoliaReply reply = await client.search(_key, 'i', 'q');

      expect(reply.ids, isNotNull);
      expect(reply.ids, isEmpty);
    });

    test('non-2xx → null (404, 429, 500)', () async {
      for (final int status in <int>[400, 404, 429, 500, 503]) {
        final AlgoliaClient client = _client(
          (_) async => _json(<String, Object>{'message': 'x'}, status),
        );
        final AlgoliaReply reply = await client.search(_key, 'i', 'q');
        expect(reply.ids, isNull, reason: '$status');
        expect(reply.authRejected, isFalse, reason: '$status');
      }
    });

    test('401 et 403 → null et authRejected', () async {
      for (final int status in <int>[401, 403]) {
        final AlgoliaClient client = _client(
          (_) async => _json(<String, Object>{'message': 'x'}, status),
        );
        final AlgoliaReply reply = await client.search(_key, 'i', 'q');
        expect(reply.ids, isNull, reason: '$status');
        expect(reply.authRejected, isTrue, reason: '$status');
      }
    });

    test('JSON invalide, forme inattendue → null', () async {
      for (final http.Response bad in <http.Response>[
        http.Response('<html>pas du json', 200),
        http.Response('[]', 200),
        http.Response('{"nbHits": 3}', 200),
        http.Response('{"hits": "non"}', 200),
      ]) {
        final AlgoliaClient client = _client((_) async => bad);
        expect((await client.search(_key, 'i', 'q')).ids, isNull);
      }
    });

    test('erreur réseau → null', () async {
      final AlgoliaClient client = _client(
        (_) async => throw http.ClientException('hors ligne'),
      );
      expect((await client.search(_key, 'i', 'q')).ids, isNull);
    });

    test('délai dépassé → null', () async {
      final AlgoliaClient client = _client((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return _json(<String, Object>{'hits': <Object>[]});
      }, timeout: const Duration(milliseconds: 30));

      expect((await client.search(_key, 'i', 'q')).ids, isNull);
    });
  });

  group('SearchKey.fromCallable', () {
    test('lit la réponse du callable', () {
      final SearchKey k = SearchKey.fromCallable(<String, Object>{
        'appId': 'A',
        'apiKey': 'k',
        'ttlSeconds': 3600,
        'indices': <String, String>{'compositions': 'c', 'matches': 'm'},
      });
      expect(k.appId, 'A');
      expect(k.apiKey, 'k');
      expect(k.ttlSeconds, 3600);
      expect(k.compositionsIndex, 'c');
      expect(k.matchesIndex, 'm');
    });

    test('réponse incomplète ou mal typée → FormatException', () {
      for (final Object? bad in <Object?>[
        null,
        'x',
        <String, Object>{'appId': 'A'},
        <String, Object>{
          'appId': 'A',
          'apiKey': '',
          'ttlSeconds': 3600,
          'indices': <String, String>{'compositions': 'c', 'matches': 'm'},
        },
        <String, Object>{
          'appId': 'A',
          'apiKey': 'k',
          'ttlSeconds': '3600',
          'indices': <String, String>{'compositions': 'c', 'matches': 'm'},
        },
        <String, Object>{
          'appId': 'A',
          'apiKey': 'k',
          'ttlSeconds': 3600,
          'indices': <String, String>{'compositions': 'c'},
        },
      ]) {
        expect(
          () => SearchKey.fromCallable(bad),
          throwsA(isA<FormatException>()),
          reason: '$bad',
        );
      }
    });
  });
}
