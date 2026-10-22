import { describe, expect, it } from "vitest";
import { auth, firestore } from "firebase-admin";
import { IDENTIFIER_PATTERN, detachFromTeams, isLinkedEmail, linkedEmail, slotRef } from "../../src/billing/linked_teams";

describe("linkedEmail", () => {
  it("derives the technical address from the identifier", () => {
    expect(linkedEmail("u15-lyon")).toBe("u15-lyon@equipes.wina.invalid");
    expect(isLinkedEmail("U15-Lyon@Equipes.Wina.Invalid")).toBe(true);
    expect(isLinkedEmail("coach@club.fr")).toBe(false);
  });
});

describe("IDENTIFIER_PATTERN", () => {
  it.each(["u15", "u15-lyon", "equipe-a-2", "abc"])("accepts %s", (id) => {
    expect(IDENTIFIER_PATTERN.test(id)).toBe(true);
  });
  it.each(["ab", "-abc", "abc-", "ABC", "a b c", "a_b_c", "a".repeat(31), "é-équipe", "a@b"])("rejects %s", (id) => {
    expect(IDENTIFIER_PATTERN.test(id)).toBe(false);
  });
});

describe("detachFromTeams", () => {
  async function seedFamily() {
    const owner = await auth().createUser({ email: "owner@club.test" });
    const team2 = await auth().createUser({ email: linkedEmail("u15-a") });
    await firestore().doc(`users/${owner.uid}`).set({ firstname: "Ibrahim" });
    await firestore().doc(`users/${team2.uid}`).set({ ownerUid: owner.uid, teamIndex: 2 });
    await firestore().doc(`users/${team2.uid}/players/p1`).set({ firstName: "A" });
    await slotRef(owner.uid, 2).set({ ownerUid: owner.uid, teamIndex: 2 });
    return { owner: owner.uid, team2: team2.uid };
  }

  it("deletes the linked accounts, their data and their slots when the owner goes", async () => {
    const { owner, team2 } = await seedFamily();

    await detachFromTeams(owner);

    await expect(auth().getUser(team2)).rejects.toMatchObject({ code: "auth/user-not-found" });
    expect((await firestore().doc(`users/${team2}`).get()).exists).toBe(false);
    expect((await firestore().collection(`users/${team2}/players`).get()).size).toBe(0);
    expect((await slotRef(owner, 2).get()).exists).toBe(false);
    // Le propriétaire lui-même est supprimé par l'appelant, pas ici.
    expect((await firestore().doc(`users/${owner}`).get()).exists).toBe(true);
  });

  it("frees the slot when a linked account goes", async () => {
    const { owner, team2 } = await seedFamily();

    await detachFromTeams(team2);

    expect((await slotRef(owner, 2).get()).exists).toBe(false);
    expect((await firestore().doc(`users/${owner}`).get()).exists).toBe(true);
  });

  it("does nothing for an account without teams", async () => {
    await firestore().doc("users/solo").set({ firstname: "Solo" });
    await expect(detachFromTeams("solo")).resolves.toBeUndefined();
  });
});
