import { describe, expect, it } from "vitest";
import { firestore } from "firebase-admin";
import { fakeRes } from "../helpers";
import webhook from "../../src/https_requests/billing/revenuecat_webhook";

const NOW = Date.now();
const DAY = 86_400_000;
const SECRET = "Bearer test-webhook-secret";

/** `authorization: undefined` explicite = aucun en-tête ; option absente = le bon secret. */
function req(body: unknown, options: { method?: string; authorization?: string } = {}): any {
  const headers: Record<string, string | undefined> = { authorization: "authorization" in options ? options.authorization : SECRET };
  return { method: options.method ?? "POST", body, headers, get: (name: string) => headers[name.toLowerCase()] };
}

function event(overrides: Record<string, unknown> = {}) {
  return {
    api_version: "1.0",
    event: {
      type: "INITIAL_PURCHASE",
      app_user_id: "owner1",
      product_id: "wina_team2_yearly",
      period_type: "TRIAL",
      expiration_at_ms: NOW + 7 * DAY,
      event_timestamp_ms: NOW,
      store: "APP_STORE",
      environment: "SANDBOX",
      ...overrides,
    },
  };
}

async function call(body: unknown, options?: Parameters<typeof req>[1]) {
  const res = fakeRes();
  await webhook(req(body, options), res);
  return res;
}

const user = async (uid: string) => (await firestore().doc(`users/${uid}`).get()).data();

async function seedFamily() {
  const db = firestore();
  await db.doc("users/owner1").set({ firstname: "Ibrahim" });
  await db.doc("users/team2").set({ ownerUid: "owner1", teamIndex: 2 });
  await db.doc("users/team3").set({ ownerUid: "owner1", teamIndex: 3 });
}

describe("revenuecatWebhook: transport", () => {
  it("answers 405 to anything but POST", async () => {
    expect((await call(event(), { method: "GET" })).statusCode).toBe(405);
  });

  it.each([undefined, "", "Bearer faux", "test-webhook-secret"])("answers 401 for the header %s", async (authorization) => {
    await seedFamily();
    const res = await call(event(), { authorization });
    expect(res.statusCode).toBe(401);
    expect((await user("owner1"))?.subscription).toBeUndefined();
  });

  it.each([undefined, {}, { event: null }, { event: { type: "RENEWAL" } }, { event: { type: 1, app_user_id: "x", event_timestamp_ms: 1 } }])("answers 400 for the body %j", async (body) => {
    expect((await call(body)).statusCode).toBe(400);
  });
});

describe("revenuecatWebhook: events", () => {
  it("records a trial on the owner and grants access to the owner and the allowed teams", async () => {
    await seedFamily();

    const res = await call(event());

    expect(res.statusCode).toBe(200);
    const owner = (await user("owner1"))!;
    expect(owner.subscription).toMatchObject({ status: "trial", teamsAllowed: 2, period: "yearly", store: "app_store" });
    expect(owner.access.active).toBe(true);
    expect(owner.access.until.toMillis()).toBe(NOW + 7 * DAY);
    expect((await user("team2"))!.access.active).toBe(true);
    expect((await user("team3"))!.access.active).toBe(false);
  });

  it("accepts sandbox and production events alike (TestFlight purchases are sandbox)", async () => {
    await seedFamily();
    expect((await call(event({ environment: "PRODUCTION" }))).statusCode).toBe(200);
    expect((await user("owner1"))?.subscription.status).toBe("trial");
  });

  it("locks every account on expiration, without touching their data", async () => {
    await seedFamily();
    await call(event());

    await call(event({ type: "EXPIRATION", expiration_at_ms: NOW - 1, event_timestamp_ms: NOW + 10 }));

    expect((await user("owner1"))?.access.active).toBe(false);
    expect((await user("team2"))?.access.active).toBe(false);
    expect((await user("team2"))?.teamIndex).toBe(2);
  });

  it("locks the teams beyond the formula after a downgrade", async () => {
    await seedFamily();
    await call(event({ product_id: "wina_team3_yearly" }));
    expect((await user("team3"))?.access.active).toBe(true);

    await call(event({ type: "PRODUCT_CHANGE", product_id: "wina_team3_yearly", new_product_id: "wina_team1_monthly", period_type: "NORMAL", expiration_at_ms: NOW + 30 * DAY, event_timestamp_ms: NOW + 10 }));

    expect((await user("owner1"))?.access.active).toBe(true);
    expect((await user("team2"))?.access.active).toBe(false);
    expect((await user("team3"))?.access.active).toBe(false);
  });

  it("cuts access at once on a refund", async () => {
    await seedFamily();
    await call(event());

    await call(event({ type: "CANCELLATION", cancel_reason: "CUSTOMER_SUPPORT", event_timestamp_ms: NOW + 10 }));

    expect((await user("owner1"))?.subscription.status).toBe("refunded");
    expect((await user("owner1"))?.access.active).toBe(false);
  });

  it("keeps access after a plain cancellation, until the end of the period", async () => {
    await seedFamily();
    await call(event());

    await call(event({ type: "CANCELLATION", cancel_reason: "UNSUBSCRIBE", event_timestamp_ms: NOW + 10 }));

    expect((await user("owner1"))?.access.active).toBe(true);
  });

  it("ignores an event older than the one already applied", async () => {
    await seedFamily();
    await call(event({ event_timestamp_ms: NOW + 100 }));

    await call(event({ type: "EXPIRATION", expiration_at_ms: NOW - 1, event_timestamp_ms: NOW }));

    expect((await user("owner1"))?.subscription.status).toBe("trial");
  });

  it("answers 200 and writes nothing for an unknown user, a linked account or an unknown product", async () => {
    await seedFamily();

    expect((await call(event({ app_user_id: "$RCAnonymousID:abc" }))).statusCode).toBe(200);
    expect(await user("$RCAnonymousID:abc")).toBeUndefined();

    expect((await call(event({ app_user_id: "team2" }))).statusCode).toBe(200);
    expect((await user("team2"))?.subscription).toBeUndefined();

    expect((await call(event({ product_id: "autre" }))).statusCode).toBe(200);
    expect((await user("owner1"))?.subscription).toBeUndefined();
  });
});
