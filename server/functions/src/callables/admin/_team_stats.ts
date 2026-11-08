type Row = Record<string, unknown>;

const num = (v: unknown): number => (typeof v === "number" && Number.isFinite(v) ? v : 0);
const str = (v: unknown): string => (typeof v === "string" ? v : "");

export interface PlayerLine {
  id: string;
  name: string;
  position: string;
  /** Matchs terminés où le joueur a une ligne de statistiques. */
  matches: number;
  goals: number;
  assists: number;
  yellowCards: number;
  redCards: number;
  /** Total de chaque statistique saisie (clés du catalogue de l'app), valeurs non nulles seulement. */
  stats: Record<string, number>;
  /** Statistiques du joueur match par match (matchs terminés, du plus récent au plus ancien). */
  history: { matchId: string; opponent: string; finishedAt: string | null; stats: Record<string, number> }[];
}

export interface MatchLine {
  id: string;
  opponent: string;
  scoreUs: number;
  scoreThem: number;
  result: "win" | "draw" | "loss";
  finishedAt: string | null;
  elapsedSeconds: number;
  /** Buteurs, déduits des statistiques `butsMarques` du match. */
  scorers: { name: string; goals: number }[];
  yellowCards: number;
  redCards: number;
}

export interface TeamStats {
  record: { played: number; wins: number; draws: number; losses: number; goalsFor: number; goalsAgainst: number };
  matches: MatchLine[];
  players: PlayerLine[];
}

function playerName(p: Row | undefined, fallback: string): string {
  const name = `${str(p?.firstName)} ${str(p?.lastName)}`.trim();
  return name === "" ? fallback : name;
}

/**
 * Bilan d'une équipe à partir de ses joueurs (`users/{uid}/players`) et de ses matchs TERMINÉS. Un match terminé
 * ne garde que le score et `playerStats` (joueur -> statistique -> valeur) : le temps de jeu et la minute des
 * buts ne sont conservés que pendant le direct, ils ne sont donc pas calculés ici.
 */
export function computeTeamStats(players: Row[], matches: Row[]): TeamStats {
  const byId = new Map(players.map((p) => [str(p.id), p]));
  const lines = new Map<string, PlayerLine>(
    players.map((p) => [str(p.id), { id: str(p.id), name: playerName(p, "Joueur"), position: str(p.position), matches: 0, goals: 0, assists: 0, yellowCards: 0, redCards: 0, stats: {}, history: [] }]),
  );
  const record = { played: 0, wins: 0, draws: 0, losses: 0, goalsFor: 0, goalsAgainst: 0 };
  const out: MatchLine[] = [];

  for (const m of matches) {
    if (m.status !== "finished") continue;
    const scoreUs = num(m.scoreUs);
    const scoreThem = num(m.scoreThem);
    const result = scoreUs > scoreThem ? "win" : scoreUs < scoreThem ? "loss" : "draw";
    record.played++;
    record.goalsFor += scoreUs;
    record.goalsAgainst += scoreThem;
    if (result === "win") record.wins++;
    else if (result === "loss") record.losses++;
    else record.draws++;

    const opponent = str((m.opponent as Row | undefined)?.name) || "—";
    const finishedAt = typeof m.finishedAt === "string" ? m.finishedAt : null;
    const scorers: MatchLine["scorers"] = [];
    let yellowCards = 0;
    let redCards = 0;
    const stats = (m.playerStats ?? {}) as Record<string, Record<string, unknown>>;
    for (const [pid, s] of Object.entries(stats)) {
      if (s == null || typeof s !== "object") continue;
      const line = lines.get(pid) ?? { id: pid, name: playerName(byId.get(pid), "Ancien joueur"), position: "", matches: 0, goals: 0, assists: 0, yellowCards: 0, redCards: 0, stats: {}, history: [] };
      lines.set(pid, line);
      line.matches++;
      const matchStats: Record<string, number> = {};
      for (const [key, value] of Object.entries(s)) {
        if (num(value) === 0) continue;
        matchStats[key] = num(value);
        line.stats[key] = (line.stats[key] ?? 0) + num(value);
      }
      line.history.push({ matchId: str(m.id), opponent, finishedAt, stats: matchStats });
      line.goals += num(s.butsMarques);
      line.assists += num(s.passesDecisives);
      line.yellowCards += num(s.cartonsJaunes);
      line.redCards += num(s.cartonsRouges);
      yellowCards += num(s.cartonsJaunes);
      redCards += num(s.cartonsRouges);
      if (num(s.butsMarques) > 0) scorers.push({ name: line.name, goals: num(s.butsMarques) });
    }

    out.push({
      id: str(m.id),
      opponent,
      scoreUs,
      scoreThem,
      result,
      finishedAt,
      elapsedSeconds: num(m.elapsedSeconds),
      scorers: scorers.sort((a, b) => b.goals - a.goals),
      yellowCards,
      redCards,
    });
  }

  return { record, matches: out, players: [...lines.values()].sort((a, b) => b.goals - a.goals || b.assists - a.assists || a.name.localeCompare(b.name)) };
}
