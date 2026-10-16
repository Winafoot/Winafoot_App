/**
 * Module du socle commun des projets.
 */
import { MAILER_API_KEY, readSecret } from "../config/secrets";
import { logger } from "../runtime/firebase";

export interface MailerSendConfig {
  apiKey?: string;
}

const warnedFeatures = new Set<string>();

function warnMissingConfig(feature: string, message: string): void {
  if (warnedFeatures.has(feature)) {
    return;
  }

  warnedFeatures.add(feature);
  logger.error(message);
}

export class EnvProvider {
  private static _instance: EnvProvider = new EnvProvider();

  constructor() {
    if (EnvProvider._instance) {
      throw new Error("Use UserRepository.getInstance() instead of new.");
    }
  }

  public static get instance(): EnvProvider {
    return EnvProvider._instance;
  }

  get mailerSendConfig(): MailerSendConfig {
    const mailerConfig: MailerSendConfig = {
      apiKey: readSecret(MAILER_API_KEY),
    };

    if (mailerConfig.apiKey == null) {
      warnMissingConfig("mailer", "Mailer secret config is not set, do not use mailer function");
    }

    return mailerConfig;
  }
}
