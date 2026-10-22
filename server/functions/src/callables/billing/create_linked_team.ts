import { auth, firestore } from "firebase-admin";
import { IDENTIFIER_PATTERN, linkedEmail, slotRef } from "../../billing/linked_teams";
import { accessToDoc, subscriptionFromDoc } from "../../billing/store";
import { computeAccess } from "../../billing/subscription";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AuthedCaller } from "../../runtime/v2_authed";
import { describeError } from "../../utils/describe_error";
import { assertPasswordPolicy } from "../admin/_password_policy";

export interface CreateLinkedTeamRequest {
  identifier: string;
  password: string;
  teamName: string;
  category: string;
  division: string;
  teamFormat: number;
  coachName?: string;
}

export interface CreateLinkedTeamResult {
  uid: string;
  teamIndex: number;
}

/** Noms d'énumérations Dart (`TeamCategory.name`, `TeamDivision.name`). */
const ENUM_NAME = /^[A-Za-z0-9]{1,30}$/;
const MAX_NAME_LENGTH = 100;

/**
 * Crée une équipe liée au compte propriétaire de l'appelant (formules 2 et 3 équipes).
 *
 * - L'appelant doit être un propriétaire (pas un compte lié) avec un abonnement actif ; le nombre
 *   d'équipes se juge sur `subscription.teamsAllowed`, lu ICI, jamais fourni par le client.
 * - Une place (`team_slots/{ownerUid}_{index}`) est réservée dans une transaction avant toute création :
 *   deux appels simultanés ne peuvent pas prendre la même place, ni dépasser la formule.
 * - L'identifiant est celui de l'adresse technique Auth : un identifiant déjà pris fait échouer la
 *   création Auth, et la place est rendue.
 * - Si une écriture échoue, le compte Auth, les documents et la place sont retirés : aucun compte à moitié créé.
 */
export default async (data: CreateLinkedTeamRequest, caller: AuthedCaller): Promise<CreateLinkedTeamResult> => {
  const req = parseRequest(data);
  assertPasswordPolicy(req.password);

  const db = firestore();
  const ownerRef = db.collection("users").doc(caller.uid);
  const now = Date.now();

  const { teamIndex, owner } = await db.runTransaction(async (tx) => {
    const ownerSnap = await tx.get(ownerRef);
    if (!ownerSnap.exists) throw new HttpsError("failed-precondition", "profile-missing");
    if (ownerSnap.get("ownerUid") != null) {
      throw new HttpsError("permission-denied", "Un compte d'équipe ne peut pas créer d'autre équipe.");
    }

    const sub = subscriptionFromDoc(ownerSnap.get("subscription"));
    if (sub == null || !computeAccess(sub, 1, now).active) {
      throw new HttpsError("failed-precondition", "no-active-subscription");
    }

    const indexes = [2, 3].filter((i) => i <= sub.teamsAllowed);
    const slots = indexes.length > 0 ? await tx.getAll(...indexes.map((i) => slotRef(caller.uid, i))) : [];
    const free = slots.findIndex((s) => !s.exists);
    if (free === -1) throw new HttpsError("failed-precondition", "team-quota-reached");

    const index = indexes[free];
    tx.set(slotRef(caller.uid, index), { ownerUid: caller.uid, teamIndex: index, createdAt: firestore.Timestamp.now() });
    return { teamIndex: index, owner: ownerSnap };
  });

  const releaseSlot = () => slotRef(caller.uid, teamIndex).delete().catch(() => undefined);

  const email = linkedEmail(req.identifier);
  let uid: string;
  try {
    uid = (await auth().createUser({ email, password: req.password, emailVerified: true, disabled: false })).uid;
  } catch (e: any) {
    await releaseSlot();
    if (e?.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "identifier-taken");
    }
    logger.error(`[Error] createLinkedTeam: auth().createUser a échoué : ${describeError(e)}`);
    throw new HttpsError("internal", "La création de l'équipe a échoué, réessayez.");
  }

  const userRef = db.collection("users").doc(uid);
  const securityRef = userRef.collection("metadata").doc("security");
  const clientMetadataRef = userRef.collection("metadata").doc("metadata");

  try {
    const stamp = firestore.Timestamp.now();
    const access = accessToDoc(computeAccess(subscriptionFromDoc(owner.get("subscription")), teamIndex, now));

    await userRef.set({
      id: uid,
      email,
      firstname: owner.get("firstname") ?? "",
      coachName: req.coachName ?? owner.get("coachName") ?? owner.get("firstname") ?? "",
      teamName: req.teamName,
      category: req.category,
      division: req.division,
      teamFormat: req.teamFormat,
      userType: "client",
      createdAt: stamp,
      cguAccepted: true,
      cguAcceptedDate: stamp,
      profilCompleted: true,
      disabled: false,
      ownerUid: caller.uid,
      teamIndex,
      access,
    });

    // OBLIGATOIRES : documents attendus par l'app et par les paquets du socle (voir registerCoach).
    await securityRef.set({ email, profilCompleted: true, cguAccepted: true, cguAcceptedDate: stamp, isFirstLogin: true, createdAt: stamp });
    await clientMetadataRef.set({ cguAccepted: true, cguAcceptedDate: stamp, enablePushNotification: false, enableEmailNotification: false, createdAt: stamp });
  } catch (e: any) {
    logger.error(`[Error] createLinkedTeam: compensation en cours : ${describeError(e)}`);
    await clientMetadataRef.delete().catch(() => undefined);
    await securityRef.delete().catch(() => undefined);
    await userRef.delete().catch(() => undefined);
    await auth().deleteUser(uid).catch(() => undefined);
    await releaseSlot();
    throw new HttpsError("internal", "La création de l'équipe a échoué, aucun compte n'a été conservé. Réessayez.");
  }

  return { uid, teamIndex };
};

function parseRequest(data: unknown): CreateLinkedTeamRequest {
  const d = data as Partial<CreateLinkedTeamRequest> | null | undefined;
  const identifier = typeof d?.identifier === "string" ? d.identifier.trim().toLowerCase() : "";
  const name = (v: unknown): v is string => typeof v === "string" && v.trim().length > 0 && v.length <= MAX_NAME_LENGTH;
  const enumName = (v: unknown): v is string => typeof v === "string" && ENUM_NAME.test(v);

  if (!IDENTIFIER_PATTERN.test(identifier)) {
    throw new HttpsError("invalid-argument", "Identifiant invalide : 3 à 30 caractères, lettres minuscules, chiffres et tirets.");
  }
  if (
    typeof d?.password !== "string" ||
    !name(d?.teamName) ||
    !enumName(d?.category) ||
    !enumName(d?.division) ||
    ![5, 8, 11].includes(d?.teamFormat as number) ||
    (d?.coachName !== undefined && !name(d.coachName))
  ) {
    throw new HttpsError("invalid-argument", "Données d'équipe invalides.");
  }

  return {
    identifier,
    password: d.password,
    teamName: d.teamName.trim(),
    category: d.category,
    division: d.division,
    teamFormat: d.teamFormat as number,
    ...(d.coachName !== undefined ? { coachName: d.coachName.trim() } : {}),
  };
}
