import { describe, expect, it } from "vitest";
import { isFirstPayment, isTrialReminderDue, trialReminderWindow } from "../../src/billing/billing_mail";
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
const trial: SubscriptionData = { ...active, status: "trial", trialEndMs: NOW + 30 * HOUR, expiresAtMs: NOW + 30 * HOUR };
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

describe("isTrialReminderDue", () => {
  it("rappelle un essai qui se termine dans 24 à 48 h", () => {
    expect(isTrialReminderDue(trial, NOW, false)).toBe(true);
  });
  it("ne rappelle pas deux fois", () => {
    expect(isTrialReminderDue(trial, NOW, true)).toBe(false);
  });
  it("ne rappelle pas un essai qui finit dans moins de 24 h (trop tard pour résilier sur l'App Store)", () => {
    expect(isTrialReminderDue({ ...trial, trialEndMs: NOW + 10 * HOUR }, NOW, false)).toBe(false);
  });
  it("ne rappelle pas un essai qui finit dans plus de 48 h", () => {
    expect(isTrialReminderDue({ ...trial, trialEndMs: NOW + 60 * HOUR }, NOW, false)).toBe(false);
  });
  it("ne rappelle pas un essai résilié : il n'y aura pas de prélèvement", () => {
    expect(isTrialReminderDue({ ...trial, autoRenew: false }, NOW, false)).toBe(false);
    expect(isTrialReminderDue({ ...trial, autoRenew: true }, NOW, false)).toBe(true);
  });
  it("ne rappelle pas un abonnement déjà payant", () => {
    expect(isTrialReminderDue(active, NOW, false)).toBe(false);
  });
  it("la fenêtre fait 24 h de large : chaque essai y passe une fois par jour de passage", () => {
    const { fromMs, toMs } = trialReminderWindow(NOW);
    expect(toMs - fromMs).toBe(24 * HOUR);
  });
});
