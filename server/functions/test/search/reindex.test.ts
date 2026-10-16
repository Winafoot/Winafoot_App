import { auth, firestore } from "firebase-admin";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ALGOLIA_INDICES } from "../../src/config/algolia";
import { AlgoliaFailure } from "../../src/search/algolia_client";
import { objectId, ownerKey } from "../../src/search/ids";
import { assertNotEmulated, formatError, parseArgs, type ReindexClient, runReindex } from "../../src/search/reindex";
import type { SearchRecord } from "../../src/search/records";
import { INDEX_SETTINGS } from "../../src/search/settings";

const COMPOSITIONS = ALGOLIA_INDICES.compositions;
const MATCHES = ALGOLIA_INDICES.matches;
const OPPONENT = "Fakeopponent";
const COMPOSITION_NAME = "Fakecomposition";

/** Faux client Algolia en mémoire : journalise chaque appel, aucun réseau. */
class FakeClient implements ReindexClient {
  readonly indices = new Map<string, Set<string>>();
  readonly settings: Record<string, unknown> = {};
  readonly writes: string[] = [];

  put(index: string, objectID: string): void {
    this.indices.set(index, (this.indices.get(index) ?? new Set()).add(objectID));
  }
  ids(index: string): string[] {
    return [...(this.indices.get(index) ?? [])].sort();
  }

  async setSettings(indexName: string, settings: unknown): Promise<void> {
    this.writes.push(`settings:${indexName}`);
    this.settings[indexName] = settings;
  }
  async saveRecords(indexName: string, records: SearchRecord[]): Promise<void> {
    this.writes.push(`save:${indexName}:${records.length}`);
    records.forEach((r) => this.put(indexName, r.objectID));
  }
  async browseObjectIds(indexName: string): Promise<string[]> {
    return this.ids(indexName);
  }
  async deleteRecords(indexName: string, objectIDs: string[]): Promise<void> {
    this.writes.push(`delete:${indexName}:${objectIDs.length}`);
    objectIDs.forEach((id) => this.indices.get(indexName)?.delete(id));
  }
}

const finished = (name = OPPONENT) => ({ status: "finished", finishedAt: firestore.Timestamp.fromDate(new Date("2026-03-05T12:00:00Z")), opponent: { name } });

async function addUser(uid: string, withAuth = true): Promise<void> {
  if (withAuth) await auth().createUser({ uid });
  await firestore().doc(`users/${uid}`).set({ createdAt: 1 });
}

function run(client: FakeClient, mode: Parameters<typeof runReindex>[0], dryRun = false) {
  const lines: string[] = [];
  const report = runReindex(mode, dryRun, { db: firestore(), auth: auth(), client, log: (l) => lines.push(l) });
  return report.then((r) => ({ report: r, lines }));
}

let client: FakeClient;
beforeEach(() => {
  client = new FakeClient();
});

