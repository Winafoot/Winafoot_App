/**
 * Module du socle commun des projets.
 */
import { escapeHtml } from "../utils/html";
import { wrapEmailLayout, EMAIL_H1_STYLE, EMAIL_P_STYLE, EMAIL_LINK_STYLE, EMAIL_HR } from "./_email_layout";

/**
 * Toutes les valeurs insérées sont échappées : la description et les catégories viennent du
 * signalement. `storageRepoUrl` vide : la ligne « Fichiers du signalement » est omise.
 */
export function generateTemplateReportEmail(
  appName: string,
  type: string,
  date: string,
  idPersonUrl: string,
  idPerson: string,
  idObjectUrl: string,
  idObject: string,
  repordIdUrl: string,
  categories: string,
  storageRepoUrl: string,
  description: string,
  logoUrl: string = ""
): string {
  const files = storageRepoUrl.length > 0
    ? `<li class="text-gray-600" style="color: #718096;">Fichiers du signalement&#160;: <a href="${escapeHtml(storageRepoUrl)}" style="${EMAIL_LINK_STYLE}">Voir les fichiers</a></li>`
    : "";
  const content = `
    <h1 class="h3" style="${EMAIL_H1_STYLE}" align="left">${escapeHtml(type)} ${escapeHtml(appName)}</h1>
    <br>
    ${EMAIL_HR}
    <br>
    <p class="text-gray-700" style="${EMAIL_P_STYLE}" align="left">Nouveau ${escapeHtml(type)} r&#233;alis&#233; &#224; la date du ${escapeHtml(date)}&#160;:</p>
    <br>
    <ul>
      <li class="text-gray-600" style="color: #718096;">Id de la personne qui signale&#160;: <a href="${escapeHtml(idPersonUrl)}" style="${EMAIL_LINK_STYLE}">${escapeHtml(idPerson)}</a></li>
      <li class="text-gray-600" style="color: #718096;">Id de l&#8217;objet ou de la personne signal&#233;&#160;: <a href="${escapeHtml(idObjectUrl)}" style="${EMAIL_LINK_STYLE}">${escapeHtml(idObject)}</a></li>
      <li class="text-gray-600" style="color: #718096;">Contenu du signalement&#160;: <a href="${escapeHtml(repordIdUrl)}" style="${EMAIL_LINK_STYLE}">${escapeHtml(categories)}</a></li>
      <li class="text-gray-600" style="color: #718096;">Description du signalement&#160;: <a href="${escapeHtml(repordIdUrl)}" style="${EMAIL_LINK_STYLE}">${escapeHtml(description)}</a></li>
      ${files}
    </ul>
    ${EMAIL_HR}
  `;
  return wrapEmailLayout(logoUrl, content);
}
