import { describe, expect, it, vi } from "vitest";

// firebase-functions v7 n'expose PAS enforceAppCheck : ni `__endpoint` ni `__trigger` ne le portent (c'est un
// réglage du gestionnaire de requête, pas du manifeste de déploiement). La seule observation possible est
// d'intercepter les options passées à onCall quand callables/index.ts se charge.
const optionsOf = vi.hoisted(() => new Map<unknown, Record<string, unknown>>());

vi.mock("firebase-functions/v2/https", async (importActual) => {
  const actual = await importActual<typeof import("firebase-functions/v2/https")>();
  return {
    ...actual,
    onCall: (opts: Record<string, unknown>, handler: never) => {
      const callable = (actual.onCall as (o: unknown, h: unknown) => unknown)(opts, handler);
      optionsOf.set(callable, opts);
      return callable;
    },
  };
});

import * as callables from "../src/callables/index";

// App Check : seuls l'app et le back-office d'origine appellent ces fonctions. Le framework
// ne vérifie rien ici (les tests des handlers les appellent en direct) : on verrouille donc la configuration.
describe("App Check on the callables", () => {
  const exported = Object.entries(callables);

  it("sees every callable export", () => {
    expect(exported).toHaveLength(17);
  });

  it.each(exported)("%s enforces App Check", (_name, callable) => {
    expect(optionsOf.get(callable)?.enforceAppCheck).toBe(true);
  });

  // Consommer le jeton exige des jetons à usage unique côté client (limitedUseAppCheckToken) : le paquet
  // kosmos_auth, qui appelle sendResetPassword et deleteAccount, n'en demande pas. Voir le README, section « App Check ».
  it.each(exported)("%s does not consume App Check tokens", (_name, callable) => {
    expect(optionsOf.get(callable)?.consumeAppCheckToken).toBeFalsy();
  });
});
