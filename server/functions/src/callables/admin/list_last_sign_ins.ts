import { auth } from "firebase-admin";
import type { AdminCaller } from "../../runtime/v2_admin";
import { isoOrNull } from "./_admin_accounts";

export interface ListLastSignInsResult {
  /** uid → date ISO de la dernière connexion (null : jamais connecté). */
  lastSignIns: Record<string, string | null>;
}

/**
 * Dernière connexion de chaque compte, lue dans Firebase Auth (`metadata.lastSignInTime`) : la fiche
 * Firestore ne la porte pas. Lecture seule, rien n'est journalisé ; la vue « Coachs » joint par uid.
 */
export default async (_data: unknown, _caller: AdminCaller): Promise<ListLastSignInsResult> => {
  const lastSignIns: Record<string, string | null> = {};
  let pageToken: string | undefined;
  do {
    const page = await auth().listUsers(1000, pageToken);
    for (const user of page.users) {
      lastSignIns[user.uid] = isoOrNull(user.metadata.lastSignInTime);
    }
    pageToken = page.pageToken;
  } while (pageToken != null);
  return { lastSignIns };
};
