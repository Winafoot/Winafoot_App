import { auth } from "firebase-admin";
import type { UserRecord } from "firebase-admin/auth";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import { generateStrongPassword, getUserByEmailOrNull, refuse, validateDisplayName } from "./_admin_accounts";
import { sendAdminInvite } from "./_send_admin_invite";
import { describeError } from "../../utils/describe_error";

export interface CreateAdminData {
  email: string;
  displayName?: string;
}

export interface CreateAdminResult {
  uid: string;
  /** false : le compte existe mais l'e-mail n'est pas parti, « Renvoyer l'invitation » le renvoie. */
  inviteSent: boolean;
}

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const EMAIL_MAX_LENGTH = 254;

/**
 * Crée un administrateur et lui envoie un lien pour choisir son mot de passe. Le mot de passe
 * provisoire est aléatoire et n'est ni renvoyé ni journalisé : contrairement à un coach, un
 * administrateur ne reçoit pas son mot de passe d'un tiers. Un compte déjà existant (coach compris)
 * n'est jamais promu ici : une adresse déjà utilisée est refusée.
 */
export default async (data: CreateAdminData, caller: AdminCaller): Promise<CreateAdminResult> => {
  if (typeof data?.email !== "string") {
    throw new HttpsError("invalid-argument", "Adresse e-mail invalide.");
  }
  if (data.displayName != null && typeof data.displayName !== "string") {
    throw new HttpsError("invalid-argument", "Nom invalide.");
  }

  const email: string = data.email.trim().toLowerCase();
  const displayName: string | undefined = data.displayName?.trim() || undefined;

  if (!EMAIL_PATTERN.test(email) || email.length > EMAIL_MAX_LENGTH) {
    throw new HttpsError("invalid-argument", "Adresse e-mail invalide.");
  }
  if (displayName !== undefined) {
    validateDisplayName(displayName);
  }

  if ((await getUserByEmailOrNull(email)) != null) {
    return refuse(caller, "admin_create", { uid: "", email }, "already-exists", "Un compte existe déjà pour cette adresse.");
  }

  let record: UserRecord;
  try {
    record = await auth().createUser({
      email,
      displayName,
      password: generateStrongPassword(),
      // Non vérifiée : l'adresse l'est quand son titulaire utilise le lien reçu par e-mail.
      emailVerified: false,
      disabled: false,
    });
  } catch (e: any) {
    // Rien n'a été créé par cet appel : il n'y a rien à compenser. Surtout pas de suppression par
    // adresse ici : si deux créations se croisent, ce compte est celui de l'autre appel.
    logger.error(`[Error] createAdmin: création du compte échouée : ${describeError(e)}`);
    await recordFailure(caller, email, e);
    throw new HttpsError("internal", "La création du compte a échoué, aucun compte n'a été conservé.");
  }

  try {
    await auth().setCustomUserClaims(record.uid, { admin: true });
  } catch (e: any) {
    logger.error(`[Error] createAdmin: attribution du rôle échouée : ${describeError(e)}`);
    // Un compte sans le rôle est inutile, et inutilisable tel quel : on retire celui que CET appel a créé.
    await auth().deleteUser(record.uid).catch(() => undefined);
    await recordFailure(caller, email, e);
    throw new HttpsError("internal", "La création du compte a échoué, aucun compte n'a été conservé.");
  }

  let inviteSent = true;
  try {
    await sendAdminInvite(email, displayName);
  } catch (e: any) {
    logger.error(`[Error] createAdmin: envoi de l'invitation échoué : ${describeError(e)}`);
    inviteSent = false;
  }

  await AdminAuditRepository.instance.record({
    action: "admin_create",
    targetUid: record.uid,
    targetEmail: email,
    adminUid: caller.uid,
    adminEmail: caller.email,
    outcome: "success",
    details: inviteSent ? undefined : "invitation non envoyée",
  });

  return { uid: record.uid, inviteSent };
};

async function recordFailure(caller: AdminCaller, email: string, error: any): Promise<void> {
  await AdminAuditRepository.instance.record({
    action: "admin_create",
    targetUid: "",
    targetEmail: email,
    adminUid: caller.uid,
    adminEmail: caller.email,
    outcome: "failure",
    error: String(error?.message ?? error),
  });
}
