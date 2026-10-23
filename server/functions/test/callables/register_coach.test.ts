import { afterEach, describe, expect, it, vi } from "vitest";
import { auth, firestore } from "firebase-admin";

import registerCoach from "../../src/callables/auth/register_coach";

const PASSWORD = "Wina!2345";

function payload(overrides: Record<string, unknown> = {}) {
  return { email: "Nouveau@Club.test", password: PASSWORD, firstname: "Ibrahim", acceptedCgu: true, ...overrides } as any;
}

async function codeOf(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (e: any) {
    return e.code;
  }
  return "no-error";
}

afterEach(() => {
  vi.restoreAllMocks();
});

describe("registerCoach", () => {
  it("creates the Auth user and the three documents the app expects", async () => {
    const { uid } = await registerCoach(payload());

    const record = await auth().getUser(uid);
    expect(record.email).toBe("nouveau@club.test");
    expect(record.emailVerified).toBe(false);
    expect(record.disabled).toBe(false);

    const userDoc = await firestore().collection("users").doc(uid).get();
    expect(userDoc.get("id")).toBe(uid);
    expect(userDoc.get("email")).toBe("nouveau@club.test");
    expect(userDoc.get("firstname")).toBe("Ibrahim");
    expect(userDoc.get("coachName")).toBe("Ibrahim");
    expect(userDoc.get("userType")).toBe("client");
    expect(userDoc.get("cguAccepted")).toBe(true);
    expect(userDoc.get("profilCompleted")).toBe(false);
    // Le format du club se choisit à la page 2 : jamais posé ici.
    expect(userDoc.get("teamFormat")).toBeUndefined();
    // Sans ce marqueur, onCreateUser envoie l'e-mail de bienvenue.
    expect(userDoc.get("invitedByAdmin")).toBeUndefined();

    const security = await firestore().collection("users").doc(uid).collection("metadata").doc("security").get();
    expect(security.get("profilCompleted")).toBe(false);
    expect(security.get("cguAccepted")).toBe(true);
    expect(security.get("isFirstLogin")).toBe(true);

    const metadata = await firestore().collection("users").doc(uid).collection("metadata").doc("metadata").get();
    expect(metadata.exists).toBe(true);
    expect(metadata.get("cguAccepted")).toBe(true);
  });

  it("trims the first name", async () => {
    const { uid } = await registerCoach(payload({ email: "trim@club.test", firstname: "  Zinedine  " }));
    const userDoc = await firestore().collection("users").doc(uid).get();
    expect(userDoc.get("firstname")).toBe("Zinedine");
  });

  it("refuses an address that already has an account", async () => {
    await registerCoach(payload({ email: "doublon@club.test" }));
    expect(await codeOf(registerCoach(payload({ email: "DOUBLON@club.test" })))).toBe("already-exists");
  });

  it.each(["", "pas-un-mail", "a@b", "a b@club.test"])("refuses the invalid address %j", async (email) => {
    expect(await codeOf(registerCoach(payload({ email })))).toBe("invalid-argument");
  });

  it("refuses the technical address of team accounts", async () => {
    expect(await codeOf(registerCoach(payload({ email: "u15-lyon@equipes.wina.invalid" })))).toBe("invalid-argument");
  });

  it.each(["court1!","sansmajuscule1!", "SANSMINUSCULE1!", "SansChiffre!!", "SansSpecial12"])(
    "refuses the password %j that breaks the policy",
    async (password) => {
      expect(await codeOf(registerCoach(payload({ email: "mdp@club.test", password })))).toBe("invalid-argument");
    },
  );

  it("refuses a missing or blank first name", async () => {
    expect(await codeOf(registerCoach(payload({ email: "p1@club.test", firstname: "   " })))).toBe("invalid-argument");
    expect(await codeOf(registerCoach(payload({ email: "p2@club.test", firstname: undefined })))).toBe("invalid-argument");
    expect(await codeOf(registerCoach(payload({ email: "p3@club.test", firstname: 42 })))).toBe("invalid-argument");
  });

  it("refuses when the CGU are not accepted", async () => {
    expect(await codeOf(registerCoach(payload({ email: "cgu1@club.test", acceptedCgu: false })))).toBe("failed-precondition");
    expect(await codeOf(registerCoach(payload({ email: "cgu2@club.test", acceptedCgu: "true" })))).toBe("failed-precondition");
    expect(await codeOf(registerCoach(payload({ email: "cgu3@club.test", acceptedCgu: undefined })))).toBe("failed-precondition");
  });

  it("creates nothing when validation fails", async () => {
    await codeOf(registerCoach(payload({ email: "rien@club.test", acceptedCgu: false })));
    await expect(auth().getUserByEmail("rien@club.test")).rejects.toMatchObject({ code: "auth/user-not-found" });
  });

  it("leaves no account behind when writing the documents fails, so the address can be reused", async () => {
    vi.spyOn(firestore.DocumentReference.prototype, "set").mockRejectedValueOnce(new Error("boom"));

    expect(await codeOf(registerCoach(payload({ email: "rollback@club.test" })))).toBe("internal");
    await expect(auth().getUserByEmail("rollback@club.test")).rejects.toMatchObject({ code: "auth/user-not-found" });

    vi.restoreAllMocks();
    const { uid } = await registerCoach(payload({ email: "rollback@club.test" }));
    expect((await auth().getUser(uid)).email).toBe("rollback@club.test");
  });
});
