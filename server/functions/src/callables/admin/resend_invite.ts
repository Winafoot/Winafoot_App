import { auth, firestore } from "firebase-admin";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { HttpsError, logger } from "../../runtime/firebase";
import { AdminCaller } from "../../runtime/v2_admin";
import { sendCoachInvite } from "./_send_coach_invite";
import { describeError } from "../../utils/describe_error";

export interface ResendInviteData {
  uid: string;
}

export interface ResendInviteResult {
  sent: true;
}

/**
 * Anti-rebond : l'horodatage vit dans Firestore et non en mémoire, pour rester
 * correct malgré la concurrence entre instances de fonction.
 */
const RESEND_COOLDOWN_MS = 60_000;

export default async (data: ResendInviteData, caller: AdminCaller): Promise<ResendInviteResult> => {
  const userRef = firestore().collection("users").doc(data.uid);
  const snap = await userRef.get();

  if (!snap.exists) {
    await AdminAuditRepository.instance.record({
      action: "resend",
      targetUid: data.uid,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      error: "Compte introuvable.",
    });

    throw new HttpsError("not-found", "Compte introuvable.");
  }

  const last = snap.get("lastInviteSentAt") as firestore.Timestamp | null | undefined;
  if (last != null && Date.now() - last.toMillis() < RESEND_COOLDOWN_MS) {
    // Pas d'entrée d'audit ici : un rejet de cooldown n'est pas une panne du
    // système mais le garde-fou qui fonctionne comme prévu (double-clic côté
    // staff). L'auditer noierait les vraies pannes d'envoi sous du bruit.
    throw new HttpsError("resource-exhausted", "Invitation déjà envoyée il y a moins d'une minute.");
  }

  // L'adresse vient du compte Auth : le coach écrit lui-même users/{uid}.email.
  const email = await authEmail(data.uid);
  if (email == null || email.trim().length === 0) {
    await AdminAuditRepository.instance.record({
      action: "resend",
      targetUid: data.uid,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      error: "Ce compte n'a pas d'adresse e-mail.",
    });

    throw new HttpsError("failed-precondition", "Ce compte n'a pas d'adresse e-mail.");
  }

  const firstname = (snap.get("firstname") as string | null | undefined) ?? undefined;

  try {
    await sendCoachInvite(email, firstname);
  } catch (e: any) {
    logger.error(`[Error] resendInvite: envoi de l'invitation échoué : ${describeError(e)}`);

    await AdminAuditRepository.instance.record({
      action: "resend",
      targetUid: data.uid,
      targetEmail: email,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      error: String(e?.message ?? e),
    });

    throw new HttpsError("internal", "L'envoi de l'invitation a échoué, réessayez plus tard.");
  }

  await userRef.update({ lastInviteSentAt: firestore.Timestamp.now() });

  await AdminAuditRepository.instance.record({
    action: "resend",
    targetUid: data.uid,
    targetEmail: email,
    adminUid: caller.uid,
    adminEmail: caller.email,
    outcome: "success",
  });

  return { sent: true };
};

async function authEmail(uid: string): Promise<string | undefined> {
  try {
    return (await auth().getUser(uid)).email ?? undefined;
  } catch (e: any) {
    if (e?.code === "auth/user-not-found") {
      return undefined;
    }
    throw e;
  }
}
