import { firestore } from "firebase-admin";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { CODE_PATTERN, normalizeCode, PROMO_COLLECTION } from "../../billing/promo_codes";
import { HttpsError } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";

export interface DeletePromoCodeData {
  code: string;
}

/**
 * Supprime définitivement un code promo Google Play. Un code validé mais pas encore consommé par un achat devient
 * simplement inutilisable (voir `readPendingPromo`, qui ignore un code disparu). L'offre de la Play Console, elle, n'est pas
 * touchée. Chaque appel est journalisé (code et compteur d'utilisations, jamais de donnée client).
 */
export default async (data: DeletePromoCodeData, caller: AdminCaller): Promise<{ code: string }> => {
  const code = normalizeCode(data?.code);
  if (!CODE_PATTERN.test(code)) throw new HttpsError("invalid-argument", "Code : 4 à 20 lettres ou chiffres.");

  const ref = firestore().collection(PROMO_COLLECTION).doc(code);
  let details = `suppression ${code}`;
  const record = (outcome: "success" | "failure", error?: string) =>
    AdminAuditRepository.instance.record({ action: "delete_promo_code", targetUid: `promo_codes/${code}`, adminUid: caller.uid, adminEmail: caller.email, outcome, details, error });

  try {
    await firestore().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) throw new HttpsError("not-found", "Code introuvable.");
      details = `suppression ${code} : ${String(snap.get("label") ?? "")}, ${Number(snap.get("uses") ?? 0)}/${Number(snap.get("maxUses") ?? 0)} utilisation(s)`;
      tx.delete(ref);
    });
    await record("success");
    return { code };
  } catch (e: any) {
    await record("failure", String(e?.message ?? e)).catch(() => undefined);
    throw e;
  }
};
