import { firestore } from "firebase-admin";
import type { RevenueCatEvent } from "./subscription";

/**
 * Codes promo « maison » (Google Play, où les codes du store ne donnent qu'un essai gratuit) : le client saisit
 * le code dans l'app, le serveur le valide, puis l'app lance l'achat sur l'offre Play portant le tag du code.
 *
 * - `promo_codes/{CODE}` : `label`, `offerTag`, `active`, `expiresAt` (ou null), `maxUses`, `uses`, `createdAt`.
 * - `promo_redemptions/{uid}` : dernier code validé par ce compte, `state` « pending » puis « used ».
 * Les deux collections sont fermées aux clients (règle catch-all de firestore.rules) : tout passe par l'Admin SDK.
 *
 * Le compteur `uses` n'est JAMAIS incrémenté sur la parole de l'app : il l'est par le webhook RevenueCat, au
 * premier achat à prix d'introduction du compte, tant que sa validation date de moins d'une heure.
 */
export const PROMO_COLLECTION = "promo_codes";
export const REDEMPTION_COLLECTION = "promo_redemptions";
/** Délai entre la validation du code et l'achat. Au-delà, le client doit ressaisir son code. */
export const REDEMPTION_TTL_MS = 60 * 60 * 1000;

export const CODE_PATTERN = /^[A-Z0-9]{4,20}$/;
/** Tag posé sur l'offre dans la Play Console (Google : minuscules, chiffres, tirets). */
export const TAG_PATTERN = /^[a-z0-9-]{2,20}$/;

export function normalizeCode(value: unknown): string {
  return typeof value === "string" ? value.replace(/\s+/g, "").toUpperCase() : "";
}

export type PromoRejection = "unknown" | "inactive" | "expired" | "exhausted";

export const PROMO_MESSAGES: Record<PromoRejection | "already-used" | "not-new", string> = {
  unknown: "Ce code n'existe pas.",
  inactive: "Ce code n'est plus actif.",
  expired: "Ce code a expiré.",
  exhausted: "Ce code a atteint son nombre maximal d'utilisations.",
  "already-used": "Vous avez déjà utilisé un code promo.",
  "not-new": "Ce code est réservé aux nouveaux abonnés.",
};

export interface PromoCodeData {
  active?: unknown;
  expiresAtMs?: number | null;
  maxUses?: unknown;
  uses?: unknown;
}

/** Raison du refus d'un code, ou `null` s'il peut être utilisé maintenant. */
export function rejectionOf(code: PromoCodeData | undefined, nowMs: number): PromoRejection | null {
  if (code == null) return "unknown";
  if (code.active !== true) return "inactive";
  if (code.expiresAtMs != null && code.expiresAtMs <= nowMs) return "expired";
  const max = typeof code.maxUses === "number" ? code.maxUses : 0;
  const uses = typeof code.uses === "number" ? code.uses : 0;
  if (uses >= max) return "exhausted";
  return null;
}

/** Fin de journée (Paris approximée en UTC+1) de la date `AAAA-MM-JJ` : un code expire à la fin du jour indiqué. */
export function endOfDayMs(date: string): number {
  return Date.parse(`${date}T23:59:59+01:00`);
}

/** Un achat Play à prix d'introduction (ou en essai) : celui qui consomme un code validé. */
export function consumesPromo(event: RevenueCatEvent): boolean {
  return event.type === "INITIAL_PURCHASE" && event.store === "PLAY_STORE" && (event.period_type === "INTRO" || event.period_type === "TRIAL");
}

export interface PendingPromo {
  redemptionRef: firestore.DocumentReference;
  codeRef: firestore.DocumentReference;
}

/** Lecture (à faire avant toute écriture de la transaction) du code en attente pour ce compte, s'il est encore frais. */
export async function readPendingPromo(tx: firestore.Transaction, uid: string, nowMs: number): Promise<PendingPromo | null> {
  const db = firestore();
  const redemptionRef = db.collection(REDEMPTION_COLLECTION).doc(uid);
  const redemption = await tx.get(redemptionRef);
  if (!redemption.exists || redemption.get("state") !== "pending") return null;
  const validatedAt = redemption.get("validatedAt");
  if (!(validatedAt instanceof firestore.Timestamp) || nowMs - validatedAt.toMillis() > REDEMPTION_TTL_MS) return null;
  const codeRef = db.collection(PROMO_COLLECTION).doc(String(redemption.get("code")));
  if (!(await tx.get(codeRef)).exists) return null;
  return { redemptionRef, codeRef };
}

export function consumePromo(tx: firestore.Transaction, pending: PendingPromo, nowMs: number): void {
  tx.update(pending.codeRef, { uses: firestore.FieldValue.increment(1) });
  tx.update(pending.redemptionRef, { state: "used", usedAt: firestore.Timestamp.fromMillis(nowMs) });
}
