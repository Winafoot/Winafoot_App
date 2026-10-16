/**
 * Module du socle commun des projets.
 *
 * Shared HTML layout used by every email template.
 * Wraps the given inner content with boilerplate, a centered logo and a card.
 */
import { escapeHtml } from "../utils/html";

const EMAIL_CSS = `body,table,td{font-family:Helvetica,Arial,sans-serif !important}.ExternalClass{width:100%}.ExternalClass,.ExternalClass p,.ExternalClass span,.ExternalClass font,.ExternalClass td,.ExternalClass div{line-height:150%}a{text-decoration:none}*{color:inherit}a[x-apple-data-detectors],u+#body a,#MessageViewBody a{color:inherit;text-decoration:none;font-size:inherit;font-family:inherit;font-weight:inherit;line-height:inherit}img{-ms-interpolation-mode:bicubic}table:not([class^=s-]){font-family:Helvetica,Arial,sans-serif;mso-table-lspace:0pt;mso-table-rspace:0pt;border-spacing:0px;border-collapse:collapse}table:not([class^=s-]) td{border-spacing:0px;border-collapse:collapse}@media screen and (max-width: 600px){.w-full,.w-full>tbody>tr>td{width:100% !important}*[class*=s-lg-]>tbody>tr>td{font-size:0 !important;line-height:0 !important;height:0 !important}.s-2>tbody>tr>td{font-size:8px !important;line-height:8px !important;height:8px !important}.s-3>tbody>tr>td{font-size:12px !important;line-height:12px !important;height:12px !important}.s-5>tbody>tr>td{font-size:20px !important;line-height:20px !important;height:20px !important}.s-10>tbody>tr>td{font-size:40px !important;line-height:40px !important;height:40px !important}}`;

const SPACER_40 = `<table class="s-10 w-full" role="presentation" border="0" cellpadding="0" cellspacing="0" style="width: 100%;" width="100%"><tbody><tr><td style="line-height: 40px; font-size: 40px; width: 100%; height: 40px; margin: 0;" align="left" width="100%" height="40">&#160;</td></tr></tbody></table>`;

export function wrapEmailLayout(logoUrl: string, content: string): string {
  const logoImg = logoUrl
    ? `<img src="${logoUrl}" alt="logo" style="display: block; margin: 0 auto 20px auto; height: 100px">`
    : "";
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
<body class="bg-light" style="outline: 0; width: 100%; min-width: 100%; height: 100%; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; font-family: Helvetica, Arial, sans-serif; line-height: 24px; font-weight: normal; font-size: 16px; -moz-box-sizing: border-box; -webkit-box-sizing: border-box; box-sizing: border-box; color: #000000; margin: 0; padding: 0; border-width: 0;" bgcolor="#f7fafc">
  <table class="bg-light body" valign="top" role="presentation" border="0" cellpadding="0" cellspacing="0" style="outline: 0; width: 100%; min-width: 100%; height: 100%; font-family: Helvetica, Arial, sans-serif; line-height: 24px; font-weight: normal; font-size: 16px; color: #000000; margin: 0; padding: 0; border-width: 0;" bgcolor="#f7fafc">
    <tbody><tr>
      <td valign="top" style="line-height: 24px; font-size: 16px; margin: 0;" align="left" bgcolor="#f7fafc">
        <table class="container" role="presentation" border="0" cellpadding="0" cellspacing="0" style="width: 100%;">
          <tbody><tr>
            <td align="center" style="line-height: 24px; font-size: 16px; margin: 0; padding: 0 16px;">
              <table align="center" role="presentation" border="0" cellpadding="0" cellspacing="0" style="width: 100%; max-width: 600px; margin: 0 auto;">
                <tbody><tr>
                  <td style="line-height: 24px; font-size: 16px; margin: 0;" align="left">
                    ${SPACER_40}
                    <table class="card" role="presentation" border="0" cellpadding="0" cellspacing="0" style="border-radius: 6px; border-collapse: separate !important; width: 100%; overflow: hidden; border: 1px solid #e2e8f0;" bgcolor="#ffffff">
                      <tbody><tr>
                        <td style="line-height: 24px; font-size: 16px; width: 100%; margin: 0;" align="left" bgcolor="#ffffff">
                          <table class="card-body" role="presentation" border="0" cellpadding="0" cellspacing="0" style="width: 100%;">
                            <tbody><tr>
                              <td style="line-height: 24px; font-size: 16px; width: 100%; margin: 0; padding: 20px;" align="left">
                                ${logoImg}
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

export const EMAIL_H1_STYLE = `padding-top: 0; padding-bottom: 0; font-weight: 500; vertical-align: baseline; font-size: 28px; line-height: 33.6px; margin: 0;`;
export const EMAIL_P_STYLE = `line-height: 24px; font-size: 16px; color: #4a5568; width: 100%; margin: 0;`;
export const EMAIL_SUPPORT_P_STYLE = `font-size: 13px; line-height: 24px; color: #718096; width: 100%; margin: 0;`;
export const EMAIL_LINK_STYLE = `color: #0d6efd;`;

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
