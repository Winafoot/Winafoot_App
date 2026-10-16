/**
 * App Check exigé sur tous les callables.
 *
 * `enforceAppCheck: true` : sans jeton App Check valide, le framework répond 401
 * « unauthenticated » AVANT d'appeler l'adaptateur (aucun handler, aucun compteur de débit).
 * La vérification est faite par firebase-functions DANS l'instance : le réglage vit dans le
 * code déployé, pas dans la console. Coupure d'urgence : passer la valeur à `false` ici
 * (une seule ligne) et redéployer. Voir le README, section « App Check ».
 *
 * Pas de `consumeAppCheckToken` (protection contre le rejeu), volontairement. Dans
 * firebase-functions v7 il ajoute un appel réseau à App Check par requête et ne rejette
 * RIEN tout seul : un jeton déjà consommé passe quand même et `request.app.alreadyConsumed`
 * vaut `true`, à charge du handler de refuser. Pour que ce refus ait un sens, le client doit
 * envoyer un jeton à usage unique (`limitedUseAppCheckToken` côté Flutter,
 * `limitedUseAppCheckTokens` côté web). Le paquet kosmos_auth de l'app n'en demande pas
 * pour sendResetPassword et deleteAccount : refuser les jetons consommés casserait le second
 * appel avec le même jeton en cache. test/app_check.test.ts verrouille l'absence de l'option.
 *
 * Les trois endpoints HTTP de la landing (https_requests/index.ts) n'ont pas ce réglage :
 * `onRequest` n'a pas d'App Check intégré, et la landing n'en envoie pas.
 */
export const APP_CHECK = { enforceAppCheck: true } as const;
