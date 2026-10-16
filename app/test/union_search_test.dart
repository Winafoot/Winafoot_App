import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wina/data/search/union_search.dart';

class _Item {
  const _Item(this.id, this.name);
  final String? id;
  final String name;
}

/// « requête:id1,id2 » : comparable par valeur (un Set ne l'est pas).
String _fmt(String q, Set<String> ids) =>
    '$q:${(ids.toList()..sort()).join(',')}';

void main() {
  group('unionVisible', () {
    const List<_Item> items = <_Item>[
      _Item('a', 'Attaque rapide'),
      _Item('b', 'Défense haute'),
      _Item('c', 'Contre-attaque'),
      _Item(null, 'Brouillon'),
    ];

    List<String> run(String q, Set<String> remote) =>
        unionVisible<_Item>(
          items: items,
          matchesLocally: (_Item i) => i.name.toLowerCase().contains(q),
          idOf: (_Item i) => i.id,
          remoteIds: remote,
        ).map((_Item i) => i.name).toList();

    test('réponse 200 avec hits vides : le résultat local reste', () {
      expect(run('attaque', const <String>{}), <String>[
        'Attaque rapide',
        'Contre-attaque',
      ]);
    });

    test('indisponible (aucun id) : local seul', () {
      expect(run('défense', const <String>{}), <String>['Défense haute']);
    });

    test('Algolia ajoute ce que le local ne trouve pas (faute de frappe)', () {
      expect(run('ataque', const <String>{'a'}), <String>['Attaque rapide']);
    });

    test('ne retire jamais un résultat local, ordre local conservé', () {
      // Local : b seul. Algolia : c et a. Ordre de la liste, pas de la réponse.
      expect(run('défense', const <String>{'c', 'a'}), <String>[
        'Attaque rapide',
        'Défense haute',
        'Contre-attaque',
      ]);
    });

    test('un id inconnu de la liste locale est ignoré', () {
      expect(run('défense', const <String>{'zzz'}), <String>['Défense haute']);
    });

    test('un élément sans id ne peut pas être ajouté par Algolia', () {
      expect(run('xx', const <String>{'null', ''}), isEmpty);
    });
  });

  group('UnionSearch', () {
    late List<String> changes;
    late List<String> asked;
    late Future<Set<String>?> Function(String) answer;
    late List<bool> pendings;
    late UnionSearch union;

    setUp(() {
      changes = <String>[];
      pendings = <bool>[];
      asked = <String>[];
      answer = (_) async => <String>{'x'};
      union = UnionSearch(
        search: (String q) {
          asked.add(q);
          return answer(q);
        },
        onChange: (String q, Set<String> ids) => changes.add(_fmt(q, ids)),
        onPending: pendings.add,
      );
    });

    const Duration debounce = Duration(milliseconds: 300);

    testWidgets('debounce 300 ms : une seule recherche pour une rafale', (
      WidgetTester tester,
    ) async {
      union.input('a');
      await tester.pump(const Duration(milliseconds: 100));
      union.input('ab');
      await tester.pump(const Duration(milliseconds: 299));
      expect(changes, isEmpty);
      expect(asked, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      expect(asked, <String>['ab']);
    });

    testWidgets('le local s\'affiche tout de suite, Algolia s\'ajoute ensuite', (
      WidgetTester tester,
    ) async {
      final Completer<Set<String>?> gate = Completer<Set<String>?>();
      answer = (_) => gate.future;

      union.input('ab');
      await tester.pump(debounce);
      // Local d'abord : requête appliquée, aucun id distant, réponse en attente.
      expect(changes, <String>['ab:']);

      gate.complete(<String>{'x'});
      await tester.pump();

      expect(changes.last, 'ab:x');
    });

    testWidgets('réponse périmée ignorée (frappe plus récente)', (
      WidgetTester tester,
    ) async {
      final Completer<Set<String>?> first = Completer<Set<String>?>();
      final Completer<Set<String>?> second = Completer<Set<String>?>();
      answer = (String q) => q == 'ab' ? first.future : second.future;

      union.input('ab');
      await tester.pump(debounce);
      union.input('abc');
      await tester.pump(debounce);

      second.complete(<String>{'nouveau'});
      await tester.pump();
      first.complete(<String>{'perime'});
      await tester.pump();

      expect(changes.last, 'abc:nouveau');
      expect(changes.any((String c) => c.contains('perime')), isFalse);
    });

    testWidgets('nouvelle frappe : les ids de la précédente sont retirés', (
      WidgetTester tester,
    ) async {
      union.input('ab');
      await tester.pump(debounce);
      await tester.pump();
      expect(changes.last, 'ab:x');

      answer = (_) => Completer<Set<String>?>().future; // réponse en attente
      union.input('abc');
      await tester.pump(debounce);

      expect(changes.last, 'abc:');
    });

    testWidgets('indisponible (null) : repli silencieux sur le local', (
      WidgetTester tester,
    ) async {
      answer = (_) async => null;

      union.input('ab');
      await tester.pump(debounce);
      await tester.pump();

      expect(changes, <String>['ab:']);
    });

    testWidgets('exception : avalée, local seul', (WidgetTester tester) async {
      answer = (_) async => throw StateError('boum');

      union.input('ab');
      await tester.pump(debounce);
      await tester.pump();

      expect(changes, <String>['ab:']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('requête vide ou blanche : aucun appel', (
      WidgetTester tester,
    ) async {
      union.input('   ');
      await tester.pump(debounce);
      await tester.pump();

      expect(asked, isEmpty);
      expect(changes, <String>['   :']);
    });

    testWidgets('clear : annule la frappe en attente et la réponse en vol', (
      WidgetTester tester,
    ) async {
      final Completer<Set<String>?> gate = Completer<Set<String>?>();
      answer = (_) => gate.future;

      union.input('ab');
      await tester.pump(debounce);
      union.input('abc'); // en attente de debounce
      union.clear();
      gate.complete(<String>{'tardif'});
      await tester.pump(debounce);
      await tester.pump();

      expect(asked, <String>['ab']);
      expect(changes.last, ':');
      expect(changes.any((String c) => c.contains('tardif')), isFalse);
    });

    testWidgets('dispose : plus aucun rappel', (WidgetTester tester) async {
      final Completer<Set<String>?> gate = Completer<Set<String>?>();
      answer = (_) => gate.future;

      union.input('ab');
      await tester.pump(debounce);
      final int before = changes.length;
      union.dispose();
      gate.complete(<String>{'x'});
      await tester.pump();
      union.input('zzz');
      await tester.pump(debounce);

      expect(changes, hasLength(before));
    });

    testWidgets('pending : vrai de l\'envoi à la réponse, faux ensuite', (
      WidgetTester tester,
    ) async {
      final Completer<Set<String>?> gate = Completer<Set<String>?>();
      answer = (_) => gate.future;

      union.input('ab');
      await tester.pump(debounce);
      expect(pendings, <bool>[true]);

      gate.complete(<String>{});
      await tester.pump();
      expect(pendings, <bool>[true, false]);
    });

    testWidgets('pending retombe sur null et sur exception', (
      WidgetTester tester,
    ) async {
      answer = (_) async => null;
      union.input('ab');
      await tester.pump(debounce);
      await tester.pump();
      expect(pendings, <bool>[true, false]);

      answer = (_) async => throw StateError('boum');
      union.input('abc');
      await tester.pump(debounce);
      await tester.pump();
      expect(pendings, <bool>[true, false, true, false]);
    });

    testWidgets('pending : requête vide ou effacement → jamais en attente', (
      WidgetTester tester,
    ) async {
      union.input('   ');
      await tester.pump(debounce);
      expect(pendings, isEmpty);

      answer = (_) => Completer<Set<String>?>().future;
      union.input('ab');
      await tester.pump(debounce);
      union.clear();
      expect(pendings, <bool>[true, false]);
    });

    testWidgets('pending : une réponse périmée ne le fait pas retomber', (
      WidgetTester tester,
    ) async {
      final Completer<Set<String>?> first = Completer<Set<String>?>();
      final Completer<Set<String>?> second = Completer<Set<String>?>();
      answer = (String q) => q == 'ab' ? first.future : second.future;

      union.input('ab');
      await tester.pump(debounce);
      union.input('abc');
      await tester.pump(debounce);
      first.complete(<String>{'perime'});
      await tester.pump();
      expect(pendings.last, isTrue); // « abc » attend toujours

      second.complete(<String>{});
      await tester.pump();
      expect(pendings.last, isFalse);
    });
  });
}
