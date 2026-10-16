import { describe, expect, it } from "vitest";
import * as server from "../../src/callables/admin/_password_policy";
import { assertPasswordPolicy, passwordPolicyViolations, PASSWORD_SPECIAL_CHARACTERS } from "../../src/callables/admin/_password_policy";
import * as backOffice from "../../../cms/src/password_policy";

// Politique du projet (Firebase Authentication) : 6 caractères au moins, une minuscule, une majuscule,
// un chiffre et un caractère spécial de la liste autorisée.
describe("password policy", () => {
  it.each(["Wina!2345", "aB3$xy", "Zz9-zz", "Éte9a'B"])("accepts %s", (password) => {
    expect(passwordPolicyViolations(password)).toEqual([]);
    expect(() => assertPasswordPolicy(password)).not.toThrow();
  });

  it.each([
    ["aB3$x", "au moins 6 caractères"],
    ["AB3$XYZ", "une minuscule"],
    ["ab3$xyz", "une majuscule"],
    ["aBc$xyz", "un chiffre"],
    ["aB3xyzw", "un caractère spécial"],
    // `=`, `+`, l'espace et les lettres accentuées ne comptent pas comme caractères spéciaux pour Firebase.
    ["aB3=xyz", "un caractère spécial"],
    ["aB3+xyz", "un caractère spécial"],
    ["aB3 xyz", "un caractère spécial"],
  ])("rejects %s (%s missing)", (password, missing) => {
    expect(passwordPolicyViolations(password)).toContain(missing);
    expect(() => assertPasswordPolicy(password)).toThrowError(expect.objectContaining({ code: "invalid-argument" }));
  });

  it("lists every missing requirement at once", () => {
    expect(passwordPolicyViolations("abc")).toEqual(["au moins 6 caractères", "une majuscule", "un chiffre", "un caractère spécial"]);
  });

  it("rejects a password that is not a string", () => {
    expect(() => assertPasswordPolicy(123456)).toThrowError(expect.objectContaining({ code: "invalid-argument" }));
    expect(() => assertPasswordPolicy(undefined)).toThrowError(expect.objectContaining({ code: "invalid-argument" }));
  });

  it("accepts each special character allowed by the project policy", () => {
    for (const c of PASSWORD_SPECIAL_CHARACTERS) {
      expect(passwordPolicyViolations(`aB3${c}xy`)).toEqual([]);
    }
  });
});

// Le back-office (cms/src/password_policy.ts) applique la même règle avant l'appel : une divergence
// laisserait passer un mot de passe que createCoach refuse, ou l'inverse.
describe("back-office mirror of the password policy", () => {
  it("has the same limits and special characters", () => {
    expect(backOffice.PASSWORD_MIN_LENGTH).toBe(server.PASSWORD_MIN_LENGTH);
    expect(backOffice.PASSWORD_MAX_LENGTH).toBe(server.PASSWORD_MAX_LENGTH);
    expect(backOffice.PASSWORD_SPECIAL_CHARACTERS).toBe(server.PASSWORD_SPECIAL_CHARACTERS);
  });

  it.each(["", "abc", "Wina!2345", "wina!2345", "Wina=2345", "Éte9a'B", "aB3 xyz", "x".repeat(4097)])("answers like the server for %j", (password) => {
    expect(backOffice.passwordPolicyViolations(password)).toEqual(server.passwordPolicyViolations(password));
  });
});
