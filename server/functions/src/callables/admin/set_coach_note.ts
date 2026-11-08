import type { AdminCaller } from "../../runtime/v2_admin";
import { setCoachNote, type CoachNote } from "./coach_note";

/** Enregistre la note interne d'un coach (texte vide : la note est effacée). */
export default async (data: { uid: string; text: string }, caller: AdminCaller): Promise<CoachNote> => setCoachNote(data, caller);
