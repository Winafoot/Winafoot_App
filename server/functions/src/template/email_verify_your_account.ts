/**
 * Module du socle commun des projets.
 */
import { escapeHtml } from "../utils/html";
import { wrapEmailLayout, emailSupportParagraph, EMAIL_H1_STYLE, EMAIL_P_STYLE, EMAIL_LINK_STYLE } from "./_email_layout";

export function generateTemplateVerifyYourEmail(appName: string, verifLink: string, contactEmail?: string, logoUrl: string = ""): string {
  const content = `
    <h1 class="h3" style="${EMAIL_H1_STYLE}">V&#233;rifier votre compte</h1>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">Afin de continuer sur l&#8217;application ${escapeHtml(appName)}, merci de confirmer votre adresse e-mail avec le lien ci-dessous&#160;:</p>
    <br>
    <a href="${verifLink}" style="${EMAIL_LINK_STYLE}">Confirmer votre adresse e-mail</a>
    <br><br>
    ${emailSupportParagraph(contactEmail)}
  `;
  return wrapEmailLayout(logoUrl, content);
}
