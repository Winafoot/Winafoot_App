import 'package:core_kosmos/core_kosmos.dart' show AnalyticsController;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:wina/models/career_stats.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/match_period.dart';
import 'package:wina/models/player.dart';
import 'package:wina/models/stat_catalog.dart';

/// Export PDF des bilans de match. Construit un document puis ouvre la feuille
/// de partage / impression native du système (« Exporter en PDF »).

/// Document A4 paysage : titre répété en en-tête et « Page X / Y » en pied de
/// chaque page. [theme] fournit la police (Helvetica à défaut).
pw.Document _buildDocument(
  String title,
  List<pw.Widget> Function(pw.Context) content, {
  pw.ThemeData? theme,
}) {
  final pw.Document doc = pw.Document(theme: theme);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      header:
          (pw.Context context) => pw.Container(
            alignment: pw.Alignment.centerLeft,
            margin: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
      footer:
          (pw.Context context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              'Page ${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
      build: content,
    ),
  );
  return doc;
}

Future<void> _shareDocument({
  required pw.Document doc,
  required String filename,
  required String bilanType,
}) async {
  await Printing.sharePdf(bytes: await doc.save(), filename: filename);
  AnalyticsController.logEvent(
    'stats_pdf_exported',
    parameters: <String, Object>{'bilan_type': bilanType},
  );
}

/// Police des PDF de bilan : Poppins (celle de l'app, déjà embarquée). Le
/// Helvetica par défaut ne dessine que le latin-1 : un nom d'équipe ou de
/// joueur avec « ’ » ou « Œ », ou « — », y sortirait en carré vide.
Future<pw.ThemeData> poppinsPdfTheme() async => pw.ThemeData.withFont(
  base: pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-Regular.ttf')),
  bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-Bold.ttf')),
);

// Libellés de période du bilan collectif (mêmes mots que l'écran, dont les
// textes vivent dans fr-FR.json : le PDF, lui, ne passe pas par easy_localization).
const Map<MatchPeriod, String> _kPeriodLabels = <MatchPeriod, String>{
  MatchPeriod.firstHalf: '1ère mi-temps',
  MatchPeriod.secondHalf: '2ème mi-temps',
  MatchPeriod.total: 'Total match',
};

/// Un bloc de thème du bilan collectif : titre centré en majuscules puis un
/// tableau bordé « libellé | valeur », comme dans le document du client.
pw.Widget _collectifBlock(CollectifBlock block) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
  children: <pw.Widget>[
    pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        block.category.label.toUpperCase(),
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    ),
    pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: <pw.TableRow>[
        for (final CollectifRow r in block.rows)
          pw.TableRow(
            children: <pw.Widget>[
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2.5,
                ),
                child: pw.Text(
                  r.label,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                child: pw.Text(
                  r.value,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
      ],
    ),
  ],
);

/// Construit le PDF du « Bilan collectif » (sans le partager) : A4 portrait,
/// la seule [period] affichée à l'écran (1ère mi-temps, 2ème mi-temps ou Total
/// match), au format du document du client. Si elle ne tient pas sur une page,
/// elle déborde sur la suivante, en-tête répété. [theme] fournit la police
/// (Helvetica à défaut).
pw.Document buildBilanCollectifDocument({
  required GameMatch match,
  required MatchPeriod period,
  required String ownTeam,
  required String opponent,
  pw.ThemeData? theme,
}) {
  final pw.Document doc = pw.Document(theme: theme);
  final List<CollectifBlock> blocks = collectifBlocks(match, period);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header:
          (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: <pw.Widget>[
              pw.Text(
                'STATISTIQUES COLLECTIVES',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Expanded(
                    child: pw.Text(
                      '$ownTeam / $opponent',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Text(
                    _kPeriodLabels[period]!,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
            ],
          ),
      build:
          (pw.Context context) => <pw.Widget>[
            // Une page sans contenu n'est pas écrite : sans ce texte la période
            // disparaîtrait du PDF.
            if (blocks.isEmpty)
              pw.Text(
                'Aucune statistique enregistrée pour ce match.',
                style: const pw.TextStyle(fontSize: 11),
              ),
            for (int i = 0; i < blocks.length; i += 2)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Expanded(child: _collectifBlock(blocks[i])),
                    pw.SizedBox(width: 24),
                    pw.Expanded(
                      child:
                          i + 1 < blocks.length
                              ? _collectifBlock(blocks[i + 1])
                              : pw.SizedBox(),
                    ),
                  ],
                ),
              ),
          ],
    ),
  );
  return doc;
}

/// Exporte le « Bilan collectif » de la [period] affichée : les statistiques
/// suivies par thème (voir [buildBilanCollectifDocument]).
Future<void> exportBilanCollectifPdf({
  required GameMatch match,
  required MatchPeriod period,
  required String ownTeam,
  required String opponent,
}) async => _shareDocument(
  doc: buildBilanCollectifDocument(
    match: match,
    period: period,
    ownTeam: ownTeam,
    opponent: opponent,
    theme: await poppinsPdfTheme(),
  ),
  filename: 'bilan-collectif.pdf',
  bilanType: 'collectif',
);

/// Nombre maximal de colonnes de statistiques par page du bilan individuel.
const int kStatsPerPage = 10;

// Largeurs de colonnes (pt) : A4 paysage moins marges = 794 pt utiles, donc
// 100 + 22 + 10 × 67 = 792 tient sur une page. 67 pt = 63 pt utiles (2 pt de
// marge de chaque côté) : en Poppins gras 9, « Dégagements » (le plus long mot
// d'un libellé) fait 64,8 pt et se coupe en plein mot ; en 8,5 il fait 61,2 pt.
const double _kNameWidth = 100;
const double _kNumberWidth = 22;
@visibleForTesting
const double kStatWidth = 67;
@visibleForTesting
const double kStatHeaderFontSize = 8.5;

