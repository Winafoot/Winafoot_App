import { beforeEach, describe, expect, it } from "vitest";
import { auth, firestore } from "firebase-admin";
import { fakeReq, fakeRes, seedAdmin, seedAppConfig, seedCoach } from "../helpers";
import { LIMITS } from "../../src/config/rate_limits";
import deleteAccountByEmail from "../../src/https_requests/landing_page/delete_account_by_email_secured";

const TOKEN = "ab".repeat(48); // 96 caractères hexadécimaux, comme randomBytes(48).toString("hex")

async function call(body: unknown, method = "POST", ip?: string) {
  const res = fakeRes();
  await deleteAccountByEmail(fakeReq(method, body, undefined, ip), res);
  return res;
}

/** Jeton tel que l'écrit onSendLandingPageMailDeleteAccount (uid absent : jeton sans ce champ). */
async function seedToken(email: string, token = TOKEN, expiresInMs = 3_600_000, uid?: string) {
  await firestore()
    .collection("accountDeletionRequests")
    .doc(token)
    .set({ email, token, ...(uid ? { uid } : {}), expiresAt: firestore.Timestamp.fromMillis(Date.now() + expiresInMs) });
}

beforeEach(async () => {
  await seedAppConfig();
});

// Contrat de la landing (public/confirm-delete.html) : POST { email, token }.
// Le jeton fait foi : l'e-mail du corps est ignoré.
describe("deleteAccountByEmail (secured)", () => {
  it("deletes the account, its whole document tree, archives it and burns the token", async () => {
    const uid = await seedCoach("gone@club.test");
    const userRef = firestore().collection("users").doc(uid);
    await userRef.collection("players").doc("p1").set({ firstName: "Zidane" });
    await userRef.collection("metadata").doc("security").set({ profilCompleted: true });
    await seedToken("gone@club.test");

    const res = await call({ email: "gone@club.test", token: TOKEN });

    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ message: "User deleted successfully" });
    await expect(auth().getUser(uid)).rejects.toThrowError();
    expect((await userRef.get()).exists).toBe(false);
    expect((await userRef.collection("players").get()).empty).toBe(true);
    expect((await userRef.collection("metadata").get()).empty).toBe(true);
    const archived = await firestore().collection("deleted_users").where("email", "==", "gone@club.test").get();
    expect(archived.size).toBe(1);
    expect((await firestore().collection("accountDeletionRequests").doc(TOKEN).get()).exists).toBe(false);
  });

  it("never deletes an administrator account, answers the uniform failure and burns the token", async () => {
    const uid = await seedAdmin("boss@wina.test");
    await seedToken("boss@wina.test", TOKEN, 3_600_000, uid);

    const res = await call({ email: "boss@wina.test", token: TOKEN });

    expect(res.statusCode).toBe(400);
    expect(res.body).toEqual({ message: "Account deletion failed" });
    await expect(auth().getUser(uid)).resolves.toBeTruthy();
    expect((await firestore().collection("deleted_users").where("email", "==", "boss@wina.test").get()).empty).toBe(true);
    expect((await firestore().collection("accountDeletionRequests").doc(TOKEN).get()).exists).toBe(false);
  });

  it("ignores the email of the request: the token alone designates the account", async () => {
    const victim = await seedCoach("victim@club.test");
    const other = await seedCoach("other@club.test");
    await seedToken("victim@club.test");

    await call({ email: "other@club.test", token: TOKEN });

    await expect(auth().getUser(victim)).rejects.toThrowError();
    await expect(auth().getUser(other)).resolves.toBeTruthy();
  });

  it("refuses to reuse a token (single use)", async () => {
    await seedCoach("gone@club.test");
    await seedToken("gone@club.test");
    await call({ token: TOKEN });

    const second = await call({ token: TOKEN });

    expect(second.statusCode).toBe(400);
  });

  it("refuses an expired token and keeps the account", async () => {
    const uid = await seedCoach("alive@club.test");
    await seedToken("alive@club.test", TOKEN, -1_000);

    const res = await call({ token: TOKEN });

    expect(res.statusCode).toBe(400);
    await expect(auth().getUser(uid)).resolves.toBeTruthy();
  });

  it("refuses a well-formed token that was never issued", async () => {
    const uid = await seedCoach("alive@club.test");

    const res = await call({ token: "cd".repeat(48) });

    expect(res.statusCode).toBe(400);
    await expect(auth().getUser(uid)).resolves.toBeTruthy();
  });

  it("answers 400 and deletes nothing when the token names an address with no account", async () => {
    await seedToken("ghost@club.test");

    const res = await call({ token: TOKEN });

    expect(res.statusCode).toBe(400);
    expect((await firestore().collection("deleted_users").get()).empty).toBe(true);
  });

  // Le jeton sert d'identifiant de document Firestore : un format libre permettrait
  // des chemins, des identifiants réservés ou des lectures inattendues.
  it.each([
    ["no body", undefined],
    ["no token", {}],
    ["a non-string token", { token: 42 }],
    ["the literal string undefined", { token: "undefined" }],
    ["a too short token", { token: "abc" }],
    ["a path-like token", { token: "../users/someone" }],
    ["a non-hexadecimal token", { token: "zz".repeat(48) }],
    ["an upper-case token", { token: "AB".repeat(48) }],
  ])("rejects %s with 400 without reading Firestore", async (_label, body) => {
    const uid = await seedCoach("alive@club.test");

    const res = await call(body);

    expect(res.statusCode).toBe(400);
    await expect(auth().getUser(uid)).resolves.toBeTruthy();
  });

  // Le jeton est lié au compte qui l'a demandé : si l'adresse change de titulaire
  // entre la demande et la confirmation, il ne supprime pas le nouveau titulaire.
  it("refuses a token whose account no longer holds the address (address reassigned)", async () => {
    const a = await seedCoach("a@club.test");
    await seedToken("a@club.test", TOKEN, 3_600_000, a);
    await auth().updateUser(a, { email: "a-new@club.test" });
    const b = await seedCoach("a@club.test"); // un autre coach reprend l'ancienne adresse

    const res = await call({ token: TOKEN });

    expect(res.statusCode).toBe(400);
    await expect(auth().getUser(b)).resolves.toBeTruthy();
    await expect(auth().getUser(a)).resolves.toBeTruthy();
  });

  it("deletes the account the token was issued for", async () => {
    const uid = await seedCoach("gone@club.test");
    await seedToken("gone@club.test", TOKEN, 3_600_000, uid);

    const res = await call({ token: TOKEN });

    expect(res.statusCode).toBe(200);
    await expect(auth().getUser(uid)).rejects.toThrowError();
  });

  // Mutation : sans TOKEN_PATTERN, un jeton mal formé n'est refusé que parce que le
  // document n'existe pas. On prouve que le format est contrôlé AVANT la lecture
  // en plaçant de VRAIS documents sous des identifiants mal formés.
  it.each(["undefined", "abc", "AB".repeat(48), "zz".repeat(48)])(
    "rejects the malformed token %s even when a valid request document sits under that id",
    async (id) => {
      const uid = await seedCoach("alive@club.test");
      await seedToken("alive@club.test", id, 3_600_000, uid);

      const res = await call({ token: id });

      expect(res.statusCode).toBe(400);
      await expect(auth().getUser(uid)).resolves.toBeTruthy();
      expect((await firestore().collection("accountDeletionRequests").doc(id).get()).exists).toBe(true);
    },
  );

  it("never answers with an internal error message", async () => {
    const res = await call({ token: "cd".repeat(48) });

    expect(res.body).toEqual({ message: "Account deletion failed" });
  });

  it.each(["GET", "PUT"])("refuses %s with 405", async (method) => {
    const res = await call({ token: TOKEN }, method);

    expect(res.statusCode).toBe(405);
  });
});

describe("deleteAccountByEmail — rate limiting", () => {
  it(`refuses an IP after ${LIMITS.deleteConfirmIp.limit} attempts with 429, without consuming a valid token`, async () => {
    const uid = await seedCoach("alive@club.test");
    await seedToken("alive@club.test", TOKEN, 3_600_000, uid);
    for (let i = 0; i < LIMITS.deleteConfirmIp.limit; i++) await call({ token: "cd".repeat(48) }, "POST", "198.51.100.1");

    const res = await call({ token: TOKEN }, "POST", "198.51.100.1");

    expect(res.statusCode).toBe(429);
    await expect(auth().getUser(uid)).resolves.toBeTruthy();
    expect((await firestore().collection("accountDeletionRequests").doc(TOKEN).get()).exists).toBe(true);
  });

  it("does not block another IP", async () => {
    const uid = await seedCoach("gone@club.test");
    await seedToken("gone@club.test", TOKEN, 3_600_000, uid);
    for (let i = 0; i < LIMITS.deleteConfirmIp.limit + 1; i++) await call({ token: "cd".repeat(48) }, "POST", "198.51.100.1");

    expect((await call({ token: TOKEN }, "POST", "198.51.100.2")).statusCode).toBe(200);
  });
});
