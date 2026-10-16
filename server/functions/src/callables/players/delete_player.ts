import { firestore } from "firebase-admin";
import { HttpsError } from "../../runtime/firebase";
import type { AuthedCaller } from "../../runtime/v2_authed";

/** Identifiant automatique Firestore ou équivalent : aucun `/`, donc aucun chemin imbriqué. */
const PLAYER_ID = /^[A-Za-z0-9_-]{1,128}$/;

/**
 * Supprime un joueur de l'effectif de l'appelant et recale le compteur sur le nombre réel.
 * La suppression passe par le serveur comme la création : le compteur reste tenu par le serveur seul.
 *
 * Idempotent : un joueur déjà supprimé n'est pas une erreur (nouvel essai après coupure réseau).
 */
export default async (data: { id: string }, caller: AuthedCaller): Promise<{ deleted: boolean }> => {
  const id = (data as { id?: unknown } | null | undefined)?.id;
  if (typeof id !== "string" || !PLAYER_ID.test(id)) {
    throw new HttpsError("invalid-argument", "Identifiant de joueur invalide.");
  }

  const db = firestore();
  const userRef = db.collection("users").doc(caller.uid);
  const players = userRef.collection("players");

  return db.runTransaction(async (tx) => {
    const [player, count] = await Promise.all([tx.get(players.doc(id)), tx.get(players.count())]);
    if (!player.exists) return { deleted: false };

    tx.delete(player.ref);
    tx.set(userRef, { playerCount: Math.max(0, count.data().count - 1) }, { merge: true });
    return { deleted: true };
  });
};
