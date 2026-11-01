import { createHash, timingSafeEqual } from "node:crypto";
import type { Response } from "express";
import { firestore } from "firebase-admin";
import type { Request } from "firebase-functions/v2/https";
import { isFirstPayment, isTrialStart } from "../../billing/billing_mail";
import { sendSubscriptionMail } from "../../billing/send_subscription_mail";
import { applyEvent, type RevenueCatEvent, type SubscriptionData } from "../../billing/subscription";
import { subscriptionFromDoc, writeSubscriptionAndAccess } from "../../billing/store";
import { readSecret, REVENUECAT_WEBHOOK_SECRET } from "../../config/secrets";
import { logger } from "../../runtime/firebase";
import { describeError } from "../../utils/describe_error";

/**
 * Webhook RevenueCat : reçoit chaque événement d'abonnement et met à jour l'état serveur.
 *
 * - Autorisation : l'en-tête `Authorization` configuré dans RevenueCat doit valoir
 *   `Bearer <REVENUECAT_WEBHOOK_SECRET>` (comparaison à temps constant).
 * - `app_user_id` est l'uid Firebase du PROPRIÉTAIRE (Purchases.logIn côté app). Un identifiant
 *   inconnu (ID anonyme RevenueCat) ou celui d'un compte lié est ignoré avec un 200 : RevenueCat
 *   rejoue tout ce qui n'est pas en 2xx.
 * - Les événements « sandbox » sont acceptés en production : les achats TestFlight et les testeurs
 *   de licence Google en sont.
 * - 500 sur une panne Firestore : RevenueCat rejoue, et l'horodatage de l'événement rend le rejeu inoffensif.
 */
export default async (req: Request, res: Response): Promise<void> => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const secret = readSecret(REVENUECAT_WEBHOOK_SECRET);
  if (secret == null || !safeEqual(req.get("authorization") ?? "", `Bearer ${secret}`)) {
    res.status(401).send("Unauthorized");
    return;
  }

  const event = parseEvent(req.body);
  if (event == null) {
    res.status(400).send("Bad Request");
    return;
  }

  try {
    const paid = await applyToOwner(event);
    // Début d'essai ou premier paiement : mail correspondant, hors transaction. Un échec d'envoi est journalisé et
    // ne fait pas rejouer l'événement (sendSubscriptionMail ne lève jamais).
    if (paid.owner != null && paid.sub != null && paid.kind != null) await sendSubscriptionMail(paid.kind, paid.owner, paid.sub);
    res.status(200).send("ok");
  } catch (e) {
    logger.error(`[Error] revenuecatWebhook: ${describeError(e)}`);
    res.status(500).send("Internal Server Error");
  }
};

/** Propriétaire, abonnement et type de mail à envoyer (début d'essai, premier paiement) ; vide sinon. */
interface PaidResult {
  owner?: firestore.DocumentSnapshot;
  sub?: SubscriptionData;
  kind?: "trial-started" | "payment-confirmed";
}

async function applyToOwner(event: RevenueCatEvent): Promise<PaidResult> {
  const db = firestore();
  const ownerRef = db.collection("users").doc(event.app_user_id);
  const result: PaidResult = {};

  await db.runTransaction(async (tx) => {
    // La transaction peut être rejouée : on repart d'un résultat vide.
    result.owner = undefined;
    result.sub = undefined;
    result.kind = undefined;
    const owner = await tx.get(ownerRef);
    // Compte inconnu, ou compte lié : l'abonnement n'appartient qu'au propriétaire.
    if (!owner.exists || owner.get("ownerUid") != null) return;

    const linked = await tx.get(db.collection("users").where("ownerUid", "==", event.app_user_id));
    const prev = subscriptionFromDoc(owner.get("subscription"));
    const next = applyEvent(prev, event);
    if (next == null) return;

    writeSubscriptionAndAccess(tx, ownerRef, linked.docs, next, Date.now());

    // Un seul mail par paiement : le rejeu d'un même événement ne renvoie rien.
    const lastMailMs: number = owner.get("billingMail.paymentEventMs") ?? 0;
    if (isFirstPayment(prev, next, event) && event.event_timestamp_ms > lastMailMs) {
      tx.update(ownerRef, { "billingMail.paymentEventMs": event.event_timestamp_ms });
      result.owner = owner;
      result.sub = next;
      result.kind = "payment-confirmed";
    } else if (isTrialStart(next, event) && event.event_timestamp_ms > (owner.get("billingMail.trialStartEventMs") ?? 0)) {
      tx.update(ownerRef, { "billingMail.trialStartEventMs": event.event_timestamp_ms });
      result.owner = owner;
      result.sub = next;
      result.kind = "trial-started";
    }
  });
  return result;
}

function parseEvent(body: any): RevenueCatEvent | null {
  const e = body?.event;
  if (typeof e?.type !== "string" || typeof e?.app_user_id !== "string" || e.app_user_id.length === 0 || typeof e?.event_timestamp_ms !== "number") {
    return null;
  }
  return e as RevenueCatEvent;
}

function safeEqual(a: string, b: string): boolean {
  return timingSafeEqual(createHash("sha256").update(a).digest(), createHash("sha256").update(b).digest());
}
