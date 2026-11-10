/**
 * Statistiques saisies pendant un match, avec les libellés de l'app (catalogue `stat_catalog.dart`). Les clés
 * sont celles stockées dans `playerStats` ; les totaux et pourcentages ne sont jamais stockés, `derivedStats`
 * les recalcule.
 */
export const STAT_GROUPS: { title: string; stats: { key: string; label: string }[] }[] = [
  {
    title: "Passes",
    stats: [
      { key: "passesReussies", label: "Passes réussies" },
      { key: "passesManquees", label: "Passes manquées" },
      { key: "passesProfondeur", label: "Passes en profondeur" },
    ],
  },
  { title: "Efficacité", stats: [{ key: "recuperations", label: "Récupérations de ballons" }] },
  {
    title: "Tirs",
    stats: [
      { key: "tirsCadres", label: "Tirs cadrés" },
      { key: "tirsNonCadres", label: "Tirs non cadrés" },
    ],
  },
  {
    title: "Offensives",
    stats: [
      { key: "butsMarques", label: "Buts marqués" },
      { key: "passesDecisives", label: "Passes décisives" },
      { key: "centresReussis", label: "Centres réussis" },
      { key: "centresRates", label: "Centres manqués" },
    ],
  },
  {
    title: "Coups de pied arrêtés",
    stats: [
      { key: "penaltysCrees", label: "Penaltys obtenus" },
      { key: "penaltysSubis", label: "Penaltys subis" },
    ],
  },
  {
    title: "Fautes et sanctions",
    stats: [
      { key: "fautesCommises", label: "Fautes commises" },
      { key: "fautesSubies", label: "Fautes subies" },
      { key: "cartonsJaunes", label: "Cartons jaunes" },
      { key: "cartonsRouges", label: "Cartons rouges" },
      { key: "horsJeu", label: "Hors-jeu" },
    ],
  },
  {
    title: "Gardien et défense",
    stats: [
      { key: "butsSubis", label: "Buts subis" },
      { key: "arretsGardien", label: "Arrêts du gardien" },
      { key: "tirsSubisHors", label: "Tirs subis hors de la surface" },
      { key: "tirsSubisDans", label: "Tirs subis dans la surface" },
    ],
  },
  {
    title: "Technique",
    stats: [
      { key: "controleReussi", label: "Contrôles réussis" },
      { key: "controleManque", label: "Contrôles manqués" },
      { key: "pertesBallons", label: "Pertes de ballons" },
    ],
  },
  {
    title: "Duels et actions spéciales",
    stats: [
      { key: "duelsAeriens", label: "Duels aériens gagnés" },
      { key: "duelsAeriensPerdus", label: "Duels aériens perdus" },
      { key: "duelsGagnes", label: "Duels gagnés" },
      { key: "duelsPerdus", label: "Duels perdus" },
    ],
  },
];

export const STAT_LABELS: Record<string, string> = Object.fromEntries(STAT_GROUPS.flatMap((g) => g.stats.map((s) => [s.key, s.label])));

/** Statistiques calculées à partir des saisies (affichées en plus des totaux saisis). */
export function derivedStats(stats: Record<string, number>): { label: string; value: string }[] {
  const n = (key: string) => stats[key] ?? 0;
  const out: { label: string; value: string }[] = [];
  const passes = n("passesReussies") + n("passesManquees");
  if (passes > 0) {
    out.push({ label: "Total passes", value: String(passes) });
    out.push({ label: "Réussite de passes", value: `${Math.round((n("passesReussies") / passes) * 100)} %` });
  }
  const shots = n("tirsCadres") + n("tirsNonCadres");
  if (shots > 0) out.push({ label: "Total tirs", value: String(shots) });
  const crosses = n("centresReussis") + n("centresRates");
  if (crosses > 0) out.push({ label: "Nombre de centres", value: String(crosses) });
  const shotsAgainst = n("tirsSubisHors") + n("tirsSubisDans");
  if (shotsAgainst > 0) out.push({ label: "Total tirs subis", value: String(shotsAgainst) });
  return out;
}

/** « Buts marqués 2 · Passes décisives 1 » : les statistiques non nulles d'un match, dans l'ordre du catalogue. */
export function summarizeStats(stats: Record<string, number>): string {
  const known = STAT_GROUPS.flatMap((g) => g.stats).filter((s) => stats[s.key]);
  const unknown = Object.keys(stats).filter((k) => !(k in STAT_LABELS) && stats[k]);
  const parts = [...known.map((s) => `${s.label} ${stats[s.key]}`), ...unknown.map((k) => `${k} ${stats[k]}`)];
  return parts.length === 0 ? "—" : parts.join(" · ");
}
