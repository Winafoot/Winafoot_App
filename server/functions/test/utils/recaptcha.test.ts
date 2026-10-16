import { afterEach, beforeEach, describe, expect, it, vi, type MockInstance } from "vitest";

vi.mock("firebase-functions/logger", () => ({
  warn: vi.fn(),
  error: vi.fn(),
  info: vi.fn(),
}));

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { RECAPTCHA } from "../../src/config/recaptcha";
import { verifyRecaptcha } from "../../src/utils/recaptcha";

const TOKEN = "03AFcWeA-jeton-recaptcha-confidentiel";
const ACCESS_TOKEN = "ya29.jeton-d-acces-confidentiel";
const ASSESSMENTS_URL = "https://recaptchaenterprise.googleapis.com/v1/projects/wina-c4c4a/assessments";

/** Évaluation acceptable par défaut ; chaque test n'écrase que ce qu'il veut tester. */
const assessment = (tokenProperties: object = {}, riskAnalysis: object = {}) => ({
  tokenProperties: { valid: true, hostname: "wina-c4c4a.web.app", ...tokenProperties },
  riskAnalysis: { score: 0.9, ...riskAnalysis },
});
const reply = (body: unknown, status = 200) => new Response(typeof body === "string" ? body : JSON.stringify(body), { status });

let fetchMock: MockInstance<typeof fetch>;

beforeEach(() => {
  vi.spyOn(admin.app().options.credential!, "getAccessToken").mockResolvedValue({ access_token: ACCESS_TOKEN, expires_in: 3600 });
  fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async () => reply(assessment()));
  vi.mocked(logger.warn).mockClear();
  vi.mocked(logger.error).mockClear();
});

afterEach(() => {
  vi.restoreAllMocks();
});

/** Tout ce qui a été journalisé, à plat. */
const logged = () => JSON.stringify([...vi.mocked(logger.warn).mock.calls, ...vi.mocked(logger.error).mock.calls]);

describe("verifyRecaptcha — contract", () => {
  it("targets the Wina site key and the two Firebase Hosting domains", () => {
    expect(RECAPTCHA.siteKey).toBe("6LfKUe0tAAAAAHxnM9AC-zdPhUlHxr8DlkY3Q7PY");
    expect([...RECAPTCHA.allowedHostnames].sort()).toEqual(["wina-c4c4a.firebaseapp.com", "wina-c4c4a.web.app"]);
  });

  it("creates an assessment authenticated with the function's service account", async () => {
    await verifyRecaptcha(TOKEN);

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe(ASSESSMENTS_URL);
    expect(init?.method).toBe("POST");
    expect((init?.headers as Record<string, string>).Authorization).toBe(`Bearer ${ACCESS_TOKEN}`);
    expect(JSON.parse(init?.body as string)).toEqual({ event: { token: TOKEN, siteKey: RECAPTCHA.siteKey } });
    expect(init?.signal).toBeInstanceOf(AbortSignal); // pas d'attente illimitée de Google
  });
});

describe("verifyRecaptcha — accepted", () => {
  it.each(["wina-c4c4a.web.app", "wina-c4c4a.firebaseapp.com"])("accepts a valid token issued for %s", async (hostname) => {
    fetchMock.mockImplementation(async () => reply(assessment({ hostname })));

    expect(await verifyRecaptcha(TOKEN)).toBe("ok");
  });

  it("accepts a score exactly at the minimum", async () => {
    fetchMock.mockImplementation(async () => reply(assessment({}, { score: RECAPTCHA.minScore })));

    expect(await verifyRecaptcha(TOKEN)).toBe("ok");
  });
});

