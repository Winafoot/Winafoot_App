import { firestore } from "firebase-admin";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { HttpsError } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import { toJson } from "./_serialize";

const LIMIT = 200;

export interface GetCoachDataInput {
  uid: string;
}

export interface CoachData {
  players: Record<string, unknown>[];
  matches: Record<string, unknown>[];
  compositions: Record<string, unknown>[];
  /** Comptes d'équipe rattachés à ce compte (formules à 2 ou 3 équipes). */
  linkedTeams: Record<string, unknown>[];
  /** Vrai quand une liste a été coupée à `limit` entrées. */
  truncated: boolean;
  limit: number;
}

/**
 * Données d'un coach pour la fiche du back-office : effectif, matchs, compositions, équipes liées. Les règles
 * Firestore les réservent au propriétaire ; l'accès administrateur passe donc ici, en lecture seule, borné à
 * 200 entrées par liste, et journalisé (ces données concernent des joueurs, parfois mineurs).
 */
export default async (data: GetCoachDataInput, caller: AdminCaller): Promise<CoachData> => {
  const uid: unknown = data?.uid;
  if (typeof uid !== "string" || uid.length === 0 || uid.length > 128 || uid.includes("/")) {
    throw new HttpsError("invalid-argument", "Compte invalide.");
  }

  const db = firestore();
  const userRef = db.collection("users").doc(uid);
  const user = await userRef.get();
  if (!user.exists) throw new HttpsError("not-found", "Compte introuvable.");

  const read = async (query: firestore.Query): Promise<Record<string, unknown>[]> =>
    (await query.limit(LIMIT).get()).docs.map((d) => ({ id: d.id, ...(toJson(d.data()) as Record<string, unknown>) }));

  const [players, matches, compositions, linkedTeams] = await Promise.all([
    read(userRef.collection("players")),
    read(userRef.collection("matches")),
    read(userRef.collection("compositions")),
    read(db.collection("users").where("ownerUid", "==", uid)),
  ]);

  await AdminAuditRepository.instance.record({
    action: "view_coach_data",
    targetUid: uid,
    targetEmail: user.get("email") ?? undefined,
    adminUid: caller.uid,
    adminEmail: caller.email,
    outcome: "success",
  });

  return {
    players,
    matches,
    compositions,
    linkedTeams: linkedTeams.map(({ id, email, teamName, teamIndex, access }) => ({ id, email, teamName, teamIndex, access })),
    truncated: [players, matches, compositions, linkedTeams].some((list) => list.length >= LIMIT),
    limit: LIMIT,
  };
};
