import { inspect } from "node:util";
import { beforeEach, describe, expect, it, vi } from "vitest";

// Mêmes pièges que sync_sanitization : une erreur du SDK embarque la clé dans `stackTrace`.
const FAKE_KEY = "fake-setup-key-for-tests-0000";

const sdk = vi.hoisted(() => ({
  setSettings: vi.fn(),
  waitForTask: vi.fn(),
  saveObjects: vi.fn(),
  deleteObjects: vi.fn(),
  browseObjects: vi.fn(),
  algoliasearch: vi.fn(),
}));

vi.mock("algoliasearch", () => ({ algoliasearch: sdk.algoliasearch }));

import { AlgoliaFailure } from "../../src/search/algolia_client";
import { createReindexClient } from "../../src/search/reindex_client";

function sdkError(status: number | undefined, message: string) {
  return Object.assign(new Error(message), {
    name: "ApiError",
    status,
    stackTrace: [{ request: { headers: { "x-algolia-api-key": FAKE_KEY } }, response: { status } }],
  });
}

const settings = { attributesForFaceting: ["filterOnly(ownerKey)"] } as any;
const record = { objectID: "o1", ownerKey: "k", docId: "d", name: "n", formationLabel: "4-3-3", formationDigits: "433" };

beforeEach(() => {
  vi.resetAllMocks();
  sdk.algoliasearch.mockReturnValue(sdk);
});

describe("createReindexClient", () => {
  it("builds the SDK client with the app id and the given key", () => {
    createReindexClient("APPID", FAKE_KEY);

    expect(sdk.algoliasearch).toHaveBeenCalledWith("APPID", FAKE_KEY);
  });

  it("applies settings then waits for the task", async () => {
    sdk.setSettings.mockResolvedValue({ taskID: 7 });
    sdk.waitForTask.mockResolvedValue({});

    await createReindexClient("APPID", FAKE_KEY).setSettings("wina_matches", settings);

    expect(sdk.setSettings).toHaveBeenCalledWith({ indexName: "wina_matches", indexSettings: settings });
    expect(sdk.waitForTask).toHaveBeenCalledWith({ indexName: "wina_matches", taskID: 7 });
  });

  it("saves and deletes with waitForTasks", async () => {
    sdk.saveObjects.mockResolvedValue([]);
    sdk.deleteObjects.mockResolvedValue([]);
    const client = createReindexClient("APPID", FAKE_KEY);

    await client.saveRecords("wina_matches", [record]);
    await client.deleteRecords("wina_matches", ["o1"]);

    expect(sdk.saveObjects).toHaveBeenCalledWith({ indexName: "wina_matches", objects: [record], waitForTasks: true });
    expect(sdk.deleteObjects).toHaveBeenCalledWith({ indexName: "wina_matches", objectIDs: ["o1"], waitForTasks: true });
  });

  it("browses the objectID of every record, and only that", async () => {
    sdk.browseObjects.mockImplementation(async ({ aggregator }) => {
      aggregator({ hits: [{ objectID: "o1" }] });
      aggregator({ hits: [{ objectID: "o2" }] });
    });

    const ids = await createReindexClient("APPID", FAKE_KEY).browseObjectIds("wina_matches");

    expect(ids).toEqual(["o1", "o2"]);
    expect(sdk.browseObjects).toHaveBeenCalledWith(expect.objectContaining({ indexName: "wina_matches", browseParams: { attributesToRetrieve: ["objectID"] } }));
  });

  it.each([
    ["setSettings", (c: ReturnType<typeof createReindexClient>) => c.setSettings("i", settings), sdk.setSettings],
    ["saveRecords", (c: ReturnType<typeof createReindexClient>) => c.saveRecords("i", [record]), sdk.saveObjects],
    ["deleteRecords", (c: ReturnType<typeof createReindexClient>) => c.deleteRecords("i", ["o"]), sdk.deleteObjects],
    ["browseObjectIds", (c: ReturnType<typeof createReindexClient>) => c.browseObjectIds("i"), sdk.browseObjects],
  ])("%s turns any SDK error into a clean AlgoliaFailure", async (_name, call, sdkCall) => {
    sdkCall.mockRejectedValue(sdkError(403, `Not enough rights (${FAKE_KEY})`));

    const failure = await call(createReindexClient("APPID", FAKE_KEY)).catch((e: unknown) => e);

    expect(failure).toBeInstanceOf(AlgoliaFailure);
    expect(failure).toMatchObject({ status: 403 });
    expect(inspect(failure, { depth: Infinity, showHidden: true })).not.toContain(FAKE_KEY);
  });
});
