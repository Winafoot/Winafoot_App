import { type DocumentSnapshot } from "firebase-functions/v2/firestore";
import { ALGOLIA_ENABLED } from "../../config/algolia";
import { type LegacyDocumentChange, type LegacyWrittenEventContext } from "../../runtime/firebase";
import { SYNC_TARGETS, syncDocument } from "../../search/sync";

/** Recopie users/{uid}/matches/{id} dans l'index Algolia wina_matches (matchs terminés seulement). */
export default async (change: LegacyDocumentChange<DocumentSnapshot>, context: LegacyWrittenEventContext): Promise<void> => {
  // Interrupteur coupé : retour immédiat, sans exception (une exception relancerait l'événement pendant 24 h).
  if (!ALGOLIA_ENABLED) return;
  await syncDocument(SYNC_TARGETS.matches, change, context);
};
