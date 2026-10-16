import { auth } from "firebase-admin";
import { AppConfigRepository } from "../../database/app_config/app_config_repository";
import { AppMetadataConfig } from "../../model/config/app_metadata_config";
import { UserModel } from "../../model/user/user_model";
import { ADMIN_BACKOFFICE_URL, generateTemplateAdminInviteEmail } from "../../template/email_admin_invite";
import { mailIdentity } from "../../utils/mail_identity";
import { sendEmail } from "../../utils/send_email";

// Le nom de l'app est déjà préfixé au sujet dans sendEmail.
export const ADMIN_INVITE_SUBJECT = "Votre accès au back-office est prêt";

/**
 * Génère un lien de définition de mot de passe et l'envoie à l'administrateur. Même mécanisme que
 * l'invitation des coachs (_send_coach_invite.ts), gabarit et libellés propres aux administrateurs.
 * Le lien n'est ni journalisé ni renvoyé à l'appelant : seul le destinataire le reçoit.
 */
export async function sendAdminInvite(email: string, displayName?: string): Promise<void> {
  const config: AppMetadataConfig | undefined = await AppConfigRepository.instance.getMetadata();
  if (config == null) {
    throw new Error("app_config/metadata introuvable : impossible d'envoyer l'invitation.");
  }

  const { appName, contactEmail } = mailIdentity(config);
  const inviteLink: string = await auth().generatePasswordResetLink(email);
  const content: string = generateTemplateAdminInviteEmail(displayName ?? "", inviteLink, contactEmail, appName);

  const trimmedName: string = (displayName ?? "").trim();
  const greeting: string = trimmedName.length > 0 ? `Bonjour ${trimmedName}` : "Bonjour";
  const emailText: string =
    `${greeting}, un compte administrateur vient d’être ouvert pour vous sur le back-office ${appName}. Ouvrez ce lien pour choisir votre mot de passe :\n\n` +
    `${inviteLink}\n\n` +
    `Ce lien expire au bout d’une heure et ne peut servir qu’une fois. Une fois le mot de passe défini, connectez-vous sur ${ADMIN_BACKOFFICE_URL}.` +
    (contactEmail != null ? `\n\nBesoin d’aide ? Écrivez-nous à ${contactEmail}.` : "");

  const recipient: UserModel = Object.assign(new UserModel(), { email, firstname: displayName ?? "" });
  await sendEmail(config, recipient, content, ADMIN_INVITE_SUBJECT, emailText);
}
