import { firestore } from "firebase-admin";
import { describe, expect, it } from "vitest";
import { objectId, ownerKey } from "../../src/search/ids";
import { projectComposition, projectMatch, toRecord } from "../../src/search/records";

/** Instantané minimal : `data` absent = document inexistant. */
function snap(data?: unknown): any {
  return { exists: data !== undefined, data: () => data };
}

const FINISHED_AT = firestore.Timestamp.fromDate(new Date("2026-03-05T12:00:00Z"));

describe("projectComposition", () => {
  it("projects name, formationLabel and the digits of the label", () => {
    expect(projectComposition(snap({ name: "Attaque rapide", formationLabel: "4-3-3", slots: [1, 2, 3], isFavorite: true }))).toEqual({
      name: "Attaque rapide",
      formationLabel: "4-3-3",
      formationDigits: "433",
    });
  });

  it("keeps the digits only, zeros included", () => {
    expect(projectComposition(snap({ name: "x", formationLabel: "3-4-0" }))?.formationDigits).toBe("340");
  });

  it.each([
    ["missing name", { formationLabel: "4-3-3" }],
    ["missing label", { name: "x" }],
    ["numeric name", { name: 12, formationLabel: "4-3-3" }],
    ["map label", { name: "x", formationLabel: { a: 1 } }],
    ["null name", { name: null, formationLabel: "4-3-3" }],
    ["empty document", {}],
  ])("returns null for %s", (_label, data) => {
    expect(projectComposition(snap(data))).toBeNull();
  });

  it("returns null for a missing snapshot, a null document or a throwing snapshot", () => {
    expect(projectComposition(snap(undefined))).toBeNull();
    expect(projectComposition(undefined as any)).toBeNull();
    expect(projectComposition({ exists: true, data: () => null } as any)).toBeNull();
    expect(projectComposition({ exists: true, data: () => { throw new Error("boom"); } } as any)).toBeNull();
  });

  it("never exposes anything else than the three fields (no slots, no player)", () => {
    const projected = projectComposition(snap({ name: "x", formationLabel: "4-4-2", slots: [{ role: "GK" }], playerId: "p1" }));
    expect(Object.keys(projected ?? {}).sort()).toEqual(["formationDigits", "formationLabel", "name"]);
  });
});

describe("projectMatch", () => {
  const valid = { status: "finished", finishedAt: FINISHED_AT, opponent: { name: "FC Lyon", category: "u13" }, playerStats: { p1: { goals: 2 } } };

  it("projects the opponent name and the date label of a finished match", () => {
    expect(projectMatch(snap(valid))).toEqual({ opponentName: "FC Lyon", dateLabel: "05 Mars 2026" });
  });

  it("returns null for a match that is not finished", () => {
    expect(projectMatch(snap({ ...valid, status: "abandoned" }))).toBeNull();
    expect(projectMatch(snap({ ...valid, status: "inProgress" }))).toBeNull();
    expect(projectMatch(snap({ ...valid, status: undefined }))).toBeNull();
  });

  it("returns null when finishedAt is absent or not a Timestamp", () => {
    expect(projectMatch(snap({ ...valid, finishedAt: undefined }))).toBeNull();
    expect(projectMatch(snap({ ...valid, finishedAt: null }))).toBeNull();
    expect(projectMatch(snap({ ...valid, finishedAt: "2026-03-05" }))).toBeNull();
    expect(projectMatch(snap({ ...valid, finishedAt: 1772712000000 }))).toBeNull();
  });

  it.each([
    ["missing opponent", undefined],
    ["null opponent", null],
    ["string opponent", "FC Lyon"],
    ["missing name", { category: "u13" }],
    ["numeric name", { name: 7 }],
  ])("returns null for %s", (_label, opponent) => {
    expect(projectMatch(snap({ ...valid, opponent }))).toBeNull();
  });

  it("returns null for a missing snapshot, a null document or a throwing snapshot", () => {
    expect(projectMatch(snap(undefined))).toBeNull();
    expect(projectMatch(undefined as any)).toBeNull();
    expect(projectMatch({ exists: true, data: () => null } as any)).toBeNull();
    expect(projectMatch({ exists: true, data: () => { throw new Error("boom"); } } as any)).toBeNull();
  });

  it("never exposes player data", () => {
    expect(Object.keys(projectMatch(snap(valid)) ?? {}).sort()).toEqual(["dateLabel", "opponentName"]);
  });
});

describe("toRecord", () => {
  it("adds the hashed ids and the docId, never the uid", () => {
    const record = toRecord("uid-A", "doc1", { name: "x", formationLabel: "4-3-3", formationDigits: "433" });

    expect(record).toEqual({
      objectID: objectId("uid-A", "doc1"),
      ownerKey: ownerKey("uid-A"),
      docId: "doc1",
      name: "x",
      formationLabel: "4-3-3",
      formationDigits: "433",
    });
    expect(JSON.stringify(record)).not.toContain("uid-A");
  });
});
