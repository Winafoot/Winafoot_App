import { beforeEach, describe, expect, it, vi } from "vitest";
import { auth } from "firebase-admin";

vi.mock("firebase-functions/logger", () => ({
  debug: vi.fn(),
  error: vi.fn(),
  info: vi.fn(),
  log: vi.fn(),
  warn: vi.fn(),
}));

import * as logger from "firebase-functions/logger";
import { assertAdmin, adminCallableAdapter } from "../../src/runtime/v2_admin";

beforeEach(() => {
  vi.mocked(logger.warn).mockClear();
});

function request(auth: unknown): any {
  return { data: {}, auth };
}

/** Vrai jeton d'identité émis par l'émulateur Auth, pour exercer verifyIdToken sans simulacre. */
async function realAdminRequest(claims: Record<string, unknown> = { admin: true }, emailVerified = true) {
  const { uid } = await auth().createUser({ email: "boss@club.test", emailVerified });
  await auth().setCustomUserClaims(uid, claims);
  const custom = await auth().createCustomToken(uid);
  const res = await fetch(
    `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake`,
    { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ token: custom, returnSecureToken: true }) },
  );
  const rawToken: string = ((await res.json()) as { idToken: string }).idToken;
  const token = await auth().verifyIdToken(rawToken);
  return { uid, req: request({ uid, token, rawToken }) };
}

describe("assertAdmin", () => {
  it("rejects an unauthenticated caller", async () => {
    await expect(assertAdmin(request(undefined))).rejects.toThrowError(/administrateurs/i);
  });

  it("rejects an authenticated caller without the admin claim", async () => {
    await expect(assertAdmin(request({ uid: "u1", token: { email: "a@b.test" } }))).rejects.toThrowError(/administrateurs/i);
  });

  it("rejects a caller whose admin claim is the string \"true\"", async () => {
    await expect(assertAdmin(request({ uid: "u1", token: { admin: "true" } }))).rejects.toThrowError(/administrateurs/i);
  });

  it("accepts a caller with a valid admin token and returns its identity", async () => {
    const { uid, req } = await realAdminRequest();

    expect(await assertAdmin(req)).toEqual({ uid, email: "boss@club.test" });
  });

  it("rejects an admin whose e-mail address is not verified, and logs the reason", async () => {
    const { uid, req } = await realAdminRequest({ admin: true }, false);

    await expect(assertAdmin(req)).rejects.toMatchObject({ code: "permission-denied" });
    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ reason: "email-not-verified", uid }));
  });

  it("rejects a token whose email_verified claim is not exactly true", async () => {
    await expect(assertAdmin(request({ uid: "u1", token: { admin: true, email_verified: "true" }, rawToken: "x" }))).rejects.toMatchObject({
      code: "permission-denied",
    });
    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ reason: "email-not-verified" }));
  });

  it("rejects a verified admin call that carries no raw token", async () => {
    await expect(assertAdmin(request({ uid: "u1", token: { admin: true, email_verified: true } }))).rejects.toMatchObject({ code: "permission-denied" });
    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ reason: "token-revoked" }));
  });

  it("rejects an admin whose refresh tokens were revoked", async () => {
    const { uid, req } = await realAdminRequest();
    // validSince est en secondes : sans cette pause, jeton et révocation tombent dans la même seconde.
    await new Promise((resolve) => setTimeout(resolve, 1100));
    await auth().revokeRefreshTokens(uid);

    await expect(assertAdmin(req)).rejects.toMatchObject({ code: "permission-denied" });
    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ reason: "token-revoked", uid }));
  });

  it("rejects an admin whose account was disabled", async () => {
    const { uid, req } = await realAdminRequest();
    await auth().updateUser(uid, { disabled: true });

    await expect(assertAdmin(req)).rejects.toMatchObject({ code: "permission-denied" });
    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ reason: "token-revoked", uid }));
  });

  it("logs a structured warning for a refusal, with ids only", async () => {
    await expect(assertAdmin(request({ uid: "u1", token: { email: "a@b.test" } }))).rejects.toThrow();

    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ event: "access-denied", reason: "not-admin", uid: "u1" }));
    expect(JSON.stringify(vi.mocked(logger.warn).mock.calls)).not.toContain("a@b.test");
  });

  it("logs an unauthenticated refusal without a uid", async () => {
    await expect(assertAdmin(request(undefined))).rejects.toThrow();

    expect(logger.warn).toHaveBeenCalledWith("access-denied", expect.objectContaining({ reason: "unauthenticated", uid: undefined }));
  });
});

describe("adminCallableAdapter", () => {
  // `modulePath` points at a module that does not exist on disk. If the admin
  // guard ran after the `require()`, this would fail with a module-resolution
  // error instead of `permission-denied` -- so a `permission-denied` rejection
  // here proves the guard runs first and the handler module is never reached
  // by an unauthorised caller.
  it("rejects a caller without the admin claim before requiring the handler module", async () => {
    const adapter = adminCallableAdapter("handlers/does-not-exist");

    await expect(adapter(request({ uid: "u1", token: {} }))).rejects.toMatchObject({
      code: "permission-denied",
    });
  });

  it("rejects an unauthenticated caller before requiring the handler module", async () => {
    const adapter = adminCallableAdapter("handlers/does-not-exist");

    await expect(adapter(request(undefined))).rejects.toMatchObject({
      code: "permission-denied",
    });
  });

  // Not covered: the authorised pass-through path (assertAdmin succeeds, then
  // `adminCallableAdapter` does `require(fullPath).default` and invokes the
  // handler with `(data, caller)`). Exercising that would need either a real
  // compiled handler module on disk for it to `require()` at runtime, or an
  // injection seam (an overridable loader/require) added to the adapter
  // purely so the test could stub it. The task explicitly rules out
  // restructuring `adminCallableAdapter`'s signature or adding seams just for
  // testability, and `require()`-ing a TypeScript handler under Vitest is not
  // practical. So the pass-through wiring is left unverified by this suite;
  // it is exercised end-to-end once the four admin endpoints call through it.
});
