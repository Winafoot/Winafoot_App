import { beforeEach, describe, expect, it, vi } from "vitest";
import { auth, firestore } from "firebase-admin";

vi.mock("../../src/utils/send_email", () => ({
  sendEmail: vi.fn().mockResolvedValue({}),
}));
// Le vérificateur reCAPTCHA a ses propres tests (test/utils/recaptcha.test.ts) : ici on simule son verdict.
vi.mock("../../src/utils/recaptcha", () => ({
  verifyRecaptcha: vi.fn(),
}));

import { sendEmail } from "../../src/utils/send_email";
import { verifyRecaptcha } from "../../src/utils/recaptcha";
import { fakeReq, fakeRes, seedAdmin, seedAppConfig, seedCoach } from "../helpers";
import { LIMITS } from "../../src/config/rate_limits";
import { rateLimitKey } from "../../src/utils/rate_limit";
import sendDeleteMail from "../../src/https_requests/landing_page/send_delete_account_mail_secured";

// GCLOUD_PROJECT vaut demo-wina dans test/setup.ts : hébergement par défaut du projet.
const DEFAULT_BASE = "https://demo-wina.web.app";
const TOKEN = "jeton-recaptcha-factice";

/** Ajoute le jeton reCAPTCHA factice aux corps objets ; les autres (absent, chaîne...) restent tels quels. */
async function call(body: unknown, options: { method?: string; origin?: string; ip?: string } = {}) {
  const res = fakeRes();
  const withToken = body != null && typeof body === "object" ? { recaptchaToken: TOKEN, ...body } : body;
  await sendDeleteMail(fakeReq(options.method ?? "POST", withToken, options.origin, options.ip), res);
  return res;
}

const tokenDocs = async () => (await firestore().collection("accountDeletionRequests").get()).docs;

/** Lien « Supprimer mon compte » du dernier mail envoyé. */
function sentLink(): string {
  const html = vi.mocked(sendEmail).mock.calls[0][2] as string;
  return html.match(/href="([^"]*confirm-delete[^"]*)"/)?.[1] ?? "";
}

beforeEach(async () => {
  vi.mocked(sendEmail).mockClear();
  vi.mocked(sendEmail).mockResolvedValue({} as any);
  vi.mocked(verifyRecaptcha).mockReset();
  vi.mocked(verifyRecaptcha).mockResolvedValue("ok");
  await seedAppConfig();
});

