/**
 * Envoi des e-mails d'abonnement (confirmation de paiement, rappel de fin d'essai). Une erreur d'envoi est
 * journalisée et ne remonte jamais : un mail raté ne doit ni faire rejouer le webhook RevenueCat ni bloquer le
 * passage quotidien des rappels.
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
  generateTemplateTrialEndingEmail,
  generateTemplateTrialStartedEmail,
  paymentConfirmedText,
  trialEndingText,
  trialStartedText,
  type SubscriptionMailData,
} from "../template/email_subscription";

export type SubscriptionMailKind = "trial-started" | "payment-confirmed" | "trial-ending";

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
      // Échéance : fin de l'essai (début et rappel), prochain renouvellement pour la confirmation de paiement.
      dateLabel: formatDateFr(kind === "payment-confirmed" ? sub.expiresAtMs : (sub.trialEndMs ?? sub.expiresAtMs)),
    };

    const user = UserModel.fromFirestore(owner);
    if (kind === "payment-confirmed") {
      await sendEmail(config, user, generateTemplatePaymentConfirmedEmail(data), "Paiement confirmé", paymentConfirmedText(data));
    } else if (kind === "trial-started") {
      await sendEmail(config, user, generateTemplateTrialStartedEmail(data), "Votre essai gratuit commence", trialStartedText(data));
    } else {
      await sendEmail(config, user, generateTemplateTrialEndingEmail(data), "Votre essai gratuit se termine bientôt", trialEndingText(data));
    }
    return true;
  } catch (e) {
    logger.error(`[Error] sendSubscriptionMail(${kind}) : ${describeError(e)}`);
    return false;
  }
}
