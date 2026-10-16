import { describe, expect, it } from "vitest";
import { firestore } from "firebase-admin";
import deletePlayer from "../../src/callables/players/delete_player";

const CALLER = { uid: "coach1", token: {} };

const players = (uid = CALLER.uid) => firestore().collection("users").doc(uid).collection("players");
const counter = async (uid = CALLER.uid) => (await firestore().collection("users").doc(uid).get()).get("playerCount");

async function seed(count: number, playerCount = count): Promise<void> {
  await firestore().collection("users").doc(CALLER.uid).set({ teamFormat: 11, playerCount });
  for (let i = 0; i < count; i++) await players().doc(`p${i}`).set({ lastName: `J${i}` });
}

describe("deletePlayer", () => {
  it("deletes the player and lowers the counter", async () => {
    await seed(3);

    await expect(deletePlayer({ id: "p1" }, CALLER)).resolves.toEqual({ deleted: true });

    expect((await players().doc("p1").get()).exists).toBe(false);
    expect((await players().get()).size).toBe(2);
    expect(await counter()).toBe(2);
  });

  it("is idempotent: an already deleted player is not an error and leaves the counter alone", async () => {
    await seed(2);

    await expect(deletePlayer({ id: "ghost" }, CALLER)).resolves.toEqual({ deleted: false });

    expect(await counter()).toBe(2);
  });

  it("re-synchronises a drifted counter on the real number of players", async () => {
    await seed(3, 9);

    await deletePlayer({ id: "p0" }, CALLER);

    expect(await counter()).toBe(2);
  });

  it("never lets the counter go below zero", async () => {
    await seed(1, 0);

    await deletePlayer({ id: "p0" }, CALLER);

    expect(await counter()).toBe(0);
  });

  it("cannot reach another coach's players", async () => {
    await seed(1);
    await firestore().collection("users").doc("other").set({ playerCount: 1 });
    await players("other").doc("p0").set({ lastName: "Autre" });

    await deletePlayer({ id: "p0" }, CALLER);

    expect((await players("other").doc("p0").get()).exists).toBe(true);
    expect(await counter("other")).toBe(1);
  });

  it.each([
    ["no payload", undefined],
    ["a missing id", {}],
    ["a numeric id", { id: 12 }],
    ["an empty id", { id: "" }],
    ["an id that climbs the path", { id: "../other/players/p0" }],
    ["an id with a slash", { id: "a/b" }],
    ["an id that is too long", { id: "x".repeat(129) }],
  ])("rejects %s", async (_label, data) => {
    await seed(1);

    await expect(deletePlayer(data as any, CALLER)).rejects.toMatchObject({ code: "invalid-argument" });
    expect((await players().get()).size).toBe(1);
  });
});
