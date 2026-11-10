import { firestore } from "firebase-admin";
import { CODE_PATTERN, normalizeCode, PROMO_COLLECTION, PROMO_MESSAGES, REDEMPTION_COLLECTION, rejectionOf } from "../../billing/promo_codes";
import { subscriptionFromDoc } from "../../billing/store";
import { HttpsError } from "../../runtime/firebase";
import type { AuthedCaller } from "../../runtime/v2_authed";

export interface RedeemPromoCodeRequest {
  code: string;
}

export interface RedeemPromoCodeResult {
  /** Tag de l'offre Google Play à acheter (posé sur l'offre dans la Play Console). */
  offerTag: string;
  /** Texte affiché au client (« 50 % de réduction sur le premier mois »). */
  label: string;
}

/**
 * Valide un code promo saisi dans l'app et mémorise la validation du compte (`promo_redemptions/{uid}`, « pending »).
 * Réservé au compte principal sans abonnement : un compte lié, un adjoint ou un abonné ne peuvent pas en profiter.
 * Ne compte rien : l'usage est enregistré par le webhook RevenueCat quand l'achat à prix réduit a bien eu lieu.
 */
export default async (data: RedeemPromoCodeRequest, caller: AuthedCaller): Promise<RedeemPromoCodeResult> => {
  const code = normalizeCode(data?.code);
  if (!CODE_PATTERN.test(code)) throw new HttpsError("invalid-argument", "Code invalide : 4 à 20 lettres ou chiffres.");

  const db = firestore();
  const ownerRef = db.collection("users").doc(caller.uid);
  const codeRef = db.collection(PROMO_COLLECTION).doc(code);
  const redemptionRef = db.collection(REDEMPTION_COLLECTION).doc(caller.uid);
  const now = Date.now();

  return db.runTransaction(async (tx) => {
    const [owner, promo, redemption] = await tx.getAll(ownerRef, codeRef, redemptionRef);
    if (!owner.exists) throw new HttpsError("failed-precondition", "profile-missing");
    if (owner.get("ownerUid") != null || owner.get("assistantOf") != null) {
      throw new HttpsError("permission-denied", "Seul le compte principal peut utiliser un code promo.");
    }
    if (subscriptionFromDoc(owner.get("subscription")) != null) throw new HttpsError("failed-precondition", PROMO_MESSAGES["not-new"]);
    if (redemption.exists && redemption.get("state") === "used") throw new HttpsError("failed-precondition", PROMO_MESSAGES["already-used"]);

    const expiresAt = promo.get("expiresAt");
    const reason = rejectionOf(promo.exists ? { active: promo.get("active"), expiresAtMs: expiresAt instanceof firestore.Timestamp ? expiresAt.toMillis() : null, maxUses: promo.get("maxUses"), uses: promo.get("uses") } : undefined, now);
    if (reason != null) throw new HttpsError("failed-precondition", PROMO_MESSAGES[reason]);

    tx.set(redemptionRef, { code, offerTag: promo.get("offerTag"), state: "pending", validatedAt: firestore.Timestamp.fromMillis(now) });
    return { offerTag: String(promo.get("offerTag")), label: String(promo.get("label") ?? "") };
  });
};
