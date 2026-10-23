import { firestore } from "firebase-admin";
import { writeSubscriptionAndAccess } from "../../billing/store";
import { parseProduct, type SubscriptionData } from "../../billing/subscription";
import { HttpsError } from "../../runtime/firebase";
import type { AuthedCaller } from "../../runtime/v2_authed";

export interface GrantTestSubscriptionRequest {
  productId: string;
}

const DAY_MS = 24 * 60 * 60 * 1000;
const VALIDITY_DAYS = 30;

/**
 * Simule un achat pour l'appelant tant que les produits des stores ne sont pas disponibles.
 *
 * Coupé par défaut : l'appel est refusé tant que `app_config/config.test_purchases_enabled` n'est pas `true`.
 * L'administrateur pose ce champ dans la console Firebase pour une bêta fermée, et le repasse à `false` (ou le
 * supprime) quand les produits des stores existent : tant qu'il est actif, il donne un abonnement gratuit de
 * 30 jours à tout compte connecté.
 *
 * Écrit les mêmes champs que le webhook RevenueCat (`subscription`, `access`), valables 30 jours, et
 * marque la fiche `testGrant: true` (comme scripts/grant-test-subscription.ts).
 */
export default async (data: GrantTestSubscriptionRequest, caller: AuthedCaller): Promise<true> => {
  const db = firestore();
  const cfg = await db.collection("app_config").doc("config").get();
  if (cfg.get("test_purchases_enabled") !== true) {
    throw new HttpsError("failed-precondition", "test-purchases-disabled");
  }
  const product = parseProduct(data?.productId);
  if (product == null) throw new HttpsError("invalid-argument", "Formule inconnue.");

  const ownerRef = db.collection("users").doc(caller.uid);
  const now = Date.now();
  const sub: SubscriptionData = {
    productId: data.productId,
    period: product.period,
    teamsAllowed: product.teamsAllowed,
    status: "active",
    trialEndMs: null,
    expiresAtMs: now + VALIDITY_DAYS * DAY_MS,
    store: "play_store",
    lastEventMs: now,
  };

  await db.runTransaction(async (tx) => {
    const ownerSnap = await tx.get(ownerRef);
    if (!ownerSnap.exists) throw new HttpsError("failed-precondition", "profile-missing");
    if (ownerSnap.get("ownerUid") != null) {
      throw new HttpsError("permission-denied", "Un compte d'équipe n'a pas d'abonnement propre.");
    }
    const linked = await tx.get(db.collection("users").where("ownerUid", "==", caller.uid));
    writeSubscriptionAndAccess(tx, ownerRef, linked.docs, sub, now);
    tx.update(ownerRef, { testGrant: true });
  });
  return true;
};
