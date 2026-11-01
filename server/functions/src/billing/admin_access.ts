import { firestore } from "firebase-admin";
import { HttpsError } from "../runtime/firebase";
import { subscriptionFromDoc, writeSubscriptionAndAccess } from "./store";
import { computeAccess, type SubscriptionData, type TeamsAllowed } from "./subscription";

/**
 * Abonnement attribué à la main depuis le back-office (comptes de test, invités, partenaires), sans passer par
 * les stores. Écrit les mêmes champs que le webhook RevenueCat (`subscription`, `access`) : le mur de paiement
 * de l'app et les règles Firestore le voient comme un abonnement ordinaire. La fiche est marquée
 * `testGrant: true`, ce qui permet au back-office de le retirer, et seulement celui-là : un abonnement acheté
 * sur un store ne se touche pas d'ici.
 */

const DAY_MS = 24 * 60 * 60 * 1000;
export const DEFAULT_GRANT_DAYS = 30;
export const MAX_GRANT_DAYS = 365;

export interface GrantOptions {
  teams: TeamsAllowed;
  days: number;
}

/** Contrôle ce que le back-office envoie ; les valeurs absentes prennent la formule la plus simple. */
export function parseGrant(input: { teams?: unknown; days?: unknown } | undefined): GrantOptions {
  const teams = input?.teams ?? 1;
  const days = input?.days ?? DEFAULT_GRANT_DAYS;
  if (teams !== 1 && teams !== 2 && teams !== 3) {
    throw new HttpsError("invalid-argument", "Nombre d'équipes invalide : 1, 2 ou 3.");
  }
  if (typeof days !== "number" || !Number.isInteger(days) || days < 1 || days > MAX_GRANT_DAYS) {
    throw new HttpsError("invalid-argument", `Durée invalide : de 1 à ${MAX_GRANT_DAYS} jours.`);
  }
  return { teams, days };
}

/** Abonnement actif pour `days` jours à partir de `nowMs`. */
export function grantedSubscription({ teams, days }: GrantOptions, nowMs: number): SubscriptionData {
  return {
    productId: `wina_${teams}team${teams > 1 ? "s" : ""}_monthly`,
    period: "monthly",
    teamsAllowed: teams,
    status: "active",
    trialEndMs: null,
    expiresAtMs: nowMs + days * DAY_MS,
    store: "play_store",
    lastEventMs: nowMs,
  };
}

/** Même abonnement, arrêté à `nowMs` : l'accès tombe immédiatement. */
export function revokedSubscription(prev: SubscriptionData, nowMs: number): SubscriptionData {
  return { ...prev, status: "expired", expiresAtMs: nowMs, lastEventMs: nowMs };
}

function assertManageable(snap: firestore.DocumentSnapshot, nowMs: number): SubscriptionData | undefined {
  if (!snap.exists) throw new HttpsError("not-found", "Compte introuvable.");
  if (snap.get("ownerUid") != null) {
    throw new HttpsError("failed-precondition", "Un compte d'équipe liée hérite de l'abonnement de son propriétaire.");
  }
  const sub = subscriptionFromDoc(snap.get("subscription"));
  if (sub != null && snap.get("testGrant") !== true && computeAccess(sub, 1, nowMs).active) {
    throw new HttpsError("failed-precondition", "Ce compte a un abonnement actif acheté sur un store : il se gère depuis le store.");
  }
  return sub;
}

/** Attribue (ou prolonge) un abonnement offert au coach `uid`, comptes d'équipe liés compris. */
export async function grantAccess(uid: string, options: GrantOptions, nowMs: number = Date.now()): Promise<SubscriptionData> {
  const db = firestore();
  const ref = db.collection("users").doc(uid);
  const sub = grantedSubscription(options, nowMs);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    assertManageable(snap, nowMs);
    const linked = await tx.get(db.collection("users").where("ownerUid", "==", uid));
    writeSubscriptionAndAccess(tx, ref, linked.docs, sub, nowMs);
    tx.update(ref, { testGrant: true });
  });
  return sub;
}

/** Retire l'abonnement offert du coach `uid` : l'app repasse sur le mur de paiement. */
export async function revokeAccess(uid: string, nowMs: number = Date.now()): Promise<void> {
  const db = firestore();
  const ref = db.collection("users").doc(uid);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const prev = assertManageable(snap, nowMs);
    if (prev == null) throw new HttpsError("failed-precondition", "Ce compte n'a pas d'abonnement à retirer.");
    const linked = await tx.get(db.collection("users").where("ownerUid", "==", uid));
    writeSubscriptionAndAccess(tx, ref, linked.docs, revokedSubscription(prev, nowMs), nowMs);
  });
}