// Contrat de la landing (public/delete-account.html) : POST { email }, réponse
// 200 uniforme. Le lien du mail vise confirm-delete.html?token=…&isDeleted=….
describe("onSendLandingPageMailDeleteAccount (secured)", () => {
  it("mails a deletion link to an existing account and stores a single-use token", async () => {
    const uid = await seedCoach("coach@club.test");

    const res = await call({ email: "coach@club.test" });

    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ message: "Data received" });
    expect(sendEmail).toHaveBeenCalledTimes(1);
    expect(vi.mocked(sendEmail).mock.calls[0][1]).toMatchObject({ email: "coach@club.test" });

    const tokens = await tokenDocs();
    expect(tokens).toHaveLength(1);
    expect(tokens[0].id).toMatch(/^[0-9a-f]{96}$/);
    expect(tokens[0].get("email")).toBe("coach@club.test");
    expect(tokens[0].get("uid")).toBe(uid); // le jeton vise CE compte, pas seulement une adresse
    expect(tokens[0].get("expiresAt").toMillis()).toBeGreaterThan(Date.now());
    expect(vi.mocked(sendEmail).mock.calls[0][2]).toContain("Suppression de compte Wina");
    expect(sentLink()).toBe(`${DEFAULT_BASE}/confirm-delete.html?token=${tokens[0].id}&isDeleted=false`);
  });

  // Le lien du mail vise toujours la landing : les champs du corps de la requête, dont `urlPath`,
  // n'entrent jamais dans le lien ni dans le HTML.
  it("ignores a urlPath sent by the client: the link always targets the landing", async () => {
    await seedCoach("coach@club.test");

    await call({ email: "coach@club.test", urlPath: 'https://evil.test"><img src="https://evil.test/c?a=' });

    const html = vi.mocked(sendEmail).mock.calls[0][2] as string;
    expect(html).not.toContain("evil.test");
    expect(sentLink().startsWith(`${DEFAULT_BASE}/confirm-delete.html?token=`)).toBe(true);
  });

  it("uses app_config/metadata.landingUrl when it is an https URL (trailing slash tolerated)", async () => {
    await seedAppConfig({ landingUrl: "https://winafoot.example.fr/" });
    await seedCoach("coach@club.test");

    await call({ email: "coach@club.test" });

    expect(sentLink().startsWith("https://winafoot.example.fr/confirm-delete.html?token=")).toBe(true);
  });

  it.each(["http://winafoot.example.fr", "javascript:alert(1)", "//evil.test", 42])(
    "ignores an unsafe landingUrl (%s) and falls back to the project hosting",
    async (landingUrl) => {
      await seedAppConfig({ landingUrl });
      await seedCoach("coach@club.test");

      await call({ email: "coach@club.test" });

      expect(sentLink().startsWith(`${DEFAULT_BASE}/confirm-delete.html?token=`)).toBe(true);
    },
  );

  // Réponse uniforme : rien ne distingue « compte inconnu » de « compte connu ».
  // Et surtout pas d'envoi : l'ancien handler mailait n'importe quelle adresse.
  it("answers the same 200 for an administrator account, sends nothing and stores no token", async () => {
    await seedAdmin("boss@wina.test");

    const res = await call({ email: "boss@wina.test" });

    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ message: "Data received" });
    expect(sendEmail).not.toHaveBeenCalled();
    expect(await tokenDocs()).toHaveLength(0);
  });

  it("answers the same 200 for an unknown address, sends nothing and stores no token", async () => {
    const res = await call({ email: "ghost@club.test" });

    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ message: "Data received" });
    expect(sendEmail).not.toHaveBeenCalled();
    expect(await tokenDocs()).toHaveLength(0);
  });

  it("tells an already-deleted account so (isDeleted=true), without any usable token", async () => {
    await firestore().collection("deleted_users").add({ uid: "old", email: "gone@club.test", deletedAt: firestore.Timestamp.now() });

    const res = await call({ email: "gone@club.test" });

    expect(res.statusCode).toBe(200);
    expect(sendEmail).toHaveBeenCalledTimes(1);
    expect(sentLink()).toMatch(/&isDeleted=true$/);
    expect(await tokenDocs()).toHaveLength(0);
  });

  it("matches the address case-insensitively", async () => {
    await seedCoach("coach@club.test");

    await call({ email: "  Coach@Club.TEST " });

    expect(sendEmail).toHaveBeenCalledTimes(1);
    expect((await tokenDocs())[0].get("email")).toBe("coach@club.test");
  });

  it.each([
    ["no body", undefined],
    ["no email", {}],
    ["a non-string email", { email: 42 }],
    ["a malformed email", { email: "pas une adresse" }],
    ["an email carrying markup", { email: 'a"@b.test><img src=x>' }],
    ["an oversized email", { email: `${"a".repeat(260)}@club.test` }],
  ])("rejects %s with 400 and does nothing", async (_label, body) => {
    const res = await call(body);

    expect(res.statusCode).toBe(400);
    expect(sendEmail).not.toHaveBeenCalled();
    expect(await tokenDocs()).toHaveLength(0);
  });

  // La réponse est la même 200 pour un compte connu et pour une adresse inconnue, y compris quand
  // MailerSend refuse l'envoi (quota, domaine).
  it("answers the same 200 when the mail cannot be sent, removes the token and leaks nothing", async () => {
    await seedCoach("coach@club.test");
    vi.mocked(sendEmail).mockRejectedValueOnce(new Error("MailerSend indisponible"));

    const res = await call({ email: "coach@club.test" });

    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ message: "Data received" });
    expect(await tokenDocs()).toHaveLength(0); // pas de jeton orphelin
  });

  it("answers the same 200 for an already-deleted address whose mail cannot be sent", async () => {
    await firestore().collection("deleted_users").add({ uid: "old", email: "gone@club.test", deletedAt: firestore.Timestamp.now() });
    vi.mocked(sendEmail).mockRejectedValueOnce(new Error("quota exceeded"));

    const res = await call({ email: "gone@club.test" });

    expect(res.statusCode).toBe(200);
  });

  // Un double clic envoie deux mails : si le second invalidait le premier, le lien
  // du premier mail échouerait en silence (la page affiche « message envoyé »).
  it("reuses the pending token: a second request mails the same working link", async () => {
    await seedCoach("coach@club.test");

    await call({ email: "coach@club.test" });
    await call({ email: "coach@club.test" });

    expect(sendEmail).toHaveBeenCalledTimes(2);
    expect((await tokenDocs())).toHaveLength(1);
    const links = vi.mocked(sendEmail).mock.calls.map((c) => ((c[2] as string).match(/href="([^"]*confirm-delete[^"]*)"/) ?? [])[1]);
    expect(links[0]).toBeTruthy();
    expect(links[0]).toBe(links[1]);
  });

  it("issues a new token once the pending one is about to expire", async () => {
    const uid = await seedCoach("coach@club.test");
    await firestore()
      .collection("accountDeletionRequests")
      .doc("ab".repeat(48))
      .set({ email: "coach@club.test", uid, token: "ab".repeat(48), expiresAt: firestore.Timestamp.fromMillis(Date.now() + 60_000) });

    await call({ email: "coach@club.test" });

    const tokens = await tokenDocs();
    expect(tokens).toHaveLength(1);
    expect(tokens[0].id).not.toBe("ab".repeat(48));
  });

  it("does not reuse a token issued for another account that held the address", async () => {
    await seedCoach("coach@club.test");
    await firestore()
      .collection("accountDeletionRequests")
      .doc("cd".repeat(48))
      .set({ email: "coach@club.test", uid: "someone-else", token: "cd".repeat(48), expiresAt: firestore.Timestamp.fromMillis(Date.now() + 3_600_000) });

    await call({ email: "coach@club.test" });

    const tokens = await tokenDocs();
    expect(tokens).toHaveLength(1);
    expect(tokens[0].id).not.toBe("cd".repeat(48));
  });

  it("answers 500 when app_config/metadata is missing", async () => {
    await firestore().collection("app_config").doc("metadata").delete();

    const res = await call({ email: "coach@club.test" });

    expect(res.statusCode).toBe(500);
    expect(sendEmail).not.toHaveBeenCalled();
  });
});

