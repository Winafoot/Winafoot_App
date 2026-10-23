import { beforeEach, describe, expect, it, vi } from "vitest";
import { auth, firestore } from "firebase-admin";

vi.mock("firebase-functions/logger", () => ({
  debug: vi.fn(),
  error: vi.fn(),
  info: vi.fn(),
  log: vi.fn(),
  warn: vi.fn(),
}));

import * as logger from "firebase-functions/logger";
import { seedAdmin, seedCoach, signedInCaller } from "../helpers";
import deleteAccount from "../../src/callables/auth/delete_account_secured";

const asUser = (uid: string) => ({ uid, token: {} as Record<string, unknown> });

const auditEntries = async () => (await firestore().collection("admin_audit").get()).docs.map((d) => d.data());

beforeEach(() => {
  vi.mocked(logger.warn).mockClear();
});

describe("deleteAccount (secured): own account", () => {
  it("deletes the Auth account, the profile with its sub-collections, and archives the address", async () => {
    const uid = await seedCoach("me@club.test");
    await firestore().doc(`users/${uid}/players/p1`).set({ firstName: "A" });
    await firestore().doc(`users/${uid}/metadata/security`).set({ profilCompleted: true });

    await expect(deleteAccount({ uid }, asUser(uid))).resolves.toBe(true);

    await expect(auth().getUser(uid)).rejects.toMatchObject({ code: "auth/user-not-found" });
    // recursiveDelete est attendu : rien ne reste quand la callable répond.
    expect((await firestore().doc(`users/${uid}`).get()).exists).toBe(false);
    expect((await firestore().collection(`users/${uid}/players`).get()).size).toBe(0);
    expect((await firestore().collection(`users/${uid}/metadata`).get()).size).toBe(0);
    const archived = await firestore().collection("deleted_users").where("email", "==", "me@club.test").get();
    expect(archived.size).toBe(1);
  });

  it("deletes the linked team accounts with their owner", async () => {
    const owner = await seedCoach("boss@club.test");
    const team = await auth().createUser({ email: "u15-a@equipes.wina.invalid" });
    await firestore().doc(`users/${team.uid}`).set({ ownerUid: owner, teamIndex: 2 });

    await deleteAccount({ uid: owner }, asUser(owner));

    await expect(auth().getUser(team.uid)).rejects.toMatchObject({ code: "auth/user-not-found" });
    expect((await firestore().doc(`users/${team.uid}`).get()).exists).toBe(false);
  });

  it("reports an unknown account as an HttpsError, never as a resolved error object", async () => {
    await expect(deleteAccount({ uid: "ghost" }, asUser("ghost"))).rejects.toMatchObject({ code: "not-found" });
  });

  it("does not audit a user deleting their own account", async () => {
    const uid = await seedCoach("self@club.test");

    await deleteAccount({ uid }, asUser(uid));

    expect(await auditEntries()).toEqual([]);
  });
});

describe("deleteAccount (secured): someone else's account", () => {
  it("refuses a user who is not an administrator, keeps the account and logs the refusal", async () => {
    const victim = await seedCoach("victim@club.test");
    const coach = await seedCoach("coach@club.test");

    await expect(deleteAccount({ uid: victim }, asUser(coach))).rejects.toMatchObject({ code: "permission-denied" });

    await expect(auth().getUser(victim)).resolves.toBeTruthy();
    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ reason: "delete-other-account", uid: coach }));
  });

  // Un administrateur passe les mêmes contrôles que pour les callables d'administration, pas seulement le claim.
  it("refuses an administrator whose address is not verified", async () => {
    const caller = await seedAdmin("unverified@wina.test");
    await auth().updateUser(caller, { emailVerified: false });
    const victim = await seedCoach("victim@club.test");

    await expect(deleteAccount({ uid: victim }, await signedInCaller(caller))).rejects.toMatchObject({ code: "permission-denied" });

    await expect(auth().getUser(victim)).resolves.toBeTruthy();
    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ reason: "email-not-verified", uid: caller }));
  });

  it("refuses an administrator whose session was revoked", async () => {
    const caller = await seedAdmin("revoked@wina.test");
    const identity = await signedInCaller(caller);
    // validSince est en secondes : sans cette pause, jeton et révocation tombent dans la même seconde.
    await new Promise((resolve) => setTimeout(resolve, 1100));
    await auth().revokeRefreshTokens(caller);
    const victim = await seedCoach("victim@club.test");

    await expect(deleteAccount({ uid: victim }, identity)).rejects.toMatchObject({ code: "permission-denied" });

    await expect(auth().getUser(victim)).resolves.toBeTruthy();
    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ reason: "token-revoked", uid: caller }));
  });

  it("refuses an admin claim that does not come with a raw identity token", async () => {
    const victim = await seedCoach("victim@club.test");

    await expect(deleteAccount({ uid: victim }, { uid: "forged", token: { admin: true, email_verified: true } })).rejects.toMatchObject({
      code: "permission-denied",
    });

    await expect(auth().getUser(victim)).resolves.toBeTruthy();
  });

  it("lets a verified administrator delete a coach account and audits it", async () => {
    const caller = await seedAdmin("boss@wina.test");
    const victim = await seedCoach("coach@club.test");

    await expect(deleteAccount({ uid: victim }, await signedInCaller(caller))).resolves.toBe(true);

    await expect(auth().getUser(victim)).rejects.toMatchObject({ code: "auth/user-not-found" });
    expect(await auditEntries()).toEqual([
      expect.objectContaining({ action: "delete", targetUid: victim, targetEmail: "coach@club.test", adminUid: caller, outcome: "success", details: "via deleteAccount" }),
    ]);
  });

  it("audits a failed deletion by an administrator", async () => {
    const caller = await seedAdmin("boss@wina.test");

    await expect(deleteAccount({ uid: "ghost" }, await signedInCaller(caller))).rejects.toMatchObject({ code: "not-found" });

    expect(await auditEntries()).toEqual([
      expect.objectContaining({ action: "delete", targetUid: "ghost", adminUid: caller, outcome: "failure", details: "via deleteAccount" }),
    ]);
  });

  it("rejects a malformed target from a verified administrator", async () => {
    const caller = await seedAdmin("boss@wina.test");

    await expect(deleteAccount({ uid: "" }, await signedInCaller(caller))).rejects.toMatchObject({ code: "invalid-argument" });
  });
});

// deleteAccount n'a ni verrou ni protection du dernier administrateur : un compte administrateur
// se supprime depuis la vue « Administrateurs » (deleteAdmin).
describe("deleteAccount (secured): administrator accounts", () => {
  it("refuses to delete another administrator, keeps the account, and audits the attempt", async () => {
    const caller = await seedAdmin("a@wina.test");
    const target = await seedAdmin("b@wina.test");

    await expect(deleteAccount({ uid: target }, await signedInCaller(caller))).rejects.toMatchObject({
      code: "failed-precondition",
      message: expect.stringMatching(/Administrateurs/),
    });

    await expect(auth().getUser(target)).resolves.toBeTruthy();
    expect(await auditEntries()).toEqual([
      expect.objectContaining({ action: "admin_delete", targetUid: target, adminUid: caller, outcome: "failure", details: "via deleteAccount" }),
    ]);
  });

  it("refuses an administrator who targets their own account (the last administrator included)", async () => {
    const only = await seedAdmin("only@wina.test");

    await expect(deleteAccount({ uid: only }, await signedInCaller(only))).rejects.toMatchObject({ code: "failed-precondition" });

    await expect(auth().getUser(only)).resolves.toBeTruthy();
  });
});
