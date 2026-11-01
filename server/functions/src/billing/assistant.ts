import { auth, firestore } from "firebase-admin";

/**
 * Adjoint du coach : un compte Auth unique par coach, qui voit le match en cours et y saisit des
 * statistiques. Il se connecte comme un compte d'équipe liée (identifiant, adresse technique
 * `<identifiant>@equipes.wina.invalid`, donc un identifiant n'est jamais pris par les deux).
 *
 * - La fiche `users/{assistantUid}` porte `assistantOf` (uid du coach), jamais `ownerUid` : l'adjoint
 *   n'apparaît pas dans « Mes équipes ».
 * - Le custom claim `assistantOf` (posé par createAssistant seul) ouvre la lecture de
 *   `users/{coach}/liveMatch/current` et la création de commandes dans les règles Firestore.
 * - `users/{coach}/assistant/current` ({ uid, identifier }) est ce que le coach lit pour afficher son adjoint.
 */
export function assistantRef(coachUid: string): firestore.DocumentReference {
  return firestore().collection("users").doc(coachUid).collection("assistant").doc("current");
}

/**
 * Supprime l'adjoint du coach `coachUid` (Auth, fiche et document de liaison) ; idempotent.
 * Appelé aussi à la suppression du compte du coach (detachFromTeams).
 */
export async function removeAssistant(coachUid: string): Promise<void> {
  const link = await assistantRef(coachUid).get();
  const uid: unknown = link.get("uid");
  if (typeof uid === "string") {
    await auth()
      .deleteUser(uid)
      .catch((e: any) => {
        if (e?.code !== "auth/user-not-found") throw e;
      });
    await firestore().recursiveDelete(firestore().collection("users").doc(uid));
  }
  await assistantRef(coachUid).delete();
}
