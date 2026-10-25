import { beforeEach, describe, expect, it, vi } from "vitest";
import { auth, firestore } from "firebase-admin";

vi.mock("../../src/utils/send_email", () => ({
  sendEmail: vi.fn().mockResolvedValue({}),
}));

import { sendEmail } from "../../src/utils/send_email";
import { seedAppConfig, seedCoach } from "../helpers";
import { LIMITS } from "../../src/config/rate_limits";
import { rateLimitKey } from "../../src/utils/rate_limit";
import sendResetPassword from "../../src/callables/auth/send_reset_password_secured";

beforeEach(async () => {
  vi.mocked(sendEmail).mockClear();
  vi.mocked(sendEmail).mockResolvedValue({} as any);
  await seedAppConfig();
});

// Le callable reste public (appelé avant connexion) : la réponse ne doit donc
// rien révéler de l'existence du compte, ni des pannes internes.
describe("sendResetPassword (secured)", () => {
  it("sends the reset mail and answers true for an existing coach", async () => {
    await seedCoach("coach@club.test");

    const result = await sendResetPassword({ email: "coach@club.test" });

    expect(result).toBe(true);
    expect(sendEmail).toHaveBeenCalledTimes(1);
  });

  it("answers true and sends nothing for an unknown address", async () => {
    const result = await sendResetPassword({ email: "ghost@club.test" });

    expect(result).toBe(true);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("answers true even when the mail provider fails, never leaking the error", async () => {
    await seedCoach("coach@club.test");
    vi.mocked(sendEmail).mockRejectedValueOnce(new Error("Resend indisponible"));

    const result = await sendResetPassword({ email: "coach@club.test" });

    expect(result).toBe(true);
  });

  // Le client peut écrire sa propre fiche users/{uid}, y compris `email` et
  // `firstname`. Le destinataire et le prénom ne doivent donc jamais venir d'une
  // fiche retrouvée par e-mail : le compte Auth fait foi.
  it("mails the Auth account itself, not another profile that holds the same address", async () => {
    await seedCoach("victim@club.test", { firstname: "Ibrahim" });
    // "!" se trie avant tout identifiant Auth : le handler du socle (limit 1 par e-mail) lirait celle-ci.
    await firestore().collection("users").doc("!forged").set({
      id: "!forged",
      email: "victim@club.test",
      firstname: '<a href="https://evil.test">Votre compte est suspendu, cliquez ici</a>',
    });

    const result = await sendResetPassword({ email: "victim@club.test" });

    expect(result).toBe(true);
    expect(sendEmail).toHaveBeenCalledTimes(1);
    const [, recipient, content] = vi.mocked(sendEmail).mock.calls[0];
    expect(recipient).toMatchObject({ email: "victim@club.test" });
    expect(content).toContain("Ibrahim");
    expect(content).not.toContain("evil.test");
  });

  it("still mails an Auth account that has no profile document", async () => {
    await auth().createUser({ email: "noprofile@club.test" });

    expect(await sendResetPassword({ email: "noprofile@club.test" })).toBe(true);
    expect(sendEmail).toHaveBeenCalledTimes(1);
  });

  it.each([
    ["no payload", undefined],
    ["no email", {}],
    ["a non-string email", { email: 42 }],
    ["an empty email", { email: "  " }],
  ])("rejects %s with invalid-argument", async (_label, payload) => {
    await expect(sendResetPassword(payload as any)).rejects.toMatchObject({ code: "invalid-argument" });
    expect(sendEmail).not.toHaveBeenCalled();
  });
});

// Sans limite par compte, une adresse de coach connue suffit à inonder sa boîte et à
// épuiser le quota Resend. La limite par IP est posée par l'adaptateur (v2_limited).
describe("sendResetPassword (secured) — per-account limit", () => {
  it(`mails an account at most ${LIMITS.resetPasswordAccount.limit} times per window, always answering true`, async () => {
    await seedCoach("coach@club.test");

    const results: boolean[] = [];
    for (let i = 0; i < LIMITS.resetPasswordAccount.limit + 3; i++) results.push(await sendResetPassword({ email: "coach@club.test" }));

    expect(new Set(results)).toEqual(new Set([true])); // la réponse ne trahit pas la limite
    expect(sendEmail).toHaveBeenCalledTimes(LIMITS.resetPasswordAccount.limit);
  });

  it("limits each account separately", async () => {
    await seedCoach("a@club.test");
    await seedCoach("b@club.test");
    for (let i = 0; i < LIMITS.resetPasswordAccount.limit + 1; i++) await sendResetPassword({ email: "a@club.test" });
    vi.mocked(sendEmail).mockClear();

    await sendResetPassword({ email: "b@club.test" });

    expect(sendEmail).toHaveBeenCalledTimes(1);
  });

  it("creates no rate-limit document for an address that has no account (no unbounded growth)", async () => {
    for (let i = 0; i < 5; i++) await sendResetPassword({ email: `ghost${i}@club.test` });

    expect((await firestore().collection("rate_limits").get()).empty).toBe(true);
  });
});

describe("sendResetPassword (secured) — daily and global caps", () => {
  async function exhaust(scope: string, id: string, limit: number, windowMs: number) {
    await firestore()
      .collection("rate_limits")
      .doc(rateLimitKey(scope, id))
      .set({ count: limit, windowStart: Date.now(), expiresAt: firestore.Timestamp.fromMillis(Date.now() + windowMs) });
  }

  it("stops mailing an account once its DAILY cap is reached, even with a fresh hourly window", async () => {
    const uid = await seedCoach("coach@club.test");
    await exhaust("reset-account-day", uid, LIMITS.resetPasswordAccountDay.limit, LIMITS.resetPasswordAccountDay.windowMs);

    expect(await sendResetPassword({ email: "coach@club.test" })).toBe(true);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("stops mailing everyone once the global daily cap of public mails is reached, answering true", async () => {
    await seedCoach("coach@club.test");
    await exhaust("public-mail-global", "all", LIMITS.publicMailGlobal.limit, LIMITS.publicMailGlobal.windowMs);

    expect(await sendResetPassword({ email: "coach@club.test" })).toBe(true);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  // Mutation : une clé par adresse saisie offrirait un compteur neuf à chaque variante de casse.
  it("shares one counter between spelling variants of the same address", async () => {
    await seedCoach("coach@club.test");

    for (const variant of ["Coach@Club.test", "COACH@CLUB.TEST", "coach@club.test", "cOaCh@club.test", "coach@CLUB.test"]) {
      await sendResetPassword({ email: variant });
    }

    expect(sendEmail).toHaveBeenCalledTimes(LIMITS.resetPasswordAccount.limit);
  });
});
