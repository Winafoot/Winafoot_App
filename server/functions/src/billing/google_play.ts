import { createPrivateKey, sign } from "node:crypto";
import { GOOGLEPLAY_SERVICE_ACCOUNT, readSecret } from "../config/secrets";
import { HttpsError } from "../runtime/firebase";

/**
 * Client minimal de l'API Google Play Developer (androidpublisher v3), en lecture seule : sert au back-office à lister
 * les tags posés sur les offres d'abonnement. Authentification par compte de service (JWT RS256 échangé contre un
 * jeton OAuth). Le compte doit être invité dans la Play Console avec le droit de voir les abonnements.
 */
export const GOOGLE_PLAY_PACKAGE = "fr.winafoot.app";
const API = "https://androidpublisher.googleapis.com/androidpublisher/v3";
const TOKEN_URL = "https://oauth2.googleapis.com/token";
const SCOPE = "https://www.googleapis.com/auth/androidpublisher";

export interface ServiceAccount {
  client_email: string;
  private_key: string;
}

const base64url = (input: Buffer | string) => Buffer.from(input).toString("base64url");

/** JWT d'échange du compte de service (1 h au plus côté Google). */
export function serviceAccountJwt(account: ServiceAccount, nowS = Math.floor(Date.now() / 1000)): string {
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = base64url(JSON.stringify({ iss: account.client_email, scope: SCOPE, aud: TOKEN_URL, iat: nowS, exp: nowS + 3000 }));
  const signature = sign("RSA-SHA256", Buffer.from(`${header}.${payload}`), createPrivateKey(account.private_key.replace(/\\n/g, "\n")));
  return `${header}.${payload}.${base64url(signature)}`;
}

function account(): ServiceAccount {
  const raw = readSecret(GOOGLEPLAY_SERVICE_ACCOUNT);
  if (raw == null) throw new HttpsError("failed-precondition", "Le compte de service Google Play n'est pas configuré sur le serveur.");
  try {
    const json = JSON.parse(raw);
    if (typeof json.client_email !== "string" || typeof json.private_key !== "string") throw new Error("champs manquants");
    return { client_email: json.client_email, private_key: json.private_key };
  } catch {
    throw new HttpsError("failed-precondition", "Le secret GOOGLEPLAY_SERVICE_ACCOUNT est illisible : collez le contenu complet du fichier JSON.");
  }
}

let cached: { token: string; untilMs: number } | undefined;

async function accessToken(): Promise<string> {
  if (cached != null && cached.untilMs > Date.now() + 60_000) return cached.token;
  let assertion: string;
  try {
    assertion = serviceAccountJwt(account());
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    throw new HttpsError("failed-precondition", "La clé privée du compte de service Google est illisible.");
  }
  const response = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }),
  });
  const json: any = await response.json().catch(() => ({}));
  if (!response.ok || typeof json.access_token !== "string") {
    throw new HttpsError("failed-precondition", `Google a refusé le compte de service : ${String(json.error_description ?? json.error ?? response.status).slice(0, 200)}`);
  }
  cached = { token: json.access_token, untilMs: Date.now() + (Number(json.expires_in) || 3600) * 1000 };
  return cached.token;
}

async function get(path: string): Promise<any> {
  const response = await fetch(`${API}${path}`, { headers: { Authorization: `Bearer ${await accessToken()}` } });
  const text = await response.text();
  if (!response.ok) {
    let detail = text.slice(0, 300);
    try {
      detail = JSON.parse(text)?.error?.message ?? detail;
    } catch {
      /* corps non JSON : on garde le texte brut */
    }
    throw new HttpsError("failed-precondition", `Google Play : ${detail}`);
  }
  // Google répond parfois 200 sans corps quand il n'y a rien à lister : une liste vide, pas une erreur.
  return text.trim() === "" ? {} : JSON.parse(text);
}

export interface GoogleOffer {
  productId: string;
  basePlanId: string;
  offerId: string;
  state: string;
  tags: string[];
}

/** Offres de tous les abonnements de l'app, avec leurs tags (les plans de base sans offre n'apparaissent pas). */
export async function listGoogleOffers(packageName = GOOGLE_PLAY_PACKAGE): Promise<GoogleOffer[]> {
  const pkg = encodeURIComponent(packageName);
  const subs = (await get(`/applications/${pkg}/subscriptions?pageSize=100`)).subscriptions ?? [];
  const offers: GoogleOffer[] = [];
  for (const sub of subs) {
    for (const plan of sub.basePlans ?? []) {
      const path = `/applications/${pkg}/subscriptions/${encodeURIComponent(sub.productId)}/basePlans/${encodeURIComponent(plan.basePlanId)}/offers?pageSize=100`;
      for (const offer of (await get(path)).subscriptionOffers ?? []) {
        offers.push({
          productId: sub.productId,
          basePlanId: plan.basePlanId,
          offerId: offer.offerId,
          state: String(offer.state ?? ""),
          tags: (offer.offerTags ?? []).map((t: any) => String(t.tag)).filter((t: string) => t !== ""),
        });
      }
    }
  }
  return offers;
}

export interface OfferTag {
  tag: string;
  offers: { productId: string; basePlanId: string; offerId: string; state: string }[];
  /** Vrai si le tag est posé sur plusieurs offres du MÊME abonnement : l'app en prendrait une au hasard. */
  ambiguous: boolean;
}

/** Regroupe les offres par tag (ordre alphabétique) et repère les tags en double dans un même abonnement. */
export function groupOfferTags(offers: GoogleOffer[]): OfferTag[] {
  const byTag = new Map<string, OfferTag["offers"]>();
  for (const o of offers) {
    for (const tag of o.tags) {
      const list = byTag.get(tag) ?? [];
      list.push({ productId: o.productId, basePlanId: o.basePlanId, offerId: o.offerId, state: o.state });
      byTag.set(tag, list);
    }
  }
  return [...byTag.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([tag, list]) => ({ tag, offers: list, ambiguous: new Set(list.map((o) => o.productId)).size < list.length }));
}
