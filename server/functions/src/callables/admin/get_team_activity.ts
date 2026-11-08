import { firestore } from "firebase-admin";
import type { AdminCaller } from "../../runtime/v2_admin";
import { toJson } from "./_serialize";

const MAX_TEAMS = 1000;
const BATCH = 25;

export interface TeamActivity {
  uid: string;
  players: number;
  /** Matchs créés (brouillons compris). */
  matches: number;
  finished: number;
  /** Fin du dernier match terminé (ISO), `null` s'il n'y en a aucun. */
  lastFinishedAt: string | null;
}

export interface GetTeamActivityResult {
  teams: TeamActivity[];
  /** Vrai quand la liste a été coupée à `limit` comptes. */
  truncated: boolean;
  limit: number;
}

async function count(query: firestore.Query): Promise<number> {
  return (await query.count().get()).data().count;
}

/**
 * Activité de chaque compte (effectif, matchs, dernier match terminé) pour la vue « Équipes » du back-office.
 * Uniquement des agrégations `count()` et un document par compte : aucun joueur ni match n'est renvoyé, rien
 * n'est journalisé. Lecture seule.
 */
export default async (_data: unknown, _caller: AdminCaller): Promise<GetTeamActivityResult> => {
  const db = firestore();
  const ids = (await db.collection("users").select().limit(MAX_TEAMS).get()).docs.map((d) => d.id);

  const teams: TeamActivity[] = [];
  for (let i = 0; i < ids.length; i += BATCH) {
    teams.push(
      ...(await Promise.all(
        ids.slice(i, i + BATCH).map(async (uid): Promise<TeamActivity> => {
          const user = db.collection("users").doc(uid);
          const [players, matches, finished, last] = await Promise.all([
            count(user.collection("players")),
            count(user.collection("matches")),
            count(user.collection("matches").where("status", "==", "finished")),
            user.collection("matches").orderBy("finishedAt", "desc").limit(1).select("finishedAt").get(),
          ]);
          const lastFinishedAt = last.docs[0]?.get("finishedAt");
          return { uid, players, matches, finished, lastFinishedAt: (toJson(lastFinishedAt) as string | undefined) ?? null };
        }),
      )),
    );
  }
  return { teams, truncated: ids.length >= MAX_TEAMS, limit: MAX_TEAMS };
};
