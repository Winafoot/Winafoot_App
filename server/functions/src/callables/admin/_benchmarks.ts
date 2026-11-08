type Row = Record<string, unknown>;

const num = (v: unknown): number => (typeof v === "number" && Number.isFinite(v) ? v : 0);
const NO_CATEGORY = "Sans catégorie";
/** Un joueur ne figure au classement qu'à partir de ce nombre de matchs : un but en un match n'est pas un niveau. */
export const MIN_MATCHES = 3;
const TOP = 20;

export interface CategoryBenchmark {
  category: string;
  teams: number;
  matches: number;
  goalsForPerMatch: number;
  goalsAgainstPerMatch: number;
  /** Part de victoires, en %. */
  winRate: number;
  /** Passes réussies / (réussies + manquées), en %, `null` sans passes saisies. */
  passAccuracy: number | null;
  yellowCardsPerMatch: number;
}

/** Joueur anonyme : ni nom, ni équipe, ni identifiant. */
export interface AnonymousPlayer {
  rank: number;
  category: string;
  matches: number;
  goals: number;
  assists: number;
  goalsPerMatch: number;
}

export interface Benchmarks {
  categories: CategoryBenchmark[];
  topScorers: AnonymousPlayer[];
  topAssisters: AnonymousPlayer[];
}

const round1 = (n: number) => Math.round(n * 10) / 10;
const round2 = (n: number) => Math.round(n * 100) / 100;

/**
 * Moyennes par catégorie et classement anonyme des joueurs, à partir de la catégorie de chaque compte
 * (`categories`: uid -> catégorie) et des matchs terminés (`uid` = compte propriétaire du match).
 * Rien d'identifiant n'est renvoyé : seuls des agrégats et des lignes « Joueur n°k ».
 */
export function computeBenchmarks(categories: Map<string, string>, matches: { uid: string; data: Row }[]): Benchmarks {
  const perCategory = new Map<string, { teams: Set<string>; matches: number; gf: number; ga: number; wins: number; ok: number; miss: number; yellow: number }>();
  const players = new Map<string, { category: string; matches: number; goals: number; assists: number }>();

  for (const { uid, data } of matches) {
    if (data.status !== "finished") continue;
    const category = categories.get(uid) || NO_CATEGORY;
    const c = perCategory.get(category) ?? { teams: new Set<string>(), matches: 0, gf: 0, ga: 0, wins: 0, ok: 0, miss: 0, yellow: 0 };
    perCategory.set(category, c);
    c.teams.add(uid);
    c.matches++;
    c.gf += num(data.scoreUs);
    c.ga += num(data.scoreThem);
    if (num(data.scoreUs) > num(data.scoreThem)) c.wins++;

    const stats = (data.playerStats ?? {}) as Record<string, Record<string, unknown>>;
    for (const [pid, s] of Object.entries(stats)) {
      if (s == null || typeof s !== "object") continue;
      c.ok += num(s.passesReussies);
      c.miss += num(s.passesManquees);
      c.yellow += num(s.cartonsJaunes);
      const key = `${uid}/${pid}`;
      const p = players.get(key) ?? { category, matches: 0, goals: 0, assists: 0 };
      players.set(key, p);
      p.matches++;
      p.goals += num(s.butsMarques);
      p.assists += num(s.passesDecisives);
    }
  }

  const rows = [...perCategory.entries()]
    .map(([category, c]): CategoryBenchmark => ({
      category,
      teams: c.teams.size,
      matches: c.matches,
      goalsForPerMatch: round2(c.gf / c.matches),
      goalsAgainstPerMatch: round2(c.ga / c.matches),
      winRate: Math.round((c.wins / c.matches) * 100),
      passAccuracy: c.ok + c.miss > 0 ? Math.round((c.ok / (c.ok + c.miss)) * 100) : null,
      yellowCardsPerMatch: round2(c.yellow / c.matches),
    }))
    .sort((a, b) => b.matches - a.matches);

  const eligible = [...players.values()].filter((p) => p.matches >= MIN_MATCHES);
  const ranked = (key: "goals" | "assists"): AnonymousPlayer[] =>
    [...eligible]
      .sort((a, b) => b[key] - a[key] || b.matches - a.matches)
      .filter((p) => p[key] > 0)
      .slice(0, TOP)
      .map((p, i) => ({ rank: i + 1, category: p.category, matches: p.matches, goals: p.goals, assists: p.assists, goalsPerMatch: round1(p.goals / p.matches) }));

  return { categories: rows, topScorers: ranked("goals"), topAssisters: ranked("assists") };
}
