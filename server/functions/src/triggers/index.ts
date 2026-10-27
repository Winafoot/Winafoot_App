import { onMessagePublished } from "firebase-functions/v2/pubsub";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { sendTrialRemindersHandler } from "./billing/send_trial_reminders";
import { onBudgetAlertHandler } from "./billing/on_budget_alert";
import { onDocumentCreated, onDocumentDeleted, onDocumentUpdated, onDocumentWritten } from "firebase-functions/v2/firestore";
import { ALGOLIA_ENABLED } from "../config/algolia";
import { BUDGET_ALERT_MAX_INSTANCES, TRIGGER_MAX_INSTANCES } from "../config/rate_limits";
import { ALGOLIA_WRITE_SECRET_PARAMS, MAILER_SECRET_PARAMS } from "../config/secrets";
import { BUDGET_GUARD_SERVICE_ACCOUNT } from "../config/service_accounts";
import { documentCreatedAdapter, documentDeletedAdapter, documentUpdatedAdapter, documentWrittenAdapter } from "../runtime/v2";

/** Configuration : remise à zéro de l'acceptation des CGU quand elles changent. */
export const onUpdateAppConfig = onDocumentUpdated({ document: "app_config/{id}", maxInstances: TRIGGER_MAX_INSTANCES }, documentUpdatedAdapter("triggers/app_config/on_update_app_config"));

/** Notifications : envoi des notifications push. */
export const onCreateNotification = onDocumentCreated({ document: "notifications/{notificationId}", maxInstances: TRIGGER_MAX_INSTANCES }, documentCreatedAdapter("triggers/notification/on_create_notification"));

/** Signalements : e-mail à l'adresse de contact de l'app. */
export const onCreateReport = onDocumentCreated({ document: "reports/{reportId}", secrets: MAILER_SECRET_PARAMS, maxInstances: TRIGGER_MAX_INSTANCES }, documentCreatedAdapter("triggers/report/on_create_report"));

/** Fiches utilisateur : e-mail de bienvenue à la création, nettoyage des sous-documents à la suppression. */
export const onCreateUser = onDocumentCreated({ document: "users/{userId}", secrets: MAILER_SECRET_PARAMS, maxInstances: TRIGGER_MAX_INSTANCES }, documentCreatedAdapter("triggers/user/on_create_user"));
export const onDeleteUser = onDocumentDeleted({ document: "users/{userId}", maxInstances: TRIGGER_MAX_INSTANCES }, documentDeletedAdapter("triggers/user/on_delete_user"));

/** Abonnements : rappel par e-mail 24 à 48 h avant la fin de l'essai gratuit (tous les jours à 10 h, heure de Paris). */
export const sendTrialReminders = onSchedule(
  // europe-west1 : Cloud Scheduler y est disponible, et son quota de CPU Cloud Run n'est pas celui, saturé, d'europe-west9.
  { schedule: "every day 10:00", timeZone: "Europe/Paris", region: "europe-west1", secrets: MAILER_SECRET_PARAMS, maxInstances: TRIGGER_MAX_INSTANCES, timeoutSeconds: 300 },
  sendTrialRemindersHandler,
);

/** Coupe-circuit budgétaire : maintenance et détachement de la facturation si le budget est dépassé. */
// Compte d'exécution propre : seul compte autorisé à détacher la facturation du projet.
export const onBudgetAlert = onMessagePublished(
  { topic: "budget-alerts", maxInstances: BUDGET_ALERT_MAX_INSTANCES, serviceAccount: BUDGET_GUARD_SERVICE_ACCOUNT },
  onBudgetAlertHandler,
);

/** Back-office : recopie de profilCompleted pour la liste des coachs. */
export const onUpdateSecurityMetadata = onDocumentUpdated(
  { document: "users/{userId}/metadata/security", maxInstances: TRIGGER_MAX_INSTANCES },
  documentUpdatedAdapter("triggers/user/on_update_security_metadata")
);

/**
 * Recherche Algolia : recopie des compositions et des matchs terminés (README, section « Recherche »).
 * Tant que ALGOLIA_ENABLED est false : aucun secret lié (déploiement possible sans) et handlers inertes.
 * retry : un échec transitoire (réseau, 429, 5xx, clé absente) est rejoué pendant 24 h.
 * maxInstances 1 : le quota CPU Cloud Run d'europe-west9 est saturé ; une rafale (suppression d'un compte)
 * est absorbée par la concurrence puis par le retry.
 */
const ALGOLIA_SYNC = { secrets: ALGOLIA_ENABLED ? ALGOLIA_WRITE_SECRET_PARAMS : [], retry: true, maxInstances: 1 };
export const onWriteCompositionSearch = onDocumentWritten(
  { document: "users/{userId}/compositions/{docId}", ...ALGOLIA_SYNC },
  documentWrittenAdapter("triggers/search/on_write_composition_search")
);
export const onWriteMatchSearch = onDocumentWritten(
  { document: "users/{userId}/matches/{docId}", ...ALGOLIA_SYNC },
  documentWrittenAdapter("triggers/search/on_write_match_search")
);
