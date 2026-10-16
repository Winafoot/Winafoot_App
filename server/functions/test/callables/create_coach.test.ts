import { beforeEach, describe, expect, it, vi } from "vitest";
import { auth, firestore } from "firebase-admin";

vi.mock("../../src/utils/send_email", () => ({
  sendEmail: vi.fn().mockResolvedValue({}),
}));

import { sendEmail } from "../../src/utils/send_email";
import { seedAppConfig } from "../helpers";
import createCoach from "../../src/callables/admin/create_coach";

const CALLER = { uid: "admin1", email: "staff@wina.test" };
const PASSWORD = "Wina!2345";

beforeEach(async () => {
  vi.mocked(sendEmail).mockClear();
  vi.mocked(sendEmail).mockResolvedValue({} as any);
  await seedAppConfig();
});

describe("createCoach", () => {
  it("creates the Auth user, both documents and an audit entry", async () => {
    const { uid } = await createCoach(
      { email: "Coach@Club.test", password: PASSWORD, firstname: "Ibrahim", teamFormat: 11 },
      CALLER,
    );

    const record = await auth().getUser(uid);
    expect(record.email).toBe("coach@club.test");
    expect(record.disabled).toBe(false);
    // Compte provisionné par l'admin : prêt à se connecter, adresse vérifiée.
    expect(record.emailVerified).toBe(true);

    const userDoc = await firestore().collection("users").doc(uid).get();
    expect(userDoc.get("email")).toBe("coach@club.test");
    expect(userDoc.get("firstname")).toBe("Ibrahim");
    expect(userDoc.get("userType")).toBe("client");
    expect(userDoc.get("invitedByAdmin")).toBe(true);
    expect(userDoc.get("createdByAdmin")).toBe("admin1");
    expect(userDoc.get("disabled")).toBe(false);

    const audit = await firestore().collection("admin_audit").get();
    expect(audit.size).toBe(1);
    expect(audit.docs[0].get("outcome")).toBe("success");
  });

  it.each([5, 8, 11])("stores teamFormat %i on the user document", async (teamFormat) => {
    const { uid } = await createCoach({ email: `f${teamFormat}@club.test`, password: PASSWORD, teamFormat }, CALLER);

    const userDoc = await firestore().collection("users").doc(uid).get();
    expect(userDoc.get("teamFormat")).toBe(teamFormat);
  });

  it("stores the optional profile fields under the names the app reads", async () => {
    const { uid } = await createCoach(
      {
        email: "profil@club.test",
        password: PASSWORD,
        firstname: "Zinedine Zidane",
        teamFormat: 8,
        teamName: "  FC Wina  ",
        category: "u13",
        division: "r1",
      },
      CALLER,
    );

    const data = (await firestore().collection("users").doc(uid).get()).data()!;
    expect(data.teamName).toBe("FC Wina");
    expect(data.category).toBe("u13");
    expect(data.division).toBe("r1");
    // Le nom du coach reste porté par `firstname` (pré-remplit coachName côté
    // app) : pas de doublon, et le profil reste à finaliser par le coach.
    expect(data.firstname).toBe("Zinedine Zidane");
    expect(data).not.toHaveProperty("coachName");
    expect(data.profilCompleted).toBe(false);
    expect(data.invitedByAdmin).toBe(true);
  });

  it("omits the optional profile fields when they are not provided", async () => {
    const { uid } = await createCoach(
      { email: "min@club.test", password: PASSWORD, teamFormat: 11, teamName: "  ", category: "", division: undefined },
      CALLER,
    );

    const data = (await firestore().collection("users").doc(uid).get()).data()!;
    expect(data).not.toHaveProperty("teamName");
    expect(data).not.toHaveProperty("category");
    expect(data).not.toHaveProperty("division");
  });

  it("accepts every category and division key of the contract", async () => {
    const categories = [
      "u6", "u7", "u8", "u9", "u10", "u11", "u12", "u13", "u14", "u15", "u16", "u17", "u18", "u19",
      "seniors", "veterans",
    ];
    const divisions = ["r1", "r2", "r3", "d1", "d2", "d3", "d4", "d5"];
    for (const [i, category] of categories.entries()) {
      const division = divisions[i % divisions.length];
      const { uid } = await createCoach(
        { email: `k${i}@club.test`, password: PASSWORD, teamFormat: 11, category, division },
        CALLER,
      );
      const userDoc = await firestore().collection("users").doc(uid).get();
      expect(userDoc.get("category")).toBe(category);
      expect(userDoc.get("division")).toBe(division);
    }
  });

  it.each([
    ["missing", undefined],
    ["unsupported", 7],
    ["zero", 0],
    ["a string", "11"],
    ["null", null],
  ])("rejects a teamFormat that is %s, creating nothing", async (_label, teamFormat) => {
    await expect(
      createCoach({ email: "nofmt@club.test", password: PASSWORD, teamFormat } as any, CALLER),
    ).rejects.toMatchObject({ code: "invalid-argument", message: expect.stringMatching(/format/i) });

    await expect(auth().getUserByEmail("nofmt@club.test")).rejects.toThrow();
    const users = await firestore().collection("users").get();
    expect(users.size).toBe(0);
  });

  it.each([
    ["category", { category: "u20" }, /catégorie/i],
    ["division", { division: "d1 " }, /division/i],
    ["teamName", { teamName: "x".repeat(41) }, /équipe/i],
  ])("rejects an invalid %s, creating nothing", async (_field, extra, message) => {
    await expect(
      createCoach({ email: "bad@club.test", password: PASSWORD, teamFormat: 11, ...extra }, CALLER),
    ).rejects.toMatchObject({ code: "invalid-argument", message: expect.stringMatching(message) });

    await expect(auth().getUserByEmail("bad@club.test")).rejects.toThrow();
    const users = await firestore().collection("users").get();
    expect(users.size).toBe(0);
  });

  it.each([
    ["an object", { a: 1 }],
    ["an array", ["FC", "Wina"]],
    ["a number", 12345],
    ["zero", 0],
    ["a boolean", true],
  ])("rejects a teamName that is %s instead of coercing it, creating nothing", async (_label, teamName) => {
    await expect(
      createCoach({ email: "badtype@club.test", password: PASSWORD, teamFormat: 11, teamName } as any, CALLER),
    ).rejects.toMatchObject({ code: "invalid-argument", message: expect.stringMatching(/équipe/i) });

    await expect(auth().getUserByEmail("badtype@club.test")).rejects.toThrow();
    const users = await firestore().collection("users").get();
    expect(users.size).toBe(0);
  });

  it("accepts a team name of exactly the maximum length", async () => {
    const teamName = "x".repeat(40);
    const { uid } = await createCoach(
      { email: "long@club.test", password: PASSWORD, teamFormat: 11, teamName },
      CALLER,
    );
    const userDoc = await firestore().collection("users").doc(uid).get();
    expect(userDoc.get("teamName")).toBe(teamName);
  });

  it("writes metadata/security so the app does not hang on the loader", async () => {
    const { uid } = await createCoach({ email: "coach2@club.test", password: PASSWORD, teamFormat: 11 }, CALLER);

    const security = await firestore().collection("users").doc(uid).collection("metadata").doc("security").get();
    expect(security.exists).toBe(true);
    expect(security.get("profilCompleted")).toBe(false);
    expect(security.get("cguAccepted")).toBe(false);
    expect(security.get("isFirstLogin")).toBe(true);
  });

  it("seeds metadata/metadata so the Kosmos packages can update it on login", async () => {
    // Sans ce document, acceptCgu (et d'autres écritures des packages) font un
    // update() sur un doc inexistant -> permission-denied -> connexion bloquée.
    const { uid } = await createCoach({ email: "coach2b@club.test", password: PASSWORD, teamFormat: 11 }, CALLER);

    const meta = await firestore().collection("users").doc(uid).collection("metadata").doc("metadata").get();
    expect(meta.exists).toBe(true);
    expect(meta.get("cguAccepted")).toBe(false);
    expect(meta.get("enablePushNotification")).toBe(false);
  });

  it("does not send any email", async () => {
    await createCoach({ email: "coach3@club.test", password: PASSWORD, firstname: "Léa", teamFormat: 11 }, CALLER);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("rejects a malformed email address", async () => {
    await expect(
      createCoach({ email: "not-an-email", password: PASSWORD, teamFormat: 11 }, CALLER),
    ).rejects.toThrowError(/invalide/i);
  });

  // L'Admin SDK n'applique pas la politique du projet : sans ce contrôle, le coach recevrait un mot de
  // passe refusé à sa première connexion.
  it.each(["wina!2345", "WINA!2345", "Wina!abcd", "Wina2345", "Wina=2345"])(
    "rejects %s, which breaks the project password policy, creating nothing",
    async (password) => {
      await expect(createCoach({ email: "policy@club.test", password, teamFormat: 11 }, CALLER)).rejects.toMatchObject({
        code: "invalid-argument",
        message: expect.stringMatching(/mot de passe/i),
      });

      await expect(auth().getUserByEmail("policy@club.test")).rejects.toThrow();
      expect((await firestore().collection("users").get()).size).toBe(0);
    },
  );

  it("rejects a password shorter than the minimum, creating nothing", async () => {
    await expect(
      createCoach({ email: "weak@club.test", password: "abc", teamFormat: 11 }, CALLER),
    ).rejects.toThrowError(/mot de passe/i);

    await expect(auth().getUserByEmail("weak@club.test")).rejects.toThrow();
    const users = await firestore().collection("users").get();
    expect(users.size).toBe(0);
  });

  it("rejects a duplicate address without touching the existing account", async () => {
    await createCoach({ email: "dup@club.test", password: PASSWORD, teamFormat: 11 }, CALLER);
    await expect(
      createCoach({ email: "dup@club.test", password: PASSWORD, teamFormat: 11 }, CALLER),
    ).rejects.toThrowError(/existe d/i);

    const users = await firestore().collection("users").get();
    expect(users.size).toBe(1);
  });

  it("rolls back the Auth user and documents when a Firestore write fails", async () => {
    // Force l'échec de la première écriture Firestore (dans le bloc de
    // compensation) pour vérifier qu'aucun compte orphelin ne subsiste.
    const spy = vi.spyOn(firestore.Timestamp, "now").mockImplementationOnce(() => {
      throw new Error("firestore boom");
    });

    try {
      await expect(
        createCoach({ email: "rollback@club.test", password: PASSWORD, teamFormat: 11 }, CALLER),
      ).rejects.toThrowError(/échoué/i);
    } finally {
      spy.mockRestore();
    }

    await expect(auth().getUserByEmail("rollback@club.test")).rejects.toThrow();
    const users = await firestore().collection("users").get();
    expect(users.size).toBe(0);

    const audit = await firestore().collection("admin_audit").get();
    expect(audit.size).toBe(1);
    expect(audit.docs[0].get("outcome")).toBe("failure");
  });
});
