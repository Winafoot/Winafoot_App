import { onCall } from "firebase-functions/v2/https";
import { ALGOLIA_ENABLED } from "../config/algolia";
import { APP_CHECK } from "../config/app_check";
import { ADMIN_MAX_INSTANCES, LIMITS, PUBLIC_MAX_INSTANCES } from "../config/rate_limits";
import { ALGOLIA_SEARCH_SECRET_PARAMS, MAILER_SECRET_PARAMS } from "../config/secrets";
import { callableAdapter } from "../runtime/v2";
import { limitedAuthedCallableAdapter, limitedPublicCallableAdapter } from "../runtime/v2_limited";
import { adminCallableAdapter } from "../runtime/v2_admin";

// Chaque callable ci-dessous reprend l'un de ces quatre objets d'options : APP_CHECK s'y propage (config/app_check.ts).
const PUBLIC = { ...APP_CHECK, maxInstances: PUBLIC_MAX_INSTANCES };
const PUBLIC_MAILER = { ...APP_CHECK, maxInstances: PUBLIC_MAX_INSTANCES, secrets: MAILER_SECRET_PARAMS };

/// Authentification (paquet kosmos_auth de l'app) ///
// Public : « Mot de passe oublié » l'appelle avant connexion et exige `true`. Réponse constante,
// sans lecture ni coût : pas de limite de débit, seulement le plafond d'instances.
export const emailIsAlreadyUsed = onCall(PUBLIC, callableAdapter("callables/auth/email_is_already_used_secured"));
// Le paquet kosmos_auth appelle aussi phoneIsAlreadyUsed (liaison d'un téléphone) : même contrat que emailIsAlreadyUsed.
export const phoneIsAlreadyUsed = onCall(PUBLIC, callableAdapter("callables/auth/phone_is_already_used_secured"));

// Authentifié : uid issu du jeton, et la fiche doit porter l'adresse du compte Auth de l'appelant.
export const sendEmailVerification = onCall(
  PUBLIC_MAILER,
  limitedAuthedCallableAdapter("callables/auth/send_email_verification_secured", { scope: "verification", perUid: LIMITS.verificationUid }),
);
// Public (appelé avant connexion) : même réponse que l'adresse ait un compte ou non.
// Limité par IP ici, et par compte dans le handler (une adresse inconnue ne crée aucun compteur).
export const sendResetPassword = onCall(
  PUBLIC_MAILER,
  limitedPublicCallableAdapter("callables/auth/send_reset_password_secured", { scope: "reset-password", perIp: LIMITS.resetPasswordIp }),
);

// Authentifié : suppression du propre compte de l'appelant (ou admin) uniquement.
export const deleteAccount = onCall(
  PUBLIC,
  limitedAuthedCallableAdapter("callables/auth/delete_account_secured", { scope: "delete-account", perUid: LIMITS.deleteAccountUid }),
);

/// Notifications ///
// Authentifié : l'expéditeur est l'appelant (senderId issu du jeton), le destinataire aussi.
export const addNotification = onCall(
  PUBLIC,
  limitedAuthedCallableAdapter("callables/notifications/add_notification_secured", { scope: "add-notification", perUid: LIMITS.addNotificationUid }),
);

/// Effectif Wina ///
// Authentifié : le plafond d'effectif est appliqué ICI (Admin SDK, transaction, nombre réel de joueurs).
// Les règles Firestore réservent la création et la suppression des joueurs à ces deux callables.
export const createPlayer = onCall(
  PUBLIC,
  limitedAuthedCallableAdapter("callables/players/create_player", { scope: "create-player", perUid: LIMITS.createPlayerUid }),
);
export const deletePlayer = onCall(
  PUBLIC,
  limitedAuthedCallableAdapter("callables/players/delete_player", { scope: "delete-player", perUid: LIMITS.deletePlayerUid }),
);

/// Recherche Algolia ///
// Authentifié : la clé sécurisée est restreinte aux enregistrements de l'appelant (uid issu du jeton, payload ignoré).
// Lie le SEUL secret de recherche (clé parente) ; la clé d'écriture n'est jamais liée ici.
// Tant que ALGOLIA_ENABLED est false : aucun secret lié, le handler répond failed-precondition.
export const getSearchKey = onCall(
  { ...PUBLIC, secrets: ALGOLIA_ENABLED ? ALGOLIA_SEARCH_SECRET_PARAMS : [] },
  limitedAuthedCallableAdapter("callables/search/get_search_key", { scope: "search-key", perUid: LIMITS.searchKeyUid }),
);

/** Back-office Wina — endpoints administrateur (adaptateur authentifiant) */
const ADMIN = { ...APP_CHECK, maxInstances: ADMIN_MAX_INSTANCES };
const ADMIN_MAILER = { ...APP_CHECK, maxInstances: ADMIN_MAX_INSTANCES, secrets: MAILER_SECRET_PARAMS };
// Mot de passe choisi par l'administrateur : createCoach n'envoie aucun e-mail.
export const createCoach = onCall(ADMIN, adminCallableAdapter("callables/admin/create_coach"));
export const resendInvite = onCall(ADMIN_MAILER, adminCallableAdapter("callables/admin/resend_invite"));
export const setCoachDisabled = onCall(ADMIN, adminCallableAdapter("callables/admin/set_coach_disabled"));
export const deleteCoach = onCall(ADMIN, adminCallableAdapter("callables/admin/delete_coach"));

// Comptes administrateurs (vue « Administrateurs » du back-office) : mêmes adaptateur et options que ci-dessus.
export const listAdmins = onCall(ADMIN, adminCallableAdapter("callables/admin/list_admins"));
export const createAdmin = onCall(ADMIN_MAILER, adminCallableAdapter("callables/admin/create_admin"));
export const updateAdmin = onCall(ADMIN_MAILER, adminCallableAdapter("callables/admin/update_admin"));
export const deleteAdmin = onCall(ADMIN, adminCallableAdapter("callables/admin/delete_admin"));
