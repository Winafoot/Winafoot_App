import { firestore } from "firebase-admin";
import { HttpsError } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import { toJson } from "./_serialize";

const MAX_LENGTH = 4000;

export interface CoachNote {
  text: string;
  updatedAt: string | null;
  updatedBy: string | null;
}

function validUid(uid: unknown): string {
  if (typeof uid !== "string" || uid.length === 0 || uid.length > 128 || uid.includes("/")) {
    throw new HttpsError("invalid-argument", "Compte invalide.");
  }
  return uid;
}

/** Note interne d'un coach (`admin_notes/{uid}`) : collection fermée aux clients, visible des administrateurs seuls. */
export async function getCoachNote(data: { uid: string }, _caller: AdminCaller): Promise<CoachNote> {
  const snap = await firestore().collection("admin_notes").doc(validUid(data?.uid)).get();
  return {
    text: snap.get("text") ?? "",
    updatedAt: (toJson(snap.get("updatedAt")) as string | undefined) ?? null,
    updatedBy: snap.get("updatedBy") ?? null,
  };
}

/** Enregistre (ou efface, si le texte est vide) la note interne d'un coach. */
export async function setCoachNote(data: { uid: string; text: string }, caller: AdminCaller): Promise<CoachNote> {
  const uid = validUid(data?.uid);
  if (typeof data.text !== "string") throw new HttpsError("invalid-argument", "Note invalide.");
  const text = data.text.trim();
  if (text.length > MAX_LENGTH) throw new HttpsError("invalid-argument", `La note est limitée à ${MAX_LENGTH} caractères.`);
  if (!(await firestore().collection("users").doc(uid).get()).exists) throw new HttpsError("not-found", "Compte introuvable.");

  const ref = firestore().collection("admin_notes").doc(uid);
  if (text === "") {
    await ref.delete();
    return { text: "", updatedAt: null, updatedBy: null };
  }
  const updatedBy = caller.email ?? caller.uid;
  const updatedAt = firestore.Timestamp.now();
  await ref.set({ text, updatedAt, updatedBy });
  return { text, updatedAt: updatedAt.toDate().toISOString(), updatedBy };
}
