import { firestore } from "firebase-admin";
import { UserModel } from "../../model/user/user_model";
import { sendEmail } from "../../utils/send_email";
import { generateTemplateWelcomeEmail } from "../../template/email_welcome";
import { AppConfigRepository } from "../../database/app_config/app_config_repository";
import { AppMetadataConfig } from "../../model/config/app_metadata_config";
import { type LegacyEventContext, logger } from "../../runtime/firebase";
import { describeError } from "../../utils/describe_error";
import { mailIdentity } from "../../utils/mail_identity";

/**
 * Fiche créée : e-mail de bienvenue, sauf pour les comptes créés depuis le back-office, qui
 * reçoivent le seul e-mail d'invitation, et pour les comptes d'équipe liés. La fiche est déjà enregistrée : un échec d'envoi est
 * journalisé et ne fait pas échouer le trigger.
 */
export default async (snap: firestore.QueryDocumentSnapshot<firestore.DocumentData>, context: LegacyEventContext) => {
  const id: string = context.params.userId;

  // Seul l'identifiant : le modèle contient e-mail, nom et téléphone.
  logger.info(`[Info] onCreateUser : ${id}`);

  // On lit le snapshot et non le modèle : UserModel est une classe à champs fixes qui ne
  // déclare pas `invitedByAdmin`.
  // Un compte d'équipe lié (ownerUid) a une adresse technique : aucun e-mail ne peut lui être envoyé.
  if (snap.get("invitedByAdmin") === true || snap.get("ownerUid") != null) {
    return;
  }

  try {
    await sendWelcomeEmail(UserModel.fromFirestore(snap));
  } catch (e) {
    logger.error(`[onCreateUser] e-mail de bienvenue non envoyé : ${describeError(e)}`);
  }
};

async function sendWelcomeEmail(userModel: UserModel): Promise<void> {
  const config: AppMetadataConfig | undefined = await AppConfigRepository.instance.getMetadata();
  if (config == null) {
    throw new Error("app_config/metadata introuvable.");
  }

  const { appName, contactEmail } = mailIdentity(config);
  const emailContent = generateTemplateWelcomeEmail(appName, contactEmail);

  // Version texte brut : seule chose que verront les clients mail sans HTML.
  // Le sujet est préfixé par le nom de l'app dans sendEmail, inutile de le répéter.
  const emailText: string =
    `Bienvenue sur ${appName} !\n\n` +
    "Nous sommes ravis que vous ayez décidé de nous rejoindre. En vous connectant, vous accédez à l’ensemble des fonctionnalités de l’application.\n\n" +
    (contactEmail != null ? `Une question ou une remarque ? Écrivez-nous à ${contactEmail}.\n\n` : "") +
    `Votre équipe ${appName}`;

  await sendEmail(config, userModel, emailContent, "Bienvenue", emailText);
}
