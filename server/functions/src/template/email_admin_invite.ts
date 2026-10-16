import { escapeHtml } from "../utils/html";
import { wrapEmailLayout, emailSupportParagraph, EMAIL_H1_STYLE, EMAIL_P_STYLE, EMAIL_LINK_STYLE } from "./_email_layout";

/** Adresse du back-office : l'e-mail la donne, car le lien de définition du mot de passe n'y ramène pas. */
export const ADMIN_BACKOFFICE_URL = "https://wina-admin.web.app";

/**
 * E-mail envoyé à un administrateur dont le compte vient d'être créé (ou qui a besoin d'un nouveau
 * lien) depuis la vue « Administrateurs » du back-office. Toutes les valeurs insérées sont échappées.
 */
export function generateTemplateAdminInviteEmail(displayName: string, inviteLink: string, contactEmail: string | undefined, appName: string = "Wina", logoUrl: string = ""): string {
  const name = escapeHtml(displayName.trim());
  const app = escapeHtml(appName);
  const greeting = name.length > 0 ? `Bonjour ${name}` : "Bonjour";
  const content = `
    <h1 class="h3" style="${EMAIL_H1_STYLE}" align="left">Votre acc&#232;s au back-office ${app} est pr&#234;t</h1>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">${greeting}, un compte administrateur vient d&#8217;&#234;tre ouvert pour vous sur le back-office ${app}. Choisissez votre mot de passe pour y acc&#233;der.</p>
    <br>
    <a href="${escapeHtml(inviteLink)}" style="${EMAIL_LINK_STYLE}">D&#233;finir mon mot de passe</a>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left"><br>Ce lien expire au bout d&#8217;une heure et ne peut servir qu&#8217;une fois. Une fois le mot de passe d&#233;fini, connectez-vous sur ${escapeHtml(ADMIN_BACKOFFICE_URL)}.</p>
    <br>
    ${emailSupportParagraph(contactEmail)}
  `;
  return wrapEmailLayout(logoUrl, content);
}
