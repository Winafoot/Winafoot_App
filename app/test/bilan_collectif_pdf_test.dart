import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_period.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/services/stats_pdf_export.dart';

/// PDF du « Bilan collectif » : A4 portrait, la seule période affichée à
/// l'écran (exporter la 1ère mi-temps ne doit pas embarquer la 2ème ni le
/// Total). Construit en Dart pur, sans partage.
void main() {
  // Poppins chargé comme dans l'export réel (assets de l'app) : le Helvetica
  // par défaut ne dessine ni « — » ni « ’ ».
  late pw.ThemeData theme;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    theme = await poppinsPdfTheme();
  });

  /// Match découpé : 1re mi-temps = [premiere], total = [total] (la 2e s'en
  /// déduit), toutes les stats de [keys] suivies.
  GameMatch decoupe(
    List<String> keys, {
    int premiere = 3,
    int total = 8,
    int half = 2,
  }) => GameMatch(
    opponent: const MatchOpponent(name: 'Villemoisson'),
    status: MatchStatus.finished,
    half: half,
    enabledStatKeys: keys,
    firstHalfStatKeys: keys,
    firstHalfStats: <String, Map<String, int>>{
      'p1': <String, int>{for (final String k in keys) k: premiere},
    },
    playerStats: <String, Map<String, int>>{
      'p1': <String, int>{for (final String k in keys) k: total},
    },
  );

  Future<int> pages(
    GameMatch match, [
    MatchPeriod period = MatchPeriod.total,
  ]) async {
    final doc = buildBilanCollectifDocument(
      match: match,
      period: period,
      ownTeam: 'Vert le grand',
      opponent: 'Villemoisson',
      theme: theme,
    );
    final List<int> bytes = await doc.save();
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    return doc.document.pdfPageList.pages.length;
  }

  test('match découpé : chaque période exporte sa seule page', () async {
    for (final MatchPeriod p in MatchPeriod.values) {
      expect(
        await pages(decoupe(defaultEnabledStatKeys()), p),
        1,
        reason: '$p',
      );
    }
  });

  test('match ancien sans découpage : le Total seul, une page', () async {
    const GameMatch ancien = GameMatch(
      enabledStatKeys: <String>['butsMarques', 'passesReussies'],
      playerStats: <String, Map<String, int>>{
        'p1': <String, int>{'butsMarques': 2, 'passesReussies': 9},
      },
    );

    expect(await pages(ancien), 1);
  });

  test(
    '2e mi-temps non jouée : son export se construit, une page',
    () async {
      expect(
        await pages(
          decoupe(<String>['butsMarques'], total: 3, half: 1),
          MatchPeriod.secondHalf,
        ),
        1,
      );
    },
  );

  // Les 42 stats suivies : le pire cas tient encore sur une seule page
  // (lignes compactes, polices à 10 et 11 pt, jamais sous 9).
  test('42 stats suivies : une seule page par export', () async {
    final List<String> toutes = <String>[
      for (final StatDef s in kStatCatalog) s.key,
    ];

    for (final MatchPeriod p in MatchPeriod.values) {
      expect(await pages(decoupe(toutes), p), 1, reason: '$p');
    }
  });

  test('aucune stat suivie : le document se construit quand même', () async {
    expect(await pages(decoupe(const <String>[], premiere: 0, total: 0)), 1);
  });
}
