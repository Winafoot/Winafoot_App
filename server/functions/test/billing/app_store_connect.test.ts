import { generateKeyPairSync, createPublicKey, verify } from "node:crypto";
import { describe, expect, it } from "vitest";
import { appleToken, currentPrice, discountedPrice, normalizePem, pickPricePoint } from "../../src/billing/app_store_connect";

describe("discountedPrice", () => {
  it("applies the percentage and rounds to the cent", () => {
    expect(discountedPrice(9.99, 10)).toBe(8.99);
    expect(discountedPrice(4.99, 10)).toBe(4.49);
  });
});

describe("pickPricePoint", () => {
  const points = [
    { id: "a", price: 7.99 },
    { id: "b", price: 8.99 },
    { id: "c", price: 9.99 },
  ];

  it("picks the Apple price tier closest to the target", () => {
    expect(pickPricePoint(points, 8.99)?.id).toBe("b");
    expect(pickPricePoint(points, 8.4)?.id).toBe("b");
  });

  it("returns nothing without any price tier", () => {
    expect(pickPricePoint([], 8.99)).toBeUndefined();
  });
});

describe("appleToken", () => {
  it("is an ES256 JWT carrying the key id, issuer and audience", () => {
    const { privateKey, publicKey } = generateKeyPairSync("ec", { namedCurve: "prime256v1" });
    const pem = privateKey.export({ type: "pkcs8", format: "pem" }).toString();
    const [header, payload, signature] = appleToken("KEY123", "issuer-1", pem, 1_000).split(".");

    expect(JSON.parse(Buffer.from(header, "base64url").toString())).toEqual({ alg: "ES256", kid: "KEY123", typ: "JWT" });
    expect(JSON.parse(Buffer.from(payload, "base64url").toString())).toEqual({ iss: "issuer-1", iat: 1_000, exp: 1_600, aud: "appstoreconnect-v1" });
    expect(
      verify("sha256", Buffer.from(`${header}.${payload}`), { key: createPublicKey(publicKey), dsaEncoding: "ieee-p1363" }, Buffer.from(signature, "base64url")),
    ).toBe(true);
  });
});

describe("currentPrice", () => {
  const now = new Date("2026-06-01");

  it("takes the latest price already in force and ignores future ones", () => {
    expect(
      currentPrice(
        [
          { startDate: null, price: 9.99 },
          { startDate: "2026-03-01", price: 10.99 },
          { startDate: "2026-09-01", price: 12.99 },
        ],
        now,
      ),
    ).toBe(10.99);
  });

  it("returns nothing when no price has started", () => {
    expect(currentPrice([{ startDate: "2026-09-01", price: 12.99 }], now)).toBeUndefined();
  });
});

describe("normalizePem", () => {
  const { privateKey } = generateKeyPairSync("ec", { namedCurve: "prime256v1" });
  const pem = privateKey.export({ type: "pkcs8", format: "pem" }).toString();

  it.each([
    ["with literal \\n", (p: string) => p.trim().replace(/\n/g, "\\n")],
    ["on a single line", (p: string) => p.trim().replace(/\n/g, " ")],
    ["without BEGIN/END lines", (p: string) => p.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "")],
  ])("rebuilds a readable key pasted %s", (_name, mangle) => {
    expect(() => appleToken("K", "I", normalizePem(mangle(pem)))).not.toThrow();
  });
});
