import { describe, expect, it } from "vitest";
import { CODE_PATTERN, consumesPromo, endOfDayMs, normalizeCode, rejectionOf, TAG_PATTERN } from "../../src/billing/promo_codes";

const NOW = Date.parse("2026-11-10T12:00:00Z");
const ok = { active: true, expiresAtMs: NOW + 86_400_000, maxUses: 100, uses: 0 };

describe("normalizeCode", () => {
  it("uppercases and strips spaces", () => {
    expect(normalizeCode("  bienvenue 50 ")).toBe("BIENVENUE50");
    expect(CODE_PATTERN.test(normalizeCode("bienvenue50"))).toBe(true);
  });
  it("rejects non-strings and symbols", () => {
    expect(normalizeCode(42)).toBe("");
    expect(CODE_PATTERN.test(normalizeCode("a-b!"))).toBe(false);
  });
});

describe("rejectionOf", () => {
  it("accepts a live code", () => expect(rejectionOf(ok, NOW)).toBeNull());
  it("accepts a code without end date", () => expect(rejectionOf({ ...ok, expiresAtMs: null }, NOW)).toBeNull());
  it("refuses unknown, inactive, expired and exhausted codes", () => {
    expect(rejectionOf(undefined, NOW)).toBe("unknown");
    expect(rejectionOf({ ...ok, active: false }, NOW)).toBe("inactive");
    expect(rejectionOf({ ...ok, expiresAtMs: NOW - 1 }, NOW)).toBe("expired");
    expect(rejectionOf({ ...ok, uses: 100 }, NOW)).toBe("exhausted");
    expect(rejectionOf({ ...ok, maxUses: undefined }, NOW)).toBe("exhausted");
  });
});

describe("offer tag and dates", () => {
  it("accepts Google-style tags only", () => {
    expect(TAG_PATTERN.test("promo50")).toBe(true);
    expect(TAG_PATTERN.test("Promo_50")).toBe(false);
  });
  it("expires at the end of the given day", () => {
    expect(endOfDayMs("2026-12-31")).toBe(Date.parse("2026-12-31T22:59:59Z"));
    expect(Number.isNaN(endOfDayMs("n'importe quoi"))).toBe(true);
  });
});

describe("consumesPromo", () => {
  const base = { app_user_id: "u", event_timestamp_ms: 1 };
  it("counts only a Play intro purchase", () => {
    expect(consumesPromo({ ...base, type: "INITIAL_PURCHASE", store: "PLAY_STORE", period_type: "INTRO" })).toBe(true);
    expect(consumesPromo({ ...base, type: "INITIAL_PURCHASE", store: "PLAY_STORE", period_type: "NORMAL" })).toBe(false);
    expect(consumesPromo({ ...base, type: "INITIAL_PURCHASE", store: "APP_STORE", period_type: "INTRO" })).toBe(false);
    expect(consumesPromo({ ...base, type: "RENEWAL", store: "PLAY_STORE", period_type: "INTRO" })).toBe(false);
  });
});
