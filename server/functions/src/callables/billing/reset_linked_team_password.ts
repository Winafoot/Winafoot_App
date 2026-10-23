import { auth, firestore } from "firebase-admin";
import { HttpsError } from "../../runtime/firebase";
import type { AuthedCaller } from "../../runtime/v2_authed";
import { assertPasswordPolicy } from "../admin/_password_policy";

export interface ResetLinkedTeamPasswordRequest {
  uid: string;
  password: string;
}

const UID_MAX_LENGTH = 128;

/**
 * Le propriétaire redéfinit le mot de passe d'un de ses comptes d'équipe liés : ces comptes n'ont pas
 * d'adresse réelle, « Mot de passe oublié » ne peut pas les servir. Seul le propriétaire du compte visé
 * (`ownerUid` de la fiche) y est autorisé ; les sessions ouvertes du compte visé sont révoquées.
 */
export default async (data: ResetLinkedTeamPasswordRequest, caller: AuthedCaller): Promise<true> => {
  if (typeof data?.uid !== "string" || data.uid.length === 0 || data.uid.length > UID_MAX_LENGTH) {
    throw new HttpsError("invalid-argument", "Compte invalide.");
  }
  assertPasswordPolicy(data.password);

  const target = await firestore().collection("users").doc(data.uid).get();
  if (!target.exists || target.get("ownerUid") !== caller.uid) {
    throw new HttpsError("permission-denied", "Ce compte n'est pas l'une de vos équipes.");
  }

  await auth().updateUser(data.uid, { password: data.password });
  await auth().revokeRefreshTokens(data.uid);
  return true;
};
