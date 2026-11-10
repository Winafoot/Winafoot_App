import { auth, firestore } from "firebase-admin";
import { HttpsError } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import deleteCoach, { type DeleteCoachResult } from "./delete_coach";

export interface DeleteOrphanTeamData {
  uid: string;
}

/**
 * Supprime une équipe liée dont le compte principal n'existe plus (ni fiche, ni compte Auth). Refuse tout autre
 * compte : un coach, une équipe liée dont le propriétaire existe encore, ou un administrateur. La suppression
 * elle-même (archivage, place d'équipe, Auth, Firestore, Storage, piste d'audit) est celle de `deleteCoach`.
 */
export default async (data: DeleteOrphanTeamData, caller: AdminCaller): Promise<DeleteCoachResult> => {
  const uid: unknown = data?.uid;
  if (typeof uid !== "string" || uid.length === 0 || uid.length > 128 || uid.includes("/")) {
    throw new HttpsError("invalid-argument", "Compte invalide.");
  }

  const users = firestore().collection("users");
  const team = await users.doc(uid).get();
  if (!team.exists) throw new HttpsError("not-found", "Équipe introuvable.");

  const ownerUid: unknown = team.get("ownerUid");
  if (typeof ownerUid !== "string" || ownerUid === "") {
    throw new HttpsError("failed-precondition", "Ce compte n'est pas une équipe liée.");
  }
  if ((await users.doc(ownerUid).get()).exists) {
    throw new HttpsError("failed-precondition", "Le compte principal existe encore : cette équipe n'est pas orpheline.");
  }
  const ownerInAuth = await auth()
    .getUser(ownerUid)
    .then(() => true)
    .catch((e: any) => {
      if (e?.code === "auth/user-not-found") return false;
      throw e;
    });
  if (ownerInAuth) {
    throw new HttpsError("failed-precondition", "Le compte principal existe encore : cette équipe n'est pas orpheline.");
  }

  return deleteCoach({ uid }, caller);
};
