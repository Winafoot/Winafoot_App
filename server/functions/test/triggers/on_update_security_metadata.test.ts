import { describe, expect, it } from "vitest";
import { firestore } from "firebase-admin";
import onUpdateSecurityMetadata from "../../src/triggers/user/on_update_security_metadata";

async function change(uid: string, before: unknown, after: unknown) {
  const ref = firestore().collection("users").doc(uid).collection("metadata").doc("security");
  await ref.set({ profilCompleted: before });
  const beforeSnap = await ref.get();
  await ref.set({ profilCompleted: after });
  const afterSnap = await ref.get();
  return { before: beforeSnap, after: afterSnap };
}

describe("onUpdateSecurityMetadata", () => {
  it("copies profilCompleted onto the root user document", async () => {
    await firestore().collection("users").doc("c1").set({ email: "a@b.test", profilCompleted: false });

    await onUpdateSecurityMetadata(await change("c1", false, true) as any, { params: { userId: "c1" } });

    const doc = await firestore().collection("users").doc("c1").get();
    expect(doc.get("profilCompleted")).toBe(true);
  });

  it("does nothing when the value is unchanged", async () => {
    await firestore().collection("users").doc("c2").set({ email: "a@b.test", profilCompleted: false, marker: 1 });

    await onUpdateSecurityMetadata(await change("c2", true, true) as any, { params: { userId: "c2" } });

    const doc = await firestore().collection("users").doc("c2").get();
    expect(doc.get("profilCompleted")).toBe(false);
    expect(doc.get("marker")).toBe(1);
  });

  it("tolerates a missing root document", async () => {
    await expect(
      onUpdateSecurityMetadata(await change("ghost", false, true) as any, { params: { userId: "ghost" } })
    ).resolves.not.toThrow();
  });
});
