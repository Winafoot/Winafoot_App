import { beforeEach, describe, expect, it, vi } from "vitest";
import { auth } from "firebase-admin";

// Ce fichier teste le drapeau ACTIVÉ ; la valeur par défaut (false) est couverte par v2_admin.test.ts.
vi.mock("../../src/config/admin_mfa", () => ({ REQUIRE_ADMIN_MFA: true }));

vi.mock("firebase-functions/logger", () => ({
  debug: vi.fn(),
  error: vi.fn(),
  info: vi.fn(),
  log: vi.fn(),
  warn: vi.fn(),
}));

import * as logger from "firebase-functions/logger";
import { assertAdmin } from "../../src/runtime/v2_admin";

beforeEach(() => {
  vi.mocked(logger.warn).mockClear();
});

/** Vrai jeton de l'émulateur Auth ; `secondFactor` simule la présence du second facteur dans les claims lus. */
async function adminRequest(secondFactor?: string) {
  const { uid } = await auth().createUser({ email: "boss@club.test", emailVerified: true });
  await auth().setCustomUserClaims(uid, { admin: true });
  const custom = await auth().createCustomToken(uid);
  const res = await fetch(
    `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake`,
    { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ token: custom, returnSecureToken: true }) },
  );
  const rawToken: string = ((await res.json()) as { idToken: string }).idToken;
  const decoded = await auth().verifyIdToken(rawToken);
  const token = secondFactor === undefined ? decoded : { ...decoded, firebase: { ...decoded.firebase, sign_in_second_factor: secondFactor } };
  return { uid, req: { data: {}, auth: { uid, token, rawToken } } as any };
}

describe("assertAdmin avec le second facteur obligatoire", () => {
  it("refuse un administrateur connecté sans second facteur et le journalise", async () => {
    const { uid, req } = await adminRequest();

    await expect(assertAdmin(req)).rejects.toMatchObject({ code: "permission-denied" });
    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ reason: "mfa-required", uid }));
  });

  it("accepte un administrateur dont la connexion a validé un code TOTP", async () => {
    const { uid, req } = await adminRequest("totp");

    expect(await assertAdmin(req)).toEqual({ uid, email: "boss@club.test" });
  });

  it("refuse toujours un non-administrateur, même avec un second facteur", async () => {
    await expect(
      assertAdmin({ data: {}, auth: { uid: "u1", token: { firebase: { sign_in_second_factor: "totp" } } } } as any),
    ).rejects.toMatchObject({ code: "permission-denied" });
    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ reason: "not-admin" }));
  });

  it("n'accepte pas un second facteur qui n'est pas une chaîne non vide", async () => {
    const { req } = await adminRequest("");

    await expect(assertAdmin(req)).rejects.toMatchObject({ code: "permission-denied" });
  });
});
