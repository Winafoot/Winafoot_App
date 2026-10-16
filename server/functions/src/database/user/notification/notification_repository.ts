/**
 * Module du socle commun des projets.
 */
import { SubCollectionRepository } from "../../../interface/interface_subcollection_repository";
import { InternalNotificationModel, InternalNotificationModelConverter } from "../../../model/internal_notification/internal_notification_model";

export class InternalNotificationRepository extends SubCollectionRepository<InternalNotificationModel> {
  private static _instance: InternalNotificationRepository = new InternalNotificationRepository();

  constructor() {
    super("notifications", InternalNotificationModelConverter);

    if (InternalNotificationRepository._instance) {
      throw new Error("Use InternalNotificationRepository.getInstance() instead of new.");
    }
    InternalNotificationRepository._instance = this;
  }

  public static get instance(): InternalNotificationRepository {
    return InternalNotificationRepository._instance;
  }
}
