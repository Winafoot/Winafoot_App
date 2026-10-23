import { describe, expect, it } from "vitest";
import { auth, firestore } from "firebase-admin";
import { seedCoach } from "../helpers";
import resetLinkedTeamPassword from "../../src/callables/billing/reset_linked_team_password";

const NEW_PASSWORD = "Nouveau!2345";
const caller = (uid: string) => ({ uid, token: {} as Record<string, unknown> });

async function seedFamily() {
  const owner = await seedCoach("owner@club.test");
  const team = await auth().createUser({ email: "u15-a@equipes.wina.invalid", password: "Ancien!2345" });
  await firestore().doc(`users/${team.uid}`).set({ ownerUid: owner, teamIndex: 2 });
  return { owner, team: team.uid };
}

async function codeOf(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (e: any) {
    return e.code;
  }
  return "no-error";
}

describe("resetLinkedTeamPassword", () => {
  it("changes the password of a team account for its owner", async () => {
    const { owner, team } = await seedFamily();
    const before = (await auth().getUser(team)).passwordHash;

    await expect(resetLinkedTeamPassword({ uid: team, password: NEW_PASSWORD }, caller(owner))).resolves.toBe(true);

    expect((await auth().getUser(team)).passwordHash).not.toBe(before);
  });

  it("refuses another owner", async () => {
    const { team } = await seedFamily();
    const stranger = await auth().createUser({ email: "stranger@club.test" });
    await firestore().doc(`users/${stranger.uid}`).set({ firstname: "X" });

    expect(await codeOf(resetLinkedTeamPassword({ uid: team, password: NEW_PASSWORD }, caller(stranger.uid)))).toBe("permission-denied");
  });

  it("refuses an account that is not a team account", async () => {
    const { owner } = await seedFamily();
    expect(await codeOf(resetLinkedTeamPassword({ uid: owner, password: NEW_PASSWORD }, caller(owner)))).toBe("permission-denied");
  });

  it("refuses a weak password", async () => {
    const { owner, team } = await seedFamily();
    expect(await codeOf(resetLinkedTeamPassword({ uid: team, password: "faible" }, caller(owner)))).toBe("invalid-argument");
  });

  it("refuses a malformed request", async () => {
    const { owner } = await seedFamily();
    expect(await codeOf(resetLinkedTeamPassword({ uid: 12, password: NEW_PASSWORD } as any, caller(owner)))).toBe("invalid-argument");
  });
});
