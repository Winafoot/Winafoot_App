import { describe, expect, it } from "vitest";
import { subscriptionFromDoc } from "../../src/billing/store";
import { applyEvent, type RevenueCatEvent } from "../../src/billing/subscription";

const NOW = Date.parse("2026-11-10T12:00:00Z");
const event = (extra: Partial<RevenueCatEvent>): RevenueCatEvent => ({
  type: "INITIAL_PURCHASE",
  app_user_id: "u1",
  product_id: "wina_1team_monthly",
  expiration_at_ms: NOW + 86_400_000,
  event_timestamp_ms: NOW,
  store: "PLAY_STORE",
  ...extra,
});

describe("subscription environment", () => {
  it("records sandbox and production purchases", () => {
    expect(applyEvent(undefined, event({ environment: "SANDBOX" }))?.environment).toBe("sandbox");
    expect(applyEvent(undefined, event({ environment: "PRODUCTION" }))?.environment).toBe("production");
  });

  it("stays unknown when RevenueCat does not say, and keeps the previous value", () => {
    expect(applyEvent(undefined, event({}))).not.toHaveProperty("environment");
    const first = applyEvent(undefined, event({ environment: "SANDBOX" }))!;
    expect(applyEvent(first, event({ type: "RENEWAL", event_timestamp_ms: NOW + 1 }))?.environment).toBe("sandbox");
  });

  it("is read back from the stored document, and ignored when invalid", () => {
    const base = { productId: "wina_1team_monthly", period: "monthly", teamsAllowed: 1, status: "active", expiresAt: { toMillis: () => NOW }, store: "play_store" };
    expect(subscriptionFromDoc({ ...base, environment: "sandbox" })?.environment).toBe("sandbox");
    expect(subscriptionFromDoc({ ...base, environment: "autre" })).not.toHaveProperty("environment");
  });
});
