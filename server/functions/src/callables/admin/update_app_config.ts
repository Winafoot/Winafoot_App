import { firestore } from "firebase-admin";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import { describeError } from "../../utils/describe_error";
import { buildConfigUpdate } from "./_app_config";

export interface UpdateAppConfigResult {
  /** Champs modifiés ou supprimés. */
  changed: string[];
}

/**
 * Modifie des champs de `app_config/metadata` depuis le back-office (adresses, réseaux sociaux, expéditeur des
 * e-mails, textes légaux). Seuls les champs de la liste blanche sont acceptés. La trace d'audit liste les champs,
 * jamais leurs valeurs. Changer `cgvu` déclenche la remise à zéro de l'acceptation des CGU (trigger existant).
 */
export default async (data: { changes: unknown }, caller: AdminCaller): Promise<UpdateAppConfigResult> => {
  const { set, remove } = buildConfigUpdate(data?.changes);
  const changed = [...Object.keys(set), ...remove];
  const details = changed.map((k) => (k === "cgvu" ? "cgvu (acceptation des CGU réinitialisée)" : k)).join(", ");
  const record = (outcome: "success" | "failure", error?: string) =>
    AdminAuditRepository.instance.record({ action: "update_config", targetUid: "app_config/metadata", adminUid: caller.uid, adminEmail: caller.email, outcome, details, error });

  try {
    const ref = firestore().collection("app_config").doc("metadata");
    if (!(await ref.get()).exists) throw new HttpsError("failed-precondition", "app_config/metadata est introuvable.");
    await ref.update({
      ...set,
      ...Object.fromEntries(remove.map((k) => [k, firestore.FieldValue.delete()])),
    });
    await record("success");
    return { changed };
  } catch (e: any) {
    await record("failure", String(e?.message ?? e)).catch(() => undefined);
    if (e instanceof HttpsError) throw e;
    logger.error(`[Error] updateAppConfig: ${describeError(e)}`);
    throw new HttpsError("internal", "L'enregistrement de la configuration a échoué, réessayez.");
  }
};
