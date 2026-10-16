import { LIMITS } from "../../config/rate_limits";
import { UserModel } from "../../model/user/user_model";
import { logger } from "../../runtime/firebase";
import { generateTemplateLandingPageEmail } from "../../template/email_landing_page";
import { consume } from "../../utils/rate_limit";
import { sendEmail } from "../../utils/send_email";
import { escapeHtml, landingEndpoint, normalizeEmail, requireCaptcha } from "./_landing_endpoint";

const NAME_MAX_LENGTH = 100;
const SUBJECT_MAX_LENGTH = 200;
const MESSAGE_MAX_LENGTH = 5000;

/** Chaîne non vide de 1 à `max` caractères, sinon `undefined`. */
function field(value: unknown, max: number): string | undefined {
  if (typeof value !== "string") return undefined;
  const text = value.trim();
  return text.length > 0 && text.length <= max ? text : undefined;
}

/**
 * Formulaire de support (public/support.html : POST { name, email, subject, message }).
 * Les champs sont bornés et échappés avant d'entrer dans le HTML du mail, qui ne part que vers
 * contactEmail (app_config/metadata). Le jeton reCAPTCHA Enterprise du corps (`recaptchaToken`) est
 * vérifié côté serveur (README, section « Landing »).
 */
export default landingEndpoint(async (body, config, res) => {
  const name = field(body.name, NAME_MAX_LENGTH);
  const email = normalizeEmail(body.email);
  const subject = field(body.subject, SUBJECT_MAX_LENGTH);
  const message = field(body.message, MESSAGE_MAX_LENGTH);
  if (name == null || email == null || subject == null || message == null) {
    res.status(400).send({ message: "Invalid form" });
    return;
  }

  // Avant le plafond global : un robot sans jeton valide ne doit pas vider le quota MailerSend de tous.
  if (!(await requireCaptcha(body, res))) return;

  // Plafond global quotidien, compté APRÈS la validation : les formulaires invalides n'entament pas le
  // quota, et une armée d'IP ne vide pas le quota MailerSend partagé par tous les mails transactionnels.
  if (!(await consume("support-global", "all", LIMITS.supportGlobal))) {
    res.status(429).send({ message: "Too many requests" });
    return;
  }

  const contactEmail = config.contactEmail?.trim();
  if (!contactEmail) {
    logger.error("[Error] sendLandingPageMail: contactEmail absent de app_config/metadata");
    res.status(500).send({ message: "Service unavailable" });
    return;
  }

  const html = generateTemplateLandingPageEmail(
    config.appName ?? "Wina",
    escapeHtml(name),
    escapeHtml(subject),
    escapeHtml(email),
    escapeHtml(message).replace(/\r?\n/g, "<br>"),
  );
  const text = `Demande de renseignement de ${name} <${email}>\nSujet : ${subject}\n\n${message}`;

  await sendEmail(config, Object.assign(new UserModel(), { email: contactEmail }), html, "Demande de renseignement", text);

  res.status(200).send({ message: "Data received" });
}, { scope: "support", perIp: LIMITS.supportIp });
