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
import onCreateReport, { REPORT_SUBJECT } from "../../src/triggers/report/on_create_report";

beforeEach(async () => {
  vi.mocked(sendEmail).mockReset();
  vi.mocked(sendEmail).mockResolvedValue({} as any);
  vi.mocked(logger.error).mockClear();
  vi.mocked(logger.info).mockClear();
  await seedAppConfig();
});

async function reportSnapshot(id: string, data: Record<string, unknown>) {
  const ref = firestore().collection("reports").doc(id);
  await ref.set(data);
  return ref.get();
}

const BASE_REPORT = () => ({
  type: "report",
  categories: ["spam"],
  description: "Contenu signalé",
  fromId: firestore().doc("users/reporter1"),
  objectReported: firestore().doc("users/target1"),
  sendAt: firestore.Timestamp.fromDate(new Date("2026-10-01T10:00:00Z")),
  files: ["https://files.test/report.png"],
});

describe("onCreateReport", () => {
  it("mails the report to the contact address of the app", async () => {
    const snap = await reportSnapshot("r1", BASE_REPORT());

    await onCreateReport(snap as any, { params: { reportId: "r1" } });

    expect(sendEmail).toHaveBeenCalledTimes(1);
    const [, recipient, html, subject] = vi.mocked(sendEmail).mock.calls[0];
    expect(recipient).toMatchObject({ email: "support@wina.test" });
    expect(subject).toBe(REPORT_SUBJECT);
    expect(html).toContain("Contenu signal");
    expect(html).toContain("Voir les fichiers");
  });

  it("does not crash on a report without files", async () => {
    const { files: _files, ...withoutFiles } = BASE_REPORT();
    const snap = await reportSnapshot("r2", withoutFiles);

    await expect(onCreateReport(snap as any, { params: { reportId: "r2" } })).resolves.toBeUndefined();

    expect(sendEmail).toHaveBeenCalledTimes(1);
    expect(vi.mocked(sendEmail).mock.calls[0][2]).not.toContain("Voir les fichiers");
  });

  it("escapes the description written by the reporter", async () => {
    const snap = await reportSnapshot("r3", { ...BASE_REPORT(), description: '<img src=x onerror="alert(1)">' });

    await onCreateReport(snap as any, { params: { reportId: "r3" } });

    const html = vi.mocked(sendEmail).mock.calls[0][2];
    expect(html).not.toContain("<img src=x");
    expect(html).toContain("&lt;img src=x onerror=&quot;alert(1)&quot;&gt;");
  });

  it("sends nothing, borrows no address and logs the reason when no contact address is configured", async () => {
    await seedAppConfig({ contactEmail: undefined });
    const snap = await reportSnapshot("r4", BASE_REPORT());

    await expect(onCreateReport(snap as any, { params: { reportId: "r4" } })).resolves.toBeUndefined();

    expect(sendEmail).not.toHaveBeenCalled();
    expect(logger.error).toHaveBeenCalledWith(expect.stringMatching(/contactEmail est absent/));
  });

  it("logs a failed send without failing the trigger, and never logs the provider response", async () => {
    vi.mocked(sendEmail).mockRejectedValueOnce(new Error("MailerSend : 422 : domaine non vérifié"));
    const snap = await reportSnapshot("r5", BASE_REPORT());

    await expect(onCreateReport(snap as any, { params: { reportId: "r5" } })).resolves.toBeUndefined();

    expect(logger.error).toHaveBeenCalledWith("[onCreateReport] e-mail de signalement non envoyé : MailerSend : 422 : domaine non vérifié");
    expect(logger.info).not.toHaveBeenCalled();
  });
});
