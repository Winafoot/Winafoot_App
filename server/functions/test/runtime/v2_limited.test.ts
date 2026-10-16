import { describe, expect, it } from "vitest";
import { limitedAuthedCallableAdapter, limitedPublicCallableAdapter } from "../../src/runtime/v2_limited";

// `modulePath` désigne un module qui n'existe pas : une erreur « Cannot find module »
// prouve que l'appel a PASSÉ la garde et atteint le chargement du handler, alors que
// `resource-exhausted` / `unauthenticated` prouvent qu'elle l'a arrêté avant.
const PASSED = /Cannot find module/;

function request(options: { ip?: string; uid?: string } = {}): any {
  return {
    data: {},
    auth: options.uid ? { uid: options.uid, token: {} } : undefined,
    rawRequest: { headers: options.ip ? { "x-forwarded-for": `6.6.6.6, ${options.ip}` } : {} },
  };
}

describe("limitedPublicCallableAdapter", () => {
  const limits = { scope: "pub", perIp: { limit: 2, windowMs: 60_000 } };

  it("refuses an IP once it exceeds its limit, before loading the handler", async () => {
    const adapter = limitedPublicCallableAdapter("handlers/does-not-exist", limits);

    await expect(adapter(request({ ip: "198.51.100.1" }))).rejects.toThrow(PASSED);
    await expect(adapter(request({ ip: "198.51.100.1" }))).rejects.toThrow(PASSED);
    await expect(adapter(request({ ip: "198.51.100.1" }))).rejects.toMatchObject({ code: "resource-exhausted" });
  });

  it("does not block another IP", async () => {
    const adapter = limitedPublicCallableAdapter("handlers/does-not-exist", limits);
    for (let i = 0; i < 3; i++) await adapter(request({ ip: "198.51.100.1" })).catch(() => undefined);

    await expect(adapter(request({ ip: "198.51.100.2" }))).rejects.toThrow(PASSED);
  });

  it("cannot be dodged by a client-supplied X-Forwarded-For prefix", async () => {
    const adapter = limitedPublicCallableAdapter("handlers/does-not-exist", limits);
    for (const forged of ["1.1.1.1", "2.2.2.2", "3.3.3.3"]) {
      await adapter({ data: {}, rawRequest: { headers: { "x-forwarded-for": `${forged}, 198.51.100.1` } } } as any).catch(() => undefined);
    }

    await expect(adapter(request({ ip: "198.51.100.1" }))).rejects.toMatchObject({ code: "resource-exhausted" });
  });
});

describe("limitedAuthedCallableAdapter", () => {
  const limits = { scope: "auth", perUid: { limit: 1, windowMs: 60_000 } };

  it("rejects an anonymous caller before counting anything or loading the handler", async () => {
    const adapter = limitedAuthedCallableAdapter("handlers/does-not-exist", limits);
    for (let i = 0; i < 5; i++) {
      await expect(adapter(request())).rejects.toMatchObject({ code: "unauthenticated" });
    }

    await expect(adapter(request({ uid: "u1" }))).rejects.toThrow(PASSED); // aucun appel anonyme n'a consommé le quota
  });

  it("limits each uid independently", async () => {
    const adapter = limitedAuthedCallableAdapter("handlers/does-not-exist", limits);

    await expect(adapter(request({ uid: "u1" }))).rejects.toThrow(PASSED);
    await expect(adapter(request({ uid: "u1" }))).rejects.toMatchObject({ code: "resource-exhausted" });
    await expect(adapter(request({ uid: "u2" }))).rejects.toThrow(PASSED);
  });

  it("can combine a per-IP and a per-uid limit", async () => {
    const adapter = limitedAuthedCallableAdapter("handlers/does-not-exist", {
      scope: "both",
      perIp: { limit: 1, windowMs: 60_000 },
      perUid: { limit: 5, windowMs: 60_000 },
    });

    await expect(adapter(request({ uid: "u1", ip: "198.51.100.1" }))).rejects.toThrow(PASSED);
    await expect(adapter(request({ uid: "u2", ip: "198.51.100.1" }))).rejects.toMatchObject({ code: "resource-exhausted" });
  });
});
