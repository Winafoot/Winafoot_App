import { describe, expect, it } from "vitest";
import { generateTemplateCoachInviteEmail } from "../../src/template/email_coach_invite";

describe("generateTemplateCoachInviteEmail", () => {
  const html = generateTemplateCoachInviteEmail(
    "Ibrahim",
    "https://demo-wina.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=XYZ",
    "support@wina.test",
    "Wina"
  );

  it("embeds the invitation link", () => {
    expect(html).toContain("oobCode=XYZ");
  });

  it("greets the coach by first name", () => {
    expect(html).toContain("Ibrahim");
  });

  it("warns that the link expires", () => {
    expect(html).toMatch(/expire/i);
  });

  it("exposes the support contact", () => {
    expect(html).toContain("mailto:support@wina.test");
  });

  it("never mentions the other product's name", () => {
    expect(html).not.toMatch(/sharing challenge/i);
  });

  it("falls back to a neutral greeting when the first name is unknown", () => {
    const anonymous = generateTemplateCoachInviteEmail("", "https://link.test", "support@wina.test", "Wina");
    expect(anonymous).toContain("Bonjour");
    expect(anonymous).not.toContain("Bonjour ,");
  });
});
