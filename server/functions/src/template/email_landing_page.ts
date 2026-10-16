/**
 * Module du socle commun des projets.
 */
import { wrapEmailLayout, EMAIL_H1_STYLE, EMAIL_P_STYLE, EMAIL_HR } from "./_email_layout";

export function generateTemplateLandingPageEmail(
  appName: string,
  name: string,
  subject: string,
  email: string,
  message: string,
  logoUrl: string = ""
): string {
  const content = `
    <h1 class="h3" style="${EMAIL_H1_STYLE}" align="left">Nouvelle demande de contact ${appName}</h1>
    <br>
    ${EMAIL_HR}
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">Nom&#160;: ${name}</p>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">E-mail&#160;: ${email}</p>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">Sujet&#160;: ${subject}</p>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">${message}</p>
    <br>
    ${EMAIL_HR}
  `;
  return wrapEmailLayout(logoUrl, content);
}