describe("verifyRecaptcha — token refused", () => {
  // Rien n'est envoyé à Google : inutile (et facturable) pour un jeton qui ne peut pas être valide.
  it.each([
    ["absent", undefined],
    ["null", null],
    ["a number", 42],
    ["an object", { token: TOKEN }],
    ["an array", [TOKEN]],
    ["an empty string", ""],
  ])("refuses a token that is %s without calling Google", async (_label, token) => {
    expect(await verifyRecaptcha(token)).toBe("invalid");
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("refuses a token longer than any real one without calling Google (a billable assessment)", async () => {
    expect(await verifyRecaptcha("x".repeat(RECAPTCHA.maxTokenLength + 1))).toBe("invalid");
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("still sends a token at the maximum length", async () => {
    expect(await verifyRecaptcha("x".repeat(RECAPTCHA.maxTokenLength))).toBe("ok");
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it("refuses a token Google reports as invalid (answer observed for a fake token)", async () => {
    fetchMock.mockImplementation(async () => reply({ tokenProperties: { valid: false, invalidReason: "MALFORMED", hostname: "" }, riskAnalysis: { score: 0 } }));

    expect(await verifyRecaptcha(TOKEN)).toBe("invalid");
    expect(logged()).toContain("MALFORMED");
  });

  it.each(["EXPIRED", "DUPE", "MISSING"])("refuses an invalid token (%s)", async (invalidReason) => {
    fetchMock.mockImplementation(async () => reply(assessment({ valid: false, invalidReason })));

    expect(await verifyRecaptcha(TOKEN)).toBe("invalid");
  });

  // Un jeton n'est accepté que s'il a été émis pour l'un des domaines de la landing, même valide par ailleurs.
  it.each(["evil.test", "wina-c4c4a.web.app.evil.test", "", undefined])("refuses a token issued for another domain (%s)", async (hostname) => {
    fetchMock.mockImplementation(async () => reply(assessment({ hostname })));

    expect(await verifyRecaptcha(TOKEN)).toBe("invalid");
  });

  it.each([0, 0.1, RECAPTCHA.minScore - 0.01])("refuses a score that is too low (%s)", async (score) => {
    fetchMock.mockImplementation(async () => reply(assessment({}, { score })));

    expect(await verifyRecaptcha(TOKEN)).toBe("invalid");
  });

  it.each([{}, { score: "0.9" }, { score: null }])("refuses an evaluation without a numeric score (%j)", async (riskAnalysis) => {
    fetchMock.mockImplementation(async () => reply({ tokenProperties: assessment().tokenProperties, riskAnalysis }));

    expect(await verifyRecaptcha(TOKEN)).toBe("invalid");
  });

  it("refuses an answer without tokenProperties", async () => {
    fetchMock.mockImplementation(async () => reply({ riskAnalysis: { score: 0.9 } }));

    expect(await verifyRecaptcha(TOKEN)).toBe("invalid");
  });

  it("refuses only when valid is exactly true", async () => {
    fetchMock.mockImplementation(async () => reply(assessment({ valid: "true" })));

    expect(await verifyRecaptcha(TOKEN)).toBe("invalid");
  });
});

// Échec fermé : si on ne peut pas décider, on n'envoie rien.
describe("verifyRecaptcha — Google unavailable", () => {
  it.each([400, 403, 429, 500, 503])("is unavailable when Google answers %s, and logs the status", async (status) => {
    fetchMock.mockImplementation(async () => reply({ error: { message: `contenu de la réponse ${TOKEN}` } }, status));

    expect(await verifyRecaptcha(TOKEN)).toBe("unavailable");
    expect(logged()).toContain(String(status));
    expect(logged()).not.toContain("contenu de la réponse");
  });

  it.each([
    ["an HTML page", "<html>502 Bad Gateway</html>"],
    ["an empty body", ""],
  ])("is unavailable when the answer is not JSON (%s)", async (_label, body) => {
    fetchMock.mockImplementation(async () => reply(body));

    expect(await verifyRecaptcha(TOKEN)).toBe("unavailable");
  });

  it.each([["null", "null"], ["a string", '"ok"'], ["a number", "42"]])("is unavailable when the JSON is %s, not an evaluation", async (_label, body) => {
    fetchMock.mockImplementation(async () => reply(body));

    expect(await verifyRecaptcha(TOKEN)).toBe("unavailable");
  });

  it("is unavailable when Google cannot be reached, without leaking the request", async () => {
    fetchMock.mockRejectedValue(Object.assign(new Error("fetch failed"), { cause: { config: { body: TOKEN } } }));

    expect(await verifyRecaptcha(TOKEN)).toBe("unavailable");
    expect(logged()).toContain("fetch failed");
    expect(logged()).not.toContain(TOKEN);
  });

  it("is unavailable when the call times out", async () => {
    fetchMock.mockRejectedValue(new DOMException("The operation was aborted due to timeout", "TimeoutError"));

    expect(await verifyRecaptcha(TOKEN)).toBe("unavailable");
  });

  it("is unavailable when the service account token cannot be obtained, without calling Google", async () => {
    vi.mocked(admin.app().options.credential!.getAccessToken).mockRejectedValue(new Error("Could not load the default credentials"));

    expect(await verifyRecaptcha(TOKEN)).toBe("unavailable");
    expect(fetchMock).not.toHaveBeenCalled();
  });
});

describe("verifyRecaptcha — logs", () => {
  it.each([
    ["accepted", assessment(), 200],
    ["invalid", assessment({ valid: false, invalidReason: "EXPIRED" }), 200],
    ["wrong domain", assessment({ hostname: "evil.test" }), 200],
    ["low score", assessment({}, { score: 0.1 }), 200],
    ["refused by Google", { error: { message: "denied" } }, 403],
  ])("never writes the reCAPTCHA token or the access token (%s)", async (_label, body, status) => {
    fetchMock.mockImplementation(async () => reply(body, status));

    await verifyRecaptcha(TOKEN);

    expect(logged()).not.toContain(TOKEN);
    expect(logged()).not.toContain(ACCESS_TOKEN);
  });

  it("logs the score of a refused token", async () => {
    fetchMock.mockImplementation(async () => reply(assessment({}, { score: 0.1 })));

    await verifyRecaptcha(TOKEN);

    expect(logged()).toContain("0.1");
  });
});
