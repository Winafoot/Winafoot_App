import { describe, expect, it } from "vitest";
import { firestore } from "firebase-admin";
import createPlayer from "../../src/callables/players/create_player";

const CALLER = { uid: "coach1", token: {} };
const VALID = { firstName: "Zinedine", lastName: "Zidane", strongFoot: "droit", position: "milieu" };

const players = (uid = CALLER.uid) => firestore().collection("users").doc(uid).collection("players");

/** Compte avec `count` joueurs déjà créés et le compteur tenu à jour. */
async function seed(user: Record<string, unknown>, count = 0, config?: Record<string, unknown>): Promise<void> {
  await firestore().collection("users").doc(CALLER.uid).set({ ...user, playerCount: count });
  for (let i = 0; i < count; i++) await players().doc(`p${i}`).set({ lastName: `J${i}` });
  if (config) await firestore().collection("app_config").doc("config").set(config);
}

describe("createPlayer", () => {
  it("creates the player, stamps order and createdAt, and bumps the counter", async () => {
    await seed({ teamFormat: 11 }, 2);

    const { id } = await createPlayer(VALID, CALLER);

    const saved = (await players().doc(id).get()).data()!;
    expect(saved).toMatchObject({ ...VALID, order: 2 });
    expect(saved.createdAt).toBeDefined();
    expect((await firestore().collection("users").doc(CALLER.uid).get()).get("playerCount")).toBe(3);
  });

  it("honours an explicit order", async () => {
    await seed({ teamFormat: 11 }, 2);

    const { id } = await createPlayer({ ...VALID, order: 7 }, CALLER);

    expect((await players().doc(id).get()).get("order")).toBe(7);
  });

  it.each([
    [5, 9],
    [8, 14],
    [11, 20],
  ])("caps a %i-a-side club at %i players", async (format, cap) => {
    await seed({ teamFormat: format }, cap);

    await expect(createPlayer(VALID, CALLER)).rejects.toMatchObject({ code: "failed-precondition", message: "squad-full" });
    expect((await players().get()).size).toBe(cap);
  });

  it("allows one more player right under the cap", async () => {
    await seed({ teamFormat: 5 }, 8);

    await expect(createPlayer(VALID, CALLER)).resolves.toHaveProperty("id");
  });

  it("never exceeds the cap when several creations race for the last place", async () => {
    await seed({ teamFormat: 5 }, 8);

    const results = await Promise.allSettled(Array.from({ length: 5 }, () => createPlayer(VALID, CALLER)));

    expect(results.filter((r) => r.status === "fulfilled")).toHaveLength(1);
    expect((await players().get()).size).toBe(9);
  });

  it("falls back to app_config/config.max_players for an account without a club format", async () => {
    await seed({}, 3, { max_players: 3 });

    await expect(createPlayer(VALID, CALLER)).rejects.toMatchObject({ code: "failed-precondition" });
  });

  it("falls back to 20 when neither the format nor the configuration says anything", async () => {
    await seed({}, 20);

    await expect(createPlayer(VALID, CALLER)).rejects.toMatchObject({ code: "failed-precondition" });
  });

  it("trusts the real number of players, not a lowered counter", async () => {
    // Un compteur remis à 0 (ou en retard sur des joueurs créés avant lui) ne doit pas rouvrir le plafond.
    await seed({ teamFormat: 5 }, 9);
    await firestore().collection("users").doc(CALLER.uid).update({ playerCount: 0 });

    await expect(createPlayer(VALID, CALLER)).rejects.toMatchObject({ code: "failed-precondition" });
  });

  it("creates the user document when the account has none yet", async () => {
    const { id } = await createPlayer(VALID, CALLER);

    expect((await players().doc(id).get()).exists).toBe(true);
    expect((await firestore().collection("users").doc(CALLER.uid).get()).get("playerCount")).toBe(1);
  });

  it("only ever writes under the caller's own tree", async () => {
    await seed({ teamFormat: 11 }, 0);
    await firestore().collection("users").doc("other").set({ teamFormat: 11 });

    await createPlayer(VALID, CALLER);

    expect((await players("other").get()).empty).toBe(true);
  });

  it.each([
    ["no payload", undefined],
    ["a non-object payload", "Zidane"],
    ["a missing first name", { ...VALID, firstName: undefined }],
    ["a numeric last name", { ...VALID, lastName: 12 }],
    ["a name that is too long", { ...VALID, lastName: "x".repeat(61) }],
    ["a strong foot with a slash", { ...VALID, strongFoot: "a/b" }],
    ["an empty position", { ...VALID, position: "" }],
    ["a fractional order", { ...VALID, order: 1.5 }],
    ["a negative order", { ...VALID, order: -1 }],
    ["an absurd order", { ...VALID, order: 100000 }],
  ])("rejects %s", async (_label, data) => {
    await seed({ teamFormat: 11 }, 0);

    await expect(createPlayer(data as any, CALLER)).rejects.toMatchObject({ code: "invalid-argument" });
    expect((await players().get()).empty).toBe(true);
  });

  it("ignores any extra field sent by the client", async () => {
    await seed({ teamFormat: 11 }, 0);

    const { id } = await createPlayer({ ...VALID, isAdmin: true, playerCount: 0 } as any, CALLER);

    const saved = (await players().doc(id).get()).data()!;
    expect(Object.keys(saved).sort()).toEqual(["createdAt", "firstName", "lastName", "order", "position", "strongFoot"]);
  });
});
