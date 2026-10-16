import { beforeEach, describe, expect, it, vi } from "vitest";
import { firestore } from "firebase-admin";

vi.mock("../../src/utils/send_email", () => ({
  sendEmail: vi.fn().mockResolvedValue({}),
}));

import { sendEmail } from "../../src/utils/send_email";
import { seedAppConfig, seedCoach } from "../helpers";
import resendInvite from "../../src/callables/admin/resend_invite";

const CALLER = { uid: "admin1", email: "staff@wina.test" };

beforeEach(async () => {
  vi.mocked(sendEmail).mockClear();
  vi.mocked(sendEmail).mockResolvedValue({} as any);
  await seedAppConfig();
});

describe("resendInvite", () => {
  it("resends the invitation and stamps lastInviteSentAt", async () => {
    const uid = await seedCoach("coach@club.test");

    const result = await resendInvite({ uid }, CALLER);

    expect(result).toEqual({ sent: true });
    expect(sendEmail).toHaveBeenCalledTimes(1);
    const doc = await firestore().collection("users").doc(uid).get();
    expect(doc.get("lastInviteSentAt")).toBeTruthy();
  });

  it("rejects an unknown account", async () => {
    await expect(resendInvite({ uid: "nope" }, CALLER)).rejects.toThrowError(/introuvable/i);
  });

  it("refuses a second send within the cooldown", async () => {
    const uid = await seedCoach("cooldown@club.test", { lastInviteSentAt: firestore.Timestamp.now() });

    await expect(resendInvite({ uid }, CALLER)).rejects.toThrowError(/moins d'une minute/i);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("allows a send once the cooldown has elapsed", async () => {
    const old = firestore.Timestamp.fromMillis(Date.now() - 120_000);
    const uid = await seedCoach("elapsed@club.test", { lastInviteSentAt: old });

    await expect(resendInvite({ uid }, CALLER)).resolves.toEqual({ sent: true });
  });

  // Le coach écrit lui-même users/{uid}.email (changement d'e-mail des réglages) :
  // l'invitation doit partir à l'adresse du compte Auth, pas à celle de la fiche.
  it("sends the invitation to the Auth address even if the profile email was rewritten", async () => {
    const uid = await seedCoach("real@club.test");
    await firestore().collection("users").doc(uid).update({ email: "someone-else@club.test" });

    await resendInvite({ uid }, CALLER);

    expect(sendEmail).toHaveBeenCalledTimes(1);
    expect(vi.mocked(sendEmail).mock.calls[0][1]).toMatchObject({ email: "real@club.test" });
    const audit = await firestore().collection("admin_audit").get();
    expect(audit.docs[0].get("targetEmail")).toBe("real@club.test");
  });

  it("records an audit entry", async () => {
    const uid = await seedCoach("audited@club.test");
    await resendInvite({ uid }, CALLER);

    const audit = await firestore().collection("admin_audit").get();
    expect(audit.size).toBe(1);
    expect(audit.docs[0].get("action")).toBe("resend");
  });

  it("surfaces a mail failure as a French HttpsError instead of INTERNAL", async () => {
    vi.mocked(sendEmail).mockRejectedValueOnce(new Error("SMTP down"));
    const uid = await seedCoach("mailfail@club.test");

    await expect(resendInvite({ uid }, CALLER)).rejects.toThrowError(/l'envoi de l'invitation a échoué/i);
  });

  it("records a failure audit entry when the mail send fails", async () => {
    vi.mocked(sendEmail).mockRejectedValueOnce(new Error("SMTP down"));
    const uid = await seedCoach("mailfail-audit@club.test");

    await expect(resendInvite({ uid }, CALLER)).rejects.toThrow();

    const audit = await firestore().collection("admin_audit").get();
    expect(audit.size).toBe(1);
    expect(audit.docs[0].get("action")).toBe("resend");
    expect(audit.docs[0].get("outcome")).toBe("failure");
  });

  it("records a failure audit entry for an unknown account", async () => {
    await expect(resendInvite({ uid: "nope" }, CALLER)).rejects.toThrow();

    const audit = await firestore().collection("admin_audit").get();
    expect(audit.size).toBe(1);
    expect(audit.docs[0].get("action")).toBe("resend");
    expect(audit.docs[0].get("outcome")).toBe("failure");
  });

  it("does not record an audit entry when a resend is blocked by the cooldown", async () => {
    const uid = await seedCoach("cooldown-audit@club.test", { lastInviteSentAt: firestore.Timestamp.now() });

    await expect(resendInvite({ uid }, CALLER)).rejects.toThrow();

    const audit = await firestore().collection("admin_audit").get();
    expect(audit.size).toBe(0);
  });
});
