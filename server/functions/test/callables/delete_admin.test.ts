import { beforeEach, describe, expect, it, vi } from "vitest";
import { auth, firestore } from "firebase-admin";
import { seedAdmin, seedCoach } from "../helpers";
import deleteAdmin from "../../src/callables/admin/delete_admin";
import { listAdminRecords } from "../../src/callables/admin/_admin_accounts";

const CALLER_EMAIL = "root@wina.test";
let caller: { uid: string; email: string };

beforeEach(async () => {
  caller = { uid: await seedAdmin(CALLER_EMAIL), email: CALLER_EMAIL };
});

const auditEntries = async () => (await firestore().collection("admin_audit").get()).docs.map((d) => d.data());

describe("deleteAdmin", () => {
  it("deletes another administrator account and records who did it", async () => {
    const uid = await seedAdmin("gone@wina.test");

    const result = await deleteAdmin({ uid }, caller);

    expect(result).toEqual({ deleted: true });
    await expect(auth().getUser(uid)).rejects.toThrowError();
    const audit = await auditEntries();
    expect(audit).toHaveLength(1);
    expect(audit[0]).toMatchObject({ action: "admin_delete", targetUid: uid, targetEmail: "gone@wina.test", adminUid: caller.uid, outcome: "success" });
  });

  it("can delete a disabled administrator while another active one remains", async () => {
    const uid = await seedAdmin("old@wina.test", { disabled: true });

    await expect(deleteAdmin({ uid }, caller)).resolves.toEqual({ deleted: true });
  });

  describe("safeguards", () => {
    it("refuses to delete one's own account", async () => {
      await expect(deleteAdmin({ uid: caller.uid }, caller)).rejects.toMatchObject({ code: "failed-precondition" });

      await expect(auth().getUser(caller.uid)).resolves.toBeTruthy();
      expect((await auditEntries())[0]).toMatchObject({ outcome: "failure", error: expect.stringMatching(/propre compte/) });
    });

    it("refuses to delete the last active administrator", async () => {
      // Le seul autre administrateur est désactivé : supprimer `last` laisserait le back-office sans personne.
      await auth().updateUser(caller.uid, { disabled: true });
      const last = await seedAdmin("last@wina.test");

      await expect(deleteAdmin({ uid: last }, { uid: "someone", email: "x@wina.test" })).rejects.toMatchObject({
        code: "failed-precondition",
        message: expect.stringMatching(/dernier administrateur/),
      });

      await expect(auth().getUser(last)).resolves.toBeTruthy();
    });

    it("refuses an account that is not an administrator, and leaves it alone", async () => {
      const coach = await seedCoach("coach@club.test");

      await expect(deleteAdmin({ uid: coach }, caller)).rejects.toMatchObject({ code: "failed-precondition" });

      await expect(auth().getUser(coach)).resolves.toBeTruthy();
      expect((await firestore().collection("users").doc(coach).get()).exists).toBe(true);
    });

    it("refuses an administrator who also has a coach profile, whose data this view does not archive", async () => {
      const uid = await seedCoach("both@club.test");
      await auth().setCustomUserClaims(uid, { admin: true });

      await expect(deleteAdmin({ uid }, caller)).rejects.toMatchObject({ code: "failed-precondition", message: expect.stringMatching(/fiche coach/) });

      await expect(auth().getUser(uid)).resolves.toBeTruthy();
    });

    it("refuses an unknown account", async () => {
      await expect(deleteAdmin({ uid: "nope" }, caller)).rejects.toMatchObject({ code: "not-found" });
    });
  });

  it.each([
    ["no payload", undefined],
    ["no uid", {}],
    ["a non-string uid", { uid: 7 }],
    ["an oversized uid", { uid: "u".repeat(129) }],
  ])("rejects %s with invalid-argument", async (_label, payload) => {
    await expect(deleteAdmin(payload as any, caller)).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("keeps the account and records a failure when Auth refuses the deletion", async () => {
    const uid = await seedAdmin("authfail@wina.test");
    const spy = vi.spyOn(auth(), "deleteUser").mockRejectedValueOnce(new Error("auth boom"));

    try {
      await expect(deleteAdmin({ uid }, caller)).rejects.toMatchObject({ code: "internal" });
    } finally {
      spy.mockRestore();
    }

    await expect(auth().getUser(uid)).resolves.toBeTruthy();
    expect((await auditEntries())[0]).toMatchObject({ action: "admin_delete", outcome: "failure" });
  });

  // Le contrôle « il reste un autre administrateur actif » lit puis écrit : sans le verrou, deux
  // administrateurs qui se suppriment l'un l'autre au même instant passeraient tous les deux.
  it("never leaves the back-office without an administrator when two delete each other at once", async () => {
    await auth().deleteUser(caller.uid);
    const alice = await seedAdmin("alice@wina.test");
    const bob = await seedAdmin("bob@wina.test");

    const results = await Promise.allSettled([
      deleteAdmin({ uid: bob }, { uid: alice, email: "alice@wina.test" }),
      deleteAdmin({ uid: alice }, { uid: bob, email: "bob@wina.test" }),
    ]);

    expect(results.filter((r) => r.status === "fulfilled")).toHaveLength(1);
    expect(await listAdminRecords()).toHaveLength(1);
  });

  it("refuses while another account operation holds the lock", async () => {
    const uid = await seedAdmin("busy@wina.test");
    await firestore().collection("admin_locks").doc("accounts").set({ holder: "other", until: firestore.Timestamp.fromMillis(Date.now() + 60_000) });

    await expect(deleteAdmin({ uid }, caller)).rejects.toMatchObject({ code: "aborted" });

    await expect(auth().getUser(uid)).resolves.toBeTruthy();
  });
});
