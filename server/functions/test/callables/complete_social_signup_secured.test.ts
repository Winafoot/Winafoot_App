import { describe, expect, it } from "vitest";
import { auth, firestore } from "firebase-admin";
import { seedCoach } from "../helpers";
import completeSocialSignup from "../../src/callables/auth/complete_social_signup_secured";

function caller(uid: string) {
  return { uid, token: {} };
}

/** Compte Auth rattaché à un fournisseur « Se connecter avec… », comme après une première connexion. */
async function seedSocial(email: string, providerId = "google.com", displayName?: string): Promise<string> {
  const record = await auth().createUser({ email, emailVerified: true, displayName });
  await auth().updateUser(record.uid, { providerToLink: { providerId, uid: `${providerId}-${record.uid}` } });
  return record.uid;
}

const userDoc = (uid: string) => firestore().collection("users").doc(uid);

describe("completeSocialSignup (secured)", () => {
  it("creates the three documents the app expects for a Google account", async () => {
    const uid = await seedSocial("Coach@Club.test", "google.com", "Ibrahim Diallo");

    expect(await completeSocialSignup({ acceptedCgu: true }, caller(uid))).toEqual({ created: true });

    const user = await userDoc(uid).get();
    expect(user.get("id")).toBe(uid);
    expect(user.get("email")).toBe("coach@club.test");
    expect(user.get("firstname")).toBe("Ibrahim");
    expect(user.get("coachName")).toBe("Ibrahim");
    expect(user.get("userType")).toBe("client");
    expect(user.get("cguAccepted")).toBe(true);
    expect(user.get("profilCompleted")).toBe(false);
    expect(user.get("invitedByAdmin")).toBeUndefined();

    const security = await userDoc(uid).collection("metadata").doc("security").get();
    expect(security.get("profilCompleted")).toBe(false);
    expect(security.get("isFirstLogin")).toBe(true);
    expect((await userDoc(uid).collection("metadata").doc("metadata").get()).get("cguAccepted")).toBe(true);
  });

  it("accepts an Apple account and prefers the first name sent by the client", async () => {
    const uid = await seedSocial("relay@privaterelay.test", "apple.com", "Nom Affiché");

    await completeSocialSignup({ acceptedCgu: true, firstname: "  Karim " }, caller(uid));

    expect((await userDoc(uid).get()).get("firstname")).toBe("Karim");
  });

  it("falls back to a generic first name when none is usable", async () => {
    const uid = await seedSocial("anon@club.test", "apple.com");

    await completeSocialSignup({ acceptedCgu: true, firstname: "<script>" }, caller(uid));

    expect((await userDoc(uid).get()).get("firstname")).toBe("Coach");
  });

  it("is idempotent: an account that already has a profile is left untouched", async () => {
    const uid = await seedSocial("coach@club.test");
    await completeSocialSignup({ acceptedCgu: true, firstname: "Ibrahim" }, caller(uid));
    await userDoc(uid).update({ teamName: "FC Test" });

    expect(await completeSocialSignup({ acceptedCgu: true, firstname: "Autre" }, caller(uid))).toEqual({ created: false });

    const user = await userDoc(uid).get();
    expect(user.get("firstname")).toBe("Ibrahim");
    expect(user.get("teamName")).toBe("FC Test");
  });

  it("refuses to create a profile when the CGU are not accepted", async () => {
    const uid = await seedSocial("coach@club.test");

    await expect(completeSocialSignup({}, caller(uid))).rejects.toMatchObject({ code: "failed-precondition" });
    await expect(completeSocialSignup({ acceptedCgu: "true" }, caller(uid))).rejects.toMatchObject({ code: "failed-precondition" });
    expect((await userDoc(uid).get()).exists).toBe(false);
  });

  it("refuses an e-mail / password account: it registers through registerCoach", async () => {
    const uid = await seedCoach("coach@club.test");
    await userDoc(uid).delete();

    await expect(completeSocialSignup({ acceptedCgu: true }, caller(uid))).rejects.toMatchObject({ code: "failed-precondition" });
    expect((await userDoc(uid).get()).exists).toBe(false);
  });

  it("writes the address of the Auth account, never one sent by the client", async () => {
    const uid = await seedSocial("vrai@club.test");

    await completeSocialSignup({ acceptedCgu: true, email: "autre@club.test" } as any, caller(uid));

    expect((await userDoc(uid).get()).get("email")).toBe("vrai@club.test");
  });

  it("refuses the technical address of the linked team accounts", async () => {
    const uid = await seedSocial("equipe@equipes.wina.invalid");

    await expect(completeSocialSignup({ acceptedCgu: true }, caller(uid))).rejects.toMatchObject({ code: "failed-precondition" });
  });
});
