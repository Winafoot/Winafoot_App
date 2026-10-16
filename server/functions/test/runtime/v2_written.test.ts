import { beforeEach, describe, expect, it } from "vitest";
import { documentWrittenAdapter } from "../../src/runtime/v2";

// Chemin relatif à `src/` (loadDefaultHandler le résout depuis src/runtime/..).
const HANDLER = "../test/runtime/fixtures/capture_handler.cjs";

const calls = () => (globalThis as any).__capturedHandlerCalls as any[][];

function event(data: unknown): any {
  return { data, params: { userId: "u1", docId: "d1" }, time: "2026-10-14T10:00:00.000Z", id: "evt-42" };
}

beforeEach(() => {
  (globalThis as any).__capturedHandlerCalls = [];
});

describe("documentWrittenAdapter", () => {
  it("does nothing when the event carries no data", async () => {
    await documentWrittenAdapter(HANDLER)(event(undefined));

    expect(calls()).toHaveLength(0);
  });

  it("hands {before, after} and {params, eventTime, eventId} to the handler on creation", async () => {
    const before = { exists: false };
    const after = { exists: true, id: "d1" };

    await documentWrittenAdapter(HANDLER)(event({ before, after }));

    expect(calls()).toEqual([
      [{ before, after }, { params: { userId: "u1", docId: "d1" }, eventTime: "2026-10-14T10:00:00.000Z", eventId: "evt-42" }],
    ]);
    expect(calls()[0][0].before).toBe(before);
    expect(calls()[0][0].after).toBe(after);
  });

  it("forwards a deletion (after does not exist)", async () => {
    const before = { exists: true };
    const after = { exists: false };

    await documentWrittenAdapter(HANDLER)(event({ before, after }));

    expect(calls()).toHaveLength(1);
    expect(calls()[0][0]).toEqual({ before, after });
  });

  it("forwards an update", async () => {
    const before = { exists: true, v: 1 };
    const after = { exists: true, v: 2 };

    await documentWrittenAdapter(HANDLER)(event({ before, after }));

    expect(calls()[0][0]).toEqual({ before, after });
  });

  it("falls back to empty params like the sibling adapters", async () => {
    await documentWrittenAdapter(HANDLER)({ data: { before: {}, after: {} }, time: "t", id: "i" } as any);

    expect(calls()[0][1]).toEqual({ params: {}, eventTime: "t", eventId: "i" });
  });
});
