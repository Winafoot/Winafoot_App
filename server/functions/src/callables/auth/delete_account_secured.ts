import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { logAccessDeniedFor } from "../../runtime/access_denied";
import { HttpsError } from "../../runtime/firebase";
import type { AuthedCaller } from "../../runtime/v2_authed";
import { verifyAdmin, type AdminCaller } from "../../runtime/v2_admin";
import { describeError } from "../../utils/describe_error";
import { ADMIN_TARGET_MESSAGE, getUserOrNull, isAdminRecord } from "../admin/_admin_accounts";
import deleteAccountSkeleton from "./delete_account";

interface DeleteAccountData {
  uid: string;
}

const UID_MAX_LENGTH = 128;

/**
 * Garde d'autorisation devant le handler du socle `delete_account`, qui fait confiance à
 * `data.uid` sans vérifier l'appelant.
 *
 * - Un utilisateur ne supprime que son propre compte.
 * - Viser le compte d'un autre est réservé à un administrateur, qui passe par les mêmes
 *   contrôles que les callables d'administration (verifyAdmin : claim, adresse vérifiée, second
 *   facteur si exigé, jeton ni révoqué ni désactivé). Cette suppression est tracée dans la piste
 *   d'audit, succès comme échec.
 * - Un compte administrateur ne se supprime jamais par ici : ce chemin n'a ni verrou, ni
 *   protection du dernier administrateur. Il passe par la vue « Administrateurs » (deleteAdmin).
 *
 * Chaque refus d'autorisation est journalisé (logAccessDeniedFor).
 */
export default async (data: DeleteAccountData, caller: AuthedCaller): Promise<true> => {
  const uid = data?.uid;
  const isSelf = typeof uid === "string" && uid === caller.uid;

  let admin: AdminCaller | undefined;
  if (!isSelf) {
    if (caller.token.admin !== true) {
      logAccessDeniedFor(caller.uid, "delete-other-account");
      throw new HttpsError("permission-denied", "Vous ne pouvez supprimer que votre propre compte.");
    }
    admin = await verifyAdmin(caller, (reason, code) => logAccessDeniedFor(caller.uid, reason, code));
  }

  if (typeof uid !== "string" || uid.length === 0 || uid.length > UID_MAX_LENGTH) {
    throw new HttpsError("invalid-argument", "Compte invalide.");
  }

  const target = await getUserOrNull(uid);
  if (target != null && isAdminRecord(target)) {
    await AdminAuditRepository.instance.record({
      action: "admin_delete",
      targetUid: uid,
      targetEmail: target.email,
      adminUid: caller.uid,
      adminEmail: typeof caller.token.email === "string" ? caller.token.email : undefined,
      outcome: "failure",
      error: ADMIN_TARGET_MESSAGE,
      details: "via deleteAccount",
    });
    throw new HttpsError("failed-precondition", ADMIN_TARGET_MESSAGE);
  }

  if (admin == null) {
    return deleteAccountSkeleton({ uid });
  }

  try {
    await deleteAccountSkeleton({ uid });
  } catch (e) {
    await AdminAuditRepository.instance.record({
      action: "delete",
      targetUid: uid,
      targetEmail: target?.email,
      adminUid: admin.uid,
      adminEmail: admin.email,
      outcome: "failure",
      error: describeError(e),
      details: "via deleteAccount",
    });
    throw e;
  }

  await AdminAuditRepository.instance.record({
    action: "delete",
    targetUid: uid,
    targetEmail: target?.email,
    adminUid: admin.uid,
    adminEmail: admin.email,
    outcome: "success",
    details: "via deleteAccount",
  });
  return true;
};
