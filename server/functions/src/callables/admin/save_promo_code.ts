import { firestore } from "firebase-admin";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { CODE_PATTERN, endOfDayMs, normalizeCode, PROMO_COLLECTION, TAG_PATTERN } from "../../billing/promo_codes";
import { HttpsError } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";

export interface SavePromoCodeData {
  code: string;
  /** Vrai à la création : refuse d'écraser un code existant. Faux : modifie un code existant. */
  create: boolean;
  /** Texte montré au client (« 50 % de réduction sur le premier mois »). */
  label: string;
  /** Tag de l'offre Google Play ; fixé à la création, ensuite inchangeable (les usages passés s'y rattachent). */
  offerTag?: string;
  /** `AAAA-MM-JJ`, vide : sans date limite. */
  expiresAt?: string | null;
  maxUses: number;
  active: boolean;
}

/**
 * Crée ou modifie un code promo Google Play. Un code ne se supprime pas : on le désactive. Chaque appel est
 * journalisé (code et réglages, jamais de donnée client).
 */
export default async (data: SavePromoCodeData, caller: AdminCaller): Promise<{ code: string }> => {
  const code = normalizeCode(data?.code);
  if (!CODE_PATTERN.test(code)) throw new HttpsError("invalid-argument", "Code : 4 à 20 lettres ou chiffres.");
  const label = typeof data.label === "string" ? data.label.trim() : "";
  if (label === "" || label.length > 80) throw new HttpsError("invalid-argument", "Texte affiché au client : 1 à 80 caractères.");
  const maxUses = Number(data.maxUses);
  if (!Number.isInteger(maxUses) || maxUses < 1 || maxUses > 100000) throw new HttpsError("invalid-argument", "Nombre d'utilisations : entier de 1 à 100 000.");
  const expires = data.expiresAt == null || data.expiresAt.trim() === "" ? null : data.expiresAt.trim();
  if (expires != null && (!/^\d{4}-\d{2}-\d{2}$/.test(expires) || Number.isNaN(endOfDayMs(expires)))) {
    throw new HttpsError("invalid-argument", "Date limite invalide (AAAA-MM-JJ).");
  }
  const offerTag = typeof data.offerTag === "string" ? data.offerTag.trim().toLowerCase() : "";
  if (data.create === true && !TAG_PATTERN.test(offerTag)) throw new HttpsError("invalid-argument", "Tag de l'offre : 2 à 20 minuscules, chiffres ou tirets.");

  const ref = firestore().collection(PROMO_COLLECTION).doc(code);
  const details = `${data.create === true ? "création" : "modification"} ${code} : ${label}, max ${maxUses}, ${data.active === true ? "actif" : "inactif"}${expires != null ? `, jusqu'au ${expires}` : ""}`;
  const record = (outcome: "success" | "failure", error?: string) =>
    AdminAuditRepository.instance.record({ action: "save_promo_code", targetUid: `promo_codes/${code}`, adminUid: caller.uid, adminEmail: caller.email, outcome, details, error });

  try {
    await firestore().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const fields = {
        label,
        maxUses,
        active: data.active === true,
        expiresAt: expires == null ? null : firestore.Timestamp.fromMillis(endOfDayMs(expires)),
        updatedAt: firestore.Timestamp.now(),
      };
      if (data.create === true) {
        if (snap.exists) throw new HttpsError("already-exists", "Ce code existe déjà.");
        tx.set(ref, { ...fields, offerTag, uses: 0, createdAt: firestore.Timestamp.now() });
      } else {
        if (!snap.exists) throw new HttpsError("not-found", "Code introuvable.");
        tx.update(ref, fields);
      }
    });
    await record("success");
    return { code };
  } catch (e: any) {
    await record("failure", String(e?.message ?? e)).catch(() => undefined);
    throw e;
  }
};
