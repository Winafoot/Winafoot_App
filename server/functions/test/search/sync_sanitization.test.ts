import { inspect } from "node:util";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

// Le SDK Algolia v5 attache la requête brute (clé d'écriture en en-tête, corps = enregistrement)
// à `stackTrace` de toute erreur HTTP non réessayable. Aucune de ces erreurs ne doit sortir.
const FAKE_KEY = "fake-write-key-for-tests-0000";
const FAKE_PLAYER = "Zinedine Fakeplayer";

const sdk = vi.hoisted(() => ({
  saveObjects: vi.fn(),
  deleteObject: vi.fn(),
  algoliasearch: vi.fn(),
}));

vi.mock("algoliasearch", () => ({ algoliasearch: sdk.algoliasearch }));
vi.mock("firebase-functions/logger", () => ({
  debug: vi.fn(),
  error: vi.fn(),
  info: vi.fn(),
  log: vi.fn(),
  warn: vi.fn(),
}));

import * as logger from "firebase-functions/logger";
import { AlgoliaFailure } from "../../src/search/algolia_client";
import { SYNC_TARGETS, syncDocument } from "../../src/search/sync";

/** Erreur du SDK telle que construite par deserializeFailure : message serveur propre, requête brute dans stackTrace. */
function sdkError(status: number | undefined, message: string) {
  return Object.assign(new Error(message), {
    name: "ApiError",
    status,
    stackTrace: [
      {
        request: {
          method: "POST",
          path: "/1/indexes/wina_compositions/batch",
          headers: { "x-algolia-api-key": FAKE_KEY, "x-algolia-application-id": "APPID" },
          data: JSON.stringify({ requests: [{ action: "addObject", body: { name: FAKE_PLAYER } }] }),
        },
        response: { status, content: `{"message":"${message}"}` },
      },
    ],
  });
}

const COMPOSITION = { name: "Attaque", formationLabel: "4-3-3" };

function change(before: unknown, after: unknown) {
  const read = (data: any) => ({ exists: data != null, data: () => data });
  const ref = { get: vi.fn().mockResolvedValue(read(after)) };
  return { before: { ...read(before), ref }, after: { ...read(after), ref } } as any;
}

const context = { params: { userId: "uid-coach-1", docId: "doc-1" }, eventTime: new Date().toISOString(), eventId: "evt-1" };

function expectClean(value: unknown) {
  const dumped = inspect(value, { depth: Infinity, showHidden: true });
  expect(dumped).not.toContain(FAKE_KEY);
  expect(dumped).not.toContain(FAKE_PLAYER);
}

function expectLogsClean() {
  const logged = JSON.stringify([
    ...vi.mocked(logger.error).mock.calls,
    ...vi.mocked(logger.warn).mock.calls,
    ...vi.mocked(logger.info).mock.calls,
  ]);
  expect(logged).not.toContain(FAKE_KEY);
  expect(logged).not.toContain(FAKE_PLAYER);
}

beforeEach(() => {
  vi.clearAllMocks();
  process.env.ALGOLIA_WRITE_KEY = FAKE_KEY;
  sdk.algoliasearch.mockReturnValue({ saveObjects: sdk.saveObjects, deleteObject: sdk.deleteObject });
});

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("syncDocument with the real Algolia client wrapper", () => {
  it("builds the client with the write secret and the app id", async () => {
    sdk.saveObjects.mockResolvedValue([]);

    await syncDocument(SYNC_TARGETS.compositions, change(undefined, COMPOSITION), context);

    expect(sdk.algoliasearch).toHaveBeenCalledWith("UV1NCQERZ5", FAKE_KEY);
    expect(sdk.saveObjects).toHaveBeenCalledWith({
      indexName: "wina_compositions",
      objects: [expect.objectContaining({ docId: "doc-1", name: "Attaque" })],
    });
  });

  it("rethrows a 403 from the SDK without its request (key, player name) — error inspected in depth", async () => {
    sdk.saveObjects.mockRejectedValue(sdkError(403, "Invalid API key"));

    const error = await syncDocument(SYNC_TARGETS.compositions, change(undefined, COMPOSITION), context).catch((e) => e);

    expect(error).toBeInstanceOf(AlgoliaFailure);
    expect(error.status).toBe(403);
    expect(error.message).toBe("Invalid API key");
    expectClean(error);
    expectLogsClean();
  });

  it("logs a 400 without the request (the event is not retried)", async () => {
    sdk.saveObjects.mockRejectedValue(sdkError(400, "Invalid object"));

    await expect(syncDocument(SYNC_TARGETS.compositions, change(undefined, COMPOSITION), context)).resolves.toBeUndefined();

    expect(logger.error).toHaveBeenCalled();
    expectLogsClean();
  });

  it("rethrows a network error (no status) without the request", async () => {
    sdk.saveObjects.mockRejectedValue(sdkError(undefined, "Unreachable hosts"));

    const error = await syncDocument(SYNC_TARGETS.compositions, change(undefined, COMPOSITION), context).catch((e) => e);

    expect(error).toBeInstanceOf(AlgoliaFailure);
    expect(error.status).toBeUndefined();
    expectClean(error);
    expectLogsClean();
  });

  it("rethrows a failed deletion without the request", async () => {
    sdk.deleteObject.mockRejectedValue(sdkError(500, "Internal error"));

    const error = await syncDocument(SYNC_TARGETS.compositions, change(COMPOSITION, undefined), context).catch((e) => e);

    expect(error).toBeInstanceOf(AlgoliaFailure);
    expectClean(error);
    expectLogsClean();
  });

  it("does not retry a 404 on deletion", async () => {
    sdk.deleteObject.mockRejectedValue(sdkError(404, "Index does not exist"));

    await expect(syncDocument(SYNC_TARGETS.compositions, change(COMPOSITION, undefined), context)).resolves.toBeUndefined();
    expectLogsClean();
  });

  it("an empty secret makes the client unavailable (retried), without any fallback and without building the SDK client", async () => {
    process.env.ALGOLIA_WRITE_KEY = "";

    const error = await syncDocument(SYNC_TARGETS.compositions, change(undefined, COMPOSITION), context).catch((e) => e);
    expect(error).toBeInstanceOf(AlgoliaFailure);
    expect(error.status).toBeUndefined();

    const deletion = await syncDocument(SYNC_TARGETS.compositions, change(COMPOSITION, undefined), context).catch((e) => e);
    expect(deletion).toBeInstanceOf(AlgoliaFailure);
    expect(sdk.algoliasearch).not.toHaveBeenCalled();
  });

  // L'émulateur Functions charge la VRAIE clé depuis Secret Manager : il ne doit jamais écrire chez Algolia.
  it("refuses to write under the Functions emulator, even with a key available (no SDK client built)", async () => {
    vi.stubEnv("FUNCTIONS_EMULATOR", "true");

    const saved = await syncDocument(SYNC_TARGETS.compositions, change(undefined, COMPOSITION), context).catch((e) => e);
    const deleted = await syncDocument(SYNC_TARGETS.compositions, change(COMPOSITION, undefined), context).catch((e) => e);

    for (const error of [saved, deleted]) {
      expect(error).toBeInstanceOf(AlgoliaFailure);
      expect(error.status).toBeUndefined();
      expect(error.message).toMatch(/émulateur/i);
      expectClean(error);
    }
    expect(sdk.algoliasearch).not.toHaveBeenCalled();
    expect(sdk.saveObjects).not.toHaveBeenCalled();
    expect(sdk.deleteObject).not.toHaveBeenCalled();
  });
});
