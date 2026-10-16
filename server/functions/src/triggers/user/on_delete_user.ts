import { firestore } from "firebase-admin";
import { UserProvider } from "../../provider/user_provider";
import { InternalNotificationRepository } from "../../database/user/notification/notification_repository";
import { HttpsError, type LegacyEventContext, logger } from "../../runtime/firebase";
import { describeError } from "../../utils/describe_error";

export default async (snapshot: firestore.DocumentSnapshot<firestore.DocumentData>, context: LegacyEventContext): Promise<void> => {
  try {
    const userId: string = context.params.userId;

    await UserProvider.instance.metadataRepository.deleteDocument(userId);
    await UserProvider.instance.securityRepository.deleteDocument(userId);
    await InternalNotificationRepository.instance.deleteCollectionFromParent(snapshot.ref);
  } catch (e: any) {
    logger.error(`[Error] onDeleteUser: ${describeError(e)}`);
    throw new HttpsError("internal", e.message);
  }
};
