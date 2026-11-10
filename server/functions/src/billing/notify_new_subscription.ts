/**
 * Mail interne à l'adresse `app_config/metadata.salesEmail` à chaque nouvel abonnement. Une erreur d'envoi est
 * journalisée et ne remonte jamais : un mail raté ne doit pas faire rejouer le webhook RevenueCat.
 */
import type { firestore } from "firebase-admin";
import { AppConfigRepository } from "../database/app_config/app_config_repository";
import { UserModel } from "../model/user/user_model";
import { logger } from "../runtime/firebase";
import { describeError } from "../utils/describe_error";
import { mailIdentity } from "../utils/mail_identity";
import { sendEmail } from "../utils/send_email";
import { formatDateFr, formulaLabel, newSubscriptionKind, priceLabel, storeName } from "./billing_mail";
import type { RevenueCatEvent, SubscriptionData } from "./subscription";
import { generateTemplateNewSubscriptionNotice, newSubscriptionNoticeText, type NewSubscriptionNoticeData } from "../template/email_subscription";

/** Renvoie `true` si le mail est parti. Sans `salesEmail` dans la configuration, rien n'est envoyé. */
export async function notifyNewSubscription(
  owner: firestore.DocumentSnapshot<firestore.DocumentData>,
  sub: SubscriptionData,
  event: RevenueCatEvent,
): Promise<boolean> {
  try {
    const config = await AppConfigRepository.instance.getMetadata();
    if (config == null) throw new Error("app_config/metadata introuvable.");
    const to = typeof config.salesEmail === "string" ? config.salesEmail.trim() : "";
    if (to === "") return false;

    const { appName } = mailIdentity(config);
    const offerCode = typeof event.offer_code === "string" && event.offer_code !== "" ? event.offer_code : undefined;
    const data: NewSubscriptionNoticeData = {
      appName,
      team: String(owner.get("teamName") ?? ""),
      coachEmail: String(owner.get("email") ?? owner.id),
      formula: formulaLabel(sub),
      storeName: storeName(sub.store),
      kind: newSubscriptionKind(event),
      offerCode,
      price: priceLabel(event),
      dateLabel: formatDateFr(sub.expiresAtMs),
    };

    const recipient: UserModel = Object.assign(new UserModel(), { email: to, firstname: appName });
    await sendEmail(config, recipient, generateTemplateNewSubscriptionNotice(data), `Nouvel abonnement : ${data.formula}`, newSubscriptionNoticeText(data));
    return true;
  } catch (e) {
    logger.error(`[Error] notifyNewSubscription : ${describeError(e)}`);
    return false;
  }
}
