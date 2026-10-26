import { describe, expect, it } from "vitest";
import { auth } from "firebase-admin";
import { seedCoach } from "../helpers";
import { issueCode } from "../../src/utils/otp_code";
import verifyEmailCode from "../../src/callables/auth/verify_email_code_secured";

function caller(uid: string) {
  return { uid, token: {} };
}

describe("verifyEmailCode (secured)", () => {
  it("marks the caller's address as verified when the code is right", async () => {
    const uid = await seedCoach("a@club.test");
    const code = await issueCode("verify-email", uid);

    expect(await verifyEmailCode({ code }, caller(uid))).toBe(true);
    expect((await auth().getUser(uid)).emailVerified).toBe(true);
  });

  it("rejects a wrong code and leaves the address unverified", async () => {
    const uid = await seedCoach("a@club.test");
    const code = await issueCode("verify-email", uid);

    await expect(verifyEmailCode({ code: code === "000000" ? "111111" : "000000" }, caller(uid))).rejects.toMatchObject({ code: "invalid-argument" });
    expect((await auth().getUser(uid)).emailVerified).toBe(false);
  });

  it("rejects a call without any code issued", async () => {
    const uid = await seedCoach("a@club.test");

    await expect(verifyEmailCode({ code: "123456" }, caller(uid))).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("rejects a missing or non-string code", async () => {
    const uid = await seedCoach("a@club.test");
    await issueCode("verify-email", uid);

    await expect(verifyEmailCode({}, caller(uid))).rejects.toMatchObject({ code: "invalid-argument" });
    await expect(verifyEmailCode({ code: 123456 }, caller(uid))).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("does not accept the code issued to another account", async () => {
    const a = await seedCoach("a@club.test");
    const b = await seedCoach("b@club.test");
    const codeOfB = await issueCode("verify-email", b);

    await expect(verifyEmailCode({ code: codeOfB }, caller(a))).rejects.toMatchObject({ code: "invalid-argument" });
    expect((await auth().getUser(a)).emailVerified).toBe(false);
  });

  it("does not accept a password-reset code", async () => {
    const uid = await seedCoach("a@club.test");
    const code = await issueCode("reset-password", uid);

    await expect(verifyEmailCode({ code }, caller(uid))).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("answers true for an address that is already verified", async () => {
    const uid = await seedCoach("a@club.test");
    await auth().updateUser(uid, { emailVerified: true });

    expect(await verifyEmailCode({}, caller(uid))).toBe(true);
  });
});
