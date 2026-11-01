
/**
 * Abonnement d'un coach : logique pure (aucun accès à Firestore), alimentée par les événements du
 * webhook RevenueCat (https_requests/billing/revenuecat_webhook.ts).
 */
export type SubscriptionStatus = "trial" | "active" | "grace" | "expired" | "refunded";
export type SubscriptionPeriod = "monthly" | "yearly";
export type TeamsAllowed = 1 | 2 | 3;

export interface SubscriptionData {
  productId: string;
  period: SubscriptionPeriod;
  teamsAllowed: TeamsAllowed;
  status: SubscriptionStatus;
  trialEndMs: number | null;
  expiresAtMs: number;
  store: "app_store" | "play_store";
  /** Horodatage du dernier événement pris en compte : un événement plus ancien est ignoré. */
  lastEventMs: number;
  /** Faux dès que l'utilisateur résilie (CANCELLATION) : l'abonnement ne sera plus renouvelé ni prélevé. Absent : inconnu. */
  autoRenew?: boolean;
}

/** Les champs de l'événement RevenueCat dont le serveur se sert (https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields). */
export interface RevenueCatEvent {
  type: string;
  app_user_id: string;
  product_id?: string;
  new_product_id?: string;
  period_type?: string;
  expiration_at_ms?: number | null;
  grace_period_expiration_at_ms?: number | null;
  event_timestamp_ms: number;
  store?: string;
  cancel_reason?: string;
}

export interface Access {
  active: boolean;
  untilMs: number;
}

/**
 * Identifiants de produit, deux écritures du nombre d'équipes et trois de la période :
 *   - `wina_<1|2|3>team[s]_<monthly|annual>` : ceux créés dans App Store Connect (`wina_1team_monthly`,
 *     `wina_3teams_annual`...). « annual » vaut yearly.
 *   - `wina_team<1|2|3>_<monthly|yearly>` : ancienne écriture, toujours acceptée.
 * Sur Google Play, RevenueCat envoie « identifiant de l'abonnement:identifiant du plan » : le séparateur
 * peut donc être `:` (`wina_1team:monthly`), et un identifiant de plan de base peut suivre
 * (`wina_3teams_annual:p1y`). Les abonnements Play créés sous la forme `wina<n>_team` (`wina3_team:monthly`) et un plan de
 * base suffixé d'un chiffre (`wina_1team:annual1`) sont aussi acceptés : un identifiant Play ne se renomme pas.
 */
const PRODUCT = /^wina_?(?:team_?([123])|([123])_?teams?)[_:](monthly|yearly|annual)[0-9]*(?::[a-z0-9_.-]+)?$/;

export function parseProduct(productId: unknown): { teamsAllowed: TeamsAllowed; period: SubscriptionPeriod } | null {
  if (typeof productId !== "string") return null;
  const match = PRODUCT.exec(productId);
  if (match == null) return null;
  return {
    teamsAllowed: Number(match[1] ?? match[2]) as TeamsAllowed,
    period: match[3] === "monthly" ? "monthly" : "yearly",
  };
}

const HANDLED = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "PRODUCT_CHANGE",
  "CANCELLATION",
  "UNCANCELLATION",
  "EXPIRATION",
  "BILLING_ISSUE",
  "SUBSCRIPTION_EXTENDED",
]);

/**
 * Nouvel état d'abonnement après un événement, ou `null` quand l'événement ne change rien : type non
 * géré, produit inconnu, ou événement plus ancien que le dernier pris en compte (RevenueCat peut
 * rejouer ou désordonner ses envois).
 */
export function applyEvent(prev: SubscriptionData | undefined, event: RevenueCatEvent): SubscriptionData | null {
  if (!HANDLED.has(event.type)) return null;
  if (prev != null && event.event_timestamp_ms < prev.lastEventMs) return null;

  const product = parseProduct(event.type === "PRODUCT_CHANGE" ? event.new_product_id : event.product_id);
  if (product == null) return null;

  let status: SubscriptionStatus;
  if (event.type === "EXPIRATION") status = "expired";
  else if (event.type === "CANCELLATION" && event.cancel_reason === "CUSTOMER_SUPPORT") status = "refunded";
  else if (event.type === "BILLING_ISSUE") status = "grace";
  else status = event.period_type === "TRIAL" ? "trial" : "active";

  // Pendant le délai de grâce l'accès tient jusqu'à la date de grâce, pas jusqu'à l'échéance manquée.
  const graceUntil = event.type === "BILLING_ISSUE" ? event.grace_period_expiration_at_ms : undefined;
  const expiresAtMs = graceUntil ?? event.expiration_at_ms ?? prev?.expiresAtMs ?? 0;
  const trialEndMs = event.period_type === "TRIAL" ? (event.expiration_at_ms ?? null) : (prev?.trialEndMs ?? null);

  // Résiliation : plus de renouvellement (donc plus de prélèvement) ; achat, renouvellement, reprise ou changement de formule : il revient.
  let autoRenew: boolean | undefined = prev?.autoRenew;
  if (event.type === "CANCELLATION" || event.type === "EXPIRATION") autoRenew = false;
  else if (event.type === "INITIAL_PURCHASE" || event.type === "RENEWAL" || event.type === "UNCANCELLATION" || event.type === "PRODUCT_CHANGE") autoRenew = true;

  return {
    productId: (event.type === "PRODUCT_CHANGE" ? event.new_product_id : event.product_id) as string,
    period: product.period,
    teamsAllowed: product.teamsAllowed,
    status,
    trialEndMs,
    expiresAtMs,
    store: event.store === "PLAY_STORE" ? "play_store" : event.store != null ? "app_store" : (prev?.store ?? "app_store"),
    lastEventMs: event.event_timestamp_ms,
    autoRenew,
  };
}

const LIVE = new Set<SubscriptionStatus>(["trial", "active", "grace"]);

/**
 * Accès d'un compte. `teamIndex` vaut 1 pour le propriétaire, 2 ou 3 pour une équipe liée : une équipe
 * au-delà de `teamsAllowed` n'a pas accès (baisse de formule), sans que ses données soient touchées.
 */
export function computeAccess(sub: SubscriptionData | null | undefined, teamIndex: number, nowMs: number): Access {
  if (sub == null || !LIVE.has(sub.status) || sub.expiresAtMs <= nowMs || teamIndex > sub.teamsAllowed) {
    return { active: false, untilMs: 0 };
  }
  return { active: true, untilMs: sub.expiresAtMs };
}
