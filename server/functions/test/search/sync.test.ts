import { beforeEach, describe, expect, it, vi } from "vitest";
import { firestore } from "firebase-admin";

vi.mock("firebase-functions/logger", () => ({
  debug: vi.fn(),
  error: vi.fn(),
  info: vi.fn(),
  log: vi.fn(),
  warn: vi.fn(),
}));

import * as logger from "firebase-functions/logger";
import { AlgoliaFailure } from "../../src/search/algolia_client";
import { objectId, ownerKey } from "../../src/search/ids";
import { SYNC_TARGETS, syncDocument } from "../../src/search/sync";

const UID = "uid-coach-1";
const DOC = "doc-1";
const HOUR = 3_600_000;

const comp = (name: string, label = "4-3-3") => ({ name, formationLabel: label, slots: [] });
const NEW = { name: "Attaque", formationLabel: "4-3-3", formationDigits: "433" };

function fakeWriter() {
  return {
    saveObject: vi.fn().mockResolvedValue(undefined),
    deleteObject: vi.fn().mockResolvedValue(undefined),
  };
}

function run(change: { before: any; after: any }, writer = fakeWriter(), eventTime = new Date().toISOString(), target = SYNC_TARGETS.compositions) {
  const createWriter = vi.fn(() => writer);
  const result = syncDocument(target, change, { params: { userId: UID, docId: DOC }, eventTime, eventId: "evt-1" }, createWriter);
  return { result, writer, createWriter };
}

/** `current` = ce que renvoie la relecture du document (après chaque relecture, le dernier état persiste). */
function change(before: Record<string, unknown> | undefined, after: Record<string, unknown> | undefined, ...rereads: Array<Record<string, unknown> | undefined>) {
  const ref = { get: vi.fn() };
  const reads = rereads.length > 0 ? rereads : [after];
  reads.forEach((data) => ref.get.mockResolvedValueOnce({ exists: data !== undefined, data: () => data }));
  const last = reads[reads.length - 1];
  ref.get.mockResolvedValue({ exists: last !== undefined, data: () => last });
  return {
    before: { exists: before !== undefined, data: () => before, ref },
    after: { exists: after !== undefined, data: () => after, ref },
    ref,
  };
}

beforeEach(() => {
  vi.mocked(logger.warn).mockClear();
  vi.mocked(logger.error).mockClear();
  vi.mocked(logger.info).mockClear();
});

