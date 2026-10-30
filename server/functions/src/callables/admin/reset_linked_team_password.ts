import { auth, firestore } from "firebase-admin";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { isLinkedEmail } from "../../billing/linked_teams";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import { describeError } from "../../utils/describe_error";
import { assertPasswordPolicy } from "./_password_policy";

export interface ResetLinkedTeamPasswordByAdminData {
  uid: string;
  password: string;
}

const UID_MAX_LENGTH = 128;

/**
 * L'administrateur redéfinit le mot de passe d'un compte d'équipe lié, à la demande du propriétaire (ces comptes
 * n'ont pas d'adresse réelle : « Mot de passe oublié » ne peut pas les servir). Seul un compte d'équipe lié est
 * accepté (adresse technique `@equipes.wina.invalid` et `ownerUid` sur la fiche), jamais un compte coach ni un
 * administrateur. Les sessions ouvertes sont révoquées. L'action est journalisée, sans le mot de passe.
 */
export default async (data: ResetLinkedTeamPasswordByAdminData, caller: AdminCaller): Promise<{ identifier: string }> => {
  if (typeof data?.uid !== "string" || data.uid.length === 0 || data.uid.length > UID_MAX_LENGTH || data.uid.includes("/")) {
    throw new HttpsError("invalid-argument", "Compte invalide.");
  }
  assertPasswordPolicy(data.password);

  const fail = async (message: string, code: "not-found" | "failed-precondition", email?: string): Promise<never> => {
    await AdminAuditRepository.instance.record({
      action: "linked_reset_password",
      targetUid: data.uid,
      targetEmail: email,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      error: message,
    });
    throw new HttpsError(code, message);
  };

  const doc = await firestore().collection("users").doc(data.uid).get();
  if (!doc.exists) return fail("Compte introuvable.", "not-found");

  let email: string | undefined;
  try {
    email = (await auth().getUser(data.uid)).email ?? undefined;
  } catch (e) {
    if ((e as { code?: string })?.code === "auth/user-not-found") return fail("Compte introuvable.", "not-found");
    throw e;
  }

  if (typeof doc.get("ownerUid") !== "string" || email == null || !isLinkedEmail(email)) {
    return fail("Ce compte n'est pas un compte d'équipe lié.", "failed-precondition", email);
  }

  try {
    await auth().updateUser(data.uid, { password: data.password });
    await auth().revokeRefreshTokens(data.uid);
  } catch (e) {
    logger.error(`[Error] resetLinkedTeamPasswordByAdmin: ${describeError(e)}`);
    await AdminAuditRepository.instance.record({
      action: "linked_reset_password",
      targetUid: data.uid,
      targetEmail: email,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      error: String((e as { message?: string })?.message ?? e),
    });
    throw new HttpsError("internal", "La réinitialisation a échoué, réessayez.");
  }

  await AdminAuditRepository.instance.record({
    action: "linked_reset_password",
    targetUid: data.uid,
    targetEmail: email,
    adminUid: caller.uid,
    adminEmail: caller.email,
    outcome: "success",
  });

  return { identifier: email.replace(/@.*$/, "") };
};
