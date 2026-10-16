import { describe, expect, it } from "vitest";
import { firestore } from "firebase-admin";
import { generateStrongPassword, withAdminLock } from "../../src/callables/admin/_admin_accounts";

describe("generateStrongPassword", () => {
  it("meets the project password policy: upper, lower, digit and special character", () => {
    for (let i = 0; i < 50; i++) {
      const password = generateStrongPassword();

      expect(password).toHaveLength(28);
      expect(password).toMatch(/[A-Z]/);
      expect(password).toMatch(/[a-z]/);
      expect(password).toMatch(/[0-9]/);
      expect(password).toMatch(/[!@#$%^&*\-_=+]/);
    }
  });

  it("never repeats", () => {
    const passwords = new Set(Array.from({ length: 200 }, () => generateStrongPassword()));

    expect(passwords.size).toBe(200);
  });
});

const lockDoc = () => firestore().collection("admin_locks").doc("accounts");

// Deux administrateurs qui se retirent l'un l'autre au même instant passeraient chacun le contrôle
// « il reste un autre administrateur actif » : ce verrou les sérialise.
describe("withAdminLock", () => {
  it("runs the work and releases the lock afterwards", async () => {
    const result = await withAdminLock(async () => "ok");

    expect(result).toBe("ok");
    expect((await lockDoc().get()).exists).toBe(false);
  });

  it("releases the lock when the work throws, and rethrows", async () => {
    await expect(
      withAdminLock(async () => {
        throw new Error("boom");
      }),
    ).rejects.toThrowError("boom");

    expect((await lockDoc().get()).exists).toBe(false);
  });

  it("refuses a second operation while the first one holds the lock", async () => {
    let release!: () => void;
    const holding = withAdminLock(() => new Promise<void>((resolve) => (release = resolve)));
    // Laisse la première opération prendre le verrou.
    await new Promise((resolve) => setTimeout(resolve, 200));

    await expect(withAdminLock(async () => "second")).rejects.toMatchObject({ code: "aborted" });

    release();
    await holding;
    await expect(withAdminLock(async () => "third")).resolves.toBe("third");
  });

  it("takes over a lock that has expired (a crashed instance must not block the accounts)", async () => {
    await lockDoc().set({ holder: "dead", until: firestore.Timestamp.fromMillis(Date.now() - 1000) });

    await expect(withAdminLock(async () => "ok")).resolves.toBe("ok");
  });

  it("does not release a lock it no longer owns", async () => {
    await withAdminLock(async () => {
      // Une autre instance a repris le verrou entre-temps (le premier avait expiré).
      await lockDoc().set({ holder: "someone-else", until: firestore.Timestamp.fromMillis(Date.now() + 60_000) });
    });

    expect((await lockDoc().get()).get("holder")).toBe("someone-else");
  });
});
