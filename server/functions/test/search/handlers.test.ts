import { beforeEach, describe, expect, it, vi } from "vitest";

// Interrupteur modifiable par test : les handlers le lisent à chaque appel.
const flag = vi.hoisted(() => ({ enabled: false }));
vi.mock("../../src/config/algolia", async (importActual) => ({
  ...(await importActual<typeof import("../../src/config/algolia")>()),
  get ALGOLIA_ENABLED() {
    return flag.enabled;
  },
}));

const sync = vi.hoisted(() => ({ syncDocument: vi.fn().mockResolvedValue(undefined) }));
vi.mock("../../src/search/sync", async (importActual) => ({ ...(await importActual<typeof import("../../src/search/sync")>()), syncDocument: sync.syncDocument }));

import onWriteComposition from "../../src/triggers/search/on_write_composition_search";
import onWriteMatch from "../../src/triggers/search/on_write_match_search";
import { ALGOLIA_WRITE_KEY } from "../../src/config/secrets";

/** Un événement dont toute lecture lèverait : prouve qu'un handler inerte ne touche à rien. */
const untouchable = (): any => new Proxy({}, { get: () => { throw new Error("événement lu"); } });
const context = { params: { userId: "u1", docId: "d1" }, eventTime: new Date().toISOString(), eventId: "evt-1" };

beforeEach(() => {
  sync.syncDocument.mockClear();
});

describe.each([
  ["on_write_composition_search", onWriteComposition],
  ["on_write_match_search", onWriteMatch],
])("trigger handler %s", (_name, handler) => {
  it("is inert while ALGOLIA_ENABLED is false: no sync, no secret read, no exception", async () => {
    flag.enabled = false;
    const secret = vi.spyOn(ALGOLIA_WRITE_KEY, "value");

    await expect(handler({ before: untouchable(), after: untouchable() }, context)).resolves.toBeUndefined();

    expect(sync.syncDocument).not.toHaveBeenCalled();
    expect(secret).not.toHaveBeenCalled();
    secret.mockRestore();
  });

  it("delegates to syncDocument once ALGOLIA_ENABLED is true", async () => {
    flag.enabled = true;
    const change = { before: {}, after: {} } as any;

    await handler(change, context);

    expect(sync.syncDocument).toHaveBeenCalledTimes(1);
    expect(sync.syncDocument).toHaveBeenCalledWith(expect.objectContaining({ indexName: expect.any(String) }), change, context);
  });
});
