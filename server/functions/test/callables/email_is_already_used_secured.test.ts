import { describe, expect, it } from "vitest";
import { seedCoach } from "../helpers";
import emailIsAlreadyUsed from "../../src/callables/auth/email_is_already_used_secured";

// « Mot de passe oublié » (paquet kosmos_auth) appelle ce callable AVANT connexion et
// s'arrête si la réponse n'est pas `true` : il reste exporté, et sa réponse ne dépend
// pas de l'existence d'un compte.
describe("emailIsAlreadyUsed (secured)", () => {
  it("answers true for an address that has an account", async () => {
    await seedCoach("known@club.test");

    expect(await emailIsAlreadyUsed({ email: "known@club.test" })).toBe(true);
  });

  it("answers exactly the same for an address that has none", async () => {
    expect(await emailIsAlreadyUsed({ email: "ghost@club.test" })).toBe(true);
  });

  it("never throws nor returns an error object on malformed input", async () => {
    expect(await emailIsAlreadyUsed(undefined as any)).toBe(true);
    expect(await emailIsAlreadyUsed({} as any)).toBe(true);
  });
});
