/**
 * Gabarits des e-mails d'abonnement : confirmation du premier paiement.
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

/** Texte brut de la confirmation de paiement. */
export function paymentConfirmedText(d: SubscriptionMailData): string {
  return (
    `Paiement confirmé. Merci, votre abonnement ${d.appName} est actif.\n\n` +
    `Formule : ${d.formula}\nProchain renouvellement : ${d.dateLabel}\n\n` +
    `Le reçu est envoyé par ${d.storeName}. Gérer ou résilier votre abonnement : ${d.manageUrl}`
  );
}
