import { describe, expect, it } from "vitest";
import { firestore } from "firebase-admin";
import { seedCoach } from "../helpers";
import grantTestSubscription from "../../src/callables/billing/grant_test_subscription";

const caller = (uid: string) => ({ uid, token: {} as Record<string, unknown> });

async function codeOf(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (e: any) {
    return e.code === "failed-precondition" ? `${e.code}:${e.message}` : e.code;
  }
  return "no-error";
}

/** Pose (ou non) l'interrupteur de l'administrateur, comme dans la console Firebase. */
async function setTestPurchases(value: unknown): Promise<void> {
  await firestore().doc("app_config/config").set({ test_purchases_enabled: value });
}

describe("grantTestSubscription", () => {
  it("refuse tout appel tant que test_purchases_enabled n'est pas activé", async () => {
    const uid = await seedCoach("owner@club.test", { firstname: "Ibrahim" });

    expect(await codeOf(grantTestSubscription({ productId: "wina_2teams_annual" }, caller(uid)))).toBe("failed-precondition:test-purchases-disabled");
    expect((await firestore().doc(`users/${uid}`).get()).get("subscription")).toBeUndefined();
  });

  it("refuse quand test_purchases_enabled vaut autre chose que true", async () => {
    await setTestPurchases("true");
    const uid = await seedCoach("owner@club.test", { firstname: "Ibrahim" });

    expect(await codeOf(grantTestSubscription({ productId: "wina_2teams_annual" }, caller(uid)))).toBe("failed-precondition:test-purchases-disabled");
  });

  it("pose l'abonnement et l'accès du propriétaire quand il est activé", async () => {
    await setTestPurchases(true);
    const uid = await seedCoach("owner@club.test", { firstname: "Ibrahim" });

    await grantTestSubscription({ productId: "wina_2teams_annual" }, caller(uid));

    const snap = await firestore().doc(`users/${uid}`).get();
    expect(snap.get("subscription.teamsAllowed")).toBe(2);
    expect(snap.get("subscription.period")).toBe("yearly");
    expect(snap.get("access.active")).toBe(true);
    expect(snap.get("testGrant")).toBe(true);
  });

  it("refuse un produit inconnu", async () => {
    await setTestPurchases(true);
    const uid = await seedCoach("owner@club.test", { firstname: "Ibrahim" });

    expect(await codeOf(grantTestSubscription({ productId: "autre" }, caller(uid)))).toBe("invalid-argument");
  });

  it("refuse un compte d'équipe lié", async () => {
    await setTestPurchases(true);
    const uid = await seedCoach("linked@club.test", { firstname: "Lien" });
    await firestore().doc(`users/${uid}`).set({ ownerUid: "someone" }, { merge: true });

    expect(await codeOf(grantTestSubscription({ productId: "wina_1team_monthly" }, caller(uid)))).toBe("permission-denied");
  });
});
