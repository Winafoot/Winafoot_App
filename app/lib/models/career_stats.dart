import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_period.dart';
import 'package:wina/models/stat_catalog.dart';

/// Cumul des statistiques par joueur sur l'ensemble des matchs terminés.
///
/// Renvoie une nouvelle table `playerId → { statKey → cumul }` (les matchs en
/// entrée ne sont jamais modifiés). Sert à alimenter la page « Détail joueur »
/// avec les vraies données carrière (agrégation des [GameMatch.playerStats] des
/// matchs `finished`).
Map<String, Map<String, int>> aggregateCareerStats(List<GameMatch> matches) {
  final Map<String, Map<String, int>> totals = <String, Map<String, int>>{};
  for (final GameMatch match in matches) {
    match.playerStats.forEach((String playerId, Map<String, int> stats) {
      final Map<String, int> acc = totals.putIfAbsent(
        playerId,
        () => <String, int>{},
      );
      stats.forEach((String key, int value) {
        acc[key] = (acc[key] ?? 0) + value;
      });
    });
  }
  return totals;
}

/// Index libellé → clé de statistique, construit depuis [kStatCatalog].
///
/// Les libellés de la page « Détail joueur » ([kPlayerStatColumns]) reprennent
/// à l'identique ceux du catalogue ; cet index permet de relier une cellule
/// (identifiée par son libellé) à la clé persistée dans `playerStats`.
final Map<String, String> _keyByLabel = <String, String>{
  for (final StatDef s in kStatCatalog) s.label: s.key,
};

/// Clé de statistique (catalogue) correspondant à un libellé affiché, ou `null`
/// si aucun libellé ne correspond.
String? statKeyForLabel(String label) => _keyByLabel[label];

/// Totaux d'équipe d'un match sur une [period] (le match entier par défaut) :
/// somme des statistiques par joueur de [GameMatch.statsFor]. Renvoie
/// `statKey → total`, compteurs bruts : les stats calculées se dérivent ensuite
/// de ces sommes avec `readStat`. Vide quand la période n'a pas de valeurs.
Map<String, int> teamStatTotals(
  GameMatch match, [
  MatchPeriod period = MatchPeriod.total,
]) {
  final Map<String, int> totals = <String, int>{};
  match.statsFor(period).playerStats.forEach((
    String _,
    Map<String, int> stats,
  ) {
    stats.forEach((String key, int value) {
      totals[key] = (totals[key] ?? 0) + value;
    });
  });
  return totals;
}

/// Une ligne du « Bilan collectif » : thème, libellé de la statistique et valeur
/// déjà formatée (entier, pourcentage pour les stats `bilanOnly`, ou
/// [kStatNoValue] pour une 2e mi-temps non jouée).
typedef CollectifRow = ({StatCategory category, String label, String value});

/// Lignes du « Bilan collectif » d'un match sur une [period] : un total
/// d'équipe par statistique **suivie pendant cette période**, dans l'ordre du
/// catalogue. Totaux et pourcentage (`bilanOnly`, « Réussite de passes ») sont
/// dérivés des compteurs de la période sommés, jamais lus : le % du match
/// entier est celui des sommes, pas une moyenne des deux mi-temps.
///
/// Période [PeriodStatus.unavailable] (match ancien) : aucune ligne, l'appelant
/// le dit. 2e mi-temps [PeriodStatus.notPlayed] : les stats du match, toutes à
/// [kStatNoValue].
List<CollectifRow> collectifRows(
  GameMatch match, [
  MatchPeriod period = MatchPeriod.total,
]) {
  final PeriodStats stats = match.statsFor(period);
  if (stats.status == PeriodStatus.unavailable) return const <CollectifRow>[];
  final bool notPlayed = stats.status == PeriodStatus.notPlayed;
  final Map<String, int> totals = teamStatTotals(match, period);
  final List<CollectifRow> rows = <CollectifRow>[];
  final List<String> tracked =
      notPlayed ? match.statsFor(MatchPeriod.total).statKeys : stats.statKeys;
  for (final StatDef s in enabledStatsInCatalogOrder(tracked)) {
    final String value;
    if (notPlayed) {
      value = kStatNoValue;
    } else if (s.bilanOnly && s.key != 'pourcentagePasses') {
      // Seule stat en % à ce jour : la réussite de passes.
      continue;
    } else {
      value = formatStat(totals, s);
    }
    rows.add((category: s.category, label: s.label, value: value));
  }
  return rows;
}

/// Un thème du « Bilan collectif » : son titre et les lignes qui y figurent.
typedef CollectifBlock = ({StatCategory category, List<CollectifRow> rows});

/// [collectifRows] rangées par thème, dans l'ordre du catalogue. Un thème sans
/// statistique suivie n'a pas de bloc.
List<CollectifBlock> collectifBlocks(
  GameMatch match, [
  MatchPeriod period = MatchPeriod.total,
]) {
  final Map<StatCategory, List<CollectifRow>> byTheme =
      <StatCategory, List<CollectifRow>>{};
  for (final CollectifRow r in collectifRows(match, period)) {
    byTheme.putIfAbsent(r.category, () => <CollectifRow>[]).add(r);
  }
  return <CollectifBlock>[
    for (final MapEntry<StatCategory, List<CollectifRow>> e in byTheme.entries)
      (category: e.key, rows: e.value),
  ];
}
