import { describe, expect, it, vi } from "vitest";

// Interrupteur coupé, figé ici : l'état inerte reste prouvé quelle que soit la valeur du dépôt (true).
vi.mock("../src/config/algolia", async (importActual) => ({ ...(await importActual<typeof import("../src/config/algolia")>()), ALGOLIA_ENABLED: false }));

import * as callables from "../src/callables/index";
import * as triggers from "../src/triggers/index";

// Tant que ALGOLIA_ENABLED est false, aucun secret n'est lié : un déploiement n'exige ni ALGOLIA_WRITE_KEY ni ALGOLIA_SEARCH_KEY.
describe("Algolia switched off: no secret bound", () => {
  it.each(["onWriteCompositionSearch", "onWriteMatchSearch"])("trigger %s binds no secret", (name) => {
    const endpoint = (triggers as Record<string, any>)[name].__endpoint;

    expect(endpoint.secretEnvironmentVariables ?? []).toEqual([]);
    // Le reste du câblage ne dépend pas de l'interrupteur.
    expect(endpoint.eventTrigger.retry).toBe(true);
    expect(endpoint.maxInstances).toBe(1);
  });

  it("callable getSearchKey binds no secret", () => {
    expect((callables.getSearchKey as any).__endpoint.secretEnvironmentVariables ?? []).toEqual([]);
  });
});
