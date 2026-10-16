import { describe, expect, it } from "vitest";
import { auth, firestore } from "firebase-admin";
import { seedAdmin, seedCoach } from "../helpers";
import setCoachDisabled from "../../src/callables/admin/set_coach_disabled";

const CALLER = { uid: "admin1", email: "staff@wina.test" };

describe("setCoachDisabled", () => {
  // Sans ce refus, setCoachDisabled contournerait les garde-fous de updateAdmin (dernier administrateur, soi-même).
  it("refuses an administrator account, leaves it enabled, and audits the attempt", async () => {
    const uid = await seedAdmin("boss@wina.test");

    await expect(setCoachDisabled({ uid, disabled: true }, CALLER)).rejects.toMatchObject({
      code: "failed-precondition",
      message: expect.stringMatching(/Administrateurs/),
    });

    expect((await auth().getUser(uid)).disabled).toBe(false);
    const audit = await firestore().collection("admin_audit").where("targetUid", "==", uid).get();
    expect(audit.docs).toHaveLength(1);
    expect(audit.docs[0].get("outcome")).toBe("failure");
  });

  it("disables the Auth user and mirrors the state onto the document", async () => {
    const uid = await seedCoach("off@club.test");

    const result = await setCoachDisabled({ uid, disabled: true }, CALLER);

    expect(result).toEqual({ disabled: true });
    expect((await auth().getUser(uid)).disabled).toBe(true);
    const doc = await firestore().collection("users").doc(uid).get();
    expect(doc.get("disabled")).toBe(true);
    expect(doc.get("disabledAt")).toBeTruthy();
  });

  it("re-enables and clears disabledAt", async () => {
    const uid = await seedCoach("on@club.test");
    await setCoachDisabled({ uid, disabled: true }, CALLER);

    await setCoachDisabled({ uid, disabled: false }, CALLER);

    expect((await auth().getUser(uid)).disabled).toBe(false);
    const doc = await firestore().collection("users").doc(uid).get();
    expect(doc.get("disabled")).toBe(false);
    expect(doc.get("disabledAt")).toBeNull();
  });

  it("preserves the coach's data", async () => {
    const uid = await seedCoach("keep@club.test");
    await firestore().collection("users").doc(uid).collection("players").doc("p1").set({ name: "Zidane" });

    await setCoachDisabled({ uid, disabled: true }, CALLER);

    const player = await firestore().collection("users").doc(uid).collection("players").doc("p1").get();
    expect(player.exists).toBe(true);
  });

  it("records disable and enable as distinct audit actions", async () => {
    const uid = await seedCoach("audit@club.test");
    await setCoachDisabled({ uid, disabled: true }, CALLER);
    await setCoachDisabled({ uid, disabled: false }, CALLER);

    const audit = await firestore().collection("admin_audit").orderBy("at").get();
    expect(audit.docs.map((d) => d.get("action"))).toEqual(["disable", "enable"]);
  });

  it("rejects an unknown account", async () => {
    await expect(setCoachDisabled({ uid: "nope", disabled: true }, CALLER)).rejects.toThrowError();
  });

  it("surfaces a French error and audits the failure when the Firestore mirror is missing", async () => {
    // Compte Auth sans document users/{uid} : le .update() du miroir échoue.
    const { uid } = await auth().createUser({ email: "orphan@club.test" });

    await expect(setCoachDisabled({ uid, disabled: true }, CALLER)).rejects.toThrowError(
      "Le compte a été désactivé mais la fiche coach n'a pas pu être synchronisée, réessayez.",
    );

    expect((await auth().getUser(uid)).disabled).toBe(true);

    const audit = await firestore().collection("admin_audit").where("targetUid", "==", uid).get();
    expect(audit.docs).toHaveLength(1);
    expect(audit.docs[0].get("action")).toBe("disable");
    expect(audit.docs[0].get("outcome")).toBe("failure");
  });
});
