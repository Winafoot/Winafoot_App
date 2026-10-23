import { afterEach, describe, expect, it, vi } from "vitest";
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

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("grantTestSubscription", () => {
  it("refuse tout appel tant que TEST_PURCHASES_ENABLED n'est pas activé", async () => {
    const uid = await seedCoach("owner@club.test", { firstname: "Ibrahim" });

    expect(await codeOf(grantTestSubscription({ productId: "wina_2teams_annual" }, caller(uid)))).toBe("failed-precondition:test-purchases-disabled");
    expect((await firestore().doc(`users/${uid}`).get()).get("subscription")).toBeUndefined();
  });

  it("pose l'abonnement et l'accès du propriétaire quand il est activé", async () => {
    vi.stubEnv("TEST_PURCHASES_ENABLED", "true");
    const uid = await seedCoach("owner@club.test", { firstname: "Ibrahim" });

    await grantTestSubscription({ productId: "wina_2teams_annual" }, caller(uid));

    const snap = await firestore().doc(`users/${uid}`).get();
    expect(snap.get("subscription.teamsAllowed")).toBe(2);
    expect(snap.get("subscription.period")).toBe("yearly");
    expect(snap.get("access.active")).toBe(true);
    expect(snap.get("testGrant")).toBe(true);
  });

  it("refuse un produit inconnu", async () => {
    vi.stubEnv("TEST_PURCHASES_ENABLED", "true");
    const uid = await seedCoach("owner@club.test", { firstname: "Ibrahim" });

    expect(await codeOf(grantTestSubscription({ productId: "autre" }, caller(uid)))).toBe("invalid-argument");
  });

  it("refuse un compte d'équipe lié", async () => {
    vi.stubEnv("TEST_PURCHASES_ENABLED", "true");
    const uid = await seedCoach("linked@club.test", { firstname: "Lien" });
    await firestore().doc(`users/${uid}`).set({ ownerUid: "someone" }, { merge: true });

    expect(await codeOf(grantTestSubscription({ productId: "wina_1team_monthly" }, caller(uid)))).toBe("permission-denied");
  });
});
