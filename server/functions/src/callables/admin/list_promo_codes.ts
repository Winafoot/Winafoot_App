import { firestore } from "firebase-admin";
import { PROMO_COLLECTION } from "../../billing/promo_codes";
import type { AdminCaller } from "../../runtime/v2_admin";

export interface PromoCodeRow {
  code: string;
  label: string;
  offerTag: string;
  active: boolean;
  /** `AAAA-MM-JJ` (dernier jour de validité) ou null. */
  expiresAt: string | null;
  maxUses: number;
  uses: number;
  createdAt: string | null;
}

const MAX_CODES = 500;

/** Codes promo Google Play (collection `promo_codes`), du plus récent au plus ancien. */
export default async (_data: unknown, _caller: AdminCaller): Promise<{ codes: PromoCodeRow[] }> => {
  const snap = await firestore().collection(PROMO_COLLECTION).orderBy("createdAt", "desc").limit(MAX_CODES).get();
  const iso = (v: unknown) => (v instanceof firestore.Timestamp ? v.toDate().toISOString() : null);
  return {
    codes: snap.docs.map((d) => ({
      code: d.id,
      label: String(d.get("label") ?? ""),
      offerTag: String(d.get("offerTag") ?? ""),
      active: d.get("active") === true,
      expiresAt: iso(d.get("expiresAt"))?.slice(0, 10) ?? null,
      maxUses: Number(d.get("maxUses") ?? 0),
      uses: Number(d.get("uses") ?? 0),
      createdAt: iso(d.get("createdAt")),
    })),
  };
};
