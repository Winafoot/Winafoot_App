/**
 * Module du socle commun des projets.
 */
import { escapeHtml } from "../utils/html";
import { wrapEmailLayout, emailSupportParagraph, EMAIL_H1_STYLE, EMAIL_P_STYLE, EMAIL_LINK_STYLE } from "./_email_layout";

export function generateTemplateResetPasswordEmail(fullname: string, verifLink: string, contactEmail?: string, logoUrl: string = "", appName: string = ""): string {
  const title = appName ? `R&#233;initialisation du mot de passe ${escapeHtml(appName)}` : `Bonjour ${escapeHtml(fullname)}`;
  const content = `
    <h1 class="h3" style="${EMAIL_H1_STYLE}" align="left">${title}</h1>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">Vous avez fait la demande de r&#233;initialisation de mot de passe. Cliquez sur le lien ci-dessous pour d&#233;finir votre nouveau mot de passe.</p>
    <br>
    <a href="${verifLink}" style="${EMAIL_LINK_STYLE}">Changer mon mot de passe</a>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left"><br>Si vous n&#8217;&#234;tes pas &#224; l&#8217;origine de cette demande, merci d&#8217;ignorer ce message.</p>
    <br>
    ${emailSupportParagraph(contactEmail)}
  `;
  return wrapEmailLayout(logoUrl, content);
}
