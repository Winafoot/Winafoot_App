import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import * as callables from "../src/callables/index";
import * as httpRequests from "../src/https_requests/index";
import * as triggers from "../src/triggers/index";
import { BUDGET_GUARD_SERVICE_ACCOUNT, FUNCTIONS_SERVICE_ACCOUNT } from "../src/config/service_accounts";

// Comptes d'exécution dédiés : toutes les fonctions sur FUNCTIONS_SERVICE_ACCOUNT (options globales),
// sauf le coupe-circuit budgétaire, seul à pouvoir détacher la facturation.
describe("service accounts", () => {
  it("are dedicated accounts of the project, not a default account", () => {
    expect(FUNCTIONS_SERVICE_ACCOUNT).toBe("wina-functions@wina-c4c4a.iam.gserviceaccount.com");
    expect(BUDGET_GUARD_SERVICE_ACCOUNT).toBe("wina-budget-guard@wina-c4c4a.iam.gserviceaccount.com");
  });

  it("are set for every function through the global options of src/index.ts", () => {
    const entry = readFileSync(join(__dirname, "../src/index.ts"), "utf8");
    expect(entry).toMatch(/setGlobalOptions\(\{[^}]*serviceAccount: FUNCTIONS_SERVICE_ACCOUNT,/);
    expect(entry).not.toMatch(/appspot\.gserviceaccount\.com/);
  });

  it("gives onBudgetAlert its own account", () => {
    expect((triggers as Record<string, any>).onBudgetAlert.__endpoint.serviceAccountEmail).toBe(BUDGET_GUARD_SERVICE_ACCOUNT);
  });

  // Une autre fonction sur le compte du coupe-circuit pourrait détacher la facturation.
  it.each(
    [...Object.entries(callables), ...Object.entries(httpRequests), ...Object.entries(triggers)].filter(([name]) => name !== "onBudgetAlert"),
  )("%s keeps the global account", (_name, fn) => {
    // Sans option propre, le manifeste porte une valeur « réinitialiser » (pas une adresse) : le compte
    // vient alors des options globales.
    expect(typeof (fn as any).__endpoint.serviceAccountEmail).not.toBe("string");
  });
});
