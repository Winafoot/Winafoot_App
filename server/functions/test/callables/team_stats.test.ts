import { describe, expect, it } from "vitest";
import { computeTeamStats } from "../../src/callables/admin/_team_stats";
import { bucketWeeks, mondayOf } from "../../src/callables/admin/get_usage_stats";

const players = [
  { id: "p1", firstName: "Lucas", lastName: "Martin", position: "attaquant" },
  { id: "p2", firstName: "Yanis", lastName: "Bel", position: "milieu" },
];

describe("computeTeamStats", () => {
  const matches = [
    { id: "m1", status: "finished", opponent: { name: "FC Nord" }, scoreUs: 3, scoreThem: 1, finishedAt: "2026-05-02T10:00:00.000Z", playerStats: { p1: { butsMarques: 2, cartonsJaunes: 1 }, p2: { butsMarques: 1, passesDecisives: 2 } } },
    { id: "m2", status: "finished", opponent: { name: "AS Sud" }, scoreUs: 0, scoreThem: 0, playerStats: { p1: {} } },
    { id: "m3", status: "finished", opponent: { name: "US Est" }, scoreUs: 1, scoreThem: 2, playerStats: { p1: { butsMarques: 1 }, gone: { butsMarques: 0 } } },
    { id: "m4", status: "draft", opponent: { name: "Brouillon" } },
  ];

  it("counts only finished matches in the record", () => {
    expect(computeTeamStats(players, matches).record).toEqual({ played: 3, wins: 1, draws: 1, losses: 1, goalsFor: 4, goalsAgainst: 3 });
  });

  it("derives scorers and cards per match", () => {
    const [first] = computeTeamStats(players, matches).matches;
    expect(first).toMatchObject({ opponent: "FC Nord", result: "win", yellowCards: 1, redCards: 0 });
    expect(first.scorers).toEqual([
      { name: "Lucas Martin", goals: 2 },
      { name: "Yanis Bel", goals: 1 },
    ]);
  });

  it("ranks players and keeps those who left the squad", () => {
    const ranking = computeTeamStats(players, matches).players;
    expect(ranking[0]).toMatchObject({ name: "Lucas Martin", matches: 3, goals: 3, yellowCards: 1 });
    expect(ranking.find((p) => p.id === "p2")).toMatchObject({ matches: 1, assists: 2 });
    expect(ranking.find((p) => p.id === "gone")?.name).toBe("Ancien joueur");
  });

  it("totals every stat per player and keeps the match-by-match history", () => {
    const lucas = computeTeamStats(players, matches).players.find((p) => p.id === "p1")!;
    expect(lucas.stats).toEqual({ butsMarques: 3, cartonsJaunes: 1 });
    expect(lucas.history.map((h) => [h.opponent, h.stats])).toEqual([
      ["FC Nord", { butsMarques: 2, cartonsJaunes: 1 }],
      ["AS Sud", {}],
      ["US Est", { butsMarques: 1 }],
    ]);
  });
});

describe("bucketWeeks", () => {
  const now = Date.UTC(2026, 5, 10, 12); // mercredi 10 juin 2026

  it("starts weeks on Monday", () => {
    expect(new Date(mondayOf(now)).toISOString().slice(0, 10)).toBe("2026-06-08");
  });

  it("counts matches and distinct teams per week over twelve weeks", () => {
    const weeks = bucketWeeks(
      [
        { uid: "a", atMs: Date.UTC(2026, 5, 9) },
        { uid: "a", atMs: Date.UTC(2026, 5, 10) },
        { uid: "b", atMs: Date.UTC(2026, 5, 9) },
        { uid: "a", atMs: Date.UTC(2026, 4, 30) },
        { uid: "z", atMs: Date.UTC(2025, 0, 1) },
      ],
      now,
    );
    expect(weeks).toHaveLength(12);
    expect(weeks[11]).toEqual({ weekStart: "2026-06-08", matches: 3, activeTeams: 2 });
    expect(weeks[10]).toEqual({ weekStart: "2026-06-01", matches: 0, activeTeams: 0 });
    expect(weeks[9]).toEqual({ weekStart: "2026-05-25", matches: 1, activeTeams: 1 });
  });
});
