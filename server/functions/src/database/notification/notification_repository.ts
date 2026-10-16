/**
 * Module du socle commun des projets.
 */
import { RootRepository } from "../../interface/interface_root_repository";
import { NotificationModel, NotificationModelConverter } from "../../model/notification/notification_model";

export class NotificationRepository extends RootRepository<NotificationModel> {
  private static _instance: NotificationRepository = new NotificationRepository();

  constructor() {
    super("notifications", NotificationModelConverter);

    if (NotificationRepository._instance) {
      throw new Error("Use NotificationRepository.getInstance() instead of new.");
    }
    NotificationRepository._instance = this;
  }

  public static get instance(): NotificationRepository {
    return NotificationRepository._instance;
  }

  public createBetCanceled(betId: string, betTitle: string, listUserId: string[]) {
    return super.add({
      sendToIds: listUserId,
      title: `Paris annulé`,
      body: `Votre paris de ${betTitle} a été annulé`,
      type: "bet-cancelled",
      toTopic: false,
      metadata: {
        betId: betId,
      },
    });
  }
}
