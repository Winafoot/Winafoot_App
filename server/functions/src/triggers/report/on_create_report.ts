/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";
import { AppConfigRepository } from "../../database/app_config/app_config_repository";
import { UserModel } from "../../model/user/user_model";
import { type LegacyEventContext, logger } from "../../runtime/firebase";
import { generateTemplateReportEmail } from "../../template/email_report";
import { describeError } from "../../utils/describe_error";
import { mailIdentity } from "../../utils/mail_identity";
import { sendEmail } from "../../utils/send_email";

export const REPORT_SUBJECT = "Nouveau signalement";

/**
 * Signalement créé (collection racine `reports`) : prévient l'adresse de contact de l'app
 * (`app_config/metadata.contactEmail`), avec l'expéditeur configuré dans `app_config/metadata.mail`
 * (voir utils/send_email.ts). Sans l'une ou l'autre, rien n'est envoyé : aucune adresse de repli.
 * Le signalement est déjà enregistré : un échec d'envoi est journalisé et ne fait pas échouer le trigger.
 */
export default async (snap: firestore.QueryDocumentSnapshot<firestore.DocumentData>, _context: LegacyEventContext): Promise<void> => {
  try {
    await sendReportEmail(snap);
  } catch (e) {
    logger.error(`[onCreateReport] e-mail de signalement non envoyé : ${describeError(e)}`);
  }
};

async function sendReportEmail(snap: firestore.QueryDocumentSnapshot<firestore.DocumentData>): Promise<void> {
  const config = await AppConfigRepository.instance.getMetadata();
  if (config == null) {
    throw new Error("app_config/metadata introuvable.");
  }
  const { appName, contactEmail } = mailIdentity(config);
  if (contactEmail == null) {
    throw new Error("app_config/metadata : contactEmail est absent, aucun destinataire pour le signalement.");
  }

  const report = snap.data();
  const type = report.type == "report" ? "signalement" : "annulation";
  const categories = Array.isArray(report.categories) ? report.categories.filter((c: unknown) => typeof c === "string").join(", ") : "";
  const firstFile = Array.isArray(report.files) && typeof report.files[0] === "string" ? report.files[0] : "";
  const description = typeof report.description === "string" ? report.description : "";
  const baseUrl = typeof config.baseUrl === "string" ? config.baseUrl : "";

  const object = report.objectReported instanceof firestore.DocumentReference ? report.objectReported : undefined;
  const person = report.fromId instanceof firestore.DocumentReference ? report.fromId : undefined;
  const sendAt = report.sendAt instanceof firestore.Timestamp ? report.sendAt : undefined;

  const emailContent = generateTemplateReportEmail(
    appName,
    type,
    sendAt?.toDate().toLocaleDateString("fr-FR") ?? "",
    `${baseUrl}~2Fusers~2F${person?.id ?? ""}`,
    person?.id ?? "",
    `${baseUrl}${object?.path ?? ""}`,
    object?.id ?? "",
    `${baseUrl}~2Freports~2F${snap.id}`,
    categories,
    firstFile,
    description
  );

  const recipient: UserModel = Object.assign(new UserModel(), { email: contactEmail, firstname: appName });
  await sendEmail(config, recipient, emailContent, REPORT_SUBJECT, "Nouveau signalement, merci de charger l'email au format HTML pour voir les détails.");
}
