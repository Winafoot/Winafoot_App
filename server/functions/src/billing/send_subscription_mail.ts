/**
 * Envoi des e-mails d'abonnement (confirmation de paiement). Une erreur d'envoi est
 * journalisée et ne remonte jamais : un mail raté ne doit pas faire rejouer le webhook RevenueCat.
 */
import type { firestore } from "firebase-admin";
import { AppConfigRepository } from "../database/app_config/app_config_repository";
import { UserModel } from "../model/user/user_model";
import { logger } from "../runtime/firebase";
import { describeError } from "../utils/describe_error";
import { mailIdentity } from "../utils/mail_identity";
import { sendEmail } from "../utils/send_email";
import { formatDateFr, formulaLabel, manageSubscriptionUrl, storeName } from "./billing_mail";
import type { SubscriptionData } from "./subscription";
import {
  generateTemplatePaymentConfirmedEmail,
  paymentConfirmedText,
  type SubscriptionMailData,
} from "../template/email_subscription";

export type SubscriptionMailKind = "payment-confirmed";

/** Renvoie `true` si le mail est parti. `owner` est la fiche `users/{uid}` du propriétaire. */
export async function sendSubscriptionMail(
  kind: SubscriptionMailKind,
  owner: firestore.DocumentSnapshot<firestore.DocumentData>,
  sub: SubscriptionData,
): Promise<boolean> {
  try {
    const email: unknown = owner.get("email");
    if (typeof email !== "string" || email.trim().length === 0) return false;

    const config = await AppConfigRepository.instance.getMetadata();
    if (config == null) throw new Error("app_config/metadata introuvable.");

    const { appName, contactEmail } = mailIdentity(config);
    const data: SubscriptionMailData = {
      appName,
      contactEmail,
      formula: formulaLabel(sub),
      storeName: storeName(sub.store),
      manageUrl: manageSubscriptionUrl(sub.store),
      // Prochain renouvellement.
      dateLabel: formatDateFr(sub.expiresAtMs),
    };

    const user = UserModel.fromFirestore(owner);
    await sendEmail(config, user, generateTemplatePaymentConfirmedEmail(data), "Paiement confirmé", paymentConfirmedText(data));
    return true;
  } catch (e) {
    logger.error(`[Error] sendSubscriptionMail(${kind}) : ${describeError(e)}`);
    return false;
  }
}
