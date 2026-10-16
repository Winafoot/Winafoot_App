import { createHmac } from "node:crypto";
import { auth } from "firebase-admin";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

// Interrupteur modifiable par test (les tests ci-dessous exercent le comportement ACTIF, valeur du dépôt).
const flag = vi.hoisted(() => ({ enabled: true }));
vi.mock("../../src/config/algolia", async (importActual) => ({
  ...(await importActual<typeof import("../../src/config/algolia")>()),
  get ALGOLIA_ENABLED() {
    return flag.enabled;
  },
}));

vi.mock("firebase-functions/logger", () => ({ debug: vi.fn(), error: vi.fn(), info: vi.fn(), log: vi.fn(), warn: vi.fn() }));

import * as logger from "firebase-functions/logger";
import getSearchKey from "../../src/callables/search/get_search_key";
import { ALGOLIA_SEARCH_KEY } from "../../src/config/secrets";
import { ownerKey } from "../../src/search/ids";

// Fausse clé parente : assez longue pour ressembler à une clé, sans rien de réel.
const PARENT_KEY = "fake-parent-key-for-tests-0000";
const caller = (uid: string) => ({ uid, token: {} });

/** Décode une clé sécurisée : base64( HMAC-SHA256 hex (64) + chaîne de requête ). */
function decode(securedKey: string) {
  const raw = Buffer.from(securedKey, "base64").toString("utf8");
  const hmac = raw.slice(0, 64);
  const query = raw.slice(64);
  return { hmac, query, params: new URLSearchParams(query), expectedHmac: createHmac("sha256", PARENT_KEY).update(query).digest("hex") };
}

beforeEach(async () => {
  flag.enabled = true;
  vi.spyOn(ALGOLIA_SEARCH_KEY, "value").mockReturnValue(PARENT_KEY);
  await auth().createUser({ uid: "coach-a" });
  await auth().createUser({ uid: "coach-b" });
});

afterEach(() => {
  vi.unstubAllEnvs();
  vi.restoreAllMocks();
  vi.mocked(logger.error).mockClear();
  vi.mocked(logger.warn).mockClear();
});

