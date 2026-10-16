/** Configuration Algolia non secrète (les clés vivent dans Secret Manager : config/secrets.ts). */
export const ALGOLIA_APP_ID = "UV1NCQERZ5";

export const ALGOLIA_INDICES = {
  compositions: "wina_compositions",
  matches: "wina_matches",
} as const;

/** Durée de validité d'une clé de recherche sécurisée (secondes). */
export const SEARCH_KEY_TTL_SECONDS = 3600;

/**
 * Interrupteur de la recherche Algolia : une ligne. La recherche est en service (`true`).
 *
 * `true` : les fonctions lient leurs secrets (un déploiement échoue s'ils sont absents de Secret
 * Manager) et travaillent : les triggers recopient les compositions et les matchs terminés,
 * `getSearchKey` délivre des clés de recherche.
 *
 * `false` : tout le code Algolia est INERTE. Les triggers de synchronisation retournent sans rien lire
 * (ni secret, ni Firestore, ni réseau, aucune exception : une exception relancerait l'événement 24 h),
 * `getSearchKey` répond `failed-precondition`, et AUCUN secret n'est lié aux fonctions : on peut déployer
 * sans `ALGOLIA_WRITE_KEY` ni `ALGOLIA_SEARCH_KEY`. Coupure : passer à `false`, compiler, redéployer
 * les trois fonctions concernées (README, section « Recherche »).
 */
export const ALGOLIA_ENABLED = true;
