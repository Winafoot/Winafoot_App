import { beforeEach, describe, expect, it, vi } from "vitest";
import { auth, firestore } from "firebase-admin";

vi.mock("../../src/utils/send_email", () => ({
  sendEmail: vi.fn().mockResolvedValue({}),
}));

import { sendEmail } from "../../src/utils/send_email";
import { seedAdmin, seedAppConfig, seedCoach } from "../helpers";
import createAdmin from "../../src/callables/admin/create_admin";

const CALLER = { uid: "admin1", email: "root@wina.test" };

beforeEach(async () => {
  vi.mocked(sendEmail).mockClear();
  vi.mocked(sendEmail).mockResolvedValue({} as any);
  await seedAppConfig();
});

describe("createAdmin", () => {
  it("creates an administrator account and invites the person", async () => {
    const result = await createAdmin({ email: "  Nouvel.Admin@Wina.TEST ", displayName: " Nora " }, CALLER);

    expect(result.inviteSent).toBe(true);
    const record = await auth().getUser(result.uid);
    expect(record.email).toBe("nouvel.admin@wina.test");
    expect(record.displayName).toBe("Nora");
    expect(record.customClaims).toEqual({ admin: true });
    expect(record.disabled).toBe(false);
    // L'adresse n'est vérifiée que lorsque son titulaire utilise le lien reçu : pas avant.
    expect(record.emailVerified).toBe(false);
    expect(sendEmail).toHaveBeenCalledTimes(1);
  });

  it("never returns the temporary password, and the invitation carries a link instead", async () => {
    const result = await createAdmin({ email: "link@wina.test" }, CALLER);

    expect(Object.keys(result).sort()).toEqual(["inviteSent", "uid"]);
    const [, recipient, , subject, text] = vi.mocked(sendEmail).mock.calls[0];
    expect((recipient as any).email).toBe("link@wina.test");
    expect(subject).toBe("Votre accès au back-office est prêt");
    expect(text).toMatch(/https?:\/\/\S+/);
  });

  it("escapes the name in the HTML of the invitation", async () => {
    await createAdmin({ email: "xss@wina.test", displayName: "<img src=x onerror=alert(1)>" }, CALLER);

    const html = vi.mocked(sendEmail).mock.calls[0][2] as string;
    expect(html).not.toContain("<img src=x");
    expect(html).toContain("&lt;img src=x onerror=alert(1)&gt;");
  });

  it("records an audit entry naming the administrator who created it", async () => {
    const { uid } = await createAdmin({ email: "audit@wina.test" }, CALLER);

    const audit = await firestore().collection("admin_audit").get();
    expect(audit.size).toBe(1);
    expect(audit.docs[0].data()).toMatchObject({
      action: "admin_create",
      targetUid: uid,
      targetEmail: "audit@wina.test",
      adminUid: "admin1",
      adminEmail: "root@wina.test",
      outcome: "success",
    });
  });

  it.each([["an administrator", seedAdmin], ["a coach", seedCoach]] as const)(
    "refuses an address already used by %s, and does not promote or alter that account",
    async (_label, seed) => {
      const uid = await seed("taken@wina.test");

      await expect(createAdmin({ email: "TAKEN@wina.test" }, CALLER)).rejects.toMatchObject({ code: "already-exists" });

      const record = await auth().getUser(uid);
      expect(record.customClaims?.admin === true).toBe(_label === "an administrator");
      expect(sendEmail).not.toHaveBeenCalled();
      // La tentative reste dans la piste d'audit : quelqu'un a visé une adresse déjà utilisée.
      const audit = await firestore().collection("admin_audit").get();
      expect(audit.docs.map((d) => d.data())).toEqual([
        expect.objectContaining({ action: "admin_create", targetEmail: "taken@wina.test", adminUid: "admin1", outcome: "failure" }),
      ]);
    },
  );

  it.each([
    ["no payload", undefined],
    ["no address", {}],
    ["a non-string address", { email: 42 }],
    ["an empty address", { email: "  " }],
    ["a malformed address", { email: "pas une adresse" }],
    ["an address without a domain suffix", { email: "a@b" }],
    ["an address that is too long", { email: `${"a".repeat(250)}@wina.test` }],
  ])("rejects %s with invalid-argument", async (_label, payload) => {
    await expect(createAdmin(payload as any, CALLER)).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it.each([
    ["a non-string name", { email: "name@wina.test", displayName: { a: 1 } }],
    ["a name over 80 characters", { email: "name@wina.test", displayName: "x".repeat(81) }],
    ["a name with a line break", { email: "name@wina.test", displayName: "Jean\r\nBcc: x@y.test" }],
    ["a name with a right-to-left override", { email: "name@wina.test", displayName: "Jean\u202Enimda" }],
  ])("rejects %s with invalid-argument and creates nothing", async (_label, payload) => {
    await expect(createAdmin(payload as any, CALLER)).rejects.toMatchObject({ code: "invalid-argument" });

    await expect(auth().getUserByEmail("name@wina.test")).rejects.toThrowError();
  });

  it("keeps the account and reports it when the invitation cannot be sent", async () => {
    vi.mocked(sendEmail).mockRejectedValueOnce(new Error("mailer down"));

    const result = await createAdmin({ email: "nomail@wina.test" }, CALLER);

    expect(result.inviteSent).toBe(false);
    expect((await auth().getUser(result.uid)).customClaims).toEqual({ admin: true });
    const audit = await firestore().collection("admin_audit").where("targetUid", "==", result.uid).get();
    expect(audit.docs[0].get("outcome")).toBe("success");
    expect(audit.docs[0].get("details")).toBe("invitation non envoyée");
  });

  it("leaves no account behind when the role cannot be granted", async () => {
    const spy = vi.spyOn(auth(), "setCustomUserClaims").mockRejectedValueOnce(new Error("claims boom"));

    try {
      await expect(createAdmin({ email: "norole@wina.test" }, CALLER)).rejects.toMatchObject({ code: "internal" });
    } finally {
      spy.mockRestore();
    }

    await expect(auth().getUserByEmail("norole@wina.test")).rejects.toThrowError();
    expect(sendEmail).not.toHaveBeenCalled();
    const audit = await firestore().collection("admin_audit").get();
    expect(audit.docs[0].get("outcome")).toBe("failure");
  });

  it("records a failure and creates nothing when Auth refuses the account", async () => {
    const spy = vi.spyOn(auth(), "createUser").mockRejectedValueOnce(new Error("auth boom"));

    try {
      await expect(createAdmin({ email: "fail@wina.test" }, CALLER)).rejects.toMatchObject({ code: "internal" });
    } finally {
      spy.mockRestore();
    }

    const audit = await firestore().collection("admin_audit").get();
    expect(audit.docs[0].data()).toMatchObject({ action: "admin_create", outcome: "failure", targetEmail: "fail@wina.test" });
  });

  // Deux créations de la même adresse qui se croisent : la perdante ne doit jamais supprimer le compte de la gagnante.
  it("never deletes an account it did not create when two creations race", async () => {
    const winner = await seedAdmin("race@wina.test");
    // La vérification préalable ne voit pas encore le compte de l'autre appel : c'est createUser qui échoue.
    const lookup = vi.spyOn(auth(), "getUserByEmail").mockRejectedValueOnce({ code: "auth/user-not-found" });

    try {
      await expect(createAdmin({ email: "race@wina.test" }, CALLER)).rejects.toMatchObject({ code: "internal" });
    } finally {
      lookup.mockRestore();
    }

    expect((await auth().getUser(winner)).customClaims).toEqual({ admin: true });
  });
});
