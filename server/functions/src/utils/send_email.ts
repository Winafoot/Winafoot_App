import { Resend } from "resend";
import { UserModel } from "../model/user/user_model";
import { AppMetadataConfig } from "../model/config/app_metadata_config";
import { EnvProvider } from "../provider/env_provider";
import { describeError } from "./describe_error";
import { mailIdentity } from "./mail_identity";

/**
 * Envoie un e-mail transactionnel via Resend.
 *
 * `emailText` est la version texte brut, propre à chaque gabarit ; à défaut elle
 * est dérivée du sujet. Aucun repli ne doit décrire un « signalement » : tous les
 * e-mails passent par ici (bienvenue, vérification, mot de passe, invitation coach).
 *
 * Renvoie l'identifiant du message chez Resend.
 */
export async function sendEmail(
  config: AppMetadataConfig,
  userModel: UserModel,
  emailContent: string,
  emailSubject?: string,
  emailText?: string
): Promise<string> {
  const resendConfig = EnvProvider.instance.resendConfig;
  if (resendConfig.apiKey == null) {
    throw new Error("No resendConfig no apiKey found inside private key");
  }

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

  const resend = new Resend(resendConfig.apiKey);

  try {
    // Le SDK ne lève pas sur un refus de l'API : il renvoie `{ data, error }`.
    const { data, error } = await resend.emails.send({
      from: `${fromName} <${from}>`,
      to: [userModel.email ?? ""],
      replyTo,
      subject: `${appName} - ${subject}`,
      html: emailContent,
      text,
    });
    if (error != null) throw error;
    return data?.id ?? "";
  } catch (e: unknown) {
    // Une erreur réseau (fetch) peut embarquer la requête, en-tête Authorization (clé API)
    // compris : la journaliser telle quelle l'écrirait en clair dans Cloud Logging.
    // On ne garde que le statut et le motif renvoyé par l'API.
    throw new Error(`Resend : ${describeError(e)}`);
  }
}
