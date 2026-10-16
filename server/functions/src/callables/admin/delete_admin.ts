import { auth, firestore } from "firebase-admin";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import { getUserOrNull, isAdminRecord, listAdminRecords, otherEnabledAdmins, refuse, withAdminLock } from "./_admin_accounts";
import { describeError } from "../../utils/describe_error";

export interface DeleteAdminData {
  uid: string;
}

export interface DeleteAdminResult {
  deleted: true;
}

const UID_MAX_LENGTH = 128;

/**
 * Supprime un compte administrateur. Garde-fous : on ne se supprime pas soi-même, on ne supprime
 * que des administrateurs (les coachs ont leur propre suppression, qui archive leurs données), et
 * on ne retire jamais le dernier administrateur actif, sans quoi plus personne ne pourrait
 * gérer le back-office.
 */
export default async (data: DeleteAdminData, caller: AdminCaller): Promise<DeleteAdminResult> => {
  const uid = data?.uid;
  if (typeof uid !== "string" || uid.length === 0 || uid.length > UID_MAX_LENGTH) {
    throw new HttpsError("invalid-argument", "Compte invalide.");
  }

  if (uid === caller.uid) {
    return refuse(caller, "admin_delete", { uid, email: caller.email }, "failed-precondition", "Vous ne pouvez pas supprimer votre propre compte.");
  }

  return withAdminLock(async () => {
    const record = await getUserOrNull(uid);
    if (record == null) {
      return refuse(caller, "admin_delete", { uid }, "not-found", "Compte introuvable.");
    }
    const target = { uid, email: record.email };
    if (!isAdminRecord(record)) {
      return refuse(caller, "admin_delete", target, "failed-precondition", "Ce compte n'est pas un administrateur : supprimez-le depuis la liste des coachs.");
    }
    // Un compte à la fois administrateur et coach a des données à archiver : ce n'est pas le rôle de cette vue.
    if ((await firestore().collection("users").doc(uid).get()).exists) {
      return refuse(caller, "admin_delete", target, "failed-precondition", "Ce compte a aussi une fiche coach : retirez-lui d'abord le rôle administrateur (script set-admin --revoke), puis supprimez-le depuis la liste des coachs.");
    }
    if (otherEnabledAdmins(await listAdminRecords(), uid) === 0) {
      return refuse(caller, "admin_delete", target, "failed-precondition", "Impossible : ce compte est le dernier administrateur actif.");
    }

    try {
      await auth().deleteUser(uid);
    } catch (e: any) {
      logger.error(`[Error] deleteAdmin: suppression Auth échouée : ${describeError(e)}`);
      await AdminAuditRepository.instance.record({
        action: "admin_delete",
        targetUid: uid,
        targetEmail: record.email,
        adminUid: caller.uid,
        adminEmail: caller.email,
        outcome: "failure",
        error: String(e?.message ?? e),
      });
      throw new HttpsError("internal", "La suppression du compte a échoué, rien n'a été supprimé, réessayez.");
    }

    await AdminAuditRepository.instance.record({
      action: "admin_delete",
      targetUid: uid,
      targetEmail: record.email,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "success",
    });

    return { deleted: true as const };
  });
};
