import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/models/player.dart';
import 'package:wina/models/stat_catalog.dart';
import 'package:wina/services/stats_pdf_export.dart';

/// PDF du bilan individuel sur plusieurs pages : ~30 colonnes de
/// statistiques sur une seule largeur d'A4 étaient écrasées jusqu'à l'illisible.
/// Les colonnes sont désormais réparties en tranches de 10 au plus, une par
/// page, et les lignes sont celles de l'écran.
void main() {
  List<StatDef> suivies(Iterable<String> keys) => <StatDef>[
    for (final StatDef s in enabledStatsInCatalogOrder(keys))
      if (!s.bilanOnly) s,
  ];

  List<List<String>> cles(List<List<StatDef>> pages) => <List<String>>[
    for (final List<StatDef> p in pages) <String>[for (final StatDef s in p) s.key],
  ];

  group('splitStatsByPage', () {
    test('suit l\'ordre du catalogue, au plus 10 colonnes, catégories groupées', () {
      final List<List<StatDef>> pages = splitStatsByPage(
        suivies(defaultEnabledStatKeys()),
      );

      // 31 colonnes par défaut (27 saisies + 4 totaux calculés) : passes 4 +
      // efficacité 2 + tirs 4 = 10 ; offensives 3 + coups de pied arrêtés 4 +
      // fautes 3 = 10 ; gardien 4 + technique 3 = 7, et les duels (4) ne
      // rentrent pas dans les 3 places restantes : ils ouvrent la 4e page
      // au lieu d'être coupés.
      expect(cles(pages), <List<String>>[
        <String>[
          'passesReussies',
          'passesManquees',
          'totalPasses',
          'passesProfondeur',
          'interceptions',
          'recuperations',
          'tirsCadres',
          'tirsNonCadres',
          'tirsBloques',
          'totalTirs',
        ],
        <String>[
          'centresReussis',
          'centresRates',
          'nombreCentres',
          'coupsFrancsCrees',
          'coupsFrancsSubis',
          'penaltysCrees',
          'nombreTouches',
          'fautesCommises',
          'fautesSubies',
          'cartonsJaunes',
        ],
        <String>[
          'tirsSubisHors',
          'tirsSubisDans',
          'totalTirsSubis',
          'degagements',
          'controleReussi',
          'controleManque',
          'pertesBallons',
        ],
        <String>[
          'duelsOffGagnes',
          'duelsOffPerdus',
          'duelsDefGagnes',
          'duelsDefPerdus',
        ],
      ]);
    });

    test('une catégorie qui tient sur une page n\'est pas coupée', () {
      // passes 4 + efficacité 2 = 6 ; « offensives » (5) ne rentre pas dans
      // les 4 places restantes : elles ouvrent la page suivante au lieu de se
      // scinder.
      final List<List<StatDef>> pages = splitStatsByPage(
        suivies(<String>[
          for (final StatDef s in kStatCatalog)
            if (<StatCategory>[
              StatCategory.passes,
              StatCategory.efficacite,
              StatCategory.offensives,
            ].contains(s.category))
              s.key,
        ]),
      );

      expect(pages.map((List<StatDef> p) => p.length), <int>[6, 5]);
      expect(pages[1].map((StatDef s) => s.category).toSet(), <StatCategory>{
        StatCategory.offensives,
      });
    });

    // Aucun thème du catalogue réel ne dépasse 10 stats (le plus gros en a 6) :
    // la branche « coupe un thème » se teste sur une liste synthétique.
    test('une catégorie de plus de 10 stats est coupée par tranches de 10', () {
      const int n = 12;
      final List<List<StatDef>> pages = splitStatsByPage(<StatDef>[
        for (int i = 0; i < n; i++)
          StatDef('s$i', 'Stat $i', category: StatCategory.passes),
      ]);

      expect(n, greaterThan(kStatsPerPage));
      expect(pages.first.length, kStatsPerPage);
      expect(pages.map((List<StatDef> p) => p.length).reduce((a, b) => a + b), n);
      expect(pages.every((List<StatDef> p) => p.length <= kStatsPerPage), isTrue);
    });

    test('aucune stat perdue ni dupliquée, ordre conservé (catalogue complet)', () {
      final List<StatDef> toutes = suivies(<String>[
        for (final StatDef s in kStatCatalog) s.key,
      ]);
      final List<List<StatDef>> pages = splitStatsByPage(toutes);

      expect(
        pages.expand((List<StatDef> p) => p).map((StatDef s) => s.key).toList(),
        toutes.map((StatDef s) => s.key).toList(),
      );
      expect(pages.every((List<StatDef> p) => p.length <= kStatsPerPage), isTrue);
      expect(pages.every((List<StatDef> p) => p.isNotEmpty), isTrue);
    });

    test('aucune stat : aucune page', () {
      expect(splitStatsByPage(const <StatDef>[]), isEmpty);
    });
  });

  // 11 titulaires (1-4-4-2) + 5 remplaçants. Les numéros de la composition ne
  // sont PAS « index d'emplacement + 1 » (p1 porte le 30, le remplaçant p12 le
  // 17, p16 n'en a aucun).
  final List<String> ids = <String>[for (int i = 1; i <= 16; i++) 'p$i'];
  final GameMatch match = GameMatch(
    composition: MatchComposition(
      formationLabel: '4-4-2',
      playerCount: 11,
      slots: const <FormationSlot>[
        FormationSlot(role: PlayerPosition.gardien, x: 0.5, y: 0.9),
        FormationSlot(role: PlayerPosition.defenseur, x: 0.2, y: 0.7),
        FormationSlot(role: PlayerPosition.defenseur, x: 0.4, y: 0.7),
        FormationSlot(role: PlayerPosition.defenseur, x: 0.6, y: 0.7),
        FormationSlot(role: PlayerPosition.defenseur, x: 0.8, y: 0.7),
        FormationSlot(role: PlayerPosition.milieu, x: 0.2, y: 0.5),
        FormationSlot(role: PlayerPosition.milieu, x: 0.4, y: 0.5),
        FormationSlot(role: PlayerPosition.milieu, x: 0.6, y: 0.5),
        FormationSlot(role: PlayerPosition.milieu, x: 0.8, y: 0.5),
        FormationSlot(role: PlayerPosition.attaquant, x: 0.4, y: 0.2),
        FormationSlot(role: PlayerPosition.attaquant, x: 0.6, y: 0.2),
      ],
      assignments: ids.take(11).toList(),
      substituteIds: ids.skip(11).toList(),
      numbers: const <String, int>{'p1': 30, 'p12': 17},
    ),
    // Défaut (31 colonnes suivies) + 2 stats activées après coup, en fin de
    // liste comme le fait l'écran de paramétrage : 33 colonnes suivies.
    enabledStatKeys: <String>[
      ...defaultEnabledStatKeys(),
      'butsMarques',
      'passesDecisives',
    ],
    playerStats: <String, Map<String, int>>{
      for (final String id in ids)
        id: <String, int>{'butsMarques': 1, 'interceptions': 3},
    },
  );
  final Map<String, Player> byId = <String, Player>{
    for (final String id in ids)
      id: Player(
        id: id,
        firstName: 'Joueur',
        lastName: id,
        strongFoot: StrongFoot.droit,
        position: PlayerPosition.milieu,
      ),
  };

  test('les lignes du PDF sont celles de l\'écran : remplaçants et numéros', () {
    final List<({int? number, Player player})> rows = bilanIndividuelRows(
      LiveMatch.fromFinished(match),
      byId,
    );

    // Titulaires par poste puis remplaçants (p12 → p16), tous présents.
    expect(rows.map((e) => e.player.id), ids);
    // Numéro de la composition (pas l'index d'emplacement + 1)…
    expect(rows.first.number, 30);
    expect(rows[11].number, 17);
    // …repli « index + 1 » pour un titulaire sans numéro, aucun pour un
    // remplaçant sans numéro.
    expect(rows[1].number, 2);
    expect(rows[15].number, isNull);
  });

  test('34 stats × 16 joueurs : le PDF fait plusieurs pages', () async {
    // 33 colonnes de saisie ou de total + « Réussite de passes » (en %, qui a
    // sa colonne depuis que le bilan individuel l'affiche).
    expect(enabledStatsInCatalogOrder(match.enabledStatKeys), hasLength(34));
    final doc = buildBilanIndividuelDocument(
      match: match,
      byId: byId,
      title: 'Bilan individuel',
    );
    final List<int> bytes = await doc.save();

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    // 34 colonnes ⇒ 5 tranches de 10 au plus, thèmes entiers : avec le %,
    // passes + efficacité + tirs (11 colonnes) ne tiennent plus sur une page.
    expect(doc.document.pdfPageList.pages, hasLength(5));
  });

  // Poppins est plus large que le Helvetica sur lequel les colonnes avaient été
  // calées : « Dégagements » se coupait en « Dégagement » / « s ». Le PDF coupe
  // un mot qui ne tient pas dans la colonne (67 pt moins 2 × 2 pt de marge) ; on
  // mesure donc le plus long mot de chaque libellé, avec la vraie police.
  test('aucun mot d\'en-tête de colonne ne se coupe en Poppins gras', () {
    final PdfTtfFont gras = PdfTtfFont(
      PdfDocument(),
      ByteData.sublistView(File('assets/fonts/Poppins-Bold.ttf').readAsBytesSync()),
    );
    double largeur(String mot) =>
        (gras.stringMetrics(mot) * kStatHeaderFontSize).width;

    final Map<String, double> trop = <String, double>{
      for (final StatDef s in kStatCatalog)
        for (final String mot in s.label.split(' '))
          if (largeur(mot) > kStatWidth - 4) mot: largeur(mot),
    };

    expect(trop, isEmpty);
  });

  test('effectif vide : une seule page, pas une par tranche', () async {
    final doc = buildBilanIndividuelDocument(
      match: match,
      byId: const <String, Player>{},
      title: 'Bilan individuel',
    );
    await doc.save();

    expect(doc.document.pdfPageList.pages, hasLength(1));
  });
}
