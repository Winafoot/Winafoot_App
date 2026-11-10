import { describe, expect, it } from "vitest";
import { applyEvent, type RevenueCatEvent } from "../../src/billing/subscription";
import { subscriptionFromDoc, subscriptionToDoc } from "../../src/billing/store";

const NOW = Date.UTC(2026, 5, 1);
const event = (over: Partial<RevenueCatEvent>): RevenueCatEvent => ({
  type: "INITIAL_PURCHASE",
  app_user_id: "owner",
  product_id: "wina_1team_monthly",
  period_type: "NORMAL",
  expiration_at_ms: NOW + 30 * 86_400_000,
  event_timestamp_ms: NOW,
  store: "APP_STORE",
  ...over,
});

describe("introOffer", () => {
  it("is absent for a regular purchase", () => {
    expect(applyEvent(undefined, event({}))).not.toHaveProperty("introOffer");
  });

  it("records the first purchase made with an introductory offer, with its code when known", () => {
    expect(applyEvent(undefined, event({ period_type: "INTRO", offer_code: "WINA10" }))?.introOffer).toEqual({ code: "WINA10", atMs: NOW });
    expect(applyEvent(undefined, event({ period_type: "INTRO" }))?.introOffer).toEqual({ code: null, atMs: NOW });
  });

  it("records a purchase carrying an offer code even outside the INTRO period type", () => {
    expect(applyEvent(undefined, event({ offer_code: "FREEMONTH" }))?.introOffer).toEqual({ code: "FREEMONTH", atMs: NOW });
  });

  it("keeps the first offer through later events", () => {
    const first = applyEvent(undefined, event({ period_type: "INTRO", offer_code: "WINA10" }))!;
    const renewal = applyEvent(first, event({ type: "RENEWAL", period_type: "NORMAL", event_timestamp_ms: NOW + 40 * 86_400_000 }))!;
    expect(renewal.introOffer).toEqual({ code: "WINA10", atMs: NOW });
  });

  it("survives the Firestore round trip", () => {
    const sub = applyEvent(undefined, event({ period_type: "INTRO", offer_code: "WINA10" }))!;
    expect(subscriptionFromDoc(subscriptionToDoc(sub))?.introOffer).toEqual({ code: "WINA10", atMs: NOW });
    expect(subscriptionToDoc({ ...sub, introOffer: undefined })).not.toHaveProperty("introOffer");
  });
});
