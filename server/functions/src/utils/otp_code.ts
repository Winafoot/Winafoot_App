import { createHash, randomBytes, randomInt, timingSafeEqual } from "node:crypto";
import { firestore } from "firebase-admin";

/** Ce que le code autorise : chaque usage a son propre code, l'un ne vaut jamais pour l'autre. */
export type OtpPurpose = "verify-email" | "reset-password";

export const OTP_LENGTH = 6;
export const OTP_TTL_MS = 10 * 60_000;
export const OTP_MAX_ATTEMPTS = 5;

const COLLECTION = "email_codes";

/**
 * Document `email_codes/{purpose}_{uid}` : un seul code actif par compte et par usage, le suivant
 * remplace le précédent. Le code n'est stocké que haché (sel propre au document). La collection est
 * fermée aux clients par le catch-all des règles Firestore ; `expiresAt` sert à la politique TTL
 * (firestore.indexes.json).
 */
function codeRef(purpose: OtpPurpose, uid: string): firestore.DocumentReference {
  return firestore().collection(COLLECTION).doc(`${purpose}_${uid}`);
}

function hashCode(salt: string, code: string): Buffer {
  return createHash("sha256").update(`${salt}:${code}`).digest();
}

/** Code à 6 chiffres tiré avec un générateur cryptographique (zéros de tête conservés). */
export function generateCode(): string {
  return randomInt(0, 10 ** OTP_LENGTH).toString().padStart(OTP_LENGTH, "0");
}

/** Crée (ou remplace) le code actif du compte et le renvoie en clair, pour l'e-mail uniquement. */
export async function issueCode(purpose: OtpPurpose, uid: string, now: number = Date.now()): Promise<string> {
  const code: string = generateCode();
  const salt: string = randomBytes(16).toString("hex");
  await codeRef(purpose, uid).set({
    salt,
    hash: hashCode(salt, code).toString("hex"),
    attempts: 0,
    createdAt: firestore.Timestamp.fromMillis(now),
    expiresAt: firestore.Timestamp.fromMillis(now + OTP_TTL_MS),
  });
  return code;
}

/**
 * Vérifie un code saisi. Renvoie `true` une seule fois : le code est consommé dès qu'il est bon.
 * Chaque essai raté est compté ; au-delà de OTP_MAX_ATTEMPTS le code est détruit et il faut en
 * demander un nouveau. Un code expiré, absent ou mal formé répond `false` sans autre indice.
 */
export async function consumeCode(purpose: OtpPurpose, uid: string, input: unknown, now: number = Date.now()): Promise<boolean> {
  if (typeof input !== "string" || !new RegExp(`^\d{${OTP_LENGTH}}$`).test(input.trim())) return false;
  const code: string = input.trim();
  const ref = codeRef(purpose, uid);

  return firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return false;

    const expiresAt: firestore.Timestamp = snap.get("expiresAt");
    const attempts: number = snap.get("attempts") ?? 0;
    if (expiresAt.toMillis() <= now || attempts >= OTP_MAX_ATTEMPTS) {
      tx.delete(ref);
      return false;
    }

    const expected = Buffer.from(snap.get("hash") as string, "hex");
    if (timingSafeEqual(expected, hashCode(snap.get("salt") as string, code))) {
      tx.delete(ref);
      return true;
    }

    tx.update(ref, { attempts: attempts + 1 });
    return false;
  });
}

/** Détruit le code actif (envoi d'e-mail échoué : un code jamais reçu ne doit pas rester valable). */
export async function discardCode(purpose: OtpPurpose, uid: string): Promise<void> {
  await codeRef(purpose, uid).delete();
}
