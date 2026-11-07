import { defineSecret, SecretParam } from "firebase-functions/params";

/**
 * Secrets Secret Manager. Une fonction n'accède à un secret que si elle le déclare dans ses options
 * (`secrets`) : Cloud Run le monte alors en variable d'environnement au démarrage de l'instance.
 * test/secrets.test.ts vérifie que chaque fonction exportée déclare exactement les secrets que lit
 * son code.
 *
 *   RESEND_API_KEY       envoi des e-mails (Resend)
 *   ALGOLIA_WRITE_KEY    synchronisation des index Algolia (triggers de recherche)
 *   ALGOLIA_SEARCH_KEY   clé parente des clés de recherche temporaires (getSearchKey)
 *   REVENUECAT_WEBHOOK_SECRET  jeton d'autorisation du webhook RevenueCat (revenuecatWebhook)
 *   APPSTORE_KEY_ID, APPSTORE_ISSUER_ID, APPSTORE_PRIVATE_KEY  clé API App Store Connect (codes d'offre Apple du back-office)
 */
export const RESEND_API_KEY = defineSecret("RESEND_API_KEY");
export const ALGOLIA_WRITE_KEY = defineSecret("ALGOLIA_WRITE_KEY");
export const ALGOLIA_SEARCH_KEY = defineSecret("ALGOLIA_SEARCH_KEY");
export const REVENUECAT_WEBHOOK_SECRET = defineSecret("REVENUECAT_WEBHOOK_SECRET");
export const APPSTORE_KEY_ID = defineSecret("APPSTORE_KEY_ID");
export const APPSTORE_ISSUER_ID = defineSecret("APPSTORE_ISSUER_ID");
export const APPSTORE_PRIVATE_KEY = defineSecret("APPSTORE_PRIVATE_KEY");

export const MAILER_SECRET_PARAMS: SecretParam[] = [RESEND_API_KEY];

export const ALGOLIA_WRITE_SECRET_PARAMS: SecretParam[] = [ALGOLIA_WRITE_KEY];

export const ALGOLIA_SEARCH_SECRET_PARAMS: SecretParam[] = [ALGOLIA_SEARCH_KEY];

export const REVENUECAT_SECRET_PARAMS: SecretParam[] = [REVENUECAT_WEBHOOK_SECRET];

export const APPSTORE_SECRET_PARAMS: SecretParam[] = [APPSTORE_KEY_ID, APPSTORE_ISSUER_ID, APPSTORE_PRIVATE_KEY];

/** Valeur du secret sans espaces autour, ou `undefined` s'il est absent ou vide (secret non déclaré par la fonction). */
export function readSecret(secret: SecretParam): string | undefined {
  try {
    const value = secret.value().trim();
    return value.length > 0 ? value : undefined;
  } catch {
    return undefined;
  }
}
