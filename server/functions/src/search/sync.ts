import { type DocumentSnapshot } from "firebase-functions/v2/firestore";
import { ALGOLIA_INDICES } from "../config/algolia";
import { type LegacyDocumentChange, type LegacyWrittenEventContext, logger } from "../runtime/firebase";
import { AlgoliaFailure, type AlgoliaWriter, type AlgoliaWriterFactory, createAlgoliaWriter } from "./algolia_client";
import { objectId, ownerKey } from "./ids";
import { projectComposition, projectMatch, type SearchFields, type SnapshotLike, toRecord } from "./records";

/** Une collection synchronisée : son index et sa projection (nulle = non indexable). */
export interface SyncTarget {
  indexName: string;
  project: (snapshot: SnapshotLike | undefined) => SearchFields | null;
}

export const SYNC_TARGETS = {
  compositions: { indexName: ALGOLIA_INDICES.compositions, project: projectComposition },
  matches: { indexName: ALGOLIA_INDICES.matches, project: projectMatch },
} as const satisfies Record<string, SyncTarget>;

/** Fenêtre de relance des fonctions 2nd gen : au-delà, l'événement serait de toute façon écarté. */
const MAX_EVENT_AGE_MS = 24 * 60 * 60 * 1000;

type Operation = "upsert" | "delete";

/** Erreur à ne PAS relancer : upsert 400/413 (enregistrement refusé, inutile de rejouer), suppression 404 (rien à supprimer). */
function isPermanent(operation: Operation, failure: AlgoliaFailure): boolean {
  return operation === "upsert" ? failure.status === 400 || failure.status === 413 : failure.status === 404;
}

function isTooOld(eventTime: string): boolean {
  return Date.now() - Date.parse(eventTime) > MAX_EVENT_AGE_MS;
}

/** Applique l'écriture ; une erreur relançable sort telle quelle (AlgoliaFailure, sans requête brute). */
async function write(operation: Operation, ids: string, call: () => Promise<void>): Promise<void> {
  try {
    await call();
  } catch (error) {
    if (!(error instanceof AlgoliaFailure)) throw error;
    if (!isPermanent(operation, error)) {
      logger.warn(`[Warn] syncDocument ${operation} ${ids} : Algolia ${error.status ?? "réseau"} (relance)`);
      throw error;
    }
    logger.error(`[Error] syncDocument ${operation} ${ids} : Algolia ${error.status} (abandon)`);
  }
}

/**
 * Synchronise un document Firestore avec son enregistrement Algolia.
 * Retourne sans erreur pour ne pas relancer ; lève une AlgoliaFailure pour relancer l'événement.
 */
export async function syncDocument(
  target: SyncTarget,
  change: LegacyDocumentChange<DocumentSnapshot>,
  context: LegacyWrittenEventContext,
  createWriter: AlgoliaWriterFactory = createAlgoliaWriter,
): Promise<void> {
  const { userId: uid, docId } = context.params;
  const ids = `${ownerKey(uid)}/${docId}`;

  if (isTooOld(context.eventTime)) {
    logger.warn(`[Warn] syncDocument ${ids} : événement ${context.eventId} de plus de 24 h, ignoré`);
    return;
  }
  if (JSON.stringify(target.project(change.before)) === JSON.stringify(target.project(change.after))) {
    return;
  }

  try {
    await reconcile(target, change.after, createWriter(), uid, docId, ids);
  } catch (error) {
    if (error instanceof AlgoliaFailure) throw error;
    logger.error(`[Error] syncDocument ${ids} : ${(error as Error)?.message}`);
  }
}

/** Une erreur de lecture Firestore est une panne d'infrastructure, pas un bug : on la relance (journal : le code seul, jamais l'objet). */
async function readCurrent(after: DocumentSnapshot, ids: string): Promise<DocumentSnapshot> {
  try {
    return await after.ref.get();
  } catch (error) {
    const code = (error as { code?: unknown })?.code;
    logger.warn(`[Warn] syncDocument ${ids} : lecture Firestore impossible${typeof code === "string" || typeof code === "number" ? ` (${code})` : ""} (relance)`);
    throw new AlgoliaFailure(undefined, "lecture Firestore impossible");
  }
}

/** Relit le document COURANT (l'événement peut être périmé), l'écrit ou le retire, puis referme la fenêtre lecture/écriture. */
async function reconcile(target: SyncTarget, after: DocumentSnapshot, writer: AlgoliaWriter, uid: string, docId: string, ids: string): Promise<void> {
  const remove = () => write("delete", ids, () => writer.deleteObject(target.indexName, objectId(uid, docId)));

  const fields = target.project(await readCurrent(after, ids));
  if (fields == null) {
    await remove();
    return;
  }
  await write("upsert", ids, () => writer.saveObject(target.indexName, toRecord(uid, docId, fields)));
  // Le document a pu être supprimé entre la relecture et l'écriture : sans cela, l'orphelin survivrait.
  if (target.project(await readCurrent(after, ids)) == null) {
    await remove();
  }
}
