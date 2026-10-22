import { auth, firestore, storage } from "firebase-admin";
import { UserRecord } from "firebase-admin/auth";
import { DeletedUserRepositoryRepository } from "../../database/deleted_users/deleted_user_repository";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { HttpsError, logger } from "../../runtime/firebase";
import { AdminCaller } from "../../runtime/v2_admin";
import { ADMIN_TARGET_MESSAGE, isAdminRecord } from "./_admin_accounts";
import { describeError } from "../../utils/describe_error";
import { detachFromTeams } from "../../billing/linked_teams";

export interface DeleteCoachData {
  uid: string;
}

export interface DeleteCoachResult {
  deleted: true;
}

export default async (data: DeleteCoachData, caller: AdminCaller): Promise<DeleteCoachResult> => {
  let record: UserRecord;
  try {
    record = await auth().getUser(data.uid);
  } catch (e: any) {
    await AdminAuditRepository.instance.record({
      action: "delete",
      targetUid: data.uid,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      error: "Compte introuvable.",
    });
    throw new HttpsError("not-found", "Compte introuvable.");
  }

  if (isAdminRecord(record)) {
    await AdminAuditRepository.instance.record({
      action: "delete",
      targetUid: data.uid,
      targetEmail: record.email,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      error: ADMIN_TARGET_MESSAGE,
    });
    throw new HttpsError("failed-precondition", ADMIN_TARGET_MESSAGE);
  }

  const email = record.email;
  const ref = firestore().collection("users").doc(data.uid);

  try {
    await DeletedUserRepositoryRepository.instance.addFromUserRecord(record);
  } catch (e: any) {
    logger.error(`[Error] deleteCoach: archivage échoué : ${describeError(e)}`);
    await AdminAuditRepository.instance.record({
      action: "delete",
      targetUid: data.uid,
      targetEmail: email,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      failedStage: "archive",
      error: String(e?.message ?? e),
    });
    throw new HttpsError("internal", "L'archivage du compte a échoué, rien n'a été supprimé, réessayez.");
  }

  try {
    await detachFromTeams(data.uid);
  } catch (e: any) {
    logger.error(`[Error] deleteCoach: comptes d'équipe non supprimés : ${describeError(e)}`);
    await AdminAuditRepository.instance.record({
      action: "delete",
      targetUid: data.uid,
      targetEmail: email,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      failedStage: "teams",
      error: String(e?.message ?? e),
    });
    throw new HttpsError("internal", "La suppression des équipes liées a échoué, rien n'a été supprimé, réessayez.");
  }

  try {
    await auth().deleteUser(data.uid);
  } catch (e: any) {
    logger.error(`[Error] deleteCoach: suppression Auth échouée : ${describeError(e)}`);
    await AdminAuditRepository.instance.record({
      action: "delete",
      targetUid: data.uid,
      targetEmail: email,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      failedStage: "auth_delete",
      error: String(e?.message ?? e),
    });
    throw new HttpsError(
      "internal",
      "La suppression du compte d'authentification a échoué, rien n'a été supprimé, réessayez."
    );
  }

  try {
    await firestore().recursiveDelete(ref);
  } catch (e: any) {
    // Le compte Auth est déjà parti et n'est pas récupérable : un nouvel appel
    // échouerait immédiatement sur "Compte introuvable", donc pas de "réessayez"
    // ici, il faut remonter l'incident.
    logger.error(`[Error] deleteCoach: suppression Firestore incomplète après suppression Auth : ${describeError(e)}`);
    await AdminAuditRepository.instance.record({
      action: "delete",
      targetUid: data.uid,
      targetEmail: email,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      failedStage: "firestore_delete",
      error: String(e?.message ?? e),
    });
    throw new HttpsError(
      "internal",
      "Le compte a été supprimé mais ses données n'ont pas pu être entièrement effacées, ne réessayez pas : contactez un développeur."
    );
  }

  let storagePurged = true;
  try {
    // storage().bucket() lève une exception SYNCHRONE (pas un rejet de promesse)
    // quand aucun storageBucket n'est configuré : un .catch() chaîné sur la
    // promesse ne l'intercepterait jamais, d'où ce try/catch explicite.
    await storage()
      .bucket()
      .deleteFiles({ prefix: `users/${data.uid}` });
  } catch (e) {
    logger.warn(`[Warn] deleteCoach: purge Storage partielle : ${describeError(e)}`);
    storagePurged = false;
  }

  await AdminAuditRepository.instance.record({
    action: "delete",
    targetUid: data.uid,
    targetEmail: email,
    adminUid: caller.uid,
    adminEmail: caller.email,
    outcome: "success",
    storagePurged,
  });

  return { deleted: true };
};
