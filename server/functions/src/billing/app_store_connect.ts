import { createPrivateKey, sign } from "node:crypto";
import { APPSTORE_ISSUER_ID, APPSTORE_KEY_ID, APPSTORE_PRIVATE_KEY, readSecret } from "../config/secrets";
import { HttpsError } from "../runtime/firebase";

/**
 * Client minimal de l'API App Store Connect pour les codes d'offre d'abonnement (back-office). Authentification
 * par jeton JWT ES256 signé avec la clé API (.p8) : rôle App Manager ou Admin. Ne sert qu'aux callables admin.
 */
const BASE = "https://api.appstoreconnect.apple.com";
const TOKEN_TTL_S = 600;

export interface PricePoint {
  id: string;
  /** Prix client dans la devise du territoire, ex. « 8.99 ». */
  price: number;
}

/** Palier de prix Apple le plus proche du prix visé (Apple ne propose que des paliers, pas des pourcentages). */
export function pickPricePoint(points: PricePoint[], target: number): PricePoint | undefined {
  return points.reduce<PricePoint | undefined>(
    (best, p) => (best == null || Math.abs(p.price - target) < Math.abs(best.price - target) ? p : best),
    undefined,
  );
}

/** Prix visé après réduction, arrondi au centime. */
export function discountedPrice(basePrice: number, percentOff: number): number {
  return Math.round(basePrice * (1 - percentOff / 100) * 100) / 100;
}

function base64url(input: Buffer | string): string {
  return Buffer.from(input).toString("base64url");
}

/** Jeton d'accès à l'API (20 minutes au plus côté Apple). */
export function appleToken(keyId: string, issuerId: string, privateKeyPem: string, nowS = Math.floor(Date.now() / 1000)): string {
  const header = base64url(JSON.stringify({ alg: "ES256", kid: keyId, typ: "JWT" }));
  const payload = base64url(JSON.stringify({ iss: issuerId, iat: nowS, exp: nowS + TOKEN_TTL_S, aud: "appstoreconnect-v1" }));
  const signature = sign("sha256", Buffer.from(`${header}.${payload}`), { key: createPrivateKey(privateKeyPem), dsaEncoding: "ieee-p1363" });
  return `${header}.${payload}.${base64url(signature)}`;
}

/**
 * Clé .p8 au format PEM propre, quelle que soit la façon dont le secret a été collé : « \n » littéraux, retours à la
 * ligne perdus (tout sur une ligne), espaces en trop, ou corps base64 sans les lignes BEGIN/END.
 */
export function normalizePem(raw: string): string {
  const body = raw
    .replace(/\\n/g, "\n")
    .replace(/-----BEGIN [A-Z ]+-----|-----END [A-Z ]+-----/g, "")
    .replace(/\s+/g, "");
  return `-----BEGIN PRIVATE KEY-----\n${body.match(/.{1,64}/g)?.join("\n") ?? ""}\n-----END PRIVATE KEY-----\n`;
}

function credentials(): string {
  const keyId = readSecret(APPSTORE_KEY_ID);
  const issuerId = readSecret(APPSTORE_ISSUER_ID);
  const privateKey = readSecret(APPSTORE_PRIVATE_KEY);
  if (keyId == null || issuerId == null || privateKey == null) {
    throw new HttpsError("failed-precondition", "La clé App Store Connect n'est pas configurée sur le serveur.");
  }
  try {
    return appleToken(keyId, issuerId, normalizePem(privateKey));
  } catch {
    throw new HttpsError("failed-precondition", "La clé privée App Store Connect (APPSTORE_PRIVATE_KEY) est illisible : recollez le contenu complet du fichier .p8.");
  }
}

