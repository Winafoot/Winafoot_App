import { auth, firestore } from "firebase-admin";
import { assistantRef } from "../../billing/assistant";
import { IDENTIFIER_PATTERN, linkedEmail } from "../../billing/linked_teams";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AuthedCaller } from "../../runtime/v2_authed";
import { describeError } from "../../utils/describe_error";
import { assertPasswordPolicy } from "../admin/_password_policy";

export interface CreateAssistantRequest {
  identifier: string;
  password: string;
}

export interface CreateAssistantResult {
  uid: string;
}

/**
 * Crée l'adjoint du coach appelant (un seul par coach). Refusé pour un compte d'équipe liée ou un
 * adjoint. Si une écriture échoue, le compte Auth et les documents sont retirés.
 */
export default async (data: CreateAssistantRequest, caller: AuthedCaller): Promise<CreateAssistantResult> => {
  const identifier = typeof data?.identifier === "string" ? data.identifier.trim().toLowerCase() : "";
  if (!IDENTIFIER_PATTERN.test(identifier)) {
    throw new HttpsError("invalid-argument", "Identifiant invalide : 3 à 30 caractères, lettres minuscules, chiffres et tirets.");
  }
  assertPasswordPolicy(data?.password);

  const db = firestore();
  const coach = await db.collection("users").doc(caller.uid).get();
  if (!coach.exists) throw new HttpsError("failed-precondition", "profile-missing");
  if (coach.get("ownerUid") != null || coach.get("assistantOf") != null) {
    throw new HttpsError("permission-denied", "Ce compte ne peut pas avoir d'adjoint.");
  }
  if ((await assistantRef(caller.uid).get()).exists) {
    throw new HttpsError("failed-precondition", "assistant-exists");
  }

  const email = linkedEmail(identifier);
  let uid: string;
  try {
    uid = (await auth().createUser({ email, password: data.password, emailVerified: true, disabled: false })).uid;
  } catch (e: any) {
    if (e?.code === "auth/email-already-exists") throw new HttpsError("already-exists", "identifier-taken");
    logger.error(`[Error] createAssistant: auth().createUser a échoué : ${describeError(e)}`);
    throw new HttpsError("internal", "La création de l'adjoint a échoué, réessayez.");
  }

  const userRef = db.collection("users").doc(uid);
  const securityRef = userRef.collection("metadata").doc("security");
  const clientMetadataRef = userRef.collection("metadata").doc("metadata");

  try {
    await auth().setCustomUserClaims(uid, { assistantOf: caller.uid });
    const stamp = firestore.Timestamp.now();
    await userRef.set({
      id: uid,
      email,
      firstname: "Adjoint",
      coachName: "Adjoint",
      teamName: coach.get("teamName") ?? "",
      userType: "client",
      createdAt: stamp,
      cguAccepted: true,
      cguAcceptedDate: stamp,
      profilCompleted: true,
      disabled: false,
      assistantOf: caller.uid,
    });
    await securityRef.set({ email, profilCompleted: true, cguAccepted: true, cguAcceptedDate: stamp, isFirstLogin: false, createdAt: stamp });
    await clientMetadataRef.set({ cguAccepted: true, cguAcceptedDate: stamp, enablePushNotification: false, enableEmailNotification: false, createdAt: stamp });
    await assistantRef(caller.uid).set({ uid, identifier, createdAt: stamp });
  } catch (e: any) {
    logger.error(`[Error] createAssistant: compensation en cours : ${describeError(e)}`);
    await assistantRef(caller.uid).delete().catch(() => undefined);
    await clientMetadataRef.delete().catch(() => undefined);
    await securityRef.delete().catch(() => undefined);
    await userRef.delete().catch(() => undefined);
    await auth().deleteUser(uid).catch(() => undefined);
    throw new HttpsError("internal", "La création de l'adjoint a échoué, aucun compte n'a été conservé. Réessayez.");
  }

  return { uid };
};
