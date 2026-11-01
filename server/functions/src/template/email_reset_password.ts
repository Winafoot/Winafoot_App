/**
 * Module du socle commun des projets.
 */
import { escapeHtml } from "../utils/html";
import { OTP_TTL_MS } from "../utils/otp_code";
import { DEFAULT_APP_NAME } from "../utils/mail_identity";
import { wrapEmailLayout, emailSupportParagraph, emailCodeBlock, EMAIL_H1_STYLE, EMAIL_P_STYLE, EMAIL_SUPPORT_P_STYLE } from "./_email_layout";

export function generateTemplateResetPasswordEmail(fullname: string, code: string, contactEmail?: string, logoUrl: string = "", appName: string = DEFAULT_APP_NAME): string {
  const minutes: number = OTP_TTL_MS / 60_000;
  const greeting = fullname.trim().length > 0 ? `Bonjour ${escapeHtml(fullname)}` : "Bonjour";
  const content = `
    <h1 class="h3" style="${EMAIL_H1_STYLE}" align="left">${greeting}</h1>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">Vous avez demand&#233; &#224; r&#233;initialiser votre mot de passe. Saisissez ce code dans l&#8217;application pour en choisir un nouveau&#160;:</p>
    <br>
    ${emailCodeBlock(code)}
    <br>
    <p style="${EMAIL_SUPPORT_P_STYLE}" align="left">Ce code est valable ${minutes}&#160;minutes. Si vous n&#8217;&#234;tes pas &#224; l&#8217;origine de cette demande, ignorez ce message : votre mot de passe reste inchang&#233;.</p>
    <br>
    ${emailSupportParagraph(contactEmail)}
  `;
  return wrapEmailLayout(logoUrl, content, appName);
}
