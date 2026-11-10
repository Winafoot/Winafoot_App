import { generateKeyPairSync, verify } from "node:crypto";
import { describe, expect, it } from "vitest";
import { groupOfferTags, serviceAccountJwt, type GoogleOffer } from "../../src/billing/google_play";

describe("serviceAccountJwt", () => {
  it("signs an RS256 assertion for the androidpublisher scope", () => {
    const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
    const pem = privateKey.export({ type: "pkcs8", format: "pem" }).toString();
    const jwt = serviceAccountJwt({ client_email: "sa@wina.iam.gserviceaccount.com", private_key: pem }, 1_000);
    const [header, payload, signature] = jwt.split(".");
    expect(JSON.parse(Buffer.from(header, "base64url").toString())).toEqual({ alg: "RS256", typ: "JWT" });
    expect(JSON.parse(Buffer.from(payload, "base64url").toString())).toMatchObject({
      iss: "sa@wina.iam.gserviceaccount.com",
      scope: "https://www.googleapis.com/auth/androidpublisher",
      aud: "https://oauth2.googleapis.com/token",
      iat: 1_000,
      exp: 4_000,
    });
    expect(verify("RSA-SHA256", Buffer.from(`${header}.${payload}`), publicKey, Buffer.from(signature, "base64url"))).toBe(true);
  });
});

describe("groupOfferTags", () => {
  const offer = (productId: string, offerId: string, tags: string[]): GoogleOffer => ({ productId, basePlanId: "monthly", offerId, state: "ACTIVE", tags });

  it("groups offers by tag, alphabetically, ignoring untagged offers", () => {
    const tags = groupOfferTags([offer("a", "o1", ["promo50"]), offer("b", "o2", ["promo50", "autre"]), offer("a", "o3", [])]);
    expect(tags.map((t) => t.tag)).toEqual(["autre", "promo50"]);
    expect(tags[1].offers).toHaveLength(2);
    expect(tags[1].ambiguous).toBe(false);
  });

  it("flags a tag set on two offers of the same subscription", () => {
    const tags = groupOfferTags([offer("a", "o1", ["promo50"]), offer("a", "o2", ["promo50"])]);
    expect(tags[0].ambiguous).toBe(true);
  });
});
