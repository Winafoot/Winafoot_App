// Abonnement offert depuis le back-office (comptes de test) : durées et formules proposées.
// Le serveur (functions/src/billing/admin_access.ts) accepte 1 à 365 jours et 1 à 3 équipes.
export const OFFER_DAYS: Record<string, string> = { "7": "7 jours", "30": "30 jours", "90": "90 jours", "365": "1 an" };
export const OFFER_TEAMS: Record<string, string> = { "1": "1 équipe", "2": "2 équipes", "3": "3 équipes" };
