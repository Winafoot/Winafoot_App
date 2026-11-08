import type { AdminCaller } from "../../runtime/v2_admin";
import { getCoachNote, type CoachNote } from "./coach_note";

/** Note interne d'un coach, pour sa fiche du back-office. Lecture seule. */
export default async (data: { uid: string }, caller: AdminCaller): Promise<CoachNote> => getCoachNote(data, caller);