async function request(method: "GET" | "POST", path: string, body?: unknown): Promise<string> {
  const response = await fetch(`${BASE}${path}`, {
    method,
    headers: { Authorization: `Bearer ${credentials()}`, ...(body == null ? {} : { "Content-Type": "application/json" }) },
    body: body == null ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  if (!response.ok) {
    let detail = text.slice(0, 300);
    try {
      const error = JSON.parse(text)?.errors?.[0];
      if (error != null) detail = `${error.title ?? ""} ${error.detail ?? ""}`.trim();
    } catch {
      // Réponse non JSON : on garde le début du texte.
    }
    throw new HttpsError("failed-precondition", `Apple a refusé la demande (${response.status}) : ${detail}`);
  }
  return text;
}

async function json(method: "GET" | "POST", path: string, body?: unknown): Promise<any> {
  return JSON.parse(await request(method, path, body));
}

/** Paliers de prix d'un abonnement pour un territoire (« FRA » pour la France). */
export async function listPricePoints(subscriptionId: string, territory: string): Promise<PricePoint[]> {
  const points: PricePoint[] = [];
  let path: string | undefined = `/v1/subscriptions/${encodeURIComponent(subscriptionId)}/pricePoints?filter[territory]=${territory}&limit=200`;
  while (path != null) {
    const page: any = await json("GET", path);
    for (const p of page.data ?? []) points.push({ id: p.id, price: Number(p.attributes?.customerPrice) });
    path = typeof page.links?.next === "string" ? page.links.next.replace(BASE, "") : undefined;
  }
  return points.filter((p) => Number.isFinite(p.price));
}

/** Toutes les pages d'une liste Apple (`data` et `included` mis bout à bout). */
async function listAll(path: string): Promise<{ data: any[]; included: any[] }> {
  const data: any[] = [];
  const included: any[] = [];
  let next: string | undefined = path;
  while (next != null) {
    const page: any = await json("GET", next);
    data.push(...(page.data ?? []));
    included.push(...(page.included ?? []));
    next = typeof page.links?.next === "string" ? page.links.next.replace(BASE, "") : undefined;
  }
  return { data, included };
}

export interface AppleSubscription {
  id: string;
  /** Nom affiché dans App Store Connect. */
  name: string;
  productId: string;
  /** Application et groupe d'abonnements, pour s'y retrouver dans la liste. */
  appName: string;
  groupName: string;
}

/** Abonnements du compte, toutes apps et tous groupes confondus. */
export async function listSubscriptions(): Promise<AppleSubscription[]> {
  const out: AppleSubscription[] = [];
  for (const app of (await listAll("/v1/apps?limit=200")).data) {
    for (const group of (await listAll(`/v1/apps/${app.id}/subscriptionGroups?limit=200`)).data) {
      for (const sub of (await listAll(`/v1/subscriptionGroups/${group.id}/subscriptions?limit=200`)).data) {
        out.push({
          id: sub.id,
          name: sub.attributes?.name ?? sub.attributes?.productId ?? sub.id,
          productId: sub.attributes?.productId ?? "",
          appName: app.attributes?.name ?? "",
          groupName: group.attributes?.referenceName ?? "",
        });
      }
    }
  }
  return out;
}

export interface AppleTerritory {
  /** Code Apple à trois lettres (« FRA »). */
  id: string;
  currency: string;
}

export async function listTerritories(): Promise<AppleTerritory[]> {
  return (await listAll("/v1/territories?limit=200")).data.map((t) => ({ id: t.id as string, currency: t.attributes?.currency ?? "" }));
}

/** Prix en vigueur parmi les tarifs d'un abonnement : le plus récent déjà commencé (ceux à venir sont ignorés). */
export function currentPrice(entries: { startDate: string | null; price: number }[], now = new Date()): number | undefined {
  const started = entries.filter((e) => e.startDate == null || Date.parse(e.startDate) <= now.getTime());
  started.sort((a, b) => (a.startDate == null ? -Infinity : Date.parse(a.startDate)) - (b.startDate == null ? -Infinity : Date.parse(b.startDate)));
  return started[started.length - 1]?.price;
}

/** Prix actuel d'un abonnement dans un territoire, ou `undefined` si Apple n'en renvoie aucun. */
export async function subscriptionPrice(subscriptionId: string, territory: string): Promise<number | undefined> {
  const { data, included } = await listAll(
    `/v1/subscriptions/${encodeURIComponent(subscriptionId)}/prices?filter[territory]=${territory}&include=subscriptionPricePoint&limit=200`,
  );
  const prices = new Map<string, number>(included.filter((i) => i.type === "subscriptionPricePoints").map((i) => [i.id as string, Number(i.attributes?.customerPrice)]));
  return currentPrice(
    data
      .map((p) => ({ startDate: (p.attributes?.startDate ?? null) as string | null, price: prices.get(p.relationships?.subscriptionPricePoint?.data?.id) ?? NaN }))
      .filter((e) => Number.isFinite(e.price)),
  );
}

export interface AppleOffer {
  id: string;
  name: string;
  /** App · groupe · abonnement, pour s'y retrouver. */
  subscription: string;
  /** « PAY_AS_YOU_GO », « FREE_TRIAL » ou « PAY_UP_FRONT ». */
  mode: string;
  duration: string;
  periods: number;
  active: boolean;
  /** Lots de codes à usage unique. */
  batches: { id: string; codes: number; expirationDate: string | null; active: boolean }[];
  /** Codes personnalisés (ex. WINA10). */
  customCodes: { id: string; code: string; uses: number; expirationDate: string | null; active: boolean }[];
}

/** Offres à code de tous les abonnements du compte, avec leurs lots de codes et codes personnalisés. */
export async function listOffers(): Promise<AppleOffer[]> {
  const out: AppleOffer[] = [];
  for (const sub of await listSubscriptions()) {
    for (const offer of (await listAll(`/v1/subscriptions/${sub.id}/offerCodes?limit=200`)).data) {
      const [batches, customs] = await Promise.all([
        listAll(`/v1/subscriptionOfferCodes/${offer.id}/oneTimeUseCodes?limit=200`),
        listAll(`/v1/subscriptionOfferCodes/${offer.id}/customCodes?limit=200`),
      ]);
      out.push({
        id: offer.id,
        name: offer.attributes?.name ?? offer.id,
        subscription: `${sub.appName} · ${sub.groupName} · ${sub.name}`,
        mode: offer.attributes?.offerMode ?? "",
        duration: offer.attributes?.duration ?? "",
        periods: Number(offer.attributes?.numberOfPeriods ?? 0),
        active: offer.attributes?.active === true,
        batches: batches.data.map((b) => ({ id: b.id, codes: Number(b.attributes?.numberOfCodes ?? 0), expirationDate: b.attributes?.expirationDate ?? null, active: b.attributes?.active === true })),
        customCodes: customs.data.map((c) => ({ id: c.id, code: c.attributes?.customCode ?? "", uses: Number(c.attributes?.numberOfCodes ?? 0), expirationDate: c.attributes?.expirationDate ?? null, active: c.attributes?.active === true })),
      });
    }
  }
  return out;
}

export interface CreateOfferInput {
  subscriptionId: string;
  name: string;
  territory: string;
  pricePointId: string;
  /** Nombre de mois au prix réduit. */
  months: number;
}

const DURATIONS: Record<number, string> = { 1: "ONE_MONTH", 2: "TWO_MONTHS", 3: "THREE_MONTHS", 6: "SIX_MONTHS", 12: "ONE_YEAR" };

/** Crée l'offre « prix réduit pendant N mois » (payée à chaque période), valable pour tout nouvel abonné. */
export async function createOffer(input: CreateOfferInput): Promise<string> {
  const duration = DURATIONS[input.months];
  if (duration == null) throw new HttpsError("invalid-argument", "Durée non prise en charge par Apple (1, 2, 3, 6 ou 12 mois).");
  const priceRef = "${price0}";
  const result = await json("POST", "/v1/subscriptionOfferCodes", {
    data: {
      type: "subscriptionOfferCodes",
      attributes: {
        name: input.name,
        customerEligibilities: ["NEW"],
        offerEligibility: "STACK_WITH_INTRO_OFFERS",
        duration,
        offerMode: "PAY_AS_YOU_GO",
        numberOfPeriods: input.months,
        autoRenewEnabled: true,
      },
      relationships: {
        subscription: { data: { type: "subscriptions", id: input.subscriptionId } },
        prices: { data: [{ type: "subscriptionOfferCodePrices", id: priceRef }] },
      },
    },
    included: [
      {
        type: "subscriptionOfferCodePrices",
        id: priceRef,
        relationships: {
          territory: { data: { type: "territories", id: input.territory } },
          subscriptionPricePoint: { data: { type: "subscriptionPricePoints", id: input.pricePointId } },
        },
      },
    ],
  });
  return result.data.id as string;
}

/** Lot de codes à usage unique ; retourne l'identifiant du lot (les valeurs se lisent ensuite avec `oneTimeCodeValues`). */
export async function createOneTimeCodes(offerId: string, numberOfCodes: number, expirationDate: string): Promise<string> {
  const result = await json("POST", "/v1/subscriptionOfferCodeOneTimeUseCodes", {
    data: {
      type: "subscriptionOfferCodeOneTimeUseCodes",
      attributes: { numberOfCodes, expirationDate },
      relationships: { offerCode: { data: { type: "subscriptionOfferCodes", id: offerId } } },
    },
  });
  return result.data.id as string;
}

/** Code personnalisé (ex. WINA10), utilisable `numberOfCodes` fois. */
export async function createCustomCode(offerId: string, customCode: string, numberOfCodes: number, expirationDate: string): Promise<string> {
  const result = await json("POST", "/v1/subscriptionOfferCodeCustomCodes", {
    data: {
      type: "subscriptionOfferCodeCustomCodes",
      attributes: { customCode, numberOfCodes, expirationDate },
      relationships: { offerCode: { data: { type: "subscriptionOfferCodes", id: offerId } } },
    },
  });
  return result.data.id as string;
}

/** Valeurs d'un lot de codes à usage unique : Apple répond en CSV, un code par ligne. Vide tant que le lot est en préparation. */
export async function oneTimeCodeValues(batchId: string): Promise<string[]> {
  const text = await request("GET", `/v1/subscriptionOfferCodeOneTimeUseCodes/${encodeURIComponent(batchId)}/values`);
  return text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line !== "" && line.toLowerCase() !== "code");
}
