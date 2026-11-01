/**
 * Module du socle commun des projets.
 */
import { auth, firestore } from "firebase-admin";
import { UserRecord } from "firebase-admin/auth";
import { generateTemplateVerifyYourEmail } from "../../template/email_verify_your_account";
import { sendEmail } from "../../utils/send_email";
import { UserProvider } from "../../provider/user_provider";
import { UserModelNullable } from "../../model/user/user_model";
import { TimestampNullable } from "../../utils/type";
import { AppConfigRepository } from "../../database/app_config/app_config_repository";
import { AppMetadataConfig } from "../../model/config/app_metadata_config";
import { UserSecurityMetadataModel } from "../../model/user/metadata/user_security_metadata_model";
import { logger } from "../../runtime/firebase";
import { describeError } from "../../utils/describe_error";
import { mailIdentity } from "../../utils/mail_identity";
import { discardCode, issueCode, OTP_TTL_MS } from "../../utils/otp_code";

/** Délai minimal entre deux e-mails de vérification pour un même compte (le plafond horaire s'ajoute dans l'adaptateur). */
const RESEND_DELAY_SECONDS = 30;

/**
 * Envoie le code à 6 chiffres qui vérifie l'adresse du compte `uid` (à saisir dans l'app, voir
 * verify_email_code_secured). Un nouvel envoi remplace le code précédent. Renvoie `true` si l'e-mail
 * est parti, `false` sinon (adresse déjà vérifiée, fiche absente, envoi trop récent, échec d'envoi).
 *
 * `metadata/security.lastVerifEmailAt` n'est posé qu'APRÈS un envoi réussi : un échec ne bloque
 * pas le compte pendant le délai d'attente.
 */
export default async (data: { uid: string }): Promise<boolean> => {
  try {
    const { uid } = data;
    const userRecord: UserRecord = await auth().getUser(uid);

    if (userRecord.emailVerified) {
      return false;
    }

    const user: UserModelNullable = await UserProvider.instance.getUser(uid);
    const userSecurity: UserSecurityMetadataModel | undefined = await UserProvider.instance.securityRepository.getDocument(uid);

    if (userSecurity == null) {
      logger.error("[Error] sendEmailVerification: document metadata/security absent");
      return false;
    }
    if (user == null) {
      logger.error("[Error] sendEmailVerification: fiche utilisateur absente");
      return false;
    }

    const lastVerifEmailAt: TimestampNullable = userSecurity.lastVerifEmailAt;

    if (lastVerifEmailAt != null) {
      const diffSeconds: number = (Date.now() - lastVerifEmailAt.toDate().getTime()) / 1000;
      if (diffSeconds < RESEND_DELAY_SECONDS) {
        return false;
      }
    }

    const config: AppMetadataConfig | undefined = await AppConfigRepository.instance.getMetadata();
    if (config == null) {
      logger.error("[Error] sendEmailVerification: app_config/metadata introuvable");
      return false;
    }

    const code: string = await issueCode("verify-email", uid);
    const { appName, contactEmail } = mailIdentity(config);
    const emailContent = generateTemplateVerifyYourEmail(appName, code, contactEmail);

    // Version texte brut : seule chose que verront les clients mail sans HTML,
    // le code doit donc y figurer en clair.
    const emailText: string =
      `Pour continuer sur ${appName}, saisissez ce code dans l’application pour confirmer votre adresse e-mail : ${code}\n\n` +
      `Ce code est valable ${OTP_TTL_MS / 60_000} minutes.` +
      (contactEmail != null ? `\n\nBesoin d’aide ? Écrivez-nous à ${contactEmail}.` : "");

    try {
      await sendEmail(config, user, emailContent, "Votre code de vérification", emailText);
    } catch (e) {
      // Un code jamais reçu ne doit pas rester valable.
      await discardCode("verify-email", uid);
      throw e;
    }

    await UserProvider.instance.securityRepository.updateField(uid, "lastVerifEmailAt", firestore.FieldValue.serverTimestamp());

    return true;
  } catch (e) {
    logger.error(`[Error] sendEmailVerification: ${describeError(e)}`);
    return false;
  }
};