// Même garde pour les trois endpoints : méthode et CORS.
describe("landing endpoints — method and CORS", () => {
  it.each(["GET", "PUT", "DELETE"])("refuses %s with 405", async (method) => {
    const res = await call({ email: "coach@club.test" }, { method });

    expect(res.statusCode).toBe(405);
    expect(res.headers["allow"]).toBe("POST, OPTIONS");
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("answers the preflight with 204 and no work done", async () => {
    await seedCoach("coach@club.test");

    const res = await call(undefined, { method: "OPTIONS", origin: DEFAULT_BASE });

    expect(res.statusCode).toBe(204);
    expect(res.headers["access-control-allow-origin"]).toBe(DEFAULT_BASE);
    expect(res.headers["access-control-allow-methods"]).toBe("POST, OPTIONS");
    expect(res.headers["access-control-allow-headers"]).toBe("Content-Type");
    expect(sendEmail).not.toHaveBeenCalled();
    expect(await tokenDocs()).toHaveLength(0);
  });

  it.each([DEFAULT_BASE, "https://demo-wina.firebaseapp.com"])("allows the landing origin %s", async (origin) => {
    const res = await call({ email: "ghost@club.test" }, { origin });

    expect(res.headers["access-control-allow-origin"]).toBe(origin);
    expect(res.headers["vary"]).toBe("Origin");
  });

  it("allows the origin of the configured landingUrl", async () => {
    await seedAppConfig({ landingUrl: "https://winafoot.example.fr/some/path" });

    const res = await call({ email: "ghost@club.test" }, { origin: "https://winafoot.example.fr" });

    expect(res.headers["access-control-allow-origin"]).toBe("https://winafoot.example.fr");
  });

  it("does not allow a foreign origin", async () => {
    const res = await call({ email: "ghost@club.test" }, { origin: "https://evil.test" });

    expect(res.headers["access-control-allow-origin"]).toBeUndefined();
  });

  it("does not use the wildcard origin", async () => {
    const res = await call({ email: "ghost@club.test" });

    expect(res.headers["access-control-allow-origin"]).toBeUndefined();
  });
});

// Limitation de débit : sans elle, une seule adresse de coach connue suffit à inonder
// sa boîte de vrais mails Wina et à épuiser le quota MailerSend partagé par tous les
// mails transactionnels (invitations, réinitialisations).
describe("onSendLandingPageMailDeleteAccount — rate limiting", () => {
  it(`refuses an IP after ${LIMITS.deleteMailIp.limit} requests with 429, doing nothing`, async () => {
    await seedCoach("coach@club.test");
    for (let i = 0; i < LIMITS.deleteMailIp.limit; i++) await call({ email: "ghost@club.test" }, { ip: "198.51.100.1" });

    const res = await call({ email: "coach@club.test" }, { ip: "198.51.100.1" });

    expect(res.statusCode).toBe(429);
    expect(sendEmail).not.toHaveBeenCalled();
    expect(await tokenDocs()).toHaveLength(0);
  });

  it("does not block another IP, and the preflight does not count", async () => {
    await seedCoach("coach@club.test");
    for (let i = 0; i < 30; i++) await call(undefined, { method: "OPTIONS", ip: "198.51.100.1" });
    for (let i = 0; i < LIMITS.deleteMailIp.limit; i++) await call({ email: "ghost@club.test" }, { ip: "198.51.100.1" });

    expect((await call({ email: "coach@club.test" }, { ip: "198.51.100.2" })).statusCode).toBe(200);
    expect(sendEmail).toHaveBeenCalledTimes(1);
  });

  it(`sends at most ${LIMITS.deleteMailAccount.limit} mails per account per window, answering 200 as usual`, async () => {
    await seedCoach("coach@club.test");

    const statuses: number[] = [];
    for (let i = 0; i < LIMITS.deleteMailAccount.limit + 2; i++) {
      statuses.push((await call({ email: "coach@club.test" }, { ip: `198.51.100.${10 + i}` })).statusCode);
    }

    expect(new Set(statuses)).toEqual(new Set([200])); // rien ne trahit la limite
    expect(sendEmail).toHaveBeenCalledTimes(LIMITS.deleteMailAccount.limit);
    expect(await tokenDocs()).toHaveLength(1);
  });

  it("applies the per-account limit to already-deleted addresses too", async () => {
    await firestore().collection("deleted_users").add({ uid: "old", email: "gone@club.test", deletedAt: firestore.Timestamp.now() });

    for (let i = 0; i < LIMITS.deleteMailAccount.limit + 2; i++) await call({ email: "gone@club.test" }, { ip: `198.51.100.${10 + i}` });

    expect(sendEmail).toHaveBeenCalledTimes(LIMITS.deleteMailAccount.limit);
  });
});

describe("onSendLandingPageMailDeleteAccount — daily, global caps and uniform answers", () => {
  async function exhaust(scope: string, id: string, limit: number, windowMs: number) {
    await firestore()
      .collection("rate_limits")
      .doc(rateLimitKey(scope, id))
      .set({ count: limit, windowStart: Date.now(), expiresAt: firestore.Timestamp.fromMillis(Date.now() + windowMs) });
  }

  it("stops mailing an account once its DAILY cap is reached", async () => {
    const uid = await seedCoach("coach@club.test");
    await exhaust("delete-mail-account-day", uid, LIMITS.deleteMailAccountDay.limit, LIMITS.deleteMailAccountDay.windowMs);

    const res = await call({ email: "coach@club.test" });

    expect(res.statusCode).toBe(200);
    expect(sendEmail).not.toHaveBeenCalled();
    expect(await tokenDocs()).toHaveLength(0);
  });

  it("stops mailing everyone once the global daily cap of public mails is reached", async () => {
    await seedCoach("coach@club.test");
    await exhaust("public-mail-global", "all", LIMITS.publicMailGlobal.limit, LIMITS.publicMailGlobal.windowMs);

    const res = await call({ email: "coach@club.test" });

    expect(res.statusCode).toBe(200);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  // Mutation : compter le préflight épuiserait le quota d'une IP avant même son POST.
  it("never counts the preflight against the same IP's POST quota", async () => {
    await seedCoach("coach@club.test");
    for (let i = 0; i < LIMITS.deleteMailIp.limit + 5; i++) await call(undefined, { method: "OPTIONS", ip: "198.51.100.1" });

    const res = await call({ email: "coach@club.test" }, { ip: "198.51.100.1" });

    expect(res.statusCode).toBe(200);
    expect(sendEmail).toHaveBeenCalledTimes(1);
  });

  // La réponse est la même 200 pour un compte connu et pour une adresse inconnue, y compris quand
  // Firestore refuse une transaction (contention), cas reproduit sous 150 requêtes simultanées.
  it("answers 200 even when counting fails for a known account, like for an unknown one", async () => {
    await seedCoach("coach@club.test");
    const db = firestore();
    const original = db.runTransaction.bind(db);
    let transactions = 0;
    const spy = vi.spyOn(db, "runTransaction").mockImplementation(((...args: any[]) =>
      ++transactions === 2 ? Promise.reject(new Error("10 ABORTED: Transaction lock timeout")) : (original as any)(...args)) as any);

    const known = await call({ email: "coach@club.test" }, { ip: "198.51.100.1" });
    spy.mockRestore();
    const unknown = await call({ email: "ghost@club.test" }, { ip: "198.51.100.2" });

    expect(known.statusCode).toBe(200);
    expect(unknown.statusCode).toBe(200);
    expect(known.body).toEqual(unknown.body);
    expect(sendEmail).not.toHaveBeenCalled();
  });
});

// Le jeton est vérifié APRÈS la méthode, le CORS, la limite par IP et la validation de l'adresse, et
// AVANT tout le reste : un jeton refusé ne doit ni lire de compte, ni entamer un compteur global ou
// par compte, ni créer de jeton de suppression, ni envoyer de mail.
describe("onSendLandingPageMailDeleteAccount — reCAPTCHA", () => {
  const IP = "198.51.100.9";

  const rateLimitIds = async () => (await firestore().collection("rate_limits").get()).docs.map((doc) => doc.id);

  /** Vérificateur réel : un jeton absent ou non chaîne est refusé sans appeler Google. */
  async function useRealVerifier() {
    const actual = await vi.importActual<typeof import("../../src/utils/recaptcha")>("../../src/utils/recaptcha");
    vi.mocked(verifyRecaptcha).mockImplementation(actual.verifyRecaptcha);
  }

  it("hands the recaptchaToken of the body to the verifier, once", async () => {
    await seedCoach("coach@club.test");

    const res = await call({ email: "coach@club.test" });

    expect(res.statusCode).toBe(200);
    expect(verifyRecaptcha).toHaveBeenCalledTimes(1);
    expect(verifyRecaptcha).toHaveBeenCalledWith(TOKEN);
    expect(sendEmail).toHaveBeenCalledTimes(1);
  });

  it.each([
    ["absent", undefined],
    ["a number", 42],
    ["an object", { token: TOKEN }],
    ["empty", ""],
  ])("refuses a token that is %s with 400 captcha, doing nothing", async (_label, recaptchaToken) => {
    await seedCoach("coach@club.test");
    await useRealVerifier();
    const fetchSpy = vi.spyOn(globalThis, "fetch");

    const res = await call({ email: "coach@club.test", recaptchaToken }, { ip: IP });
    const fetched = fetchSpy.mock.calls.length;
    fetchSpy.mockRestore();

    expect(res.statusCode).toBe(400);
    expect(res.body).toEqual({ error: "captcha" });
    expect(fetched).toBe(0);
    expect(sendEmail).not.toHaveBeenCalled();
    expect(await tokenDocs()).toHaveLength(0);
  });

  it("refuses a token the verifier rejects with 400 {error: captcha}, doing nothing", async () => {
    await seedCoach("coach@club.test");
    vi.mocked(verifyRecaptcha).mockResolvedValue("invalid");

    const res = await call({ email: "coach@club.test" }, { ip: IP });

    expect(res.statusCode).toBe(400);
    expect(res.body).toEqual({ error: "captcha" });
    expect(sendEmail).not.toHaveBeenCalled();
    expect(await tokenDocs()).toHaveLength(0);
  });

  it("fails closed with 503 {error: captcha-unavailable} when the verifier cannot decide, doing nothing", async () => {
    await seedCoach("coach@club.test");
    vi.mocked(verifyRecaptcha).mockResolvedValue("unavailable");

    const res = await call({ email: "coach@club.test" }, { ip: IP });

    expect(res.statusCode).toBe(503);
    expect(res.body).toEqual({ error: "captcha-unavailable" });
    expect(sendEmail).not.toHaveBeenCalled();
    expect(await tokenDocs()).toHaveLength(0);
  });

  // Le jeton reCAPTCHA est vérifié avant toute lecture de compte et tout comptage : un appel sans
  // jeton valide ne lit aucun compte et n'entame que le compteur de son IP.
  it.each(["invalid", "unavailable"] as const)("a %s captcha reads no account and spends no counter but the per-IP one", async (verdict) => {
    await seedCoach("coach@club.test");
    await firestore().collection("deleted_users").add({ uid: "old", email: "gone@club.test", deletedAt: firestore.Timestamp.now() });
    vi.mocked(verifyRecaptcha).mockResolvedValue(verdict);
    const getUserByEmail = vi.spyOn(auth(), "getUserByEmail");

    for (const email of ["coach@club.test", "gone@club.test", "ghost@club.test"]) await call({ email }, { ip: IP });
    const reads = getUserByEmail.mock.calls.length;
    getUserByEmail.mockRestore();

    expect(reads).toBe(0);
    expect(await rateLimitIds()).toEqual([rateLimitKey("delete-mail-ip", IP)]); // ni par compte, ni global
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("answers the same 400 for a known and an unknown address when the captcha is refused", async () => {
    await seedCoach("coach@club.test");
    vi.mocked(verifyRecaptcha).mockResolvedValue("invalid");

    const known = await call({ email: "coach@club.test" }, { ip: IP });
    const unknown = await call({ email: "ghost@club.test" }, { ip: IP });

    expect(known.statusCode).toBe(unknown.statusCode);
    expect(known.body).toEqual(unknown.body);
  });

  it("does not call the verifier for an invalid address (no paid call for nothing)", async () => {
    const res = await call({ email: "pas une adresse" }, { ip: IP });

    expect(res.statusCode).toBe(400);
    expect(res.body).toEqual({ message: "Invalid email" });
    expect(verifyRecaptcha).not.toHaveBeenCalled();
  });

  it("does not call the verifier once the IP limit is reached", async () => {
    for (let i = 0; i < LIMITS.deleteMailIp.limit; i++) await call({ email: "ghost@club.test" }, { ip: IP });
    vi.mocked(verifyRecaptcha).mockClear();

    const res = await call({ email: "ghost@club.test" }, { ip: IP });

    expect(res.statusCode).toBe(429);
    expect(verifyRecaptcha).not.toHaveBeenCalled();
  });

  it("counts a refused captcha against the IP limit", async () => {
    vi.mocked(verifyRecaptcha).mockResolvedValue("invalid");
    for (let i = 0; i < LIMITS.deleteMailIp.limit; i++) await call({ email: "ghost@club.test" }, { ip: IP });

    expect((await call({ email: "ghost@club.test" }, { ip: IP })).statusCode).toBe(429);
  });

  it("does not call the verifier for a refused method nor for the preflight", async () => {
    expect((await call({ email: "coach@club.test" }, { method: "GET", ip: IP })).statusCode).toBe(405);
    expect((await call(undefined, { method: "OPTIONS", ip: IP })).statusCode).toBe(204);
    expect(verifyRecaptcha).not.toHaveBeenCalled();
  });

  it("keeps the CORS headers on a refused captcha, so the landing can read the error", async () => {
    vi.mocked(verifyRecaptcha).mockResolvedValue("invalid");

    const res = await call({ email: "coach@club.test" }, { origin: DEFAULT_BASE });

    expect(res.statusCode).toBe(400);
    expect(res.headers["access-control-allow-origin"]).toBe(DEFAULT_BASE);
  });
});
