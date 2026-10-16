import { describe, expect, it } from "vitest";
import { auth } from "firebase-admin";
import phoneIsAlreadyUsed from "../../src/callables/auth/phone_is_already_used_secured";

// Le paquet kosmos_auth (phone_login_page, set_phone_page, change_phone_page,
// create_account_page) appelle ce callable : il reste déployé. Public (avant
// connexion), sa réponse ne dépend pas de l'existence d'un compte.
describe("phoneIsAlreadyUsed (secured)", () => {
  it("answers true for a number that has an account", async () => {
    await auth().createUser({ phoneNumber: "+33600000001" });

    expect(await phoneIsAlreadyUsed({ phone: "+33600000001" })).toBe(true);
  });

  it("answers exactly the same for a number that has none", async () => {
    expect(await phoneIsAlreadyUsed({ phone: "+33600000002" })).toBe(true);
  });

  it("never throws nor returns an error object on malformed input", async () => {
    expect(await phoneIsAlreadyUsed(undefined as any)).toBe(true);
    expect(await phoneIsAlreadyUsed({ phone: "pas un numéro" })).toBe(true);
  });
});