describe("syncDocument — projections and writes", () => {
  it("indexes a created document", async () => {
    const { before, after } = change(undefined, comp("Attaque"));
    const { result, writer } = run({ before, after });
    await result;

    expect(writer.saveObject).toHaveBeenCalledWith("wina_compositions", {
      objectID: objectId(UID, DOC),
      ownerKey: ownerKey(UID),
      docId: DOC,
      ...NEW,
    });
    expect(writer.deleteObject).not.toHaveBeenCalled();
  });

  it("re-indexes a modified document from the CURRENT state, not from the event", async () => {
    const c = change(comp("Attaque"), comp("Attaque 2"), comp("Attaque 3"));
    const { result, writer } = run({ before: c.before, after: c.after });
    await result;

    expect(writer.saveObject).toHaveBeenCalledWith("wina_compositions", expect.objectContaining({ name: "Attaque 3" }));
  });

  it("removes the record of a deleted document", async () => {
    const c = change(comp("Attaque"), undefined);
    const { result, writer } = run({ before: c.before, after: c.after });
    await result;

    expect(writer.deleteObject).toHaveBeenCalledWith("wina_compositions", objectId(UID, DOC));
    expect(writer.saveObject).not.toHaveBeenCalled();
  });

  it("removes the record when the document stops being indexable (match no longer finished)", async () => {
    const finishedAt = firestore.Timestamp.fromDate(new Date("2026-03-05T12:00:00Z"));
    const finished = { status: "finished", finishedAt, opponent: { name: "FC Lyon" } };
    const c = change(finished, { ...finished, status: "abandoned" });
    const { result, writer } = run({ before: c.before, after: c.after }, fakeWriter(), undefined, SYNC_TARGETS.matches);
    await result;

    expect(writer.deleteObject).toHaveBeenCalledWith("wina_matches", objectId(UID, DOC));
    expect(writer.saveObject).not.toHaveBeenCalled();
  });

  it("indexes a match that becomes finished, in wina_matches", async () => {
    const finishedAt = firestore.Timestamp.fromDate(new Date("2026-03-05T12:00:00Z"));
    const draft = { status: "inProgress", opponent: { name: "FC Lyon" } };
    const done = { status: "finished", finishedAt, opponent: { name: "FC Lyon" } };
    const c = change(draft, done);
    const { result, writer } = run({ before: c.before, after: c.after }, fakeWriter(), undefined, SYNC_TARGETS.matches);
    await result;

    expect(writer.saveObject).toHaveBeenCalledWith(
      "wina_matches",
      expect.objectContaining({ objectID: objectId(UID, DOC), opponentName: "FC Lyon", dateLabel: "05 Mars 2026" }),
    );
  });

  it("does nothing, no read and no client, when projection(before) == projection(after)", async () => {
    // Seuls des champs non projetés changent (favori, emplacements).
    const c = change({ ...comp("Attaque"), isFavorite: false }, { ...comp("Attaque"), isFavorite: true, slots: [1] });
    const { result, writer, createWriter } = run({ before: c.before, after: c.after });
    await result;

    expect(c.ref.get).not.toHaveBeenCalled();
    expect(createWriter).not.toHaveBeenCalled();
    expect(writer.saveObject).not.toHaveBeenCalled();
    expect(writer.deleteObject).not.toHaveBeenCalled();
  });

  it("does nothing for a document that was never indexable (null before, null after)", async () => {
    const c = change({ name: 3 }, { name: 4 });
    const { result, createWriter } = run({ before: c.before, after: c.after });
    await result;

    expect(c.ref.get).not.toHaveBeenCalled();
    expect(createWriter).not.toHaveBeenCalled();
  });

  it("ignores an event older than 24 h, with a warning that carries the hashed uid only", async () => {
    const c = change(undefined, comp("Attaque"));
    const { result, writer, createWriter } = run({ before: c.before, after: c.after }, fakeWriter(), new Date(Date.now() - 25 * HOUR).toISOString());
    await result;

    expect(writer.saveObject).not.toHaveBeenCalled();
    expect(createWriter).not.toHaveBeenCalled();
    const logged = JSON.stringify(vi.mocked(logger.warn).mock.calls);
    expect(logged).toContain(ownerKey(UID));
    expect(logged).toContain(DOC);
    expect(logged).not.toContain(UID);
  });

  it("still handles an event younger than 24 h", async () => {
    const c = change(undefined, comp("Attaque"));
    const { result, writer } = run({ before: c.before, after: c.after }, fakeWriter(), new Date(Date.now() - 23 * HOUR).toISOString());
    await result;

    expect(writer.saveObject).toHaveBeenCalledTimes(1);
  });
});

describe("syncDocument — concurrent deletion", () => {
  it("deletes instead of saving when the document vanished between the event and the re-read", async () => {
    const c = change(undefined, comp("Attaque"), undefined);
    const { result, writer } = run({ before: c.before, after: c.after });
    await result;

    expect(writer.saveObject).not.toHaveBeenCalled();
    expect(writer.deleteObject).toHaveBeenCalledWith("wina_compositions", objectId(UID, DOC));
  });

  it("re-reads AFTER saveObject and deletes a document that disappeared in the meantime", async () => {
    const c = change(undefined, comp("Attaque"), comp("Attaque"), undefined);
    const writer = fakeWriter();
    const { result } = run({ before: c.before, after: c.after }, writer);
    await result;

    expect(c.ref.get).toHaveBeenCalledTimes(2);
    expect(writer.saveObject).toHaveBeenCalledTimes(1);
    expect(writer.deleteObject).toHaveBeenCalledWith("wina_compositions", objectId(UID, DOC));
    expect(writer.saveObject.mock.invocationCallOrder[0]).toBeLessThan(writer.deleteObject.mock.invocationCallOrder[0]);
  });

  it("deletes when the document is still there after the save but no longer indexable", async () => {
    const c = change(undefined, comp("Attaque"), comp("Attaque"), { name: 5, formationLabel: "4-3-3" });
    const { result, writer } = run({ before: c.before, after: c.after });
    await result;

    expect(writer.deleteObject).toHaveBeenCalledTimes(1);
  });

  it("does not delete when the document is unchanged after the save", async () => {
    const c = change(undefined, comp("Attaque"), comp("Attaque"), comp("Attaque"));
    const { result, writer } = run({ before: c.before, after: c.after });
    await result;

    expect(writer.deleteObject).not.toHaveBeenCalled();
  });
});

