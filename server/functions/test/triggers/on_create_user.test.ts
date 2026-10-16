import { beforeEach, describe, expect, it, vi } from "vitest";
import { firestore } from "firebase-admin";

vi.mock("../../src/utils/send_email", () => ({
  sendEmail: vi.fn().mockResolvedValue({}),
}));

vi.mock("firebase-functions/logger", () => ({
  debug: vi.fn(),
  error: vi.fn(),
  info: vi.fn(),
  log: vi.fn(),
  warn: vi.fn(),
}));

import * as logger from "firebase-functions/logger";
import { sendEmail } from "../../src/utils/send_email";
import { seedAppConfig } from "../helpers";
import onCreateUser from "../../src/triggers/user/on_create_user";

beforeEach(async () => {
  vi.mocked(sendEmail).mockClear();
  vi.mocked(logger.info).mockClear();
  vi.mocked(logger.warn).mockClear();
  vi.mocked(logger.error).mockClear();
  vi.mocked(sendEmail).mockResolvedValue({} as any);
  await seedAppConfig({ stripeConfig: { applicationNeedStripe: false } });
});

async function snapshotFor(uid: string, data: Record<string, unknown>) {
  const ref = firestore().collection("users").doc(uid);
  await ref.set(data);
  return ref.get();
}

describe("onCreateUser", () => {
  it("skips the skeleton welcome email for admin-created coaches", async () => {
    const snap = await snapshotFor("coach1", { email: "coach@club.test", invitedByAdmin: true });

    await onCreateUser(snap as any, { params: { userId: "coach1" } });

    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("still sends the welcome email for accounts created any other way", async () => {
    const snap = await snapshotFor("coach2", { email: "self@club.test" });

    await onCreateUser(snap as any, { params: { userId: "coach2" } });

    expect(sendEmail).toHaveBeenCalledTimes(1);
  });

  it("never writes personal data to the logs, only the user id", async () => {
    const snap = await snapshotFor("coach4", { email: "private@club.test", firstname: "Ibrahim", phone: "+33612345678" });

    await onCreateUser(snap as any, { params: { userId: "coach4" } });

    const logged = JSON.stringify([...vi.mocked(logger.info).mock.calls, ...vi.mocked(logger.warn).mock.calls]);
    expect(logged).toContain("coach4");
    expect(logged).not.toContain("private@club.test");
    expect(logged).not.toContain("Ibrahim");
    expect(logged).not.toContain("+33612345678");
  });

  it("does not throw when stripeConfig disables Stripe", async () => {
    const snap = await snapshotFor("coach3", { email: "nostripe@club.test", invitedByAdmin: true });

    await expect(onCreateUser(snap as any, { params: { userId: "coach3" } })).resolves.not.toThrow();
  });

  // La fiche est déjà créée : un échec d'envoi est journalisé (motif seulement) et le trigger réussit.
  it("logs a failed welcome email without failing the trigger", async () => {
    vi.mocked(sendEmail).mockRejectedValueOnce(new Error("MailerSend : 422 : domaine non vérifié"));
    const snap = await snapshotFor("coach5", { email: "fail@club.test" });

    await expect(onCreateUser(snap as any, { params: { userId: "coach5" } })).resolves.toBeUndefined();

    expect(logger.error).toHaveBeenCalledWith("[onCreateUser] e-mail de bienvenue non envoyé : MailerSend : 422 : domaine non vérifié");
  });

  it("sends a welcome email without a contact link when app_config has no contact address", async () => {
    await seedAppConfig({ contactEmail: undefined });
    const snap = await snapshotFor("coach6", { email: "nocontact@club.test" });

    await onCreateUser(snap as any, { params: { userId: "coach6" } });

    const [, , html, subject, text] = vi.mocked(sendEmail).mock.calls[0];
    expect(subject).toBe("Bienvenue");
    expect(html).not.toContain("mailto:");
    expect(text).not.toContain("undefined");
    expect(text).toContain("Bienvenue sur Wina");
  });
});
