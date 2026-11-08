import { firestore } from "firebase-admin";
import type { AdminCaller } from "../../runtime/v2_admin";

const WEEKS = 12;
const MAX_MATCHES = 5000;
const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

export interface UsageWeek {
  /** Lundi de la semaine (AAAA-MM-JJ, UTC). */
  weekStart: string;
  matches: number;
  /** Équipes distinctes ayant terminé au moins un match dans la semaine. */
  activeTeams: number;
}

export interface GetUsageStatsResult {
  generatedAt: string;
  weeks: UsageWeek[];
  /** Vrai quand la période compte plus de matchs que `limit` : les chiffres sont alors partiels. */
  truncated: boolean;
  limit: number;
}

/** Lundi 00:00 UTC de la semaine contenant `ms`. */
export function mondayOf(ms: number): number {
  const d = new Date(ms);
  const day = (d.getUTCDay() + 6) % 7;
  return Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate() - day);
}

/** Matchs terminés et équipes actives par semaine, sur les 12 dernières semaines. */
export function bucketWeeks(finished: { uid: string; atMs: number }[], nowMs: number): UsageWeek[] {
  const first = mondayOf(nowMs) - (WEEKS - 1) * WEEK_MS;
  const weeks = Array.from({ length: WEEKS }, (_, i) => ({ start: first + i * WEEK_MS, matches: 0, teams: new Set<string>() }));
  for (const m of finished) {
    const index = Math.floor((m.atMs - first) / WEEK_MS);
    if (index < 0 || index >= WEEKS) continue;
    weeks[index].matches++;
    weeks[index].teams.add(m.uid);
  }
  return weeks.map((w) => ({ weekStart: new Date(w.start).toISOString().slice(0, 10), matches: w.matches, activeTeams: w.teams.size }));
}

/**
 * Activité hebdomadaire de l'app pour le tableau « Statistiques » : lit seulement la date de fin des matchs
 * terminés des 12 dernières semaines (une lecture par match, bornée à 5 000). Aucun contenu n'est renvoyé.
 */
export default async (_data: unknown, _caller: AdminCaller): Promise<GetUsageStatsResult> => {
  const now = Date.now();
  const since = mondayOf(now) - (WEEKS - 1) * WEEK_MS;
  const snap = await firestore()
    .collectionGroup("matches")
    .where("finishedAt", ">=", firestore.Timestamp.fromMillis(since))
    .select("finishedAt")
    .limit(MAX_MATCHES)
    .get();

  const finished = snap.docs.flatMap((d) => {
    const at = d.get("finishedAt");
    const uid = d.ref.parent.parent?.id;
    return at instanceof firestore.Timestamp && uid != null ? [{ uid, atMs: at.toMillis() }] : [];
  });
  return { generatedAt: new Date(now).toISOString(), weeks: bucketWeeks(finished, now), truncated: snap.size >= MAX_MATCHES, limit: MAX_MATCHES };
};
