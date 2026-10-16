/**
 * Le back-office n'envoie aucune donnée à des services tiers de journalisation.
 *
 * FireCMS envoie à chaque connexion une requête à `https://api.firecms.co/access_log`, avec le jeton
 * d'identité Firebase et l'adresse e-mail de l'administrateur, et ne propose aucune option pour la
 * couper. `installThirdPartyGuard` remplace `fetch` : une requête vers firecms.co (ou l'un de ses
 * sous-domaines) reçoit une réponse locale `{}`, sans passer par le réseau. FireCMS ne lit dans cette
 * réponse que `blocked` et `message`, absents : l'interface reste celle d'une réponse ordinaire.
 * Les autres requêtes partent telles quelles.
 *
 * FireCMS n'utilise ni XMLHttpRequest, ni sendBeacon, ni WebSocket : `fetch` est son seul accès au
 * réseau (vérifié par functions/test/back_office/third_party_guard.test.ts).
 */

export const BLOCKED_DOMAIN = "firecms.co";

/** Hôte de la requête, résolu comme le ferait `fetch` (URL relative comprise) ; null si illisible. */
function requestHost(input: RequestInfo | URL, base: string): string | null {
  const raw = typeof input === "string" ? input : "href" in input ? input.href : input.url;
  try {
    return new URL(raw, base).hostname.replace(/\.$/, "");
  } catch {
    return null;
  }
}

export function isBlockedRequest(input: RequestInfo | URL, base: string): boolean {
  const host = requestHost(input, base);
  return host != null && (host === BLOCKED_DOMAIN || host.endsWith("." + BLOCKED_DOMAIN));
}

export interface FetchTarget {
  fetch: typeof fetch;
  location: { href: string };
}

export function installThirdPartyGuard(target: FetchTarget): void {
  const originalFetch = target.fetch.bind(target);
  target.fetch = (input: RequestInfo | URL, init?: RequestInit): Promise<Response> => {
    if (isBlockedRequest(input, target.location.href)) {
      return Promise.resolve(new Response("{}", { status: 200, headers: { "Content-Type": "application/json" } }));
    }
    return originalFetch(input, init);
  };
}
