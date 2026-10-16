import { HttpsError } from "../../runtime/firebase";

/**
 * Politique de mot de passe du projet (Firebase Authentication, mode « appliquer ») : au moins
 * 6 caractères, dont une minuscule, une majuscule, un chiffre et un caractère spécial pris dans la
 * liste autorisée par Firebase. Un compte créé avec l'Admin SDK n'y est pas soumis : sans ce
 * contrôle, un coach recevrait un mot de passe refusé à sa première connexion.
 *
 * Miroir côté back-office : cms/src/password_policy.ts (test/callables/password_policy.test.ts
 * vérifie que les deux restent identiques).
 */
export const PASSWORD_MIN_LENGTH = 6;
export const PASSWORD_MAX_LENGTH = 4096;
/** Caractères non alphanumériques acceptés par la politique (`allowedNonAlphanumericCharacters`). */
export const PASSWORD_SPECIAL_CHARACTERS = "^$*.[]{}()?\"!@#%&/\\,><':;|_~`-";

/** Exigences non remplies, en clair (liste vide : mot de passe conforme). */
export function passwordPolicyViolations(password: string): string[] {
  const missing: string[] = [];
  if (password.length < PASSWORD_MIN_LENGTH) missing.push(`au moins ${PASSWORD_MIN_LENGTH} caractères`);
  if (password.length > PASSWORD_MAX_LENGTH) missing.push(`au plus ${PASSWORD_MAX_LENGTH} caractères`);
  if (!/[a-z]/.test(password)) missing.push("une minuscule");
  if (!/[A-Z]/.test(password)) missing.push("une majuscule");
  if (!/[0-9]/.test(password)) missing.push("un chiffre");
  if (![...password].some((c) => PASSWORD_SPECIAL_CHARACTERS.includes(c))) missing.push("un caractère spécial");
  return missing;
}

/** Lève `invalid-argument` avec les exigences manquantes si le mot de passe n'est pas conforme. */
export function assertPasswordPolicy(password: unknown): asserts password is string {
  if (typeof password !== "string") {
    throw new HttpsError("invalid-argument", "Mot de passe invalide.");
  }
  const missing = passwordPolicyViolations(password);
  if (missing.length > 0) {
    throw new HttpsError(
      "invalid-argument",
      `Le mot de passe doit contenir ${missing.join(", ")}. Caractères spéciaux acceptés : ${[...PASSWORD_SPECIAL_CHARACTERS].join(" ")}`,
    );
  }
}
