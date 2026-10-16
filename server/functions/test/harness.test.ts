import { describe, expect, it } from "vitest";
import { auth, firestore } from "firebase-admin";

describe("test harness", () => {
  it("reaches the Firestore emulator and is reset between tests", async () => {
    await firestore().collection("harness").doc("a").set({ ok: true });
    const snap = await firestore().collection("harness").doc("a").get();
    expect(snap.get("ok")).toBe(true);
  });

  it("reaches the Auth emulator", async () => {
    const user = await auth().createUser({ email: "harness@example.test" });
    expect(user.uid).toBeTruthy();
    const fetched = await auth().getUserByEmail("harness@example.test");
    expect(fetched.uid).toBe(user.uid);
  });

  it("starts from a clean Firestore", async () => {
    const snap = await firestore().collection("harness").doc("a").get();
    expect(snap.exists).toBe(false);
  });
});
