/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";
import { AppMetadataConfig, AppMetadataConfigConverter } from "../../model/config/app_metadata_config";

export class AppConfigRepository {
  private static _instance: AppConfigRepository = new AppConfigRepository();

  constructor() {
    if (AppConfigRepository._instance) {
      throw new Error("Use AppConfigRepository.getInstance() instead of new.");
    }
    AppConfigRepository._instance = this;
  }

  public static get instance(): AppConfigRepository {
    return AppConfigRepository._instance;
  }

  public async getMetadata(): Promise<AppMetadataConfig | undefined> {
    return (await firestore().collection("app_config").withConverter(AppMetadataConfigConverter).doc("metadata").get()).data();
  }
}
