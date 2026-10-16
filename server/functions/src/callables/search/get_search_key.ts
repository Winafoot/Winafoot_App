import { algoliasearch } from "algoliasearch";
import { auth } from "firebase-admin";
import { ALGOLIA_APP_ID, ALGOLIA_ENABLED, ALGOLIA_INDICES, SEARCH_KEY_TTL_SECONDS } from "../../config/algolia";
import { ALGOLIA_SEARCH_KEY } from "../../config/secrets";
import { logAccessDeniedFor } from "../../runtime/access_denied";
import { HttpsError, logger } from "../../runtime/firebase";
import { describeError } from "../../utils/describe_error";
import type { AuthedCaller } from "../../runtime/v2_authed";
import { ownerKey } from "../../search/ids";

export interface SearchKeyResponse {
  appId: string;
  apiKey: string;
  ttlSeconds: number;
  indices: { compositions: string; matches: string };
}

/** Restrictions imposées dans la clé : le client ne peut pas les modifier. */
export interface SearchKeyRestrictions {
  filters: string;
  validUntil: number;
  restrictIndices: string[];
  userToken: string;
  searchParams: Record<string, unknown>;
}

/** Fabrique de clé sécurisée, injectable en test. Le SDK la calcule en local (HMAC), sans appel réseau. */
export type SearchKeyFactory = (parentKey: string, restrictions: SearchKeyRestrictions) => string;

const generateSecuredKey: SearchKeyFactory = (parentKey, restrictions) =>
  algoliasearch(ALGOLIA_APP_ID, parentKey).generateSecuredApiKey({ parentApiKey: parentKey, restrictions });

/** Clé parente (`wina-search-parent`), ou HttpsError si le secret est absent ou vide. */
function readParentKey(): string {
  // L'émulateur Functions charge la VRAIE clé depuis Secret Manager : on ne s'en sert pas hors production.
  if (process.env.FUNCTIONS_EMULATOR === "true") {
    throw new HttpsError("failed-precondition", "Recherche indisponible.");
  }
  let value: string | undefined;
  try {
    value = ALGOLIA_SEARCH_KEY.value();
  } catch {
    value = undefined;
  }
  if (value == null || value.trim().length === 0) {
    throw new HttpsError("failed-precondition", "Recherche indisponible.");
  }
  return value;
}

/** Un compte désactivé (ou supprimé) ne reçoit pas de clé : seule la suppression de compte purge ses enregistrements. */
async function assertAccountActive(uid: string): Promise<void> {
  let disabled: boolean;
  try {
    disabled = (await auth().getUser(uid)).disabled;
  } catch (error) {
    if ((error as { code?: string })?.code === "auth/user-not-found") {
      logAccessDeniedFor(uid, "account-not-found");
      throw new HttpsError("permission-denied", "Compte introuvable.");
    }
    logger.error(`[Error] getSearchKey : lecture du compte impossible : ${describeError(error)}`);
    throw new HttpsError("internal", "Recherche indisponible.");
  }
  if (disabled) {
    logAccessDeniedFor(uid, "account-disabled");
    throw new HttpsError("permission-denied", "Compte désactivé.");
  }
}

/**
 * Clé de recherche Algolia de 1 h, restreinte aux enregistrements de l'appelant.
 * `uid` vient EXCLUSIVEMENT du jeton : le payload est ignoré. Ni la clé parente ni la clé
 * d'écriture ne sortent d'ici ; rien n'est journalisé de la clé dérivée.
 */
export default async (_data: unknown, caller: AuthedCaller, makeKey: SearchKeyFactory = generateSecuredKey): Promise<SearchKeyResponse> => {
  // Interrupteur coupé : refus AVANT toute lecture (Auth, secret).
  if (!ALGOLIA_ENABLED) throw new HttpsError("failed-precondition", "Recherche indisponible.");
  await assertAccountActive(caller.uid);
  const parentKey = readParentKey();
  const owner = ownerKey(caller.uid);
  const indices = { compositions: ALGOLIA_INDICES.compositions, matches: ALGOLIA_INDICES.matches };

  let apiKey: string;
  try {
    apiKey = makeKey(parentKey, {
      filters: `ownerKey:"${owner}"`,
      validUntil: Math.floor(Date.now() / 1000) + SEARCH_KEY_TTL_SECONDS,
      restrictIndices: [indices.compositions, indices.matches],
      userToken: owner,
      searchParams: {
        analytics: false,
        clickAnalytics: false,
        enablePersonalization: false,
        attributesToRetrieve: ["docId"],
        attributesToHighlight: [],
        attributesToSnippet: [],
        hitsPerPage: 100,
      },
    });
  } catch {
    // Message volontairement constant : une erreur du SDK pourrait citer la clé parente.
    logger.error("[Error] getSearchKey : génération de la clé impossible");
    throw new HttpsError("internal", "Recherche indisponible.");
  }

  return { appId: ALGOLIA_APP_ID, apiKey, ttlSeconds: SEARCH_KEY_TTL_SECONDS, indices };
};
