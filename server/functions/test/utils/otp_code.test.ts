import { describe, expect, it } from "vitest";
import { firestore } from "firebase-admin";
import { consumeCode, discardCode, generateCode, issueCode, OTP_LENGTH, OTP_MAX_ATTEMPTS, OTP_TTL_MS } from "../../src/utils/otp_code";

const UID = "uid-1";

const wrong = (code: string): string => (code === "000000" ? "111111" : "000000");

describe("generateCode", () => {
  it("always returns six digits, leading zeros included", () => {
    for (let i = 0; i < 200; i++) expect(generateCode()).toMatch(new RegExp(`^\\d{${OTP_LENGTH}}$`));
  });
});

describe("issueCode / consumeCode", () => {
  it("accepts the right code once, then refuses it", async () => {
    const code = await issueCode("verify-email", UID);

    expect(await consumeCode("verify-email", UID, code)).toBe(true);
    expect(await consumeCode("verify-email", UID, code)).toBe(false);
  });

  it("stores only a hash of the code", async () => {
    const code = await issueCode("verify-email", UID);

    const snap = await firestore().collection("email_codes").doc(`verify-email_${UID}`).get();
    expect(JSON.stringify(snap.data())).not.toContain(code);
  });

  it("tolerates spaces around the typed code", async () => {
    const code = await issueCode("reset-password", UID);

    expect(await consumeCode("reset-password", UID, ` ${code} `)).toBe(true);
  });

  it.each([undefined, null, 123456, "12345", "1234567", "abcdef", "12 456"])("refuses the malformed input %j without touching the code", async (input) => {
    const code = await issueCode("verify-email", UID);

    expect(await consumeCode("verify-email", UID, input)).toBe(false);
    expect(await consumeCode("verify-email", UID, code)).toBe(true); // aucun essai consommé
  });

  it("does not let a code of one purpose serve another", async () => {
    const code = await issueCode("verify-email", UID);

    expect(await consumeCode("reset-password", UID, code)).toBe(false);
    expect(await consumeCode("verify-email", UID, code)).toBe(true);
  });

  it("does not let a code serve another account", async () => {
    const code = await issueCode("verify-email", UID);

    expect(await consumeCode("verify-email", "uid-2", code)).toBe(false);
  });

  it("replaces the previous code when a new one is issued", async () => {
    const first = await issueCode("verify-email", UID);
    let second = await issueCode("verify-email", UID);
    while (second === first) second = await issueCode("verify-email", UID);

    expect(await consumeCode("verify-email", UID, first)).toBe(false);
    expect(await consumeCode("verify-email", UID, second)).toBe(true);
  });

  it("refuses an expired code", async () => {
    const now = Date.now();
    const code = await issueCode("verify-email", UID, now);

    expect(await consumeCode("verify-email", UID, code, now + OTP_TTL_MS)).toBe(false);
  });

  it(`destroys the code after ${OTP_MAX_ATTEMPTS} wrong attempts, even if the right one comes next`, async () => {
    const code = await issueCode("verify-email", UID);

    for (let i = 0; i < OTP_MAX_ATTEMPTS; i++) expect(await consumeCode("verify-email", UID, wrong(code))).toBe(false);

    expect(await consumeCode("verify-email", UID, code)).toBe(false);
    expect(await consumeCode("verify-email", UID, code)).toBe(false);
  });

  it("accepts the right code while attempts remain", async () => {
    const code = await issueCode("verify-email", UID);

    for (let i = 0; i < OTP_MAX_ATTEMPTS - 1; i++) await consumeCode("verify-email", UID, wrong(code));

    expect(await consumeCode("verify-email", UID, code)).toBe(true);
  });

  it("refuses a discarded code", async () => {
    const code = await issueCode("verify-email", UID);
    await discardCode("verify-email", UID);

    expect(await consumeCode("verify-email", UID, code)).toBe(false);
  });
});
