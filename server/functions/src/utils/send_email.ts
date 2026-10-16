import { MailerSend, EmailParams, Sender, Recipient, APIResponse } from "mailer-send-ts";
import { UserModel } from "../model/user/user_model";
import { AppMetadataConfig } from "../model/config/app_metadata_config";
import { EnvProvider } from "../provider/env_provider";
import { describeError } from "./describe_error";
import { mailIdentity } from "./mail_identity";

/**
 * Envoie un e-mail transactionnel via MailerSend.
 *
 * `emailText` est la version texte brut, propre à chaque gabarit ; à défaut elle
 * est dérivée du sujet. Aucun repli ne doit décrire un « signalement » : tous les
 * e-mails passent par ici (bienvenue, vérification, mot de passe, invitation coach).
 */
export async function sendEmail(
  config: AppMetadataConfig,
  userModel: UserModel,
  emailContent: string,
  emailSubject?: string,
  emailText?: string
): Promise<APIResponse> {
  const mailerSendConfig = EnvProvider.instance.mailerSendConfig;
  if (mailerSendConfig.apiKey == null) {
    throw new Error("No mailerSendConfig no apiKey found inside private key");
  }

  const mailersend = new MailerSend({
    apiKey: mailerSendConfig.apiKey,
  });

  const recipients = [new Recipient(userModel.email ?? "", userModel.fullName ?? "")];

  const mailConfig = config?.mail;
  if (mailConfig === undefined) throw new Error("Mail config is undefined");

  // Pas de repli sur une adresse en dur : mieux vaut échouer bruyamment que
  // d'expédier un e-mail Wina sous l'identité d'un tiers (le domaine ne serait
  // de toute façon pas authentifié SPF/DKIM pour Wina).
  const from: string | undefined = mailConfig.from;
  if (from == null || from.trim().length === 0) {
    throw new Error("app_config/metadata : mail.from est absent, envoi annulé pour ne pas expédier sous une autre identité.");
  }
  const { appName } = mailIdentity(config);
  const fromName: string = mailConfig.fromName ?? appName;
  const replyTo: string = mailConfig.replyTo ?? from;

  const subject: string = emailSubject ?? "Notification";
  const text: string = emailText ?? `${subject}. Merci d'afficher cet e-mail au format HTML pour en voir le contenu.`;

  const emailParams: EmailParams = new EmailParams()
    .setFrom(new Sender(from, fromName))
    .setTo(recipients)
    .setReplyTo(new Sender(replyTo, fromName))
    .setSubject(`${appName} - ${subject}`)
    .setHtml(emailContent)
    .setText(text);

  try {
    return await mailersend.email.send(emailParams);
  } catch (e: unknown) {
    // Le client HTTP (gaxios) attache la requête complète à ses erreurs réseau, en-tête
    // Authorization (clé API) compris : la journaliser telle quelle l'écrirait en clair
    // dans Cloud Logging. On ne garde que le statut et le motif renvoyé par l'API.
    throw new Error(`MailerSend : ${describeError(e)}`);
  }
}
