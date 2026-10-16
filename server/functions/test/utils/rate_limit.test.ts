import { describe, expect, it } from "vitest";
import { firestore } from "firebase-admin";
import { consume, consumeAll, enforce, rateLimitKey } from "../../src/utils/rate_limit";

const LIMIT = { limit: 2, windowMs: 1_000 };

describe("consume", () => {
  it("allows up to the limit inside a window, then refuses", async () => {
    expect(await consume("s", "id", LIMIT, 0)).toBe(true);
    expect(await consume("s", "id", LIMIT, 100)).toBe(true);
    expect(await consume("s", "id", LIMIT, 200)).toBe(false);
    expect(await consume("s", "id", LIMIT, 999)).toBe(false);
  });

  it("opens a new window once the previous one has elapsed", async () => {
    await consume("s", "id", LIMIT, 0);
    await consume("s", "id", LIMIT, 1);
    expect(await consume("s", "id", LIMIT, 2)).toBe(false);

    expect(await consume("s", "id", LIMIT, 1_000)).toBe(true);
    expect(await consume("s", "id", LIMIT, 1_001)).toBe(true);
    expect(await consume("s", "id", LIMIT, 1_002)).toBe(false);
  });

  it("keeps identifiers and scopes independent", async () => {
    await consume("s", "a", LIMIT, 0);
    await consume("s", "a", LIMIT, 0);

    expect(await consume("s", "a", LIMIT, 0)).toBe(false);
    expect(await consume("s", "b", LIMIT, 0)).toBe(true);
    expect(await consume("other", "a", LIMIT, 0)).toBe(true);
  });

  it("is atomic: concurrent calls never exceed the limit", async () => {
    const results = await Promise.all(Array.from({ length: 12 }, () => consume("s", "burst", { limit: 3, windowMs: 60_000 })));

    expect(results.filter(Boolean)).toHaveLength(3);
  });

  it("stores no raw identifier (address, IP) and an expiry for the Firestore TTL policy", async () => {
    await consume("reset-ip", "victim@club.test", { limit: 5, windowMs: 60_000 }, 1_000_000);

    const docs = (await firestore().collection("rate_limits").get()).docs;
    expect(docs).toHaveLength(1);
    expect(docs[0].id).not.toContain("victim");
    expect(JSON.stringify(docs[0].data())).not.toContain("victim");
    expect(docs[0].id.startsWith("reset-ip_")).toBe(true);
    expect(docs[0].get("expiresAt").toMillis()).toBe(1_060_000);
  });
});

describe("enforce", () => {
  it("throws resource-exhausted once the limit is reached", async () => {
    await enforce("s", "id", LIMIT);
    await enforce("s", "id", LIMIT);

    await expect(enforce("s", "id", LIMIT)).rejects.toMatchObject({ code: "resource-exhausted" });
  });
});

describe("consumeAll", () => {
  it("counts every limit when all of them pass", async () => {
    expect(await consumeAll([["a", "x", LIMIT], ["b", "x", LIMIT]])).toBe(true);

    expect((await firestore().collection("rate_limits").get()).size).toBe(2);
  });

  it("stops at the first refusal and does not spend the following counters", async () => {
    await consume("a", "x", { limit: 1, windowMs: 60_000 });

    const allowed = await consumeAll([["a", "x", { limit: 1, windowMs: 60_000 }], ["b", "x", LIMIT]]);

    expect(allowed).toBe(false);
    expect((await firestore().collection("rate_limits").doc(rateLimitKey("b", "x")).get()).exists).toBe(false);
  });
});
