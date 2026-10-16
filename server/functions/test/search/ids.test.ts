import { createHash } from "node:crypto";
import { describe, expect, it } from "vitest";
import { objectId, ownerKey } from "../../src/search/ids";

const sha256 = (value: string) => createHash("sha256").update(value).digest("hex");

describe("ownerKey", () => {
  it("is the sha256 hex of the uid, and stable", () => {
    expect(ownerKey("uid-A")).toBe(sha256("uid-A"));
    expect(ownerKey("uid-A")).toBe(ownerKey("uid-A"));
  });

  it("differs from one uid to another", () => {
    expect(ownerKey("uid-A")).not.toBe(ownerKey("uid-B"));
  });

  it("never carries the uid in clear", () => {
    expect(ownerKey("uid-A")).not.toContain("uid-A");
    expect(ownerKey("uid-A")).toMatch(/^[0-9a-f]{64}$/);
  });
});

describe("objectId", () => {
  it("is the sha256 hex of uid/docId, and stable", () => {
    expect(objectId("uid-A", "doc1")).toBe(sha256("uid-A/doc1"));
    expect(objectId("uid-A", "doc1")).toBe(objectId("uid-A", "doc1"));
  });

  it("differs per document and per owner", () => {
    expect(objectId("uid-A", "doc1")).not.toBe(objectId("uid-A", "doc2"));
    expect(objectId("uid-A", "doc1")).not.toBe(objectId("uid-B", "doc1"));
  });

  it("never carries the uid or the docId in clear", () => {
    const id = objectId("uid-A", "doc1");
    expect(id).not.toContain("uid-A");
    expect(id).not.toContain("doc1");
    expect(id).not.toBe(ownerKey("uid-A"));
  });
});