describe("runReindex — indexation complète", () => {
  it("indexes compositions and finished matches of users that have an Auth account", async () => {
    await addUser("coach-a");
    await firestore().doc("users/coach-a/compositions/c1").set({ name: COMPOSITION_NAME, formationLabel: "4-3-3", extra: "x" });
    await firestore().doc("users/coach-a/matches/m1").set(finished());
    await firestore().doc("users/coach-a/matches/m2").set({ status: "live", opponent: { name: OPPONENT } });

    await run(client, { kind: "index" });

    expect(client.ids(COMPOSITIONS)).toEqual([objectId("coach-a", "c1")]);
    expect(client.ids(MATCHES)).toEqual([objectId("coach-a", "m1")]);
  });

  it("sends complete records (projected fields, hashed ids, docId)", async () => {
    await addUser("coach-a");
    await firestore().doc("users/coach-a/compositions/c1").set({ name: COMPOSITION_NAME, formationLabel: "4-3-3" });
    const sent: SearchRecord[] = [];
    client.saveRecords = async (_i, records) => void sent.push(...records);

    await run(client, { kind: "index" });

    expect(sent).toEqual([
      { objectID: objectId("coach-a", "c1"), ownerKey: ownerKey("coach-a"), docId: "c1", name: COMPOSITION_NAME, formationLabel: "4-3-3", formationDigits: "433" },
    ]);
  });

  it("does NOT push a document whose user has no Auth account, and counts it", async () => {
    await addUser("coach-a");
    await addUser("ghost", false);
    await firestore().doc("users/coach-a/compositions/c1").set({ name: "A", formationLabel: "4-4-2" });
    await firestore().doc("users/ghost/compositions/c9").set({ name: COMPOSITION_NAME, formationLabel: "4-4-2" });
    await firestore().doc("users/ghost/matches/m9").set(finished());

    const { report, lines } = await run(client, { kind: "index" });

    expect(client.ids(COMPOSITIONS)).toEqual([objectId("coach-a", "c1")]);
    expect(client.ids(MATCHES)).toEqual([]);
    expect(report.indexed).toEqual({ [COMPOSITIONS]: 1, [MATCHES]: 0 });
    expect(report.noAccount).toEqual({ [COMPOSITIONS]: 1, [MATCHES]: 1 });
    // Listés hachés, jamais en clair.
    expect(report.ignoredOwnerKeys).toEqual([ownerKey("ghost")]);
    expect(lines.join("\n")).toContain(ownerKey("ghost"));
    expect(lines.join("\n")).not.toContain("ghost");
  });

  it("ignores documents that are not under users/{uid}/", async () => {
    await addUser("coach-a");
    await firestore().doc("teams/t1/compositions/c1").set({ name: "A", formationLabel: "4-4-2" });
    await firestore().doc("users/coach-a/teams/t1/compositions/c2").set({ name: "A", formationLabel: "4-4-2" });

    await run(client, { kind: "index" });

    expect(client.ids(COMPOSITIONS)).toEqual([]);
  });

  it("counts non indexable documents without pushing them", async () => {
    await addUser("coach-a");
    await firestore().doc("users/coach-a/compositions/bad").set({ name: 3, formationLabel: "4-4-2" });

    const { report } = await run(client, { kind: "index" });

    expect(report.notIndexable[COMPOSITIONS]).toBe(1);
    expect(client.ids(COMPOSITIONS)).toEqual([]);
  });

  it("handles more than 100 accounts (Auth lookups are batched by 100)", async () => {
    const uids = Array.from({ length: 101 }, (_, i) => `coach-${i}`);
    await Promise.all(uids.map((uid) => addUser(uid)));
    await Promise.all(uids.map((uid) => firestore().doc(`users/${uid}/compositions/c`).set({ name: "A", formationLabel: "4-4-2" })));

    const { report } = await run(client, { kind: "index" });

    expect(report.indexed[COMPOSITIONS]).toBe(101);
    expect(client.ids(COMPOSITIONS)).toHaveLength(101);
  });

  it("prints counters only, never a name or an uid", async () => {
    await addUser("coach-a");
    await firestore().doc("users/coach-a/compositions/c1").set({ name: COMPOSITION_NAME, formationLabel: "4-3-3" });
    await firestore().doc("users/coach-a/matches/m1").set(finished());

    const { lines } = await run(client, { kind: "index" });

    const output = lines.join("\n");
    expect(output).not.toContain(COMPOSITION_NAME);
    expect(output).not.toContain(OPPONENT);
    expect(output).not.toContain("coach-a");
  });

  it("--dry-run writes nothing but reports what would be indexed", async () => {
    await addUser("coach-a");
    await firestore().doc("users/coach-a/compositions/c1").set({ name: "A", formationLabel: "4-3-3" });

    const { report, lines } = await run(client, { kind: "index" }, true);

    expect(client.writes).toEqual([]);
    expect(report.indexed[COMPOSITIONS]).toBe(1);
    expect(lines.join("\n")).toContain("--dry-run");
  });
});

describe("runReindex — --settings-only", () => {
  it("applies the settings of both indices and sends no record", async () => {
    await addUser("coach-a");
    await firestore().doc("users/coach-a/compositions/c1").set({ name: "A", formationLabel: "4-3-3" });

    await run(client, { kind: "settings-only" });

    expect(client.writes.sort()).toEqual([`settings:${COMPOSITIONS}`, `settings:${MATCHES}`]);
    expect(client.settings[COMPOSITIONS]).toEqual(INDEX_SETTINGS[COMPOSITIONS]);
    expect(client.settings[MATCHES]).toEqual(INDEX_SETTINGS[MATCHES]);
    expect(client.ids(COMPOSITIONS)).toEqual([]);
  });

  it("--dry-run applies nothing", async () => {
    await run(client, { kind: "settings-only" }, true);

    expect(client.writes).toEqual([]);
  });
});

