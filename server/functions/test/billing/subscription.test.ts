import { describe, expect, it } from "vitest";
import { applyEvent, computeAccess, parseProduct, type RevenueCatEvent, type SubscriptionData } from "../../src/billing/subscription";

const NOW = 1_800_000_000_000;
const DAY = 86_400_000;

function event(overrides: Partial<RevenueCatEvent> = {}): RevenueCatEvent {
  return {
    type: "INITIAL_PURCHASE",
    app_user_id: "owner1",
    product_id: "wina_team2_yearly",
    period_type: "NORMAL",
    expiration_at_ms: NOW + 365 * DAY,
    event_timestamp_ms: NOW,
    store: "APP_STORE",
    ...overrides,
  };
}

function sub(overrides: Partial<SubscriptionData> = {}): SubscriptionData {
  return {
    productId: "wina_team2_yearly",
    period: "yearly",
    teamsAllowed: 2,
    status: "active",
    trialEndMs: null,
    expiresAtMs: NOW + 365 * DAY,
    store: "app_store",
    lastEventMs: NOW,
    ...overrides,
  };
}

describe("parseProduct", () => {
  it.each([
    ["wina_team1_monthly", 1, "monthly"],
    ["wina_team2_yearly", 2, "yearly"],
    ["wina_team3_monthly", 3, "monthly"],
    // Google Play : « identifiant de l'abonnement:identifiant du plan ».
    ["wina_team3:yearly", 3, "yearly"],
    // Identifiants créés dans App Store Connect : « annual » vaut yearly, « team » est singulier pour 1.
    ["wina_1team_monthly", 1, "monthly"],
    ["wina_1team_annual", 1, "yearly"],
    ["wina_2teams_monthly", 2, "monthly"],
    ["wina_2teams_annual", 2, "yearly"],
    ["wina_3teams_monthly", 3, "monthly"],
    ["wina_3teams_annual", 3, "yearly"],
    // Google Play, mêmes noms : abonnement seul, ou suivi de l'identifiant du plan de base.
    ["wina_1team:monthly", 1, "monthly"],
    ["wina_3teams_annual:p1y", 3, "yearly"],
    // Abonnements Play réellement créés dans la console : `wina<n>_team`, et un plan de base « annual1 ».
    ["wina_1team:annual1", 1, "yearly"],
    ["wina2_team:monthly", 2, "monthly"],
    ["wina2_team:annual", 2, "yearly"],
    ["wina3_team:monthly", 3, "monthly"],
    ["wina3_team:annual", 3, "yearly"],
  ])("reads %s", (id, teamsAllowed, period) => {
    expect(parseProduct(id)).toEqual({ teamsAllowed, period });
  });

  it.each([
    "wina_team4_monthly",
    "wina_team2_weekly",
    "wina_4teams_monthly",
    "wina_0team_annual",
    "wina_2teams_weekly",
    "wina_2teams_annual:",
    "wina4_team:monthly",
    "wina2_team:weekly",
    "xwina_2teams_annual",
    "autre",
    "",
    undefined,
    3,
  ])("rejects %s", (id) => {
    expect(parseProduct(id)).toBeNull();
  });
});

