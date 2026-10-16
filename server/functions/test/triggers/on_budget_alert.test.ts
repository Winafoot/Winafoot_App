import { beforeEach, describe, expect, it, vi } from "vitest";
import { firestore } from "firebase-admin";

vi.mock("firebase-functions/logger", () => ({ debug: vi.fn(), error: vi.fn(), info: vi.fn(), log: vi.fn(), warn: vi.fn() }));

import * as logger from "firebase-functions/logger";
import { onBudgetAlertHandler, parseBudgetMessage, type BudgetGuardDeps } from "../../src/triggers/billing/on_budget_alert";

const ATTRIBUTES = { billingAccountId: "000000-000000-000000", budgetId: "budget-1", schemaVersion: "1.0" };

/** Notification telle que l'envoie Cloud Billing (champs de la documentation « Notification format »). */
const notification = (overrides: Record<string, unknown> = {}) => ({
  budgetDisplayName: "Wina",
  costAmount: 140.321,
  costIntervalStart: "2026-10-01T07:00:00Z",
  budgetAmount: 152.557,
  budgetAmountType: "SPECIFIED_AMOUNT",
  currencyCode: "EUR",
  ...overrides,
});

const event = (json: unknown, attributes: Record<string, string> = ATTRIBUTES): any => ({ data: { message: { json, attributes } } });

function fakeDeps(ok = true): BudgetGuardDeps & { fetch: ReturnType<typeof vi.fn> } {
  return {
    projectId: () => "demo-wina",
    accessToken: async () => "token-de-test",
    fetch: vi.fn().mockResolvedValue({ ok, status: ok ? 200 : 403, text: async () => "PERMISSION_DENIED" }),
  };
}

async function maintenance(): Promise<unknown> {
  return (await firestore().doc("app_config/metadata").get()).get("maintenance");
}

beforeEach(() => {
  vi.mocked(logger.error).mockClear();
  vi.mocked(logger.warn).mockClear();
});

describe("onBudgetAlert", () => {
  it("does nothing while the spend stays within the budget", async () => {
    const deps = fakeDeps();

    await onBudgetAlertHandler(event(notification({ costAmount: 152.557 })), deps);

    expect(deps.fetch).not.toHaveBeenCalled();
    expect(await maintenance()).toBeUndefined();
  });

  it("switches the app to maintenance and detaches billing once the budget is exceeded", async () => {
    const deps = fakeDeps();

    await onBudgetAlertHandler(event(notification({ costAmount: 160, alertThresholdExceeded: 1.0 })), deps);

    expect(await maintenance()).toBe(true);
    expect(deps.fetch).toHaveBeenCalledTimes(1);
    const [url, init] = deps.fetch.mock.calls[0];
    expect(url).toBe("https://cloudbilling.googleapis.com/v1/projects/demo-wina/billingInfo");
    expect(init).toMatchObject({ method: "PUT", body: JSON.stringify({ billingAccountName: "" }) });
    expect(init.headers.Authorization).toBe("Bearer token-de-test");
    expect(logger.warn).toHaveBeenCalledWith(expect.stringMatching(/facturation détachée/));
  });

  it("logs a refused detachment", async () => {
    const deps = fakeDeps(false);

    await onBudgetAlertHandler(event(notification({ costAmount: 160 })), deps);

    expect(logger.error).toHaveBeenCalledWith(expect.stringMatching(/échec du détachement de la facturation : 403/));
  });

  // Provenance du message non contrôlable par l'événement : sa forme l'est. Un message qui n'est pas
  // une notification de budget ne coupe rien.
  it.each([
    ["amounts sent as strings", notification({ costAmount: "999", budgetAmount: "1" }), ["costAmount", "budgetAmount"]],
    ["a missing cost", notification({ costAmount: undefined }), ["costAmount"]],
    ["a non-finite amount", notification({ costAmount: Number.POSITIVE_INFINITY }), ["costAmount"]],
    ["a missing currency", notification({ currencyCode: undefined }), ["currencyCode"]],
    ["a threshold that is not a number", notification({ costAmount: 500, alertThresholdExceeded: "1.0" }), ["alertThresholdExceeded"]],
    ["a JSON array", [notification({ costAmount: 500 })], ["données (objet JSON attendu)"]],
    ["no data", null, ["données (objet JSON attendu)"]],
  ])("ignores and logs a message with %s", async (_label, json, problems) => {
    const deps = fakeDeps();

    await onBudgetAlertHandler(event(json), deps);

    expect(deps.fetch).not.toHaveBeenCalled();
    expect(await maintenance()).toBeUndefined();
    expect(logger.error).toHaveBeenCalledWith(`[onBudgetAlert] message ignoré : ce n'est pas une notification de budget (${problems.join(", ")})`);
  });

  it("ignores a message without the Cloud Billing attributes", async () => {
    const deps = fakeDeps();

    await onBudgetAlertHandler(event(notification({ costAmount: 500 }), {}), deps);

    expect(deps.fetch).not.toHaveBeenCalled();
    expect(logger.error).toHaveBeenCalledWith(expect.stringMatching(/attribut billingAccountId, attribut budgetId/));
  });

  it("ignores a message whose data is not valid JSON", async () => {
    const deps = fakeDeps();
    const message = {
      attributes: ATTRIBUTES,
      get json(): unknown {
        throw new Error("Unable to parse Pub/Sub message data as JSON");
      },
    };

    await onBudgetAlertHandler({ data: { message } } as any, deps);

    expect(deps.fetch).not.toHaveBeenCalled();
    expect(logger.error).toHaveBeenCalledWith(expect.stringMatching(/JSON illisible/));
  });
});

describe("parseBudgetMessage", () => {
  it("accepts a notification without the optional thresholds", () => {
    expect(parseBudgetMessage({ json: notification(), attributes: ATTRIBUTES })).toEqual({ notification: notification() });
  });

  it("accepts the forecast threshold", () => {
    expect(parseBudgetMessage({ json: notification({ forecastThresholdExceeded: 0.2 }), attributes: ATTRIBUTES })).toHaveProperty("notification");
  });
});
