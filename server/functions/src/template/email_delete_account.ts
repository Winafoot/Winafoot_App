/**
 * Module du socle commun des projets.
 */
import { wrapEmailLayout, EMAIL_H1_STYLE, EMAIL_P_STYLE, EMAIL_LINK_STYLE } from "./_email_layout";

export function generateTemplateAccountDeletionEmail(
  email: string,
  urlPath: string,
  token: string,
  isDeleted: boolean,
  logoUrl: string = "",
  appName: string = ""
): string {
  const title = appName ? `Suppression de compte ${appName}` : `Suppression de compte`;
  const content = `
    <h1 class="h3" style="${EMAIL_H1_STYLE}" align="left">${title}</h1>
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">Vous avez fait la demande de suppression de compte. Cliquez sur le lien ci-dessous pour supprimer votre compte.</p>
    <br>
    <p style="margin: 16px 0; text-align: center;">
      <a href="${urlPath}/confirm-delete.html?token=${token}&isDeleted=${isDeleted}" style="${EMAIL_LINK_STYLE} text-decoration: underline;">Supprimer mon compte</a>
    </p>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left"><br>Si vous n&#8217;&#234;tes pas &#224; l&#8217;origine de cette demande, merci d&#8217;ignorer ce message.</p>
  `;
  // email param kept for backwards compatibility
  void email;
  return wrapEmailLayout(logoUrl, content);
}
