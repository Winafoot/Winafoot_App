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
 * Coupé par défaut : sans la variable d'environnement `TEST_PURCHASES_ENABLED=true` sur la fonction
 * (functions/.env du projet de test), l'appel est refusé. Ne jamais l'activer sur le projet de production :
 * il donne un abonnement gratuit à tout compte connecté.
 *
 * Écrit les mêmes champs que le webhook RevenueCat (`subscription`, `access`), valables 30 jours, et
 * marque la fiche `testGrant: true` (comme scripts/grant-test-subscription.ts).
 */
export default async (data: GrantTestSubscriptionRequest, caller: AuthedCaller): Promise<true> => {
  if (process.env.TEST_PURCHASES_ENABLED !== "true") {
    throw new HttpsError("failed-precondition", "test-purchases-disabled");
  }
  const product = parseProduct(data?.productId);
  if (product == null) throw new HttpsError("invalid-argument", "Formule inconnue.");

  const db = firestore();
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
