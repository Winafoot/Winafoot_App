import { describe, expect, it } from "vitest";
import { buildConfigUpdate } from "../../src/callables/admin/_app_config";

const invalid = (changes: unknown) => expect(() => buildConfigUpdate(changes)).toThrowError(expect.objectContaining({ code: "invalid-argument" }));

describe("buildConfigUpdate", () => {
  it("writes valid values, trimming plain fields and keeping HTML as typed", () => {
    expect(
      buildConfigUpdate({ contactEmail: " support@winafoot.fr ", "mail.from": "noreply@winafoot.fr", instagramUrl: "https://www.instagram.com/wina.foot", cgvu: "<p>Texte </p>\n" }),
    ).toEqual({
      set: { contactEmail: "support@winafoot.fr", "mail.from": "noreply@winafoot.fr", instagramUrl: "https://www.instagram.com/wina.foot", cgvu: "<p>Texte </p>\n" },
      remove: [],
    });
  });

  it("removes an optional field set to an empty value", () => {
    expect(buildConfigUpdate({ salesEmail: "  ", youtubeUrl: "", about: "" })).toEqual({ set: {}, remove: ["salesEmail", "youtubeUrl", "about"] });
  });

  it("refuses to empty a required field", () => {
    invalid({ contactEmail: "" });
    invalid({ "mail.from": "   " });
  });

  it("refuses fields outside the whitelist, including inherited object keys", () => {
    invalid({ appHash: "x" });
    invalid({ maintenance: "true" });
    invalid({ baseUrl: "https://x.fr" });
    invalid({ constructor: "x" });
    invalid({ "mail.apiKey": "x" });
  });

  it("refuses malformed values", () => {
    invalid({ contactEmail: "pas-un-mail" });
    invalid({ salesEmail: "a@b" });
    invalid({ instagramUrl: "http://www.instagram.com/x" });
    invalid({ tiktokUrl: "javascript:alert(1)" });
    invalid({ contactPhone: "abc" });
    invalid({ "mail.fromName": "x".repeat(81) });
    invalid({ contactEmail: 42 });
  });

  it("refuses an empty or non-object request, and writes nothing when one field is wrong", () => {
    invalid({});
    invalid(null);
    invalid([]);
    invalid({ contactEmail: "ok@winafoot.fr", instagramUrl: "pas une url" });
  });
});
