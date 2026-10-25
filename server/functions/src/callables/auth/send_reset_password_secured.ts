import { auth } from "firebase-admin";
import { LIMITS } from "../../config/rate_limits";
import { AppConfigRepository } from "../../database/app_config/app_config_repository";
import { UserModel } from "../../model/user/user_model";
import { UserProvider } from "../../provider/user_provider";
import { HttpsError, logger } from "../../runtime/firebase";
import { generateTemplateResetPasswordEmail } from "../../template/email_reset_password";
import { consumeAll } from "../../utils/rate_limit";
import { mailIdentity } from "../../utils/mail_identity";
import { sendEmail } from "../../utils/send_email";
import { describeError } from "../../utils/describe_error";
import { discardCode, issueCode, OTP_TTL_MS } from "../../utils/otp_code";

/**
 * sendResetPassword : callable public, appelé avant connexion par « Mot de passe oublié ».
 *
 * Envoie un code à 6 chiffres, que l'app échange contre un nouveau mot de passe (confirmPasswordReset).
 *
 * - La réponse est toujours `true`, que l'adresse ait un compte ou non, et même si l'envoi échoue :
 *   le client ne lit pas le résultat (login_page.dart).
 * - Le compte Auth fait foi : destinataire et prénom viennent du compte et de sa fiche lue par uid,
 *   jamais d'une fiche retrouvée par son champ `email`.
 *
 * Limites de débit : par IP dans l'adaptateur (runtime/v2_limited.ts), par compte ici, et plafond
 * global des e-mails déclenchés par un appel public.
 */
export default async (data: { email?: unknown }): Promise<boolean> => {
  if (typeof data?.email !== "string" || data.email.trim().length === 0) {
    throw new HttpsError("invalid-argument", "email est requis.");
  }

  try {
    await sendResetCode(data.email);
  } catch (e) {
    // Aucune différence visible entre « pas de compte » et « panne » côté client.
    logger.warn(`[Warn] sendResetPassword: aucun e-mail envoyé : ${describeError(e)}`);
  }

  return true;
};

async function sendResetCode(email: string): Promise<void> {
  const account = await auth().getUserByEmail(email.trim());
  if (account.email == null) return;

  // Par compte (pas par adresse saisie) : une adresse inconnue n'a pas de compte et ne crée aucun
  // compteur, et les variantes de casse d'une adresse désignent le même uid. Puis le plafond
  // global des mails publics, qui protège le quota Resend des invitations de coachs.
  const allowed = await consumeAll([
    ["reset-account", account.uid, LIMITS.resetPasswordAccount],
    ["reset-account-day", account.uid, LIMITS.resetPasswordAccountDay],
    ["public-mail-global", "all", LIMITS.publicMailGlobal],
  ]);
  if (!allowed) return;

  const config = await AppConfigRepository.instance.getMetadata();
  if (config == null) {
    throw new Error("app_config/metadata introuvable.");
  }

  const code: string = await issueCode("reset-password", account.uid);
  const profile = await UserProvider.instance.getUser(account.uid);

  const { appName, contactEmail } = mailIdentity(config);
  const displayName: string = profile?.firstname ?? profile?.pseudo ?? "";
  const emailContent = generateTemplateResetPasswordEmail(displayName, code, contactEmail, "", appName);

  // Version texte brut : seule chose que verront les clients mail sans HTML,
  // le code doit donc y figurer en clair.
  const emailText: string =
    `Vous avez demandé la réinitialisation de votre mot de passe. Saisissez ce code dans l’application pour en définir un nouveau : ${code}\n\n` +
    `Ce code est valable ${OTP_TTL_MS / 60_000} minutes.\n\n` +
    "Si vous n’êtes pas à l’origine de cette demande, ignorez ce message : votre mot de passe reste inchangé." +
    (contactEmail != null ? `\n\nBesoin d’aide ? Écrivez-nous à ${contactEmail}.` : "");

  const recipient: UserModel = Object.assign(new UserModel(), { email: account.email, firstname: profile?.firstname ?? "" });
  try {
    await sendEmail(config, recipient, emailContent, "Votre code de réinitialisation", emailText);
  } catch (e) {
    // Un code jamais reçu ne doit pas rester valable.
    await discardCode("reset-password", account.uid);
    throw e;
  }
}
