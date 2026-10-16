import { createHash } from "node:crypto";
import { firestore } from "firebase-admin";
import { HttpsError, logger } from "../runtime/firebase";

export interface Limit {
  limit: number;
  windowMs: number;
}

const COLLECTION = "rate_limits";

/**
 * Clé du compteur : l'identifiant (adresse, IP, uid) est haché, il n'est donc jamais
 * stocké en clair. La collection est fermée aux clients par le catch-all des règles
 * Firestore ; `expiresAt` sert à la politique TTL (firestore.indexes.json).
 */
export function rateLimitKey(scope: string, id: string): string {
  return `${scope}_${createHash("sha256").update(id).digest("hex").slice(0, 32)}`;
}

/**
 * Compte un appel dans une fenêtre fixe, de façon atomique (transaction).
 * Renvoie `false` quand la limite de la fenêtre est atteinte.
 */
export async function consume(scope: string, id: string, { limit, windowMs }: Limit, now: number = Date.now()): Promise<boolean> {
  const ref = firestore().collection(COLLECTION).doc(rateLimitKey(scope, id));

  return firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const windowStart: number | undefined = snap.get("windowStart");
    const count: number = snap.get("count") ?? 0;

    if (windowStart == null || now - windowStart >= windowMs) {
      tx.set(ref, { count: 1, windowStart: now, expiresAt: firestore.Timestamp.fromMillis(now + windowMs) });
      return true;
    }
    if (count >= limit) {
      // Sans l'identifiant : le scope suffit à repérer une attaque, ou une limite mal calibrée
      // (par exemple un proxy qui regrouperait tous les clients sous une seule IP).
      logger.warn(`[RateLimit] ${scope} : limite atteinte`);
      return false;
    }

    tx.update(ref, { count: count + 1 });
    return true;
  });
}

/** Compte plusieurs limites dans l'ordre et s'arrête à la première qui refuse (les suivantes ne sont pas entamées). */
export async function consumeAll(checks: ReadonlyArray<readonly [scope: string, id: string, limit: Limit]>): Promise<boolean> {
  for (const [scope, id, limit] of checks) {
    if (!(await consume(scope, id, limit))) return false;
  }
  return true;
}

/** Pour les callables : `resource-exhausted` quand la limite est atteinte. */
export async function enforce(scope: string, id: string, limit: Limit): Promise<void> {
  if (!(await consume(scope, id, limit))) {
    throw new HttpsError("resource-exhausted", "Trop de demandes, réessayez plus tard.");
  }
}
