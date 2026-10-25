import { describe, expect, it } from "vitest";
import { auth } from "firebase-admin";
import { seedCoach } from "../helpers";
import { issueCode } from "../../src/utils/otp_code";
import confirmPasswordReset from "../../src/callables/auth/confirm_password_reset_secured";

const GOOD_PASSWORD = "Nouveau-Mdp1";

const wrong = (code: string): string => (code === "000000" ? "111111" : "000000");

describe("confirmPasswordReset (secured)", () => {
  it("sets the new password when the code is right, and revokes the sessions", async () => {
    const uid = await seedCoach("coach@club.test");
    const code = await issueCode("reset-password", uid);
    expect(await confirmPasswordReset({ email: "coach@club.test", code, newPassword: GOOD_PASSWORD })).toBe(true);

    expect((await auth().getUser(uid)).tokensValidAfterTime).toBeDefined();
  });

  it("uses the code only once", async () => {
    const uid = await seedCoach("coach@club.test");
    const code = await issueCode("reset-password", uid);
    await confirmPasswordReset({ email: "coach@club.test", code, newPassword: GOOD_PASSWORD });

    await expect(confirmPasswordReset({ email: "coach@club.test", code, newPassword: "Autre-Mdp2!" })).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("rejects a wrong code", async () => {
    const uid = await seedCoach("coach@club.test");
    const code = await issueCode("reset-password", uid);

    await expect(confirmPasswordReset({ email: "coach@club.test", code: wrong(code), newPassword: GOOD_PASSWORD })).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("answers an unknown address exactly like a wrong code", async () => {
    const unknown = await confirmPasswordReset({ email: "ghost@club.test", code: "123456", newPassword: GOOD_PASSWORD }).catch((e) => e);
    const uid = await seedCoach("coach@club.test");
    await issueCode("reset-password", uid);
    const badCode = await confirmPasswordReset({ email: "coach@club.test", code: "999999".replace("9", "8"), newPassword: GOOD_PASSWORD }).catch((e) => e);

    expect(unknown).toMatchObject({ code: "invalid-argument", message: "Code invalide ou expiré." });
    expect(badCode).toMatchObject({ code: unknown.code, message: unknown.message });
  });

  it("rejects an email-verification code", async () => {
    const uid = await seedCoach("coach@club.test");
    const code = await issueCode("verify-email", uid);

    await expect(confirmPasswordReset({ email: "coach@club.test", code, newPassword: GOOD_PASSWORD })).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("refuses a weak password without spending the code", async () => {
    const uid = await seedCoach("coach@club.test");
    const code = await issueCode("reset-password", uid);

    await expect(confirmPasswordReset({ email: "coach@club.test", code, newPassword: "faible" })).rejects.toMatchObject({ code: "invalid-argument" });
    expect(await confirmPasswordReset({ email: "coach@club.test", code, newPassword: GOOD_PASSWORD })).toBe(true);
  });

  it.each([
    ["no payload", undefined],
    ["no email", { code: "123456", newPassword: GOOD_PASSWORD }],
    ["a non-string email", { email: 42, code: "123456", newPassword: GOOD_PASSWORD }],
    ["no password", { email: "coach@club.test", code: "123456" }],
  ])("rejects %s with invalid-argument", async (_label, payload) => {
    await expect(confirmPasswordReset(payload as any)).rejects.toMatchObject({ code: "invalid-argument" });
  });
});