describe("syncDocument — error classification", () => {
  const upsert = () => change(undefined, comp("Attaque"));
  const removal = () => change(comp("Attaque"), undefined);

  it.each([400, 413])("upsert: a %i is logged (hashed uid + docId) and NOT retried", async (status) => {
    const c = upsert();
    const writer = fakeWriter();
    writer.saveObject.mockRejectedValue(new AlgoliaFailure(status, "Record too big"));

    await expect(run({ before: c.before, after: c.after }, writer).result).resolves.toBeUndefined();

    const logged = JSON.stringify([...vi.mocked(logger.error).mock.calls, ...vi.mocked(logger.warn).mock.calls]);
    expect(logged).toContain(ownerKey(UID));
    expect(logged).toContain(DOC);
    expect(logged).not.toContain(UID);
  });

  it.each([401, 403, 429, 500, 502, 503, undefined])("upsert: a %s is retried (rethrown)", async (status) => {
    const c = upsert();
    const writer = fakeWriter();
    const failure = new AlgoliaFailure(status, "boom");
    writer.saveObject.mockRejectedValue(failure);

    await expect(run({ before: c.before, after: c.after }, writer).result).rejects.toBe(failure);
  });

  it("upsert: a missing secret (unavailable client) is retried", async () => {
    const c = upsert();
    const writer = fakeWriter();
    writer.saveObject.mockRejectedValue(new AlgoliaFailure(undefined, "clé d'écriture Algolia indisponible"));

    await expect(run({ before: c.before, after: c.after }, writer).result).rejects.toBeInstanceOf(AlgoliaFailure);
  });

  it("delete: a 404 (nothing to delete) is not retried", async () => {
    const c = removal();
    const writer = fakeWriter();
    writer.deleteObject.mockRejectedValue(new AlgoliaFailure(404, "Index not found"));

    await expect(run({ before: c.before, after: c.after }, writer).result).resolves.toBeUndefined();
  });

  it.each([400, 401, 403, 413, 429, 500, undefined])("delete: a %s is retried (rethrown)", async (status) => {
    const c = removal();
    const writer = fakeWriter();
    const failure = new AlgoliaFailure(status, "boom");
    writer.deleteObject.mockRejectedValue(failure);

    await expect(run({ before: c.before, after: c.after }, writer).result).rejects.toBe(failure);
  });

  it("delete after a save (concurrent deletion) follows the DELETE rules", async () => {
    const c = change(undefined, comp("Attaque"), comp("Attaque"), undefined);
    const writer = fakeWriter();
    const failure = new AlgoliaFailure(400, "boom");
    writer.deleteObject.mockRejectedValue(failure);

    await expect(run({ before: c.before, after: c.after }, writer).result).rejects.toBe(failure);
  });

  it("an exception that is not an AlgoliaFailure is logged and not retried", async () => {
    const c = upsert();
    const writer = fakeWriter();
    writer.saveObject.mockRejectedValue(new TypeError("bug"));

    await expect(run({ before: c.before, after: c.after }, writer).result).resolves.toBeUndefined();
    expect(logger.error).toHaveBeenCalled();
  });

  // Une panne Firestore est une panne d'infrastructure, pas un bug : on relance (AlgoliaFailure), sans citer l'erreur d'origine.
  it("a Firestore read error on an upsert is retried as an AlgoliaFailure, logging only the code", async () => {
    const c = upsert();
    c.ref.get.mockReset();
    c.ref.get.mockRejectedValue(Object.assign(new Error("firestore down secret-detail"), { code: 14 }));

    const error = await run({ before: c.before, after: c.after }).result.catch((e) => e);

    expect(error).toBeInstanceOf(AlgoliaFailure);
    expect(error.status).toBeUndefined();
    expect(error.message).toBe("lecture Firestore impossible");
    const logged = JSON.stringify([...vi.mocked(logger.warn).mock.calls, ...vi.mocked(logger.error).mock.calls]);
    expect(logged).toContain("14");
    expect(logged).not.toContain("secret-detail");
  });

  it("a Firestore read error on a deletion event is retried too", async () => {
    const c = removal();
    c.ref.get.mockReset();
    c.ref.get.mockRejectedValue(new Error("firestore down"));
    const { result, writer } = run({ before: c.before, after: c.after });

    await expect(result).rejects.toMatchObject({ name: "AlgoliaFailure", message: "lecture Firestore impossible" });
    expect(writer.deleteObject).not.toHaveBeenCalled();
  });

  it("a Firestore read error on the second read (after the save) is retried too", async () => {
    const c = upsert();
    c.ref.get.mockReset();
    c.ref.get.mockResolvedValueOnce({ exists: true, data: () => comp("Attaque") }).mockRejectedValue(new Error("firestore down"));

    await expect(run({ before: c.before, after: c.after }).result).rejects.toBeInstanceOf(AlgoliaFailure);
  });
});
