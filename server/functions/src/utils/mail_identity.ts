import type { AppMetadataConfig } from "../model/config/app_metadata_config";

/** Nom affiché quand `app_config/metadata.appName` est absent ou vide. */
export const DEFAULT_APP_NAME = "Wina";

export interface MailIdentity {
  /** `app_config/metadata.appName`, ou DEFAULT_APP_NAME. */
  appName: string;
  /** `app_config/metadata.contactEmail` ; absent, les e-mails n'affichent aucun lien de contact. */
  contactEmail?: string;
}

/** Nom de l'app et adresse de contact des e-mails, lus dans `app_config/metadata`. */
export function mailIdentity(config: AppMetadataConfig | undefined): MailIdentity {
  const appName = typeof config?.appName === "string" ? config.appName.trim() : "";
  const contactEmail = typeof config?.contactEmail === "string" ? config.contactEmail.trim() : "";
  return {
    appName: appName.length > 0 ? appName : DEFAULT_APP_NAME,
    contactEmail: contactEmail.length > 0 ? contactEmail : undefined,
  };
}
