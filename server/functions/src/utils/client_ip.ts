import { TRUSTED_PROXY_HOPS } from "../config/rate_limits";

interface RequestLike {
  headers?: Record<string, unknown>;
  get?: (name: string) => string | undefined;
  ip?: string;
}

/**
 * Préfixe /64 d'une IPv6 (« 2001:db8:aa:bb::/64 »), ou `undefined` si elle est invalide.
 * Un VPS reçoit un /64 entier : une clé par adresse complète offrirait 2^64 compteurs.
 */
function ipv6Prefix(value: string): string | undefined {
  const halves = value.split("::");
  if (halves.length > 2) return undefined;

  const groupsOf = (part: string): string[] => (part === "" ? [] : part.split(":"));
  const head = groupsOf(halves[0]);
  const tail = halves.length === 2 ? groupsOf(halves[1]) : [];
  const missing = 8 - head.length - tail.length;
  // Sans « :: », exactement 8 groupes ; avec « :: », il remplace au moins un groupe.
  if (halves.length === 1 ? missing !== 0 : missing < 1) return undefined;

  const groups = [...head, ...Array<string>(halves.length === 2 ? missing : 0).fill("0"), ...tail];
  if (!groups.every((group) => /^[0-9a-f]{1,4}$/.test(group))) return undefined;

  return `${groups.slice(0, 4).map((group) => parseInt(group, 16).toString(16)).join(":")}::/64`;
}

function normalizeIp(raw: string): string {
  const value = raw.trim().replace(/^\[|\]$/g, "").split("%")[0].toLowerCase();
  if (!value.includes(":")) return value; // IPv4, ou valeur qui n'est pas une IP : telle quelle

  const mapped = value.match(/^::ffff:(\d{1,3}(?:\.\d{1,3}){3})$/);
  if (mapped) return mapped[1];

  return ipv6Prefix(value) ?? value;
}

/**
 * IP du client, servant de clé de limitation de débit.
 *
 * Google AJOUTE l'IP réelle à la FIN de X-Forwarded-For : ce qui la précède est fourni par le
 * client et ne vaut rien (le prendre en tête permettrait d'échapper à toute limite en changeant
 * la valeur à chaque appel). Cette position n'est pas garantie par la documentation officielle
 * (qui ne parle que de « la première IP »), mais elle correspond au comportement observé d'un
 * appel direct ; `hops` décale la lecture si des proxys sont ajoutés derrière le client
 * (TRUSTED_PROXY_HOPS). Sans en-tête, retombe sur req.ip puis sur une constante, ce qui regroupe
 * ces appels dans un seul compteur.
 *
 * Une IPv6 est ramenée à son /64 et une IPv4 mappée à son IPv4.
 */
export function clientIp(req: RequestLike | undefined, hops: number = TRUSTED_PROXY_HOPS): string {
  const header = req?.get?.("x-forwarded-for") ?? req?.headers?.["x-forwarded-for"];
  const entries = typeof header === "string" ? header.split(",").map((entry) => entry.trim()).filter(Boolean) : [];

  const raw = entries[Math.max(entries.length - 1 - hops, 0)] ?? req?.ip;
  return raw ? normalizeIp(raw) : "unknown";
}
