import { firestore } from "firebase-admin";
import { isTrialReminderDue, trialReminderWindow } from "../../billing/billing_mail";
import { sendSubscriptionMail } from "../../billing/send_subscription_mail";
import { subscriptionFromDoc } from "../../billing/store";
import { logger } from "../../runtime/firebase";
import { describeError } from "../../utils/describe_error";

/**
 * Passage quotidien : rappelle aux propriétaires dont l'essai gratuit se termine dans 24 à 48 h que le premier
 * prélèvement approche, avec le lien pour résilier. Un seul rappel par essai (`billingMail.trialReminderSentMs`).
 *
 * Requête sur une seule plage (`subscription.trialEnd`) : aucun index composite à créer ; le statut est filtré ici.
 */
export async function sendTrialRemindersHandler(): Promise<void> {
  const now = Date.now();
  const { fromMs, toMs } = trialReminderWindow(now);
  const snap = await firestore()
    .collection("users")
    .where("subscription.trialEnd", ">", firestore.Timestamp.fromMillis(fromMs))
    .where("subscription.trialEnd", "<=", firestore.Timestamp.fromMillis(toMs))
    .get();

  let sent = 0;
  for (const doc of snap.docs) {
    try {
      // Un compte d'équipe liée n'a pas d'abonnement propre ni d'adresse réelle.
      if (doc.get("ownerUid") != null) continue;
      const sub = subscriptionFromDoc(doc.get("subscription"));
      const alreadySent = doc.get("billingMail.trialReminderSentMs") != null;
      if (sub == null || !isTrialReminderDue(sub, now, alreadySent)) continue;

      if (await sendSubscriptionMail("trial-ending", doc, sub)) {
        await doc.ref.update({ "billingMail.trialReminderSentMs": now });
        sent++;
      }
    } catch (e) {
      logger.error(`[Error] sendTrialReminders : ${describeError(e)}`);
    }
  }
  logger.info(`[Info] sendTrialReminders : ${sent} rappel(s) envoyé(s) sur ${snap.size} essai(s) dans la fenêtre.`);
}
