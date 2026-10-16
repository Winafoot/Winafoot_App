import { beforeEach, describe, expect, it, vi } from "vitest";
import { auth, firestore } from "firebase-admin";

vi.mock("../../src/utils/send_email", () => ({
  sendEmail: vi.fn().mockResolvedValue({}),
}));

import { sendEmail } from "../../src/utils/send_email";
import { seedAppConfig, seedCoach } from "../helpers";
import sendEmailVerification from "../../src/callables/auth/send_email_verification_secured";

/** Le handler skeleton exige users/{uid}/metadata/security. */
async function seedCoachWithSecurity(email: string): Promise<string> {
  const uid = await seedCoach(email);
  await firestore().collection("users").doc(uid).collection("metadata").doc("security").set({ profilCompleted: false });
  return uid;
}

function caller(uid: string) {
  return { uid, token: {} };
}

async function lastVerifEmailAt(uid: string) {
  const snap = await firestore().collection("users").doc(uid).collection("metadata").doc("security").get();
  return snap.get("lastVerifEmailAt");
}

beforeEach(async () => {
  vi.mocked(sendEmail).mockClear();
  vi.mocked(sendEmail).mockResolvedValue({} as any);
  await seedAppConfig();
});

// Callable authentifié : l'identité vient du jeton, jamais de la charge utile.
describe("sendEmailVerification (secured)", () => {
  it("sends the verification mail to the caller and answers true", async () => {
    const uid = await seedCoachWithSecurity("a@club.test");

    const result = await sendEmailVerification({ uid }, caller(uid));

    expect(result).toBe(true);
    expect(sendEmail).toHaveBeenCalledTimes(1);
    expect(vi.mocked(sendEmail).mock.calls[0][1]).toMatchObject({ email: "a@club.test" });
  });

  it("ignores a uid in the payload that is not the caller's", async () => {
    const a = await seedCoachWithSecurity("a@club.test");
    const b = await seedCoachWithSecurity("b@club.test");

    await sendEmailVerification({ uid: b }, caller(a));

    expect(sendEmail).toHaveBeenCalledTimes(1);
    expect(vi.mocked(sendEmail).mock.calls[0][1]).toMatchObject({ email: "a@club.test" });
    expect(await lastVerifEmailAt(a)).toBeTruthy();
    expect(await lastVerifEmailAt(b)).toBeUndefined();
  });

  // Le handler du socle lit l'adresse dans users/{uid}.email, que le client peut
  // réécrire : sans contrôle, un compte pourrait viser l'adresse d'un tiers.
  it("refuses to mail an address that differs from the caller's Auth address", async () => {
    const a = await seedCoachWithSecurity("a@club.test");
    await seedCoach("target@club.test"); // le compte visé existe bel et bien
    await firestore().collection("users").doc(a).update({ email: "target@club.test" });

    const result = await sendEmailVerification({}, caller(a));

    expect(result).toBe(false);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("compares the two addresses without case sensitivity", async () => {
    const uid = await seedCoachWithSecurity("Mixed@Club.test");

    expect(await sendEmailVerification({}, caller(uid))).toBe(true);
    expect(sendEmail).toHaveBeenCalledTimes(1);
  });

  it("answers false and sends nothing when the address is already verified", async () => {
    const uid = await seedCoachWithSecurity("a@club.test");
    await auth().updateUser(uid, { emailVerified: true });

    const result = await sendEmailVerification({ uid }, caller(uid));

    expect(result).toBe(false);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("answers false rather than leaking an error object when the mail provider fails", async () => {
    const uid = await seedCoachWithSecurity("a@club.test");
    vi.mocked(sendEmail).mockRejectedValueOnce(new Error("MailerSend indisponible"));

    const result = await sendEmailVerification({ uid }, caller(uid));

    expect(result).toBe(false);
  });

  // L'horodatage anti-rejeu n'est posé qu'après un envoi réussi : un échec ne bloque pas le compte 6 h.
  it("does not stamp lastVerifEmailAt when the mail provider fails, so the user can retry", async () => {
    const uid = await seedCoachWithSecurity("a@club.test");
    vi.mocked(sendEmail).mockRejectedValueOnce(new Error("MailerSend indisponible"));

    expect(await sendEmailVerification({}, caller(uid))).toBe(false);
    expect(await lastVerifEmailAt(uid)).toBeUndefined();

    expect(await sendEmailVerification({}, caller(uid))).toBe(true);
    expect(sendEmail).toHaveBeenCalledTimes(2);
    expect(await lastVerifEmailAt(uid)).toBeTruthy();
  });

  it("stamps lastVerifEmailAt after a successful send and then waits before sending again", async () => {
    const uid = await seedCoachWithSecurity("a@club.test");

    expect(await sendEmailVerification({}, caller(uid))).toBe(true);
    expect(await lastVerifEmailAt(uid)).toBeTruthy();

    expect(await sendEmailVerification({}, caller(uid))).toBe(false);
    expect(sendEmail).toHaveBeenCalledTimes(1);
  });

  it("sends again once the waiting period is over", async () => {
    const uid = await seedCoachWithSecurity("a@club.test");
    const sevenHoursAgo = firestore.Timestamp.fromMillis(Date.now() - 7 * 3_600_000);
    await firestore().collection("users").doc(uid).collection("metadata").doc("security").update({ lastVerifEmailAt: sevenHoursAgo });

    expect(await sendEmailVerification({}, caller(uid))).toBe(true);
    expect((await lastVerifEmailAt(uid)).toMillis()).toBeGreaterThan(sevenHoursAgo.toMillis());
  });
});
