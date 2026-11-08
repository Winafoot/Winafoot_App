import { firestore } from "firebase-admin";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { HttpsError } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import { toJson } from "./_serialize";
import { computeTeamStats, type TeamStats } from "./_team_stats";

const MATCH_LIMIT = 200;
const PLAYER_LIMIT = 200;

export interface GetTeamStatsResult extends TeamStats {
  /** Vrai quand la liste des matchs a été coupée à `limit` (les plus récents sont gardés). */
  truncated: boolean;
  limit: number;
}

/**
 * Bilan d'une équipe pour le back-office : résultats, buteurs, classement des joueurs. Lecture seule, bornée à
 * 200 matchs terminés les plus récents, et journalisée (ces données concernent des joueurs, parfois mineurs).
 */
export default async (data: { uid: string }, caller: AdminCaller): Promise<GetTeamStatsResult> => {
  const uid: unknown = data?.uid;
  if (typeof uid !== "string" || uid.length === 0 || uid.length > 128 || uid.includes("/")) {
    throw new HttpsError("invalid-argument", "Compte invalide.");
  }
  const db = firestore();
  const userRef = db.collection("users").doc(uid);
  const user = await userRef.get();
  if (!user.exists) throw new HttpsError("not-found", "Compte introuvable.");

  const read = async (query: firestore.Query): Promise<Record<string, unknown>[]> =>
    (await query.get()).docs.map((d) => ({ id: d.id, ...(toJson(d.data()) as Record<string, unknown>) }));

  const [players, matches] = await Promise.all([
    read(userRef.collection("players").limit(PLAYER_LIMIT)),
    read(userRef.collection("matches").orderBy("finishedAt", "desc").limit(MATCH_LIMIT)),
  ]);

  await AdminAuditRepository.instance.record({
    action: "view_coach_data",
    targetUid: uid,
    targetEmail: user.get("email") ?? undefined,
    adminUid: caller.uid,
    adminEmail: caller.email,
    outcome: "success",
    details: "team stats",
  });

  return { ...computeTeamStats(players, matches), truncated: matches.length >= MATCH_LIMIT, limit: MATCH_LIMIT };
};
