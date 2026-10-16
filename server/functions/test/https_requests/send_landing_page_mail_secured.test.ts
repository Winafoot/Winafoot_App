import { beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("../../src/utils/send_email", () => ({
  sendEmail: vi.fn().mockResolvedValue({}),
}));
// Le vérificateur reCAPTCHA a ses propres tests (test/utils/recaptcha.test.ts) : ici on simule son verdict.
vi.mock("../../src/utils/recaptcha", () => ({
  verifyRecaptcha: vi.fn(),
}));

import { sendEmail } from "../../src/utils/send_email";
import { verifyRecaptcha } from "../../src/utils/recaptcha";
import { firestore } from "firebase-admin";
import { fakeReq, fakeRes, seedAppConfig } from "../helpers";
import { LIMITS } from "../../src/config/rate_limits";
import { rateLimitKey } from "../../src/utils/rate_limit";
import sendLandingMail from "../../src/https_requests/landing_page/send_landing_page_mail_secured";

const TOKEN = "jeton-recaptcha-factice";
const FORM = { name: "Karim B.", email: "visiteur@club.test", subject: "Question", message: "Bonjour,\nComment ça marche ?", recaptchaToken: TOKEN };

async function call(body: unknown, method = "POST", ip?: string) {
  const res = fakeRes();
  await sendLandingMail(fakeReq(method, body, undefined, ip), res);
  return res;
}

beforeEach(async () => {
  vi.mocked(sendEmail).mockClear();
  vi.mocked(sendEmail).mockResolvedValue({} as any);
  vi.mocked(verifyRecaptcha).mockReset();
  vi.mocked(verifyRecaptcha).mockResolvedValue("ok");
  await seedAppConfig(); // contactEmail: support@wina.test
});

// Contrat de la landing (public/support.html) : POST { name, email, subject, message }.
describe("onSendLandingPageMail (secured)", () => {
  it("forwards the request to the app's contact address only", async () => {
    const res = await call(FORM);

    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ message: "Data received" });
    expect(sendEmail).toHaveBeenCalledTimes(1);
    expect(vi.mocked(sendEmail).mock.calls[0][1]).toMatchObject({ email: "support@wina.test" });
    const html = vi.mocked(sendEmail).mock.calls[0][2] as string;
    expect(html).toContain("Karim B.");
    expect(html).toContain("visiteur@club.test");
    expect(html).toContain("Comment ça marche ?");
  });

  // Chaque champ du formulaire (name, subject, message) est échappé avant d'entrer dans le HTML
  // du mail reçu par le support.
  it("escapes every field of the form before it reaches the HTML mail", async () => {
    await call({
      name: '<img src=x onerror="alert(1)">',
      email: "visiteur@club.test",
      subject: "<script>alert(1)</script>",
      message: '<a href="https://evil.test">Votre compte est suspendu</a>',
      recaptchaToken: TOKEN,
    });

    const html = vi.mocked(sendEmail).mock.calls[0][2] as string;
    expect(html).not.toContain("<script>");
    expect(html).not.toContain("<img src=x");
    expect(html).not.toContain('<a href="https://evil.test"');
    expect(html).toContain("&lt;script&gt;");
    expect(html).toContain("&lt;a href=&quot;https://evil.test&quot;&gt;");
  });

  it("keeps line breaks of the message readable", async () => {
    await call(FORM);

    expect(vi.mocked(sendEmail).mock.calls[0][2]).toContain("Bonjour,<br>Comment ça marche ?");
  });

  it.each([
    ["no body", undefined],
    ["a missing field", { ...FORM, message: undefined }],
    ["an empty field", { ...FORM, subject: "  " }],
    ["a non-string field", { ...FORM, name: 42 }],
    ["a malformed email", { ...FORM, email: "pas une adresse" }],
    ["an oversized name", { ...FORM, name: "a".repeat(101) }],
    ["an oversized subject", { ...FORM, subject: "a".repeat(201) }],
    ["an oversized message", { ...FORM, message: "a".repeat(5001) }],
  ])("rejects %s with 400 and sends nothing", async (_label, body) => {
    const res = await call(body);

    expect(res.statusCode).toBe(400);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("answers 500 when the contact address is not configured (no fallback to a third party)", async () => {
    await seedAppConfig({ contactEmail: undefined });

    const res = await call(FORM);

    expect(res.statusCode).toBe(500);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("answers 500 when the mail cannot be sent, without leaking the error", async () => {
    vi.mocked(sendEmail).mockRejectedValueOnce(new Error("MailerSend indisponible"));

    const res = await call(FORM);

    expect(res.statusCode).toBe(500);
    expect(JSON.stringify(res.body)).not.toContain("MailerSend");
  });

  it("refuses GET with 405", async () => {
    expect((await call(FORM, "GET")).statusCode).toBe(405);
  });
});

describe("onSendLandingPageMail — rate limiting", () => {
  it(`refuses an IP after ${LIMITS.supportIp.limit} messages with 429`, async () => {
    for (let i = 0; i < LIMITS.supportIp.limit; i++) expect((await call(FORM, "POST", "198.51.100.1")).statusCode).toBe(200);

    const res = await call(FORM, "POST", "198.51.100.1");

    expect(res.statusCode).toBe(429);
    expect(sendEmail).toHaveBeenCalledTimes(LIMITS.supportIp.limit);
  });

  it("does not block another IP", async () => {
    for (let i = 0; i < LIMITS.supportIp.limit + 1; i++) await call(FORM, "POST", "198.51.100.1");

    expect((await call(FORM, "POST", "198.51.100.2")).statusCode).toBe(200);
  });

  // Plafond global quotidien : une armée d'IP ne doit pas vider le quota MailerSend.
  it("refuses every IP once the global daily cap is reached", async () => {
    const { limit, windowMs } = LIMITS.supportGlobal;
    await firestore()
      .collection("rate_limits")
      .doc(rateLimitKey("support-global", "all"))
      .set({ count: limit, windowStart: Date.now(), expiresAt: firestore.Timestamp.fromMillis(Date.now() + windowMs) });

    const res = await call(FORM, "POST", "198.51.100.77");

    expect(res.statusCode).toBe(429);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("does not spend the quota on invalid forms", async () => {
    for (let i = 0; i < LIMITS.supportIp.limit; i++) await call({ ...FORM, email: "pas une adresse" }, "POST", "198.51.100.1");

    expect((await call(FORM, "POST", "198.51.100.3")).statusCode).toBe(200);
  });
});

// Mutation : compter le plafond global AVANT la validation laisserait des formulaires
// invalides, venus d'IP distinctes, vider le quota de tout le monde.
describe("onSendLandingPageMail — global cap and invalid forms", () => {
  it("does not spend the global cap on invalid forms sent from many IPs", async () => {
    for (let i = 0; i < LIMITS.supportGlobal.limit + 1; i++) {
      await call({ ...FORM, email: "pas une adresse" }, "POST", `198.51.100.${(i % 200) + 1}`);
    }

    const res = await call(FORM, "POST", "203.0.113.200");

    expect(res.statusCode).toBe(200);
  });

  // Plafond HORAIRE : un afflux de requêtes suspend le formulaire de support (exigé par les stores)
  // une heure au plus.
  it("uses an hourly window for the global cap, so a burst of requests suspends support for an hour at most", () => {
    expect(LIMITS.supportGlobal.windowMs).toBeLessThanOrEqual(60 * 60_000);
  });
});

// Le jeton est vérifié APRÈS la méthode, le CORS, la limite par IP et la validation du formulaire,
// et AVANT tout le reste : un jeton refusé ne doit ni entamer le plafond global (quota MailerSend
// partagé) ni envoyer quoi que ce soit.
describe("onSendLandingPageMail — reCAPTCHA", () => {
  const IP = "198.51.100.9";

  const rateLimitIds = async () => (await firestore().collection("rate_limits").get()).docs.map((doc) => doc.id);

  /** Vérificateur réel : un jeton absent ou non chaîne est refusé sans appeler Google. */
  async function useRealVerifier() {
    const actual = await vi.importActual<typeof import("../../src/utils/recaptcha")>("../../src/utils/recaptcha");
    vi.mocked(verifyRecaptcha).mockImplementation(actual.verifyRecaptcha);
  }

  it("hands the recaptchaToken of the body to the verifier, once", async () => {
    const res = await call(FORM);

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
  ])("refuses a token that is %s with 400 captcha, and sends nothing", async (_label, recaptchaToken) => {
    await useRealVerifier();
    const fetchSpy = vi.spyOn(globalThis, "fetch");

    const res = await call({ ...FORM, recaptchaToken }, "POST", IP);
    const fetched = fetchSpy.mock.calls.length;
    fetchSpy.mockRestore();

    expect(res.statusCode).toBe(400);
    expect(res.body).toEqual({ error: "captcha" });
    expect(fetched).toBe(0);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("refuses a token the verifier rejects with 400 {error: captcha}, and sends nothing", async () => {
    vi.mocked(verifyRecaptcha).mockResolvedValue("invalid");

    const res = await call(FORM, "POST", IP);

    expect(res.statusCode).toBe(400);
    expect(res.body).toEqual({ error: "captcha" });
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("fails closed with 503 {error: captcha-unavailable} when the verifier cannot decide, and sends nothing", async () => {
    vi.mocked(verifyRecaptcha).mockResolvedValue("unavailable");

    const res = await call(FORM, "POST", IP);

    expect(res.statusCode).toBe(503);
    expect(res.body).toEqual({ error: "captcha-unavailable" });
    expect(sendEmail).not.toHaveBeenCalled();
  });

  // Mutation : vérifier le jeton après le plafond global laisserait des robots sans jeton vider le quota.
  it.each(["invalid", "unavailable"] as const)("a %s captcha does not spend the global cap: only the per-IP counter moves", async (verdict) => {
    vi.mocked(verifyRecaptcha).mockResolvedValue(verdict);

    await call(FORM, "POST", IP);

    expect(await rateLimitIds()).toEqual([rateLimitKey("support-ip", IP)]);
  });

  it("checks the captcha before looking at the contact address", async () => {
    await seedAppConfig({ contactEmail: undefined }); // sans captcha ce cas répondrait 500
    vi.mocked(verifyRecaptcha).mockResolvedValue("invalid");

    const res = await call(FORM, "POST", IP);

    expect(res.statusCode).toBe(400); // et non 500 : le captcha passe avant la lecture de contactEmail
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("does not call the verifier for an invalid form (no paid call for nothing)", async () => {
    const res = await call({ ...FORM, email: "pas une adresse" }, "POST", IP);

    expect(res.statusCode).toBe(400);
    expect(res.body).toEqual({ message: "Invalid form" });
    expect(verifyRecaptcha).not.toHaveBeenCalled();
  });

  it("does not call the verifier once the IP limit is reached", async () => {
    for (let i = 0; i < LIMITS.supportIp.limit; i++) await call(FORM, "POST", IP);
    vi.mocked(verifyRecaptcha).mockClear();

    const res = await call(FORM, "POST", IP);

    expect(res.statusCode).toBe(429);
    expect(verifyRecaptcha).not.toHaveBeenCalled();
  });

  it("counts a refused captcha against the IP limit", async () => {
    vi.mocked(verifyRecaptcha).mockResolvedValue("invalid");
    for (let i = 0; i < LIMITS.supportIp.limit; i++) await call(FORM, "POST", IP);

    expect((await call(FORM, "POST", IP)).statusCode).toBe(429);
  });

  it("does not call the verifier for a refused method", async () => {
    expect((await call(FORM, "GET", IP)).statusCode).toBe(405);
    expect(verifyRecaptcha).not.toHaveBeenCalled();
  });
});
