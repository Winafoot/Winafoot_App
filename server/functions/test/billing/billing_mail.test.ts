import { describe, expect, it } from "vitest";
import { isFirstPayment } from "../../src/billing/billing_mail";
import type { RevenueCatEvent, SubscriptionData } from "../../src/billing/subscription";

const HOUR = 3600_000;
const NOW = Date.UTC(2026, 9, 27, 8, 0);

const active: SubscriptionData = {
  productId: "wina_2teams_monthly",
  period: "monthly",
  teamsAllowed: 2,
  status: "active",
  trialEndMs: null,
  expiresAtMs: NOW + 30 * 24 * HOUR,
  store: "play_store",
  lastEventMs: 1,
};
const trial: SubscriptionData = { ...active, status: "trial", trialEndMs: NOW + 30 * HOUR, expiresAtMs: NOW + 30 * HOUR }; // essai déjà en cours à la date de la bascule
const event = (type: string, period_type?: string): RevenueCatEvent => ({ type, app_user_id: "u", event_timestamp_ms: 2, period_type });

describe("isFirstPayment", () => {
  it("confirme un achat direct payant", () => {
    expect(isFirstPayment(undefined, active, event("INITIAL_PURCHASE", "NORMAL"))).toBe(true);
  });
  it("ne confirme pas le début d'un essai", () => {
    expect(isFirstPayment(undefined, trial, event("INITIAL_PURCHASE", "TRIAL"))).toBe(false);
  });
  it("confirme le passage de l'essai à l'abonnement payant", () => {
    expect(isFirstPayment(trial, active, event("RENEWAL", "NORMAL"))).toBe(true);
  });
  it("ne confirme pas un renouvellement ordinaire (le store envoie son reçu)", () => {
    expect(isFirstPayment(active, active, event("RENEWAL", "NORMAL"))).toBe(false);
  });
});
