/**
 * Comptes d'exécution des fonctions (README, section « Comptes d'exécution »).
 *
 * - FUNCTIONS_SERVICE_ACCOUNT : toutes les fonctions (setGlobalOptions, src/index.ts), avec les seuls
 *   droits dont elles ont besoin (Firestore, Firebase Auth, FCM, reCAPTCHA Enterprise, réception
 *   Eventarc, objets du bucket par défaut, lecture de leurs secrets).
 * - BUDGET_GUARD_SERVICE_ACCOUNT : le coupe-circuit budgétaire seul (onBudgetAlert), seul compte qui
 *   peut détacher la facturation du projet (roles/billing.projectManager).
 *
 * Les comptes et leurs rôles doivent exister avant le déploiement : une fonction ne se déploie pas
 * avec un compte d'exécution absent.
 */
export const FUNCTIONS_SERVICE_ACCOUNT = "wina-functions@wina-c4c4a.iam.gserviceaccount.com";

export const BUDGET_GUARD_SERVICE_ACCOUNT = "wina-budget-guard@wina-c4c4a.iam.gserviceaccount.com";
