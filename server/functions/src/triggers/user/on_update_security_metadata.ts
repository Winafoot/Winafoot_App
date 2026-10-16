import { firestore } from "firebase-admin";
import { DocumentSnapshot } from "firebase-functions/v2/firestore";
import { LegacyDocumentChange, LegacyEventContext, logger } from "../../runtime/firebase";
import { describeError } from "../../utils/describe_error";

/**
 * Recopie `profilCompleted` de users/{uid}/metadata/security vers le document
 * racine users/{uid}. L'app n'écrit que dans la sous-collection
 * (CoachProfileRepository.markProfilCompleted), or le back-office ne sait lister
 * que des champs du document racine.
 */
export default async (change: LegacyDocumentChange<DocumentSnapshot>, context: LegacyEventContext): Promise<void> => {
  const before = change.before.get("profilCompleted");
  const after = change.after.get("profilCompleted");

  if (before === after) {
    return;
  }

  try {
    await firestore()
      .collection("users")
      .doc(context.params.userId)
      .update({ profilCompleted: after ?? false });
  } catch (e) {
    logger.warn(`[Warn] onUpdateSecurityMetadata: document utilisateur absent : ${describeError(e)}`);
  }
};
