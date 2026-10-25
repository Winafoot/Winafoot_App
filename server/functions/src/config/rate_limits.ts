/**
 * Limites de débit et plafond d'instances des fonctions exposées à un abus.
 *
 * Fenêtres fixes comptées dans Firestore (utils/rate_limit.ts). Les valeurs sont
 * larges devant un usage humain : « Mot de passe oublié », une fin de match, une
 * demande de suppression de compte ne se répètent pas dix fois par quart d'heure.
 */
const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

/**
 * Plafond d'instances des fonctions publiques ou authentifiées. Sans lui, Cloud
 * Functions monte à 100 instances par fonction : un afflux d'appels se transforme
 * en facture, et le coupe-circuit budgétaire met ensuite toute l'app en maintenance.
 */
export const PUBLIC_MAX_INSTANCES = 5;

/**
 * Callables d'administration : la vérification du claim `admin` se fait DANS le code, donc
 * après le démarrage de l'instance. Un flot anonyme les ferait monter à 100 instances.
 */
export const ADMIN_MAX_INSTANCES = 2;

/**
 * Triggers Firestore (fiche créée ou supprimée, notification, signalement, configuration) : des
 * événements rares, dont le débit suit celui des callables limités ci-dessus. Au-delà de ce plafond,
 * Eventarc représente l'événement plus tard au lieu de démarrer une instance de plus.
 */
export const TRIGGER_MAX_INSTANCES = 3;

/** Coupe-circuit budgétaire : une seule instance traite les alertes, l'une après l'autre. */
export const BUDGET_ALERT_MAX_INSTANCES = 1;

/**
 * Nombre de sauts d'infrastructure ajoutés APRÈS l'IP du client dans X-Forwarded-For.
 * 0 pour un appel direct à l'URL cloudfunctions.net / run.app (l'IP réelle est la dernière
 * entrée). À relever si un Cloud Load Balancer (+1) ou un autre proxy est placé devant ces
 * fonctions : sinon tous les clients partageraient UN compteur et se bloqueraient entre eux.
 */
export const TRUSTED_PROXY_HOPS = 0;

export const LIMITS = {
  // Callables publics : par IP (adaptateur) et par compte (handler).
  resetPasswordIp: { limit: 10, windowMs: 15 * MINUTE },
  resetPasswordAccount: { limit: 3, windowMs: HOUR },
  resetPasswordAccountDay: { limit: 6, windowMs: DAY },

  // Inscription d'un coach depuis l'app : par IP seulement (aucun compte n'existe encore). Large devant
  // un usage humain (un club peut inscrire plusieurs coachs depuis le même réseau), bas devant un script.
  registerIp: { limit: 10, windowMs: HOUR },

  // Callables authentifiés : par uid (adaptateur).
  verificationUid: { limit: 3, windowMs: HOUR },
  deleteAccountUid: { limit: 3, windowMs: HOUR },
  addNotificationUid: { limit: 60, windowMs: HOUR },
  // Effectif : large devant un usage humain (un effectif de 20 se saisit en une fois), bas devant un script.
  createPlayerUid: { limit: 60, windowMs: HOUR },
  deletePlayerUid: { limit: 60, windowMs: HOUR },
  // Clé de recherche Algolia (valable 1 h, gardée en mémoire par l'app) : quelques renouvellements par heure suffisent.
  searchKeyUid: { limit: 30, windowMs: HOUR },
  // Équipes liées : au plus 2 par abonnement, quelques essais d'identifiant ou de mot de passe suffisent.
  createLinkedTeamUid: { limit: 10, windowMs: HOUR },
  resetLinkedTeamPasswordUid: { limit: 10, windowMs: HOUR },
  grantTestSubscriptionUid: { limit: 20, windowMs: HOUR },

  // Endpoints HTTP de la landing.
  deleteMailIp: { limit: 10, windowMs: 15 * MINUTE },
  deleteMailAccount: { limit: 3, windowMs: HOUR },
  deleteMailAccountDay: { limit: 6, windowMs: DAY },
  deleteConfirmIp: { limit: 20, windowMs: 15 * MINUTE },
  supportIp: { limit: 5, windowMs: HOUR },
  // Horaire, pas quotidien : un lot de requêtes ne bloque le support (exigé par les stores) qu'une
  // heure. Le reCAPTCHA Enterprise est vérifié côté serveur avant ces compteurs globaux (config/recaptcha.ts) :
  // il est le vrai remède, ce plafond n'est que le filet de sécurité.
  supportGlobal: { limit: 20, windowMs: HOUR },

  // Tous les mails déclenchés par un appel public (réinitialisation, suppression de compte) : le
  // quota Resend est partagé avec les invitations des coachs, qui ne passent pas par ce plafond.
  publicMailGlobal: { limit: 300, windowMs: DAY },
} as const;
