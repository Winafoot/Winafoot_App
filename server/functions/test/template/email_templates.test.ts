import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { BUDGET_GUARD_SERVICE_ACCOUNT, FUNCTIONS_SERVICE_ACCOUNT } from "../../src/config/service_accounts";
import { generateTemplateAdminInviteEmail } from "../../src/template/email_admin_invite";
import { generateTemplateCoachInviteEmail } from "../../src/template/email_coach_invite";
import { generateTemplateAccountDeletionEmail } from "../../src/template/email_delete_account";
import { generateTemplateLandingPageEmail } from "../../src/template/email_landing_page";
import { generateTemplateReportEmail } from "../../src/template/email_report";
import { generateTemplateResetPasswordEmail } from "../../src/template/email_reset_password";
import { generateTemplateVerifyYourEmail } from "../../src/template/email_verify_your_account";
import { generateTemplateWelcomeEmail } from "../../src/template/email_welcome";
import { mailIdentity } from "../../src/utils/mail_identity";

const LINK = "https://demo-wina.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=XYZ";
const CODE = "482915";

/** Adresses e-mail que le test donne aux gabarits : les seules qu'un rendu peut contenir. */
const CONTACT = "support@wina.test";
const VISITOR = "visiteur@club.test";
const ACCOUNT = "coach@club.test";
const EMAIL_ADDRESS = /[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+/g;

/** Chaque gabarit rendu avec et sans adresse de contact. */
const render = (contact?: string): Record<string, string> => ({
  welcome: generateTemplateWelcomeEmail("Wina", contact),
  verify: generateTemplateVerifyYourEmail("Wina", CODE, contact),
  reset: generateTemplateResetPasswordEmail("Ibrahim", CODE, contact),
  coachInvite: generateTemplateCoachInviteEmail("Ibrahim", LINK, contact, "Wina"),
  adminInvite: generateTemplateAdminInviteEmail("Ibrahim", LINK, contact, "Wina"),
});

/** Les huit gabarits, rendus avec les valeurs de configuration du test. */
const renderAll = (contact?: string): Record<string, string> => ({
  ...render(contact),
  accountDeletion: generateTemplateAccountDeletionEmail(ACCOUNT, "https://landing.wina.test", "jeton", false, "", "Wina"),
  landingPage: generateTemplateLandingPageEmail("Wina", "Karim B.", "Question", VISITOR, "Bonjour"),
  report: generateTemplateReportEmail("Wina", "signalement", "01/10/2026", "", "uid1", "", "obj1", "", "spam", "", "texte"),
});

describe("e-mail templates", () => {
  it.each([
    ...Object.entries(renderAll(CONTACT)).map(([name, html]) => [`${name} (contact configured)`, html, [CONTACT, VISITOR, ACCOUNT]] as const),
    ...Object.entries(renderAll(undefined)).map(([name, html]) => [`${name} (no contact)`, html, [VISITOR, ACCOUNT]] as const),
  ])("%s shows only e-mail addresses given by the configuration", (_name, html, allowed) => {
    expect((html.match(EMAIL_ADDRESS) ?? []).filter((address) => !allowed.includes(address))).toEqual([]);
  });

  it.each(Object.entries(render("support@wina.test")))("%s carries no filler text", (_name, html) => {
    expect(html).not.toMatch(/lorem ipsum/i);
    expect(html).not.toContain("APP NAME");
    expect(html).not.toContain("EMAIL@CONTACT");
  });

  it.each(Object.entries(render("support@wina.test")))("%s links to the contact address when one is configured", (_name, html) => {
    expect(html).toContain("mailto:support@wina.test");
  });

  it.each(Object.entries(render(undefined)))("%s drops the contact link when no address is configured", (_name, html) => {
    expect(html).not.toContain("mailto:");
    expect(html).not.toContain("undefined");
  });

  it("escapes the application name and the contact address", () => {
    const html = generateTemplateWelcomeEmail("<b>Wina</b>", 'a"b@wina.test');

    expect(html).not.toContain("<b>Wina</b>");
    expect(html).toContain("&lt;b&gt;Wina&lt;/b&gt;");
    expect(html).toContain("mailto:a&quot;b@wina.test");
  });

  it("escapes the content of a report and omits the files line when there is no file", () => {
    const html = generateTemplateReportEmail("Wina", "signalement", "01/10/2026", "u", "uid1", "o", "obj1", "r", "<i>spam</i>", "", '<script>alert("x")</script>');

    expect(html).not.toContain("<script>");
    expect(html).toContain("&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;");
    expect(html).toContain("&lt;i&gt;spam&lt;/i&gt;");
    expect(html).not.toContain("Voir les fichiers");
  });

  it("keeps the files line of a report that has one", () => {
    const html = generateTemplateReportEmail("Wina", "signalement", "", "", "", "", "", "", "", "https://files.test/a.png", "");

    expect(html).toContain('href="https://files.test/a.png"');
  });
});

describe("mailIdentity", () => {
  it("reads the application name and the contact address from app_config/metadata", () => {
    expect(mailIdentity({ appName: " Wina club ", contactEmail: " contact@wina.test " } as any)).toEqual({ appName: "Wina club", contactEmail: "contact@wina.test" });
  });

  it("falls back to the default name and no contact when the fields are missing or blank", () => {
    expect(mailIdentity({ appName: "  ", contactEmail: "" } as any)).toEqual({ appName: "Wina", contactEmail: undefined });
    expect(mailIdentity(undefined)).toEqual({ appName: "Wina", contactEmail: undefined });
  });
});

// Aucun texte de remplissage dans le code déployé, et aucune adresse e-mail écrite en dur : expéditeur et
// contact viennent de app_config/metadata. Seuls les comptes d'exécution du projet y figurent.
describe("deployed sources", () => {
  const SRC = join(__dirname, "../../src");
  const files = (dir: string): string[] =>
    readdirSync(dir).flatMap((name) => {
      const path = join(dir, name);
      return statSync(path).isDirectory() ? files(path) : path.endsWith(".ts") ? [path] : [];
    });

  it.each(["APP NAME", "EMAIL@CONTACT", "Lorem ipsum"])("contain no %s", (needle) => {
    const offenders = files(SRC).filter((f) => readFileSync(f, "utf8").includes(needle));
    expect(offenders).toEqual([]);
  });

  it("hard-code no e-mail address but the project's service accounts", () => {
    const allowed = [FUNCTIONS_SERVICE_ACCOUNT, BUDGET_GUARD_SERVICE_ACCOUNT];
    const found = files(SRC).flatMap((f) => (readFileSync(f, "utf8").match(EMAIL_ADDRESS) ?? []).map((address) => `${f.slice(SRC.length + 1)}: ${address}`));
    expect(found.filter((entry) => !allowed.some((address) => entry.endsWith(`: ${address}`)))).toEqual([]);
    expect(found.length).toBeGreaterThan(0); // la recherche voit bien les adresses du code
  });
});
