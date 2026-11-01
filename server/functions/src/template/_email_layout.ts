/**
 * Module du socle commun des projets.
 *
 * Shared HTML layout used by every email template.
 * Wraps the given inner content with boilerplate and a card sous un bandeau vert aux couleurs de l'app
 * (nom de l'app, ou logo quand une URL est fournie).
 */
import { escapeHtml } from "../utils/html";
import { DEFAULT_APP_NAME } from "../utils/mail_identity";

/** Couleurs de l'app (app/lib/config/theme.dart : AppColor.primaryColor, primaryLabels, secondaryLabels). */
export const EMAIL_PRIMARY = "#518948";
export const EMAIL_PRIMARY_SOFT = "#eaf2e8";
export const EMAIL_TEXT = "#212121";
export const EMAIL_TEXT_MUTED = "#6e6e6e";

const EMAIL_CSS = `body,table,td{font-family:Helvetica,Arial,sans-serif !important}.ExternalClass{width:100%}.ExternalClass,.ExternalClass p,.ExternalClass span,.ExternalClass font,.ExternalClass td,.ExternalClass div{line-height:150%}a{text-decoration:none}*{color:inherit}a[x-apple-data-detectors],u+#body a,#MessageViewBody a{color:inherit;text-decoration:none;font-size:inherit;font-family:inherit;font-weight:inherit;line-height:inherit}img{-ms-interpolation-mode:bicubic}table:not([class^=s-]){font-family:Helvetica,Arial,sans-serif;mso-table-lspace:0pt;mso-table-rspace:0pt;border-spacing:0px;border-collapse:collapse}table:not([class^=s-]) td{border-spacing:0px;border-collapse:collapse}@media screen and (max-width: 600px){.w-full,.w-full>tbody>tr>td{width:100% !important}*[class*=s-lg-]>tbody>tr>td{font-size:0 !important;line-height:0 !important;height:0 !important}.s-2>tbody>tr>td{font-size:8px !important;line-height:8px !important;height:8px !important}.s-3>tbody>tr>td{font-size:12px !important;line-height:12px !important;height:12px !important}.s-5>tbody>tr>td{font-size:20px !important;line-height:20px !important;height:20px !important}.s-10>tbody>tr>td{font-size:40px !important;line-height:40px !important;height:40px !important}}`;

const SPACER_40 = `<table class="s-10 w-full" role="presentation" border="0" cellpadding="0" cellspacing="0" style="width: 100%;" width="100%"><tbody><tr><td style="line-height: 40px; font-size: 40px; width: 100%; height: 40px; margin: 0;" align="left" width="100%" height="40">&#160;</td></tr></tbody></table>`;

/**
 * Remplace le bandeau vert uni du gabarit par une image (terrain + logo) : adresse https, ou `cid:` pour une image
 * jointe au mail. Sans source valide, ou si
 * le bandeau n'est pas trouvé, le HTML reste tel quel : l'e-mail part toujours, simplement sans l'image.
 */
