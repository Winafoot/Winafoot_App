import { beforeEach, describe, expect, it, vi } from "vitest";
import { firestore } from "firebase-admin";

vi.mock("firebase-functions/logger", () => ({ debug: vi.fn(), error: vi.fn(), info: vi.fn(), log: vi.fn(), warn: vi.fn() }));

import * as logger from "firebase-functions/logger";
import { seedCoach } from "../helpers";
import addNotification from "../../src/callables/notifications/add_notification_secured";

const MODEL = { title: "Match terminé", body: "Consultez le bilan", type: "match-finished", metadata: {} };

function payload(addNotifTo: unknown, sendPushNotif = false): any {
  return { internalNotifModel: MODEL, addNotifTo, sendPushNotif };
}

function caller(uid: string) {
  return { uid, token: {} };
}

async function inboxSize(uid: string): Promise<number> {
  return (await firestore().collection("users").doc(uid).collection("notifications").get()).size;
}

async function pushQueueSize(): Promise<number> {
  return (await firestore().collection("notifications").get()).size;
}

beforeEach(() => {
  vi.mocked(logger.warn).mockClear();
});

// Seul usage de l'app (MatchRepository._notifyMatchFinished) :
// addNotifTo == [uid de l'appelant]. Tout le reste est refusé AVANT d'écrire.
describe("addNotification (secured)", () => {
  it("writes the notification into the caller's own inbox", async () => {
    const a = await seedCoach("a@club.test");

    const result = await addNotification(payload([a]), caller(a));

    expect(result).toBe(true);
    expect(await inboxSize(a)).toBe(1);
    expect(await pushQueueSize()).toBe(0);
  });

  it("queues a push for the caller's own devices only when asked", async () => {
    const a = await seedCoach("a@club.test");

    await addNotification(payload([a], true), caller(a));

    const queued = await firestore().collection("notifications").get();
    expect(queued.size).toBe(1);
    expect(queued.docs[0].get("sendToIds")).toEqual([a]);
  });

  it("ignores a senderId sent by the client: the notification names the caller", async () => {
    const a = await seedCoach("a@club.test");
    const b = await seedCoach("b@club.test");

    await addNotification({ ...payload([a]), senderId: b }, caller(a));

    const inbox = await firestore().collection("users").doc(a).collection("notifications").get();
    expect(inbox.docs[0].get("sender.id")).toBe(a);
  });

  it("refuses to notify another coach and writes nothing anywhere", async () => {
    const a = await seedCoach("a@club.test");
    const b = await seedCoach("b@club.test");

    await expect(addNotification(payload([b], true), caller(a))).rejects.toMatchObject({ code: "permission-denied" });

    expect(await inboxSize(a)).toBe(0);
    expect(await inboxSize(b)).toBe(0);
    expect(await pushQueueSize()).toBe(0);
  });

  it("refuses a list that only contains the caller among other recipients", async () => {
    const a = await seedCoach("a@club.test");
    const b = await seedCoach("b@club.test");

    await expect(addNotification(payload([a, b]), caller(a))).rejects.toMatchObject({ code: "invalid-argument" });

    expect(await inboxSize(a)).toBe(0);
    expect(await inboxSize(b)).toBe(0);
  });

  it("refuses the caller repeated many times (unbounded write loop)", async () => {
    const a = await seedCoach("a@club.test");

    await expect(addNotification(payload(Array(50).fill(a)), caller(a))).rejects.toMatchObject({ code: "invalid-argument" });

    expect(await inboxSize(a)).toBe(0);
  });

  it("refuses an invented identifier, including a nested path", async () => {
    const a = await seedCoach("a@club.test");

    await expect(addNotification(payload(["ghost"]), caller(a))).rejects.toMatchObject({ code: "permission-denied" });
    await expect(addNotification(payload([`${a}/metadata/security`]), caller(a))).rejects.toMatchObject({
      code: "permission-denied",
    });
  });

  it.each([
    ["a missing list", undefined],
    ["an empty list", []],
    ["a string instead of a list", "someone"],
    ["an object instead of a list", { 0: "someone" }],
  ])("refuses %s with invalid-argument", async (_label, addNotifTo) => {
    const a = await seedCoach("a@club.test");

    await expect(addNotification(payload(addNotifTo), caller(a))).rejects.toMatchObject({ code: "invalid-argument" });
  });

  // Refus métier journalisés comme les refus d'accès (métrique access-denied).
  it("logs the refusal of a notification aimed at someone else", async () => {
    const a = await seedCoach("a@club.test");
    const b = await seedCoach("b@club.test");

    await expect(addNotification(payload([b]), caller(a))).rejects.toMatchObject({ code: "permission-denied" });

    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ reason: "notification-recipient-other", uid: a }));
  });

  it("logs the refusal of a malformed recipient list", async () => {
    const a = await seedCoach("a@club.test");

    await expect(addNotification(payload([a, a]), caller(a))).rejects.toMatchObject({ code: "invalid-argument" });

    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ reason: "notification-recipients-invalid", uid: a }));
  });
});
