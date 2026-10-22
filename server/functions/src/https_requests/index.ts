import { onRequest } from "firebase-functions/v2/https";
import { PUBLIC_MAX_INSTANCES } from "../config/rate_limits";
import { MAILER_SECRET_PARAMS, REVENUECAT_SECRET_PARAMS } from "../config/secrets";
import { requestAdapter } from "../runtime/v2";

/**
 * Endpoints HTTP publics de la landing (support, suppression de compte), exigés pour la soumission
 * aux stores. Les noms sont ceux qu'appelle la landing : ils ne changent pas.
 *
 * Ils pointent vers les handlers `*_secured` (voir _landing_endpoint.ts) ; le test d'exports verrouille
 * ce câblage.
 */
export const onSendLandingPageMail = onRequest({ secrets: MAILER_SECRET_PARAMS, maxInstances: PUBLIC_MAX_INSTANCES }, requestAdapter("https_requests/landing_page/send_landing_page_mail_secured"));
export const onSendLandingPageMailDeleteAccount = onRequest({ secrets: MAILER_SECRET_PARAMS, maxInstances: PUBLIC_MAX_INSTANCES }, requestAdapter("https_requests/landing_page/send_delete_account_mail_secured"));
export const deleteAccountByEmail = onRequest({ maxInstances: PUBLIC_MAX_INSTANCES }, requestAdapter("https_requests/landing_page/delete_account_by_email_secured"));

// Webhook RevenueCat : appelé par RevenueCat seul, protégé par le secret REVENUECAT_WEBHOOK_SECRET (pas d'App Check sur onRequest).
export const revenuecatWebhook = onRequest({ secrets: REVENUECAT_SECRET_PARAMS, maxInstances: PUBLIC_MAX_INSTANCES }, requestAdapter("https_requests/billing/revenuecat_webhook"));
