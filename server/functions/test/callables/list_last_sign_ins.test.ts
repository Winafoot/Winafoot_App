import { describe, expect, it } from "vitest";
import { seedCoach } from "../helpers";
import listLastSignIns from "../../src/callables/admin/list_last_sign_ins";

describe("listLastSignIns", () => {
  it("returns an entry per account, null or an ISO date", async () => {
    const uid = await seedCoach("coach@club.test");

    const { lastSignIns } = await listLastSignIns({}, { uid: "admin" });

    expect(lastSignIns).toHaveProperty(uid);
    const value = lastSignIns[uid];
    expect(value === null || /^\d{4}-\d{2}-\d{2}T/.test(value)).toBe(true);
  });

  it("returns nothing but uids and dates", async () => {
    await seedCoach("coach@club.test");

    const { lastSignIns } = await listLastSignIns({}, { uid: "admin" });

    expect(Object.keys(lastSignIns).length).toBeGreaterThan(0);
    for (const value of Object.values(lastSignIns)) {
      expect(value === null || typeof value === "string").toBe(true);
    }
  });
});