describe("getSearchKey", () => {
  it("answers with the app id, the ttl and the index names", async () => {
    const response = await getSearchKey({}, caller("coach-a"));

    expect(response).toEqual({
      appId: "UV1NCQERZ5",
      apiKey: expect.any(String),
      ttlSeconds: 3600,
      indices: { compositions: "wina_compositions", matches: "wina_matches" },
    });
  });

  it("derives a key signed with the parent key and restricted to the caller", async () => {
    const before = Math.floor(Date.now() / 1000);
    const { apiKey } = await getSearchKey({}, caller("coach-a"));
    const after = Math.floor(Date.now() / 1000);

    const { hmac, expectedHmac, params } = decode(apiKey);
    expect(hmac).toMatch(/^[0-9a-f]{64}$/);
    expect(hmac).toBe(expectedHmac);

    const owner = ownerKey("coach-a");
    expect(params.get("filters")).toBe(`ownerKey:"${owner}"`);
    expect(params.get("userToken")).toBe(owner);
    expect(params.get("restrictIndices")).toBe("wina_compositions,wina_matches");
    const validUntil = Number(params.get("validUntil"));
    expect(validUntil).toBeGreaterThanOrEqual(before + 3600);
    expect(validUntil).toBeLessThanOrEqual(after + 3600);
  });

  it("imposes the search parameters on the key", async () => {
    const { apiKey } = await getSearchKey({}, caller("coach-a"));

    const { params } = decode(apiKey);
    expect(params.get("analytics")).toBe("false");
    expect(params.get("clickAnalytics")).toBe("false");
    expect(params.get("enablePersonalization")).toBe("false");
    expect(params.get("attributesToRetrieve")).toBe("docId");
    expect(params.get("attributesToHighlight")).toBe("");
    expect(params.get("attributesToSnippet")).toBe("");
    expect(params.get("hitsPerPage")).toBe("100");
  });

  it("never puts the Firebase uid in the key", async () => {
    const { apiKey } = await getSearchKey({}, caller("coach-a"));

    expect(Buffer.from(apiKey, "base64").toString("utf8")).not.toContain("coach-a");
  });

  it("ignores any uid sent in the payload", async () => {
    const { apiKey } = await getSearchKey({ uid: "coach-b", userId: "coach-b", ownerKey: ownerKey("coach-b") }, caller("coach-a"));

    expect(decode(apiKey).params.get("filters")).toBe(`ownerKey:"${ownerKey("coach-a")}"`);
  });

  it("gives a different key to a different caller", async () => {
    const a = await getSearchKey({}, caller("coach-a"));
    const b = await getSearchKey({}, caller("coach-b"));

    expect(a.apiKey).not.toBe(b.apiKey);
    expect(decode(b.apiKey).params.get("filters")).toBe(`ownerKey:"${ownerKey("coach-b")}"`);
  });

  it("refuses a disabled account", async () => {
    await auth().updateUser("coach-a", { disabled: true });

    await expect(getSearchKey({}, caller("coach-a"))).rejects.toMatchObject({ code: "permission-denied", message: "Compte désactivé." });
    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ reason: "account-disabled", uid: "coach-a" }));
  });

  it("refuses a caller whose account no longer exists", async () => {
    await expect(getSearchKey({}, caller("ghost"))).rejects.toMatchObject({ code: "permission-denied" });
    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ reason: "account-not-found", uid: "ghost" }));
  });

  it.each([["empty", ""], ["blank", "   "]])("answers failed-precondition when the search secret is %s", async (_label, value) => {
    vi.spyOn(ALGOLIA_SEARCH_KEY, "value").mockReturnValue(value);

    await expect(getSearchKey({}, caller("coach-a"))).rejects.toMatchObject({ code: "failed-precondition", message: "Recherche indisponible." });
  });

  it("answers failed-precondition when the secret cannot be read", async () => {
    vi.spyOn(ALGOLIA_SEARCH_KEY, "value").mockImplementation(() => {
      throw new Error("secret absent");
    });

    await expect(getSearchKey({}, caller("coach-a"))).rejects.toMatchObject({ code: "failed-precondition" });
  });

  it("refuses before any Auth or secret read while ALGOLIA_ENABLED is false", async () => {
    flag.enabled = false;
    const secret = vi.spyOn(ALGOLIA_SEARCH_KEY, "value");
    const getUser = vi.spyOn(auth(), "getUser");

    await expect(getSearchKey({}, caller("coach-a"))).rejects.toMatchObject({ code: "failed-precondition", message: "Recherche indisponible." });

    expect(secret).not.toHaveBeenCalled();
    expect(getUser).not.toHaveBeenCalled();
  });

  // L'émulateur Functions charge la VRAIE clé depuis Secret Manager : il ne doit jamais s'en servir.
  it("answers failed-precondition under the Functions emulator, even with a secret available", async () => {
    vi.stubEnv("FUNCTIONS_EMULATOR", "true");

    await expect(getSearchKey({}, caller("coach-a"))).rejects.toMatchObject({ code: "failed-precondition", message: "Recherche indisponible." });
    vi.unstubAllEnvs();

    await expect(getSearchKey({}, caller("coach-a"))).resolves.toHaveProperty("apiKey");
  });

  it("uses the injected key factory with the parent key and the restrictions", async () => {
    const factory = vi.fn().mockReturnValue("injected-key");

    const response = await getSearchKey({}, caller("coach-a"), factory);

    expect(response.apiKey).toBe("injected-key");
    expect(factory).toHaveBeenCalledWith(PARENT_KEY, expect.objectContaining({ filters: `ownerKey:"${ownerKey("coach-a")}"` }));
  });

  it("answers internal without leaking the parent key when the factory throws", async () => {
    const factory = vi.fn().mockImplementation(() => {
      throw new Error(`boom with ${PARENT_KEY}`);
    });

    const failure = await getSearchKey({}, caller("coach-a"), factory).catch((e) => e);

    expect(failure).toMatchObject({ code: "internal" });
    expect(JSON.stringify(failure.message)).not.toContain(PARENT_KEY);
    expect(JSON.stringify(vi.mocked(logger.error).mock.calls)).not.toContain(PARENT_KEY);
  });

  it("neither logs nor returns the parent key", async () => {
    const response = await getSearchKey({}, caller("coach-a"));
    await getSearchKey({}, caller("coach-a"), () => {
      throw new Error(PARENT_KEY);
    }).catch(() => undefined);

    expect(JSON.stringify(response)).not.toContain(PARENT_KEY);
    const logged = JSON.stringify([...vi.mocked(logger.error).mock.calls, ...vi.mocked(logger.warn).mock.calls]);
    expect(logged).not.toContain(PARENT_KEY);
    expect(logged).not.toContain(decode(response.apiKey).hmac);
  });
});
