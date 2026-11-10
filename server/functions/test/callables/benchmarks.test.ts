import { describe, expect, it } from "vitest";
import { computeBenchmarks } from "../../src/callables/admin/_benchmarks";

const categories = new Map([
  ["t1", "U13"],
  ["t2", "U13"],
  ["t3", "Seniors"],
]);

const m = (uid: string, scoreUs: number, scoreThem: number, playerStats: Record<string, Record<string, number>>, status = "finished") => ({
  uid,
  data: { status, scoreUs, scoreThem, playerStats },
});

describe("computeBenchmarks", () => {
  const matches = [
    m("t1", 3, 1, { a: { butsMarques: 2, passesReussies: 8, passesManquees: 2 }, b: { passesDecisives: 1, cartonsJaunes: 1 } }),
    m("t1", 1, 1, { a: { butsMarques: 1 }, b: {} }),
    m("t1", 2, 0, { a: { butsMarques: 1, passesDecisives: 2 }, b: { passesDecisives: 1 } }),
    m("t2", 0, 2, { c: { butsMarques: 0 } }),
    m("t3", 5, 0, { d: { butsMarques: 5 } }),
    m("t3", 9, 9, { d: { butsMarques: 9 } }, "draft"),
  ];

  it("averages results per category and ignores unfinished matches", () => {
    const { categories: rows } = computeBenchmarks(categories, matches);
    const u13 = rows.find((r) => r.category === "U13")!;
    expect(u13).toMatchObject({ teams: 2, matches: 4, goalsForPerMatch: 1.5, goalsAgainstPerMatch: 1, winRate: 50, passAccuracy: 80, yellowCardsPerMatch: 0.25 });
    expect(rows.find((r) => r.category === "Seniors")).toMatchObject({ matches: 1, goalsForPerMatch: 5 });
  });

  it("ranks players from three matches only", () => {
    const { topScorers, topAssisters } = computeBenchmarks(categories, matches);
    expect(topScorers).toEqual([
      { rank: 1, name: "Joueur supprimé", teamName: "—", teamUid: "t1", playerId: "a", category: "U13", matches: 3, goals: 4, assists: 2, goalsPerMatch: 1.3 },
    ]);
    expect(topAssisters.map((p) => p.assists)).toEqual([2, 2]);
  });

  it("names the players and their team when identities are known", () => {
    const identity = { players: new Map([["t1/a", "Lucas Martin"]]), teams: new Map([["t1", "FC Test"]]) };
    const { topScorers } = computeBenchmarks(categories, matches, identity);
    expect(topScorers[0]).toMatchObject({ name: "Lucas Martin", teamName: "FC Test", teamUid: "t1", playerId: "a" });
  });

  it("files accounts without a known category apart", () => {
    const { categories: rows } = computeBenchmarks(new Map(), [m("x", 1, 0, {})]);
    expect(rows[0].category).toBe("Sans catégorie");
  });
});
