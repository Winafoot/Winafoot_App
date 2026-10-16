/**
 * Module du socle commun des projets.
 */
import * as admin from "firebase-admin";
import { InternalNotificationModel } from "../../model/internal_notification/internal_notification_model";
import { UserModelNullable } from "../../model/user/user_model";
import { UserProvider } from "../../provider/user_provider";
import { InternalNotificationRepository } from "../../database/user/notification/notification_repository";
import { UserRepository } from "../../database/user/user_repository";
import { NotificationRepository } from "../../database/notification/notification_repository";
import { logger } from "../../runtime/firebase";
import { describeError } from "../../utils/describe_error";

interface NotificationRequest {
  internalNotifModel?: InternalNotificationModel;
  addNotifTo?: string[];
  senderId?: string;
  sendPushNotif: boolean | true;
}

export default async (data: NotificationRequest) => {
  try {
    await handleNotificationRequest(data);
    return true;
  } catch (e) {
    logger.error(`[Error] addNotification: ${describeError(e)}`);
    return { error: e };
  }
};

async function handleNotificationRequest(data: NotificationRequest): Promise<void> {
  const userData: UserModelNullable = await UserProvider.instance.getUser(data.senderId!);

  if (!data.internalNotifModel) throw new Error("internalNotifModel is required");
  if (!data.addNotifTo) throw new Error("addNotifTo is required");
  if (!data.senderId) throw new Error("senderId is required");

  if (userData == undefined || userData == null) {
    throw new Error("userData is null or undefined");
  }

  logger.info(`START For ${data.addNotifTo.length} users`);
  for (const id of data.addNotifTo) {
    await InternalNotificationRepository.instance.add(UserRepository.instance.getDocumentReference(id), {
      title: data.internalNotifModel.title ?? "package.commentary.notification.title",
      body: data.internalNotifModel.body,
      metadata: data.internalNotifModel.metadata,
      senderRef: UserRepository.instance.getDocumentReference(id),
      sender: {
        id: userData?.id ?? "id",
        lastname: userData?.lastname ?? "lastname",
        firstname: userData?.firstname ?? "firstname",
        email: userData?.email ?? "email",
        userProfileImage: userData?.userProfileImage,
      },
      type: data.internalNotifModel.type ?? "commentary",
      sendAt: admin.firestore.Timestamp.now(),
      isRead: false,
    });
  }
  if (data.sendPushNotif) {
    await NotificationRepository.instance.add({
      sendToIds: data.addNotifTo,
      title: data.internalNotifModel?.title ?? "Nouvelle notification",
      body: data.internalNotifModel?.body ?? "vous avez une nouvelle notification",
      type: data.internalNotifModel?.type ?? "undefined",
      toTopic: false,
      metadata: data.internalNotifModel?.metadata ?? {},
    });
  }
}

export { handleNotificationRequest, NotificationRequest };