describe("runReindex — --purge-orphans (purge par réconciliation)", () => {
  const live = { c1: objectId("coach-a", "c1"), m1: objectId("coach-a", "m1") };

  beforeEach(async () => {
    await addUser("coach-a");
    await firestore().doc("users/coach-a/compositions/c1").set({ name: COMPOSITION_NAME, formationLabel: "4-3-3" });
    await firestore().doc("users/coach-a/matches/m1").set(finished());
    client.put(COMPOSITIONS, live.c1);
    client.put(MATCHES, live.m1);
  });

  it("purges the records of an account that no longer exists in Auth", async () => {
    await firestore().doc("users/deleted-coach/compositions/c9").set({ name: "Gone", formationLabel: "4-4-2" });
    client.put(COMPOSITIONS, objectId("deleted-coach", "c9"));
    client.put(MATCHES, objectId("deleted-coach", "m9"));

    const { report } = await run(client, { kind: "purge-orphans" });

    expect(client.ids(COMPOSITIONS)).toEqual([live.c1]);
    expect(client.ids(MATCHES)).toEqual([live.m1]);
    expect(report.deleted).toEqual({ [COMPOSITIONS]: 1, [MATCHES]: 1 });
  });

  it("purges the record of a document deleted from a LIVE account", async () => {
    client.put(COMPOSITIONS, objectId("coach-a", "deleted-doc"));
    client.put(MATCHES, objectId("coach-a", "deleted-match"));

    const { report } = await run(client, { kind: "purge-orphans" });

    expect(client.ids(COMPOSITIONS)).toEqual([live.c1]);
    expect(client.ids(MATCHES)).toEqual([live.m1]);
    expect(report.deleted).toEqual({ [COMPOSITIONS]: 1, [MATCHES]: 1 });
  });

  it("purges the record of a document that is no longer indexable (match not finished any more)", async () => {
    await firestore().doc("users/coach-a/matches/m1").set({ status: "live", opponent: { name: OPPONENT } });

    await run(client, { kind: "purge-orphans" });

    expect(client.ids(MATCHES)).toEqual([]);
  });

  it("never purges an indexable document, even of a disabled account", async () => {
    await auth().updateUser("coach-a", { disabled: true });

    const { report } = await run(client, { kind: "purge-orphans" });

    expect(client.ids(COMPOSITIONS)).toEqual([live.c1]);
    expect(client.ids(MATCHES)).toEqual([live.m1]);
    expect(report.deleted).toEqual({ [COMPOSITIONS]: 0, [MATCHES]: 0 });
    expect(client.writes).toEqual([]);
  });

  it("--dry-run deletes nothing but counts what would go", async () => {
    client.put(COMPOSITIONS, objectId("coach-a", "deleted-doc"));
    client.put(MATCHES, objectId("deleted-coach", "m9"));

    const { report } = await run(client, { kind: "purge-orphans" }, true);

    expect(client.writes).toEqual([]);
    expect(report.deleted).toEqual({ [COMPOSITIONS]: 1, [MATCHES]: 1 });
  });

  it("prints counters only, never an uid", async () => {
    client.put(COMPOSITIONS, objectId("coach-a", "deleted-doc"));

    const { lines } = await run(client, { kind: "purge-orphans" });

    expect(lines.join("\n")).not.toContain("coach-a");
  });

  it("refuses to purge when Auth lists no account at all (wrong project ?)", async () => {
    await auth().deleteUser("coach-a");

    await expect(run(client, { kind: "purge-orphans" })).rejects.toThrow(/aucun compte/i);
    expect(client.writes).toEqual([]);
  });

  // Un enregistrement créé après le browse ne doit pas être pris pour un orphelin : le browse passe d'abord.
  it("browses the indices BEFORE listing Auth and reading Firestore", async () => {
    const order: string[] = [];
    client.browseObjectIds = async (indexName) => (order.push(`browse:${indexName}`), []);
    vi.spyOn(auth(), "listUsers").mockImplementationOnce(async () => (order.push("auth"), { users: [{ uid: "coach-a" }], pageToken: undefined } as any));

    await run(client, { kind: "purge-orphans" });

    expect(order.slice(0, 2).sort()).toEqual([`browse:${COMPOSITIONS}`, `browse:${MATCHES}`]);
    expect(order[2]).toBe("auth");
    vi.restoreAllMocks();
  });
});

