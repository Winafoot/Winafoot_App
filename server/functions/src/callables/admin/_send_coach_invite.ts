import { auth } from "firebase-admin";
import { AppConfigRepository } from "../../database/app_config/app_config_repository";
import { AppMetadataConfig } from "../../model/config/app_metadata_config";
import { UserModel } from "../../model/user/user_model";
import { generateTemplateCoachInviteEmail } from "../../template/email_coach_invite";
import { mailIdentity } from "../../utils/mail_identity";
import { sendEmail } from "../../utils/send_email";

// Le nom de l'app est déjà préfixé au sujet dans sendEmail, inutile de le répéter.
export const COACH_INVITE_SUBJECT = "Votre compte est prêt";

/**
 * Génère un lien de définition de mot de passe et l'envoie au coach.
 * Partagé par createCoach et resendInvite — un seul gabarit, un seul sujet.
 */
export async function sendCoachInvite(email: string, firstname?: string): Promise<void> {
  const config: AppMetadataConfig | undefined = await AppConfigRepository.instance.getMetadata();
  if (config == null) {
    throw new Error("app_config/metadata introuvable : impossible d'envoyer l'invitation.");
  }

  const { appName, contactEmail } = mailIdentity(config);
  const inviteLink: string = await auth().generatePasswordResetLink(email);
  const content: string = generateTemplateCoachInviteEmail(firstname ?? "", inviteLink, contactEmail, appName);

  // Version texte brut : seule chose que verront les clients mail sans HTML,
  // le lien d'invitation doit donc y figurer en clair.
  const trimmedFirstname: string = (firstname ?? "").trim();
  const greeting: string = trimmedFirstname.length > 0 ? `Bonjour ${trimmedFirstname}` : "Bonjour";
  const emailText: string =
    `${greeting}, un compte coach vient d’être ouvert pour vous sur ${appName}. Ouvrez ce lien pour choisir votre mot de passe\u00A0:\n\n` +
    `${inviteLink}\n\n` +
    `Ce lien expire au bout d’une heure et ne peut servir qu’une fois. Passé ce délai, demandez un nouvel envoi à votre contact ${appName}.` +
    (contactEmail != null ? `\n\nBesoin d’aide\u00A0? Écrivez-nous à ${contactEmail}.` : "");

  const recipient: UserModel = Object.assign(new UserModel(), { email, firstname: firstname ?? "" });
  await sendEmail(config, recipient, content, COACH_INVITE_SUBJECT, emailText);
}
