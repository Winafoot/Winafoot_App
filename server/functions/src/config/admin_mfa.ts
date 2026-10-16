/**
 * Second facteur obligatoire pour les callables d'administration.
 *
 * `true` : `assertAdmin` refuse tout administrateur dont le jeton ne porte pas de second
 * facteur (`firebase.sign_in_second_factor`, présent quand la connexion a validé un code TOTP).
 *
 * Reste à `false` tant que CHAQUE administrateur n'a pas inscrit son application
 * d'authentification depuis le back-office (« Sécurité du compte ») : l'activer avant les
 * verrouille tous, propriétaire du projet compris. Ordre : déployer le back-office, inscrire
 * chaque administrateur, vérifier qu'une connexion demande bien le code, PUIS passer ce
 * drapeau à `true`, compiler et déployer les fonctions (README, section « Administrateurs »).
 * Retour arrière : repasser à `false` et redéployer.
 */
export const REQUIRE_ADMIN_MFA = false;