describe("runReindex — lecture Firestore", () => {
  // Un match peut peser 1 Mio : on ne lit que les champs projetés. Ce test verrouille la liste.
  it("reads only the projected fields of each collection (.select)", async () => {
    await addUser("coach-a");
    await firestore().doc("users/coach-a/matches/m1").set({ ...finished(), lineup: "x".repeat(1000) });
    const db = firestore();
    const original = db.collectionGroup.bind(db);
    const selected: Record<string, string[]> = {};
    vi.spyOn(db, "collectionGroup").mockImplementation((id) => {
      const query = original(id);
      const select = query.select.bind(query);
      vi.spyOn(query, "select").mockImplementation((...fields: string[]) => ((selected[id] = fields), select(...fields)));
      return query;
    });

    await run(client, { kind: "index" });
    vi.restoreAllMocks();

    expect(selected).toEqual({
      compositions: ["name", "formationLabel"],
      matches: ["status", "finishedAt", "opponent.name"],
    });
    // Et ces champs suffisent à construire l'enregistrement complet.
    expect(client.ids(MATCHES)).toEqual([objectId("coach-a", "m1")]);
  });
});

describe("assertNotEmulated", () => {
  it.each([["FIRESTORE_EMULATOR_HOST"], ["FIREBASE_AUTH_EMULATOR_HOST"]])("refuses to start when %s is set", (name) => {
    expect(() => assertNotEmulated({ [name]: "127.0.0.1:8080" })).toThrow(/émulateur/i);
  });

  it("accepts an environment without emulator variables", () => {
    expect(() => assertNotEmulated({ PATH: "/usr/bin" })).not.toThrow();
    expect(() => assertNotEmulated({ FIRESTORE_EMULATOR_HOST: "" })).not.toThrow();
  });
});

describe("runReindex — erreurs", () => {
  it("lets an AlgoliaFailure out untouched", async () => {
    client.setSettings = async () => {
      throw new AlgoliaFailure(403, "Not enough rights");
    };

    await expect(run(client, { kind: "settings-only" })).rejects.toBeInstanceOf(AlgoliaFailure);
  });
});

describe("formatError", () => {
  it("prints the status and message of an AlgoliaFailure, nothing else", () => {
    expect(formatError(new AlgoliaFailure(429, "Too many requests"))).toBe("Algolia 429 : Too many requests");
    expect(formatError(new AlgoliaFailure(undefined, "réseau"))).toBe("Algolia (réseau) : réseau");
  });

  it("prints only the message of another error, never the object", () => {
    const error = Object.assign(new Error("Auth indisponible"), { stackTrace: [{ request: { headers: { key: "fake-secret" } } }] });
    expect(formatError(error)).toBe("Auth indisponible");
    expect(formatError("x")).toBe("erreur inconnue");
  });
});

describe("parseArgs", () => {
  it.each([
    [[], { mode: { kind: "index" }, dryRun: false }],
    [["--dry-run"], { mode: { kind: "index" }, dryRun: true }],
    [["--settings-only"], { mode: { kind: "settings-only" }, dryRun: false }],
    [["--purge-orphans", "--dry-run"], { mode: { kind: "purge-orphans" }, dryRun: true }],
  ])("accepts %j", (argv, expected) => {
    expect(parseArgs(argv)).toEqual(expected);
  });

  it.each([
    [["--purge-user", "u1"]],
    [["--settings-only", "--purge-orphans"]],
    [["--unknown"]],
  ])("rejects %j", (argv) => {
    expect(() => parseArgs(argv)).toThrow(/Usage/);
  });
});
