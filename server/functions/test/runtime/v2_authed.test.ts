import { beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("firebase-functions/logger", () => ({
  debug: vi.fn(),
  error: vi.fn(),
  info: vi.fn(),
  log: vi.fn(),
  warn: vi.fn(),
}));

import * as logger from "firebase-functions/logger";
import { assertAuthed } from "../../src/runtime/v2_authed";

beforeEach(() => {
  vi.mocked(logger.warn).mockClear();
});

describe("assertAuthed", () => {
  it("returns the identity of an authenticated caller", () => {
    const caller = assertAuthed({ data: {}, auth: { uid: "u1", token: { email: "a@b.test" } } } as any);

    expect(caller).toEqual({ uid: "u1", token: { email: "a@b.test" } });
    expect(logger.warn).not.toHaveBeenCalled();
  });

  it("rejects an anonymous caller and logs a structured warning", () => {
    expect(() => assertAuthed({ data: {}, auth: undefined } as any)).toThrowError(/Authentification requise/);

    expect(logger.warn).toHaveBeenCalledWith(
      "access-denied",
      expect.objectContaining({ event: "access-denied", reason: "unauthenticated", uid: undefined }),
    );
  });
});
