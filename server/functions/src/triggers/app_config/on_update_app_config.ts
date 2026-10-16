/**
 * Module du socle commun des projets.
 */
import { firestore } from "firebase-admin";
import { AppMetadataConfig } from "../../model/config/app_metadata_config";
import { UserProvider } from "../../provider/user_provider";
import { UserRepository } from "../../database/user/user_repository";
import { UserModel } from "../../model/user/user_model";
import { HttpsError, type LegacyDocumentChange, type LegacyEventContext, logger } from "../../runtime/firebase";
import { describeError } from "../../utils/describe_error";

export default async (snap: LegacyDocumentChange<firestore.DocumentSnapshot<firestore.DocumentData>>, context: LegacyEventContext): Promise<void> => {
  try {
    const id: string = context.params.id;
    const before: AppMetadataConfig = AppMetadataConfig.fromFirestore(snap.before);
    const after: AppMetadataConfig = AppMetadataConfig.fromFirestore(snap.after);

    await onCgvuUpdate(id, before, after);
  } catch (e: any) {
    logger.error(`[Error] onUpdateAppConfig: ${describeError(e)}`);
    throw new HttpsError("internal", e.message);
  }
};

async function onCgvuUpdate(id: string, before: AppMetadataConfig, after: AppMetadataConfig): Promise<void> {
  if (before.cgvu == after.cgvu) {
    logger.log("[onCgvuUpdate] CGVU not updated");
    return;
  }

  const userCollection: firestore.QuerySnapshot<UserModel> = await UserRepository.instance.collection.get();

  for (const user of userCollection.docs) {
    if (user.id == "admin") continue;
    UserProvider.instance.securityRepository.updateField(user.id, "cguAccepted", false);
  }
}