/// Découpe [stats] (dans l'ordre du catalogue) en pages de [maxPerPage]
/// colonnes au plus. Les catégories consécutives se regroupent sur une même
/// page ; une catégorie qui ne rentre pas dans la place restante ouvre la page
/// suivante, sauf si elle dépasse à elle seule [maxPerPage] : elle est alors
/// coupée (et remplit la page en cours).
@visibleForTesting
List<List<StatDef>> splitStatsByPage(
  List<StatDef> stats, {
  int maxPerPage = kStatsPerPage,
}) {
  final List<List<StatDef>> pages = <List<StatDef>>[];
  List<StatDef> page = <StatDef>[];
  int start = 0;
  while (start < stats.length) {
    int end = start;
    while (end < stats.length && stats[end].category == stats[start].category) {
      end++;
    }
    final List<StatDef> run = stats.sublist(start, end);
    start = end;
    if (run.length <= maxPerPage && page.length + run.length > maxPerPage) {
      pages.add(page);
      page = <StatDef>[];
    }
    for (final StatDef s in run) {
      if (page.length == maxPerPage) {
        pages.add(page);
        page = <StatDef>[];
      }
      page.add(s);
    }
  }
  if (page.isNotEmpty) pages.add(page);
  return pages;
}

/// Lignes du bilan individuel : titulaires par poste puis remplaçants, avec le
/// numéro de la composition — exactement celles de l'écran (`MatchStatsBoard`),
/// via [LiveMatch].
@visibleForTesting
List<({int? number, Player player})> bilanIndividuelRows(
  LiveMatch live,
  Map<String, Player> byId,
) => <({int? number, Player player})>[
  for (final PlayerPosition pos in PlayerPosition.values)
    ...live.startersAt(pos, byId),
  ...live.substitutes(byId),
];

/// Contenu du bilan individuel d'une [period] : une tranche de colonnes par
/// page, chacune avec « Joueur » et « N° » répétés. Les stats suivies sont
/// celles de la période, calculées et % compris ; 2e mi-temps non jouée : les
/// colonnes du match, chaque cellule à « — ».
@visibleForTesting
List<pw.Widget> bilanIndividuelContent(
  GameMatch match,
  Map<String, Player> byId,
  MatchPeriod period,
) {
  final LiveMatch live = LiveMatch.fromFinished(match, period);
  final bool noValue = match.statsFor(period).status == PeriodStatus.notPlayed;
  final List<({int? number, Player player})> rows = bilanIndividuelRows(
    live,
    byId,
  );
  final List<List<StatDef>> split = splitStatsByPage(
    enabledStatsInCatalogOrder(live.enabledStatKeys),
  );
  // Sans joueur (effectif pas encore chargé) ni statistique, il n'y a rien à
  // répartir : une seule page plutôt qu'une page d'en-têtes nus par tranche.
  final List<List<StatDef>> pages =
      rows.isEmpty || split.isEmpty
          ? <List<StatDef>>[const <StatDef>[]]
          : split;
  return <pw.Widget>[
    for (int i = 0; i < pages.length; i++) ...<pw.Widget>[
      if (i > 0) pw.NewPage(),
      if (pages[i].isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(
            <String>{
              for (final StatDef s in pages[i]) s.category.label,
            }.join(', '),
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ),
      pw.TableHelper.fromTextArray(
        headers: <String>[
          'Joueur',
          'N°',
          for (final StatDef s in pages[i]) s.label,
        ],
        data: <List<String>>[
          for (final ({int? number, Player player}) e in rows)
            <String>[
              e.player.fullName,
              e.number?.toString() ?? '',
              for (final StatDef s in pages[i])
                noValue
                    ? kStatNoValue
                    : formatStat(live.playerStats[e.player.id!], s),
            ],
        ],
        headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: kStatHeaderFontSize,
        ),
        cellStyle: const pw.TextStyle(fontSize: 9),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        cellAlignment: pw.Alignment.center,
        cellAlignments: <int, pw.Alignment>{0: pw.Alignment.centerLeft},
        columnWidths: <int, pw.TableColumnWidth>{
          0: const pw.FixedColumnWidth(_kNameWidth),
          1: const pw.FixedColumnWidth(_kNumberWidth),
        },
        defaultColumnWidth: const pw.FixedColumnWidth(kStatWidth),
        tableWidth: pw.TableWidth.min,
      ),
    ],
  ];
}

/// Construit le PDF du « Bilan individuel » d'une [period] (sans le partager).
/// [theme] fournit la police (Helvetica à défaut : ni « — » ni « ’ »).
@visibleForTesting
pw.Document buildBilanIndividuelDocument({
  required GameMatch match,
  required Map<String, Player> byId,
  required String title,
  MatchPeriod period = MatchPeriod.total,
  pw.ThemeData? theme,
}) => _buildDocument(
  title,
  (_) => bilanIndividuelContent(match, byId, period),
  theme: theme,
);

/// Exporte le « Bilan individuel » d'une [period] : une ligne par joueur
/// (titulaires puis remplaçants), les statistiques suivies réparties sur
/// plusieurs pages.
Future<void> exportBilanIndividuelPdf({
  required GameMatch match,
  required Map<String, Player> byId,
  required String title,
  MatchPeriod period = MatchPeriod.total,
}) async => _shareDocument(
  doc: buildBilanIndividuelDocument(
    match: match,
    byId: byId,
    title: title,
    period: period,
    theme: await poppinsPdfTheme(),
  ),
  filename: 'bilan-individuel.pdf',
  bilanType: 'individuel',
);
