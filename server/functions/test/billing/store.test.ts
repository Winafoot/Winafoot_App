import { describe, expect, it } from "vitest";
import { firestore } from "firebase-admin";
import { accessToDoc, subscriptionFromDoc, subscriptionToDoc, writeSubscriptionAndAccess } from "../../src/billing/store";
import type { SubscriptionData } from "../../src/billing/subscription";

const NOW = 1_800_000_000_000;
const DAY = 86_400_000;

const SUB: SubscriptionData = {
  productId: "wina_team2_yearly",
  period: "yearly",
  teamsAllowed: 2,
  status: "active",
  trialEndMs: NOW - 7 * DAY,
  expiresAtMs: NOW + 365 * DAY,
  store: "play_store",
  lastEventMs: NOW,
};

describe("subscription documents", () => {
  it("round-trips through Firestore types", () => {
    expect(subscriptionFromDoc(subscriptionToDoc(SUB))).toEqual(SUB);
  });

  it("stores dates as timestamps, which the security rules compare", () => {
    const doc = subscriptionToDoc(SUB);
    expect(doc.expiresAt).toBeInstanceOf(firestore.Timestamp);
    expect(accessToDoc({ active: true, untilMs: NOW }).until).toBeInstanceOf(firestore.Timestamp);
  });

  it("reads a missing or empty field as no subscription", () => {
    expect(subscriptionFromDoc(undefined)).toBeUndefined();
    expect(subscriptionFromDoc({})).toBeUndefined();
  });
});

describe("writeSubscriptionAndAccess", () => {
  it("writes the subscription on the owner and recomputes every linked account", async () => {
    const db = firestore();
    await db.doc("users/owner").set({ firstname: "Ibrahim" });
    await db.doc("users/team2").set({ ownerUid: "owner", teamIndex: 2 });
    await db.doc("users/team3").set({ ownerUid: "owner", teamIndex: 3 });

    await db.runTransaction(async (tx) => {
      const linked = await tx.get(db.collection("users").where("ownerUid", "==", "owner"));
      writeSubscriptionAndAccess(tx, db.doc("users/owner"), linked.docs, SUB, NOW);
    });

    const owner = (await db.doc("users/owner").get()).data()!;
    expect(owner.subscription.teamsAllowed).toBe(2);
    expect(owner.access.active).toBe(true);
    expect((await db.doc("users/team2").get()).get("access.active")).toBe(true);
    // Équipe 3 au-delà de la formule à 2 équipes : bloquée, ses données restent.
    expect((await db.doc("users/team3").get()).get("access.active")).toBe(false);
  });
});
