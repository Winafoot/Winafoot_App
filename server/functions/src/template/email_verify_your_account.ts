/**
 * Module du socle commun des projets.
 */
import { escapeHtml } from "../utils/html";
import { OTP_TTL_MS } from "../utils/otp_code";
import { wrapEmailLayout, emailSupportParagraph, emailCodeBlock, EMAIL_H1_STYLE, EMAIL_P_STYLE, EMAIL_SUPPORT_P_STYLE } from "./_email_layout";

export function generateTemplateVerifyYourEmail(appName: string, code: string, contactEmail?: string, logoUrl: string = ""): string {
  const minutes: number = OTP_TTL_MS / 60_000;
  const content = `
    <h1 class="h3" style="${EMAIL_H1_STYLE}">Confirmez votre adresse e-mail</h1>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">Pour continuer sur ${escapeHtml(appName)}, saisissez ce code dans l&#8217;application&#160;:</p>
    <br>
    ${emailCodeBlock(code)}
    <br>
    <p style="${EMAIL_SUPPORT_P_STYLE}" align="left">Ce code est valable ${minutes}&#160;minutes. Si vous n&#8217;&#234;tes pas &#224; l&#8217;origine de cette demande, ignorez ce message.</p>
    <br>
    ${emailSupportParagraph(contactEmail)}
  `;
  return wrapEmailLayout(logoUrl, content, appName);
}
