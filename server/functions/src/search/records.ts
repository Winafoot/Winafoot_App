import { firestore } from "firebase-admin";
import { formatDateLabel } from "./date_label";
import { objectId, ownerKey } from "./ids";

/** Ce qu'une projection lit d'un instantané (DocumentSnapshot, ou instantané d'un `.select()`). */
export interface SnapshotLike {
  exists: boolean;
  data(): firestore.DocumentData | undefined;
}

export type CompositionFields = {
  name: string;
  formationLabel: string;
  formationDigits: string;
};

export type MatchFields = {
  opponentName: string;
  dateLabel: string;
};

export type SearchFields = CompositionFields | MatchFields;

export type SearchRecord = SearchFields & { objectID: string; ownerKey: string; docId: string };

/** Données du document, ou `undefined` s'il est absent ou illisible : les projections ne lèvent jamais. */
function readData(snapshot: SnapshotLike | undefined): firestore.DocumentData | undefined {
  try {
    if (snapshot == null || !snapshot.exists) return undefined;
    const data = snapshot.data();
    return data != null && typeof data === "object" ? data : undefined;
  } catch {
    return undefined;
  }
}

/** Composition indexée si `name` et `formationLabel` sont des chaînes ; sinon `null`. */
export function projectComposition(snapshot: SnapshotLike | undefined): CompositionFields | null {
  const data = readData(snapshot);
  if (data == null || typeof data.name !== "string" || typeof data.formationLabel !== "string") return null;
  return { name: data.name, formationLabel: data.formationLabel, formationDigits: data.formationLabel.replace(/\D/g, "") };
}

/** Match indexé s'il est terminé, daté (Timestamp) et son adversaire nommé ; sinon `null`. */
export function projectMatch(snapshot: SnapshotLike | undefined): MatchFields | null {
  const data = readData(snapshot);
  if (data == null || data.status !== "finished" || !(data.finishedAt instanceof firestore.Timestamp)) return null;
  const opponentName = data.opponent?.name;
  if (typeof opponentName !== "string") return null;
  return { opponentName, dateLabel: formatDateLabel(data.finishedAt.toDate()) };
}

/** Enregistrement Algolia : champs projetés + identifiants hachés + docId. Jamais l'uid. */
export function toRecord(uid: string, docId: string, fields: SearchFields): SearchRecord {
  return { objectID: objectId(uid, docId), ownerKey: ownerKey(uid), docId, ...fields };
}
