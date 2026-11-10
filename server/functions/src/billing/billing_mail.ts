/**
 * E-mails d'abonnement : règles pures (aucun accès à Firestore ni à Resend), pour pouvoir les tester seules.
 * - confirmation du premier paiement.
 */
import type { RevenueCatEvent, SubscriptionData } from "./subscription";

/**
 * Vrai quand l'événement marque un PREMIER paiement : achat direct (plus d'essai gratuit ; le passage d'un
 * essai déjà en cours à l'abonnement payant, RENEWAL, est encore reconnu). Les renouvellements suivants ne
 * donnent pas de mail : les stores envoient déjà leur reçu.
 */
export function isFirstPayment(prev: SubscriptionData | undefined, next: SubscriptionData, event: RevenueCatEvent): boolean {
  if (next.status !== "active") return false;
  if (event.type === "INITIAL_PURCHASE") return event.period_type !== "TRIAL";
  if (event.type === "RENEWAL") return prev?.status === "trial";
  return false;
}

/** Page de gestion de l'abonnement dans le store d'achat. */
export function manageSubscriptionUrl(store: SubscriptionData["store"]): string {
  return store === "play_store" ? "https://play.google.com/store/account/subscriptions" : "https://apps.apple.com/account/subscriptions";
}

export function storeName(store: SubscriptionData["store"]): string {
  return store === "play_store" ? "Google Play" : "l’App Store";
}

/** « 2 équipes · mensuelle » */
export function formulaLabel(sub: Pick<SubscriptionData, "teamsAllowed" | "period">): string {
  const teams = sub.teamsAllowed === 1 ? "1 équipe" : `${sub.teamsAllowed} équipes`;
  return `${teams} · ${sub.period === "monthly" ? "mensuelle" : "annuelle"}`;
}

/** « 28 octobre 2026 » (heure de Paris). */
export function formatDateFr(ms: number): string {
  return new Intl.DateTimeFormat("fr-FR", { dateStyle: "long", timeZone: "Europe/Paris" }).format(new Date(ms));
}

/** Nature d'un nouvel abonnement, pour le mail interne : paiement direct, essai ou offre gratuite, offre d'introduction. */
export function newSubscriptionKind(event: Pick<RevenueCatEvent, "period_type" | "offer_code">): string {
  if (event.period_type === "TRIAL") return "Essai ou offre gratuite";
  if (event.period_type === "INTRO" || (typeof event.offer_code === "string" && event.offer_code !== "")) return "Offre d'introduction ou code promo";
  return "Paiement au tarif normal";
}

/** « 17,00 EUR », ou « — » quand RevenueCat ne transmet pas de montant. */
export function priceLabel(event: Pick<RevenueCatEvent, "price_in_purchased_currency" | "currency">): string {
  const amount = event.price_in_purchased_currency;
  if (typeof amount !== "number" || !Number.isFinite(amount)) return "—";
  return `${amount.toFixed(2).replace(".", ",")} ${event.currency ?? ""}`.trim();
}
