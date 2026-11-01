/**
 * Module du socle commun des projets.
 */
import { escapeHtml } from "../utils/html";
import { wrapEmailLayout, EMAIL_H1_STYLE, EMAIL_P_STYLE, EMAIL_LINK_STYLE } from "./_email_layout";

/** `contactEmail` absent : la phrase d'invitation à écrire au support est omise. */
export function generateTemplateWelcomeEmail(appName: string, contactEmail?: string, logoUrl: string = ""): string {
  const app = escapeHtml(appName);
  const contact = contactEmail?.trim() ?? "";
  const closing =
    contact.length > 0
      ? `Enfin, nous vous invitons &#224; nous <a class="text-blue-400" href="mailto:${escapeHtml(contact)}" style="${EMAIL_LINK_STYLE}">contacter</a> en cas de questions ou de commentaires &#224; nous faire parvenir, et vous disons &#224; tr&#232;s bient&#244;t.<br><br>`
      : `Nous vous disons &#224; tr&#232;s bient&#244;t.<br><br>`;
  const content = `
    <h1 class="h3" style="${EMAIL_H1_STYLE}" align="left">Bienvenue sur ${app}</h1>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">
      Nous sommes ravis que vous ayez d&#233;cid&#233; de nous rejoindre.<br><br>
      En vous connectant, vous pourrez acc&#233;der &#224; l&#8217;ensemble des fonctionnalit&#233;s que notre application a &#224; vous offrir, et nous esp&#233;rons que vous les appr&#233;cierez.<br><br>
      ${closing}
      Votre &#233;quipe ${app}
    </p>
  `;
  return wrapEmailLayout(logoUrl, content, appName);
}
