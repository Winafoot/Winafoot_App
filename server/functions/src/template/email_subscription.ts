/**
 * Gabarits des e-mails d'abonnement : confirmation du premier paiement, et rappel avant la fin de l'essai gratuit.
 */
import { escapeHtml } from "../utils/html";
import { EMAIL_H1_STYLE, EMAIL_P_STYLE, EMAIL_PRIMARY, emailSupportParagraph, wrapEmailLayout } from "./_email_layout";

export interface SubscriptionMailData {
  appName: string;
  contactEmail?: string;
  /** « 2 équipes · mensuelle » */
  formula: string;
  /** « l’App Store » ou « Google Play » */
  storeName: string;
  /** Page de gestion de l'abonnement dans le store. */
  manageUrl: string;
  /** Date d'échéance déjà mise en forme (« 28 octobre 2026 »). */
  dateLabel: string;
}

function manageButton(url: string): string {
  return `<table role="presentation" border="0" cellpadding="0" cellspacing="0"><tbody><tr><td align="center" bgcolor="${EMAIL_PRIMARY}" style="border-radius: 999px; background-color: ${EMAIL_PRIMARY};"><a href="${escapeHtml(url)}" style="display: inline-block; padding: 12px 26px; font-size: 16px; font-weight: 700; color: #ffffff; text-decoration: none;">Gérer mon abonnement</a></td></tr></tbody></table>`;
}

/** Premier paiement reçu : l'abonnement est actif. */
export function generateTemplatePaymentConfirmedEmail(d: SubscriptionMailData): string {
  const content = `
    <h1 class="h3" style="${EMAIL_H1_STYLE}" align="left">Paiement confirmé</h1>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">Merci, votre abonnement ${escapeHtml(d.appName)} est actif.</p>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">
      <strong>Formule&#160;:</strong> ${escapeHtml(d.formula)}<br>
      <strong>Prochain renouvellement&#160;:</strong> ${escapeHtml(d.dateLabel)}
    </p>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">Le reçu est envoyé par ${escapeHtml(d.storeName)}. Vous pouvez changer de formule ou résilier à tout moment depuis les réglages de votre abonnement&#160;:</p>
    <br>
    ${manageButton(d.manageUrl)}
    <br>
    ${emailSupportParagraph(d.contactEmail)}
  `;
  return wrapEmailLayout("", content, d.appName);
}

/** Début de l'essai gratuit : rien n'est débité maintenant, premier prélèvement à la fin de l'essai. */
export function generateTemplateTrialStartedEmail(d: SubscriptionMailData): string {
  const content = `
    <h1 class="h3" style="${EMAIL_H1_STYLE}" align="left">Votre essai gratuit commence</h1>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">Bienvenue dans ${escapeHtml(d.appName)}&#160;! Vous pouvez utiliser toutes les fonctionnalités gratuitement jusqu&#8217;au <strong>${escapeHtml(d.dateLabel)}</strong>.</p>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">
      <strong>Formule&#160;:</strong> ${escapeHtml(d.formula)}<br>
      <strong>Rien n&#8217;est débité aujourd&#8217;hui.</strong>
    </p>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">
      À la fin de l&#8217;essai, le montant de votre formule sera prélevé automatiquement sur votre compte ${escapeHtml(d.storeName)}, puis à chaque période.
      Pour ne pas être débité, résiliez au moins 24&#160;h avant le ${escapeHtml(d.dateLabel)} depuis les réglages de votre abonnement&#160;:
    </p>
    <br>
    ${manageButton(d.manageUrl)}
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">Nous vous enverrons un rappel quelques jours avant la fin de l&#8217;essai.</p>
    <br>
    ${emailSupportParagraph(d.contactEmail)}
  `;
  return wrapEmailLayout("", content, d.appName);
}

/** Rappel : l'essai gratuit se termine, le premier prélèvement approche. */
export function generateTemplateTrialEndingEmail(d: SubscriptionMailData): string {
  const content = `
    <h1 class="h3" style="${EMAIL_H1_STYLE}" align="left">Votre essai gratuit se termine bientôt</h1>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">
      Votre période d&#8217;essai ${escapeHtml(d.appName)} se termine le <strong>${escapeHtml(d.dateLabel)}</strong>.
      À cette date, votre abonnement (${escapeHtml(d.formula)}) commence et le montant sera prélevé automatiquement sur votre compte ${escapeHtml(d.storeName)}.
    </p>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">
      Vous ne souhaitez pas continuer&#160;? Résiliez avant cette date depuis les réglages de votre abonnement, pour ne pas être débité&#160;:
    </p>
    <br>
    ${manageButton(d.manageUrl)}
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">Si vous souhaitez continuer, vous n&#8217;avez rien à faire. Bon match&#160;!</p>
    <br>
    ${emailSupportParagraph(d.contactEmail)}
  `;
  return wrapEmailLayout("", content, d.appName);
}

/** Texte brut de la confirmation de paiement. */
export function paymentConfirmedText(d: SubscriptionMailData): string {
  return (
    `Paiement confirmé. Merci, votre abonnement ${d.appName} est actif.\n\n` +
    `Formule : ${d.formula}\nProchain renouvellement : ${d.dateLabel}\n\n` +
    `Le reçu est envoyé par ${d.storeName}. Gérer ou résilier votre abonnement : ${d.manageUrl}`
  );
}

/** Texte brut du début d'essai. */
export function trialStartedText(d: SubscriptionMailData): string {
  return (
    `Votre essai gratuit ${d.appName} commence. Toutes les fonctionnalités sont gratuites jusqu'au ${d.dateLabel}.\n\n` +
    `Formule : ${d.formula}. Rien n'est débité aujourd'hui.\n\n` +
    `À la fin de l'essai, le montant sera prélevé automatiquement sur votre compte ${d.storeName}. ` +
    `Pour ne pas être débité, résiliez au moins 24 h avant le ${d.dateLabel} : ${d.manageUrl}`
  );
}

/** Texte brut du rappel de fin d'essai. */
export function trialEndingText(d: SubscriptionMailData): string {
  return (
    `Votre essai gratuit ${d.appName} se termine le ${d.dateLabel}.\n\n` +
    `À cette date, votre abonnement (${d.formula}) commence et le montant sera prélevé automatiquement sur votre compte ${d.storeName}.\n\n` +
    `Pour ne pas être débité, résiliez avant cette date : ${d.manageUrl}`
  );
}