export function withHeaderImage(html: string, imageUrl: string | undefined, appName: string = DEFAULT_APP_NAME): string {
  const url: string = (imageUrl ?? "").trim();
  if (!/^(https:\/\/[^\s"'<>]+|cid:[A-Za-z0-9_-]+)$/.test(url)) return html;
  const banner = `<table class="header" role="presentation" border="0" cellpadding="0" cellspacing="0" style="width: 100%;"><tbody><tr><td align="center" bgcolor="${EMAIL_PRIMARY}" style="background-color: ${EMAIL_PRIMARY}; padding: 0; margin: 0; line-height: 0; font-size: 0;"><img src="${escapeHtml(url)}" alt="${escapeHtml(appName)}" width="600" style="display: block; width: 100%; max-width: 600px; height: auto; border: 0;"></td></tr></tbody></table>`;
  const pattern = /<table class="header"[\s\S]*?<\/table>/;
  return pattern.test(html) ? html.replace(pattern, () => banner) : html;
}

export function wrapEmailLayout(logoUrl: string, content: string, appName: string = DEFAULT_APP_NAME): string {
  const brand = logoUrl
    ? `<img src="${logoUrl}" alt="${escapeHtml(appName)}" style="display: block; margin: 0 auto; height: 48px">`
    : `<span style="font-size: 24px; line-height: 30px; font-weight: 700; letter-spacing: 0.5px; color: #ffffff;">${escapeHtml(appName)}</span>`;
  const header = `<table class="header" role="presentation" border="0" cellpadding="0" cellspacing="0" style="width: 100%;"><tbody><tr><td align="center" bgcolor="${EMAIL_PRIMARY}" style="background-color: ${EMAIL_PRIMARY}; padding: 22px 20px; margin: 0; color: #ffffff;">${brand}</td></tr></tbody></table>`;
  return `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
  <meta http-equiv="x-ua-compatible" content="ie=edge">
  <meta name="x-apple-disable-message-reformatting">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="format-detection" content="telephone=no, date=no, address=no, email=no">
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <style type="text/css">${EMAIL_CSS}</style>
</head>
<body class="bg-light" style="outline: 0; width: 100%; min-width: 100%; height: 100%; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; font-family: Helvetica, Arial, sans-serif; line-height: 24px; font-weight: normal; font-size: 16px; -moz-box-sizing: border-box; -webkit-box-sizing: border-box; box-sizing: border-box; color: #000000; margin: 0; padding: 0; border-width: 0;" bgcolor="#f3f6f2">
  <table class="bg-light body" valign="top" role="presentation" border="0" cellpadding="0" cellspacing="0" style="outline: 0; width: 100%; min-width: 100%; height: 100%; font-family: Helvetica, Arial, sans-serif; line-height: 24px; font-weight: normal; font-size: 16px; color: #000000; margin: 0; padding: 0; border-width: 0;" bgcolor="#f3f6f2">
    <tbody><tr>
      <td valign="top" style="line-height: 24px; font-size: 16px; margin: 0;" align="left" bgcolor="#f3f6f2">
        <table class="container" role="presentation" border="0" cellpadding="0" cellspacing="0" style="width: 100%;">
          <tbody><tr>
            <td align="center" style="line-height: 24px; font-size: 16px; margin: 0; padding: 0 16px;">
              <table align="center" role="presentation" border="0" cellpadding="0" cellspacing="0" style="width: 100%; max-width: 600px; margin: 0 auto;">
                <tbody><tr>
                  <td style="line-height: 24px; font-size: 16px; margin: 0;" align="left">
                    ${SPACER_40}
                    <table class="card" role="presentation" border="0" cellpadding="0" cellspacing="0" style="border-radius: 16px; border-collapse: separate !important; width: 100%; overflow: hidden; border: 1px solid #e3e9e1;" bgcolor="#ffffff">
                      <tbody><tr>
                        <td style="line-height: 24px; font-size: 16px; width: 100%; margin: 0;" align="left" bgcolor="#ffffff">
                          ${header}
                          <table class="card-body" role="presentation" border="0" cellpadding="0" cellspacing="0" style="width: 100%;">
                            <tbody><tr>
                              <td style="line-height: 24px; font-size: 16px; width: 100%; margin: 0; padding: 28px 24px;" align="left">
                                ${content}
                              </td>
                            </tr></tbody>
                          </table>
                        </td>
                      </tr></tbody>
                    </table>
                    ${SPACER_40}
                  </td>
                </tr></tbody>
              </table>
            </td>
          </tr></tbody>
        </table>
      </td>
    </tr></tbody>
  </table>
</body>
</html>`;
}

export const EMAIL_H1_STYLE = `padding-top: 0; padding-bottom: 0; font-weight: 500; vertical-align: baseline; font-size: 24px; line-height: 30px; color: ${EMAIL_TEXT}; margin: 0;`;
export const EMAIL_P_STYLE = `line-height: 24px; font-size: 16px; color: ${EMAIL_TEXT}; width: 100%; margin: 0;`;
export const EMAIL_SUPPORT_P_STYLE = `font-size: 13px; line-height: 20px; color: ${EMAIL_TEXT_MUTED}; width: 100%; margin: 0;`;
export const EMAIL_LINK_STYLE = `color: ${EMAIL_PRIMARY}; font-weight: 600;`;

/**
 * Paragraphe « Besoin d'aide ? Contacter le support » vers l'adresse de contact de l'app, ou
 * chaîne vide quand aucune adresse n'est configurée.
 */
export function emailSupportParagraph(contactEmail?: string): string {
  const address = contactEmail?.trim() ?? "";
  if (address.length === 0) return "";
  return `<p style="${EMAIL_SUPPORT_P_STYLE}" class="text-gray-600" align="left">Besoin d&#8217;aide&#160;? <a class="text-blue-500" href="mailto:${escapeHtml(address)}" style="${EMAIL_LINK_STYLE}">Contacter le support</a></p>`;
}

/**
 * Horizontal rule helper used to separate sections inside the card.
 */
export const EMAIL_HR = `<table class="hr" role="presentation" border="0" cellpadding="0" cellspacing="0" style="width: 100%;"><tbody><tr><td style="line-height: 24px; font-size: 16px; border-top-width: 1px; border-top-color: #e2e8f0; border-top-style: solid; height: 1px; width: 100%; margin: 0;" align="left"></td></tr></tbody></table>`;

/**
 * Bloc du code à saisir dans l'app : chiffres espacés dans un cadre vert pâle, sélectionnables d'un
 * geste. Le code ne contient que des chiffres, aucun échappement n'est nécessaire.
 */
export function emailCodeBlock(code: string): string {
  return `<table role="presentation" border="0" cellpadding="0" cellspacing="0" style="width: 100%;"><tbody><tr><td align="center" bgcolor="${EMAIL_PRIMARY_SOFT}" style="background-color: ${EMAIL_PRIMARY_SOFT}; border: 1px solid ${EMAIL_PRIMARY}; border-radius: 12px; padding: 18px 12px; margin: 0;"><span style="font-family: 'Courier New', Courier, monospace; font-size: 34px; line-height: 40px; font-weight: 700; letter-spacing: 10px; color: ${EMAIL_PRIMARY}; padding-left: 10px;">${code}</span></td></tr></tbody></table>`;
}
