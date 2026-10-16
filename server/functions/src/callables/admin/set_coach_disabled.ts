import { auth, firestore } from "firebase-admin";
import { UserRecord } from "firebase-admin/auth";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { HttpsError, logger } from "../../runtime/firebase";
import { AdminCaller } from "../../runtime/v2_admin";
import { ADMIN_TARGET_MESSAGE, isAdminRecord } from "./_admin_accounts";
import { describeError } from "../../utils/describe_error";

export interface SetCoachDisabledData {
  uid: string;
  disabled: boolean;
}

export interface SetCoachDisabledResult {
  disabled: boolean;
}

export default async (data: SetCoachDisabledData, caller: AdminCaller): Promise<SetCoachDisabledResult> => {
  const disabled: boolean = data.disabled === true;

  let record: UserRecord;
  try {
    record = await auth().getUser(data.uid);
  } catch (e: any) {
    await AdminAuditRepository.instance.record({
      action: disabled ? "disable" : "enable",
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
      action: disabled ? "disable" : "enable",
      targetUid: data.uid,
      targetEmail: record.email,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      error: ADMIN_TARGET_MESSAGE,
    });
    throw new HttpsError("failed-precondition", ADMIN_TARGET_MESSAGE);
  }

  try {
    await auth().updateUser(data.uid, { disabled });
  } catch (e: any) {
    logger.error(`[Error] setCoachDisabled: mise à jour Auth échouée : ${describeError(e)}`);

    await AdminAuditRepository.instance.record({
      action: disabled ? "disable" : "enable",
      targetUid: data.uid,
      targetEmail: record.email,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      error: String(e?.message ?? e),
    });

    throw new HttpsError("internal", "La mise à jour du statut du compte a échoué, réessayez.");
  }

  try {
    // L'état Auth est invisible depuis Firestore : on le recopie pour que le
    // back-office puisse l'afficher et le filtrer.
    await firestore().collection("users").doc(data.uid).update({
      disabled,
      disabledAt: disabled ? firestore.Timestamp.now() : null,
    });
  } catch (e: any) {
    logger.error(`[Error] setCoachDisabled: recopie Firestore échouée : ${describeError(e)}`);

    await AdminAuditRepository.instance.record({
      action: disabled ? "disable" : "enable",
      targetUid: data.uid,
      targetEmail: record.email,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      error: String(e?.message ?? e),
    });

    throw new HttpsError(
      "internal",
      disabled
        ? "Le compte a été désactivé mais la fiche coach n'a pas pu être synchronisée, réessayez."
        : "Le compte a été réactivé mais la fiche coach n'a pas pu être synchronisée, réessayez."
    );
  }

  await AdminAuditRepository.instance.record({
    action: disabled ? "disable" : "enable",
    targetUid: data.uid,
    targetEmail: record.email,
    adminUid: caller.uid,
    adminEmail: caller.email,
    outcome: "success",
  });

  return { disabled };
};
