import { beforeEach, describe, expect, it, vi } from "vitest";
import { auth, firestore } from "firebase-admin";

vi.mock("../../src/utils/send_email", () => ({
  sendEmail: vi.fn().mockResolvedValue({}),
}));

import { sendEmail } from "../../src/utils/send_email";
import { seedAdmin, seedAppConfig, seedCoach } from "../helpers";
import updateAdmin from "../../src/callables/admin/update_admin";

const CALLER_EMAIL = "root@wina.test";
let caller: { uid: string; email: string };

beforeEach(async () => {
  vi.mocked(sendEmail).mockClear();
  vi.mocked(sendEmail).mockResolvedValue({} as any);
  await seedAppConfig();
  caller = { uid: await seedAdmin(CALLER_EMAIL), email: CALLER_EMAIL };
});

const auditEntries = async () => (await firestore().collection("admin_audit").get()).docs.map((d) => d.data());
const pause = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

describe("updateAdmin", () => {
  it("renames an administrator, and clears the name with an empty string", async () => {
    const uid = await seedAdmin("rename@wina.test", { displayName: "Avant" });

    const renamed = await updateAdmin({ uid, displayName: "  Après " }, caller);
    expect(renamed.admin.displayName).toBe("Après");
    expect((await auth().getUser(uid)).displayName).toBe("Après");

    const cleared = await updateAdmin({ uid, displayName: "" }, caller);
    expect(cleared.admin.displayName).toBe("");
  });

  it("disables then re-enables another administrator", async () => {
    const uid = await seedAdmin("toggle@wina.test");

    const off = await updateAdmin({ uid, disabled: true }, caller);
    expect(off.admin.disabled).toBe(true);
    expect((await auth().getUser(uid)).disabled).toBe(true);

    const on = await updateAdmin({ uid, disabled: false }, caller);
    expect(on.admin.disabled).toBe(false);
  });

  it("revokes the sessions of an account it disables, so re-enabling does not revive old tokens", async () => {
    const uid = await seedAdmin("sessions@wina.test");
    const before = (await auth().getUser(uid)).tokensValidAfterTime;
    await pause(1100); // tokensValidAfterTime a une résolution d'une seconde

    await updateAdmin({ uid, disabled: true }, caller);

    expect((await auth().getUser(uid)).tokensValidAfterTime).not.toBe(before);
  });

  it("removes the second factor of another administrator who lost their phone", async () => {
    const uid = await seedAdmin("lost@wina.test", { secondFactor: true });
    expect((await auth().getUser(uid)).multiFactor?.enrolledFactors).toHaveLength(1);

    const result = await updateAdmin({ uid, resetSecondFactor: true }, caller);

    expect(result.admin.secondFactors).toBe(0);
    expect((await auth().getUser(uid)).multiFactor?.enrolledFactors ?? []).toHaveLength(0);
  });

  it("revokes the sessions of another administrator on request", async () => {
    const uid = await seedAdmin("revoke@wina.test");
    const before = (await auth().getUser(uid)).tokensValidAfterTime;
    await pause(1100);

    await updateAdmin({ uid, revokeSessions: true }, caller);

    expect((await auth().getUser(uid)).tokensValidAfterTime).not.toBe(before);
  });

  it("does not touch the sessions when only the name changes", async () => {
    const uid = await seedAdmin("calm@wina.test");
    const before = (await auth().getUser(uid)).tokensValidAfterTime;
    await pause(1100);

    await updateAdmin({ uid, displayName: "Calme" }, caller);

    expect((await auth().getUser(uid)).tokensValidAfterTime).toBe(before);
  });

  it("sends a new invitation on request", async () => {
    const uid = await seedAdmin("again@wina.test", { displayName: "Alex" });

    const result = await updateAdmin({ uid, sendInvite: true }, caller);

    expect(result.inviteSent).toBe(true);
    expect(sendEmail).toHaveBeenCalledTimes(1);
    expect((vi.mocked(sendEmail).mock.calls[0][1] as any).email).toBe("again@wina.test");
  });

  it("reports a failed invitation without failing the update", async () => {
    const uid = await seedAdmin("nomail@wina.test");
    vi.mocked(sendEmail).mockRejectedValueOnce(new Error("mailer down"));

    const result = await updateAdmin({ uid, displayName: "Zoé", sendInvite: true }, caller);

    expect(result.inviteSent).toBe(false);
    expect(result.admin.displayName).toBe("Zoé");
    expect((await auditEntries())[0].details).toContain("invitation non envoyée");
  });

  it("does not report an invitation status when none was requested", async () => {
    const uid = await seedAdmin("quiet@wina.test");

    const result = await updateAdmin({ uid, displayName: "Quiet" }, caller);

    expect(result).not.toHaveProperty("inviteSent");
  });

  it("records what was asked in the audit trail", async () => {
    const uid = await seedAdmin("trail@wina.test");

    await updateAdmin({ uid, disabled: true, displayName: "T" }, caller);

    const entry = (await auditEntries())[0];
    expect(entry).toMatchObject({ action: "admin_update", targetUid: uid, targetEmail: "trail@wina.test", adminUid: caller.uid, outcome: "success" });
    expect(entry.details).toBe("displayName, disabled=true");
  });

  describe("safeguards", () => {
    it("refuses to disable one's own account", async () => {
      await expect(updateAdmin({ uid: caller.uid, disabled: true }, caller)).rejects.toMatchObject({ code: "failed-precondition" });

      expect((await auth().getUser(caller.uid)).disabled).toBe(false);
    });

    it.each([
      ["removing one's own second factor", { resetSecondFactor: true as const }],
      ["revoking one's own sessions", { revokeSessions: true as const }],
    ])("refuses %s (the account page and signing out exist for that)", async (_label, change) => {
      await expect(updateAdmin({ uid: caller.uid, ...change }, caller)).rejects.toMatchObject({ code: "failed-precondition" });
    });

    it("lets one rename oneself", async () => {
      const result = await updateAdmin({ uid: caller.uid, displayName: "Moi" }, caller);

      expect(result.admin.displayName).toBe("Moi");
    });

    it("refuses to disable the last active administrator", async () => {
      // `caller` est désactivé : l'administrateur visé est donc le dernier actif.
      await auth().updateUser(caller.uid, { disabled: true });
      const last = await seedAdmin("last@wina.test");

      await expect(updateAdmin({ uid: last, disabled: true }, { uid: "someone", email: "x@wina.test" })).rejects.toMatchObject({
        code: "failed-precondition",
      });

      expect((await auth().getUser(last)).disabled).toBe(false);
    });

    it("still lets one disable an administrator when another active one remains", async () => {
      const other = await seedAdmin("other@wina.test");

      await expect(updateAdmin({ uid: other, disabled: true }, caller)).resolves.toBeTruthy();
    });

    it("refuses a target that is not an administrator, and leaves that account alone", async () => {
      const coach = await seedCoach("coach@club.test");

      await expect(updateAdmin({ uid: coach, disabled: true }, caller)).rejects.toMatchObject({ code: "failed-precondition" });

      expect((await auth().getUser(coach)).disabled).toBe(false);
    });

    it("refuses an unknown account", async () => {
      await expect(updateAdmin({ uid: "nope", displayName: "x" }, caller)).rejects.toMatchObject({ code: "not-found" });
    });

    it("audits every refusal as a failure, with what was attempted", async () => {
      await expect(updateAdmin({ uid: caller.uid, disabled: true }, caller)).rejects.toThrow();

      const entry = (await auditEntries())[0];
      expect(entry).toMatchObject({ action: "admin_update", outcome: "failure", adminUid: caller.uid });
      expect(entry.details).toBe("disabled=true");
      expect(entry.error).toMatch(/propre compte/);
    });
  });

  describe("account that is both administrator and coach", () => {
    // setCoachDisabled refuse les administrateurs : la fiche que le back-office affiche doit suivre l'état Auth.
    it("mirrors the disabled state onto the coach profile", async () => {
      const uid = await seedCoach("both@club.test");
      await auth().setCustomUserClaims(uid, { admin: true });

      await updateAdmin({ uid, disabled: true }, caller);
      const off = await firestore().collection("users").doc(uid).get();
      expect(off.get("disabled")).toBe(true);
      expect(off.get("disabledAt")).toBeTruthy();

      await updateAdmin({ uid, disabled: false }, caller);
      const on = await firestore().collection("users").doc(uid).get();
      expect(on.get("disabled")).toBe(false);
      expect(on.get("disabledAt")).toBeNull();
    });

    it("does not create a coach profile for an administrator who has none", async () => {
      const uid = await seedAdmin("plain@wina.test");

      await updateAdmin({ uid, disabled: true }, caller);

      expect((await firestore().collection("users").doc(uid).get()).exists).toBe(false);
    });
  });

  it("says so, and audits it as a failure with the applied change, when the sessions cannot be cut after the update", async () => {
    const uid = await seedAdmin("partial@wina.test");
    const spy = vi.spyOn(auth(), "revokeRefreshTokens").mockRejectedValueOnce(new Error("revoke boom"));

    try {
      await expect(updateAdmin({ uid, disabled: true }, caller)).rejects.toMatchObject({
        code: "internal",
        message: expect.stringMatching(/a été modifié/),
      });
    } finally {
      spy.mockRestore();
    }

    // La modification Auth est bien appliquée : c'est pourquoi le message ne dit pas « réessayez » à vide.
    expect((await auth().getUser(uid)).disabled).toBe(true);
    const entry = (await auditEntries())[0];
    expect(entry).toMatchObject({ action: "admin_update", outcome: "failure" });
    expect(entry.details).toContain("modification appliquée");
  });

  // Deux administrateurs qui se désactivent l'un l'autre au même instant passeraient chacun le contrôle
  // « il reste un autre administrateur actif » : le verrou doit les sérialiser, comme pour deleteAdmin.
  it("never leaves the back-office without an active administrator when two disable each other at once", async () => {
    await auth().deleteUser(caller.uid);
    const alice = await seedAdmin("alice@wina.test");
    const bob = await seedAdmin("bob@wina.test");

    const results = await Promise.allSettled([
      updateAdmin({ uid: bob, disabled: true }, { uid: alice, email: "alice@wina.test" }),
      updateAdmin({ uid: alice, disabled: true }, { uid: bob, email: "bob@wina.test" }),
    ]);

    expect(results.filter((r) => r.status === "fulfilled")).toHaveLength(1);
    const accounts = await Promise.all([auth().getUser(alice), auth().getUser(bob)]);
    expect(accounts.filter((a) => !a.disabled)).toHaveLength(1);
  });

  describe("validation", () => {
    it.each([
      ["no payload", undefined],
      ["no uid", { displayName: "x" }],
      ["a non-string uid", { uid: 12, displayName: "x" }],
      ["an oversized uid", { uid: "u".repeat(129), displayName: "x" }],
    ])("rejects %s with invalid-argument", async (_label, payload) => {
      await expect(updateAdmin(payload as any, caller)).rejects.toMatchObject({ code: "invalid-argument" });
    });

    it("rejects a request that changes nothing", async () => {
      const uid = await seedAdmin("nothing@wina.test");

      await expect(updateAdmin({ uid }, caller)).rejects.toMatchObject({ code: "invalid-argument", message: "Aucune modification demandée." });
    });

    it.each([
      ["a non-boolean disabled", { disabled: "yes" }],
      ["a non-string displayName", { displayName: 5 }],
      ["a displayName over 80 characters", { displayName: "x".repeat(81) }],
      ["a displayName with a line break", { displayName: "Jean\r\nBcc: x@y.test" }],
      ["a displayName with a right-to-left override", { displayName: "Jean\u202Enimda" }],
      ["a displayName with a tab", { displayName: "Jean\tPaul" }],
      ["resetSecondFactor set to false", { resetSecondFactor: false }],
      ["revokeSessions set to a string", { revokeSessions: "true" }],
      ["sendInvite set to a number", { sendInvite: 1 }],
    ])("rejects %s", async (_label, change) => {
      const uid = await seedAdmin("valid@wina.test");

      await expect(updateAdmin({ uid, ...(change as any) }, caller)).rejects.toMatchObject({ code: "invalid-argument" });
    });
  });

  it("records a failure and keeps the account untouched when Auth refuses the update", async () => {
    const uid = await seedAdmin("authfail@wina.test", { displayName: "Avant" });
    const spy = vi.spyOn(auth(), "updateUser").mockRejectedValueOnce(new Error("auth boom"));

    try {
      await expect(updateAdmin({ uid, displayName: "Après" }, caller)).rejects.toMatchObject({ code: "internal" });
    } finally {
      spy.mockRestore();
    }

    expect((await auth().getUser(uid)).displayName).toBe("Avant");
    expect((await auditEntries())[0]).toMatchObject({ outcome: "failure", details: "displayName" });
  });
});
