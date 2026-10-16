/**
 * Module du socle commun des projets.
 */
import { firestore, messaging } from "firebase-admin";
import { NotificationModel } from "../../model/notification/notification_model";
import { UserProvider } from "../../provider/user_provider";
import { UserMetadataModel } from "../../model/user/metadata/user_metadata_model";
import { type LegacyEventContext, logger } from "../../runtime/firebase";
import { describeError } from "../../utils/describe_error";

// Limite imposée par FCM sur `sendEachForMulticast`.
const MULTICAST_CHUNK_SIZE = 500;

export default async (snap: firestore.QueryDocumentSnapshot, context: LegacyEventContext) => {
  try {
    const notificationModel: NotificationModel = NotificationModel.fromFirestore(snap);

    const payload = {
      notification: {
        title: notificationModel.title ?? "",
        body: notificationModel.body ?? "",
      },
      data: {
        type: notificationModel.type ?? "",
        metadata: JSON.stringify(notificationModel.metadata ?? {}),
        // Cible du deeplink : route explicite si le modèle en porte une,
        // sinon le type de la notification sert de route.
        route: notificationModel.route || notificationModel.type || "",
        entityId: notificationModel.entityId ?? "",
      },
    };

    if (notificationModel.toTopic == true && notificationModel.topic != null && notificationModel.topic != "") {
      await messaging().send({
        topic: notificationModel.topic,
        ...payload,
      });
    } else {
      const tokens: string[] = [];
      // Aligné sur `tokens` : permet de logger l'utilisateur en échec sans
      // jamais exposer son jeton FCM.
      const tokenUserIds: string[] = [];
      for (const userId of notificationModel.sendToIds) {
        const user: UserMetadataModel | undefined = await UserProvider.instance.metadataRepository.getDocument(userId);

        if (user == undefined || user == null) {
          logger.warn(`User ${userId} doesn't have a valide UserMetadataModel`);
          continue;
        }

        if (!user.fcmToken) continue;
        tokens.push(user.fcmToken);
        tokenUserIds.push(userId);
      }

      if (tokens.length > 0) {
        logger.warn(`Sending notifications to : ${tokens.length}`);
        // Envoi groupé : FCM plafonne sendEachForMulticast à 500 jetons par appel.
        for (let i = 0; i < tokens.length; i += MULTICAST_CHUNK_SIZE) {
          const response = await messaging().sendEachForMulticast({
            tokens: tokens.slice(i, i + MULTICAST_CHUNK_SIZE),
            ...payload,
          });
          response.responses.forEach((result, index) => {
            if (!result.success) {
              logger.error(`Error while sending notification to user ${tokenUserIds[i + index]} : ${describeError(result.error)}`);
            }
          });
        }
      } else {
        logger.warn(`Can't send notification because all user assign don't have a token`);
      }
    }

    await snap.ref.update({
      sendingStatus: "success",
    });
    return { code: 200, message: "success" };
  } catch (e) {
    logger.error(`[Error] sendPushNotification: ${describeError(e)}`);
    await snap.ref.update({
      sendingStatus: "error",
    });
    return { error: e };
  }
};
