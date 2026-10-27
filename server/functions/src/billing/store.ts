import { firestore } from "firebase-admin";
import { computeAccess, type Access, type SubscriptionData } from "./subscription";

const { Timestamp } = firestore;

/** `users/{uid}.subscription` : écrit par le serveur seul (règles Firestore). Les dates sont des timestamps. */
export function subscriptionToDoc(sub: SubscriptionData): Record<string, unknown> {
  return {
    productId: sub.productId,
    period: sub.period,
    teamsAllowed: sub.teamsAllowed,
    status: sub.status,
    trialEnd: sub.trialEndMs == null ? null : Timestamp.fromMillis(sub.trialEndMs),
    expiresAt: Timestamp.fromMillis(sub.expiresAtMs),
    store: sub.store,
    lastEventMs: sub.lastEventMs,
    autoRenew: sub.autoRenew ?? null,
    updatedAt: Timestamp.now(),
  };
}

export function subscriptionFromDoc(data: any): SubscriptionData | undefined {
  if (data == null || data.expiresAt == null) return undefined;
  return {
    productId: data.productId,
    period: data.period,
    teamsAllowed: data.teamsAllowed,
    status: data.status,
    trialEndMs: data.trialEnd == null ? null : data.trialEnd.toMillis(),
    expiresAtMs: data.expiresAt.toMillis(),
    store: data.store,
    lastEventMs: data.lastEventMs ?? 0,
    autoRenew: typeof data.autoRenew === "boolean" ? data.autoRenew : undefined,
  };
}

/** `users/{uid}.access` : lu par les règles Firestore (`active` et `until`). */
export function accessToDoc(access: Access): { active: boolean; until: firestore.Timestamp } {
  return { active: access.active, until: Timestamp.fromMillis(access.untilMs) };
}

/**
 * Écrit l'abonnement du propriétaire, puis l'accès du propriétaire et de chacun de ses comptes liés,
 * dans la transaction de l'appelant.
 */
export function writeSubscriptionAndAccess(
  tx: firestore.Transaction,
  ownerRef: firestore.DocumentReference,
  linked: firestore.QueryDocumentSnapshot[],
  sub: SubscriptionData,
  nowMs: number,
): void {
  tx.update(ownerRef, { subscription: subscriptionToDoc(sub), access: accessToDoc(computeAccess(sub, 1, nowMs)) });
  for (const doc of linked) {
    tx.update(doc.ref, { access: accessToDoc(computeAccess(sub, doc.get("teamIndex"), nowMs)) });
  }
}
