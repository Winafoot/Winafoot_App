/**
 * E-mails d'abonnement : règles pures (aucun accès à Firestore ni à Resend), pour pouvoir les tester seules.
 * - confirmation du premier paiement (achat sans essai, ou fin de l'essai gratuit) ;
 * - rappel avant la fin de l'essai gratuit.
 */
import type { RevenueCatEvent, SubscriptionData } from "./subscription";

const HOUR = 60 * 60_000;

/**
 * Le rappel part entre 24 h et 48 h avant la fin de l'essai : un achat via l'App Store ne peut être annulé
 * que plus de 24 h avant l'échéance, donc un rappel envoyé plus tard ne laisserait aucune chance d'annuler.
 * Passage quotidien : chaque essai tombe dans cette fenêtre une fois.
 */
export const TRIAL_REMINDER_MIN_MS = 24 * HOUR;
export const TRIAL_REMINDER_MAX_MS = 48 * HOUR;

/** Fenêtre [from, to] des fins d'essai à rappeler au moment `nowMs`. */
export function trialReminderWindow(nowMs: number): { fromMs: number; toMs: number } {
  return { fromMs: nowMs + TRIAL_REMINDER_MIN_MS, toMs: nowMs + TRIAL_REMINDER_MAX_MS };
}

/**
 * Vrai quand l'événement marque un PREMIER paiement : achat direct sans essai, ou passage de l'essai à
 * l'abonnement payant (RevenueCat envoie alors un RENEWAL). Les renouvellements suivants ne donnent pas de
 * mail : les stores envoient déjà leur reçu.
 */
export function isFirstPayment(prev: SubscriptionData | undefined, next: SubscriptionData, event: RevenueCatEvent): boolean {
  if (next.status !== "active") return false;
  if (event.type === "INITIAL_PURCHASE") return event.period_type !== "TRIAL";
  if (event.type === "RENEWAL") return prev?.status === "trial";
  return false;
}

/** Vrai quand l'événement marque le DÉBUT d'un essai gratuit (premier achat, période d'essai). */
export function isTrialStart(next: SubscriptionData, event: RevenueCatEvent): boolean {
  return event.type === "INITIAL_PURCHASE" && event.period_type === "TRIAL" && next.status === "trial";
}

/** Essai en cours dont la fin tombe dans la fenêtre de rappel, et qui n'a pas déjà reçu son rappel. */
export function isTrialReminderDue(sub: SubscriptionData | undefined, nowMs: number, alreadySent: boolean): boolean {
  // Essai résilié (autoRenew faux) : il n'y aura pas de prélèvement, le rappel serait faux.
  if (sub == null || sub.status !== "trial" || alreadySent || sub.autoRenew === false) return false;
  const end = sub.trialEndMs ?? sub.expiresAtMs;
  const { fromMs, toMs } = trialReminderWindow(nowMs);
  return end > fromMs && end <= toMs;
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