describe("applyEvent", () => {
  it("starts a trial", () => {
    const next = applyEvent(undefined, event({ period_type: "TRIAL", expiration_at_ms: NOW + 7 * DAY }));
    expect(next).toMatchObject({ status: "trial", teamsAllowed: 2, period: "yearly", trialEndMs: NOW + 7 * DAY, expiresAtMs: NOW + 7 * DAY, store: "app_store" });
  });

  it("keeps the trial end after the first renewal", () => {
    const trial = applyEvent(undefined, event({ period_type: "TRIAL", expiration_at_ms: NOW + 7 * DAY }))!;
    const next = applyEvent(trial, event({ type: "RENEWAL", event_timestamp_ms: NOW + 7 * DAY, expiration_at_ms: NOW + 372 * DAY }));
    expect(next).toMatchObject({ status: "active", trialEndMs: NOW + 7 * DAY, expiresAtMs: NOW + 372 * DAY });
  });

  it("maps the Play Store", () => {
    expect(applyEvent(undefined, event({ store: "PLAY_STORE", product_id: "wina_team1:monthly" }))).toMatchObject({ store: "play_store", teamsAllowed: 1, period: "monthly" });
  });

  it("switches formula on PRODUCT_CHANGE using the new product", () => {
    const next = applyEvent(sub(), event({ type: "PRODUCT_CHANGE", product_id: "wina_team2_yearly", new_product_id: "wina_team1_monthly", event_timestamp_ms: NOW + 1 }));
    expect(next).toMatchObject({ teamsAllowed: 1, period: "monthly", productId: "wina_team1_monthly" });
  });

  it("keeps access after a cancellation until the end of the period", () => {
    const next = applyEvent(sub(), event({ type: "CANCELLATION", cancel_reason: "UNSUBSCRIBE", event_timestamp_ms: NOW + 1 }));
    expect(next).toMatchObject({ status: "active", expiresAtMs: NOW + 365 * DAY });
  });

  it("marks a refund", () => {
    const next = applyEvent(sub(), event({ type: "CANCELLATION", cancel_reason: "CUSTOMER_SUPPORT", event_timestamp_ms: NOW + 1 }));
    expect(next?.status).toBe("refunded");
  });

  it("marks an expiration", () => {
    expect(applyEvent(sub(), event({ type: "EXPIRATION", expiration_at_ms: NOW - 1, event_timestamp_ms: NOW + 1 }))?.status).toBe("expired");
  });

  it("enters the grace period on a billing issue, until the grace date", () => {
    const next = applyEvent(sub(), event({ type: "BILLING_ISSUE", grace_period_expiration_at_ms: NOW + 16 * DAY, expiration_at_ms: NOW - DAY, event_timestamp_ms: NOW + 1 }));
    expect(next).toMatchObject({ status: "grace", expiresAtMs: NOW + 16 * DAY });
  });

  it("ignores an event older than the stored one", () => {
    expect(applyEvent(sub({ lastEventMs: NOW }), event({ type: "EXPIRATION", event_timestamp_ms: NOW - 1 }))).toBeNull();
  });

  it.each(["TEST", "TRANSFER", "NON_RENEWING_PURCHASE", "INVOICE_ISSUANCE"])("ignores the %s event", (type) => {
    expect(applyEvent(undefined, event({ type }))).toBeNull();
  });

  it("ignores an unknown product", () => {
    expect(applyEvent(undefined, event({ product_id: "autre_produit" }))).toBeNull();
  });

  it("records the event time", () => {
    expect(applyEvent(undefined, event({ event_timestamp_ms: NOW + 5 }))?.lastEventMs).toBe(NOW + 5);
  });
});

describe("computeAccess", () => {
  it.each(["trial", "active", "grace"] as const)("grants access while %s", (status) => {
    expect(computeAccess(sub({ status }), 1, NOW)).toEqual({ active: true, untilMs: NOW + 365 * DAY });
  });

  it.each(["expired", "refunded"] as const)("refuses access when %s", (status) => {
    expect(computeAccess(sub({ status }), 1, NOW)).toEqual({ active: false, untilMs: 0 });
  });

  it("refuses access once the period is over", () => {
    expect(computeAccess(sub({ expiresAtMs: NOW - 1 }), 1, NOW).active).toBe(false);
  });

  it("refuses a team beyond the allowed number", () => {
    expect(computeAccess(sub({ teamsAllowed: 2 }), 3, NOW).active).toBe(false);
    expect(computeAccess(sub({ teamsAllowed: 2 }), 2, NOW).active).toBe(true);
  });

  it("refuses everything without a subscription", () => {
    expect(computeAccess(undefined, 1, NOW)).toEqual({ active: false, untilMs: 0 });
  });
});
