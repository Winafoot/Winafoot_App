import { describe, expect, it } from "vitest";
import { seedAdmin, seedCoach } from "../helpers";
import listAdmins from "../../src/callables/admin/list_admins";

describe("listAdmins", () => {
  it("lists only the administrators, sorted by address, and names the caller", async () => {
    const zed = await seedAdmin("zed@wina.test", { displayName: "Zed" });
    const amy = await seedAdmin("amy@wina.test");
    await seedCoach("coach@club.test");

    const result = await listAdmins({}, { uid: amy, email: "amy@wina.test" });

    expect(result.admins.map((a) => a.email)).toEqual(["amy@wina.test", "zed@wina.test"]);
    expect(result.admins.map((a) => a.uid)).toEqual([amy, zed]);
    expect(result.self).toBe(amy);
  });

  it("reports the state of each account", async () => {
    const uid = await seedAdmin("state@wina.test", { disabled: true, displayName: "Sam", secondFactor: true });

    const { admins } = await listAdmins({}, { uid: "other" });

    const account = admins.find((a) => a.uid === uid)!;
    expect(account).toMatchObject({ email: "state@wina.test", displayName: "Sam", disabled: true, emailVerified: true, secondFactors: 1 });
    expect(account.createdAt).toMatch(/^\d{4}-\d{2}-\d{2}T/);
  });

  it("returns an empty list when nobody is an administrator", async () => {
    await seedCoach("coach@club.test");

    expect((await listAdmins({}, { uid: "other" })).admins).toEqual([]);
  });

  it("does not leak anything beyond the account fields", async () => {
    await seedAdmin("fields@wina.test");

    const { admins } = await listAdmins({}, { uid: "other" });

    expect(Object.keys(admins[0]).sort()).toEqual(
      ["createdAt", "disabled", "displayName", "email", "emailVerified", "lastSignInAt", "secondFactors", "uid"].sort(),
    );
  });
});
