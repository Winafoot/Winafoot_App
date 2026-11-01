/**
 * Politique de mot de passe du projet (Firebase Authentication) : au moins 6 caractères, dont une
 * minuscule, une majuscule, un chiffre et un caractère spécial pris dans la liste autorisée par
 * Firebase. Miroir de functions/src/callables/admin/_password_policy.ts, qui fait foi : createCoach
 * applique la même règle (un test des fonctions vérifie que les deux répondent pareil).
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
