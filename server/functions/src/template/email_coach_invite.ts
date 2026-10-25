import { escapeHtml } from "../utils/html";
import { wrapEmailLayout, emailSupportParagraph, EMAIL_H1_STYLE, EMAIL_P_STYLE, EMAIL_LINK_STYLE } from "./_email_layout";

/**
 * E-mail unique envoyé au coach dont le compte vient d'être créé depuis le
 * back-office. Remplace l'e-mail de bienvenue du skeleton pour ces comptes
 * (cf. le garde `invitedByAdmin` dans triggers/user/on_create_user.ts).
 */
export function generateTemplateCoachInviteEmail(firstname: string, inviteLink: string, contactEmail?: string, appName: string = "Wina", logoUrl: string = ""): string {
  const name = escapeHtml(firstname.trim());
  const app = escapeHtml(appName);
  const greeting = name.length > 0 ? `Bonjour ${name}` : "Bonjour";
  const content = `
    <h1 class="h3" style="${EMAIL_H1_STYLE}" align="left">Votre compte ${app} est pr&#234;t</h1>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">${greeting}, un compte coach vient d&#8217;&#234;tre ouvert pour vous sur ${app}. Choisissez votre mot de passe pour y acc&#233;der.</p>
    <br>
    <a href="${inviteLink}" style="${EMAIL_LINK_STYLE}">D&#233;finir mon mot de passe</a>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left"><br>Ce lien expire au bout d&#8217;une heure et ne peut servir qu&#8217;une fois. Pass&#233; ce d&#233;lai, demandez un nouvel envoi &#224; votre contact ${app}.</p>
    <br>
    ${emailSupportParagraph(contactEmail)}
  `;
  return wrapEmailLayout(logoUrl, content, appName);
}
