/**
 * Module du socle commun des projets.
 */
import { auth, firestore, storage } from "firebase-admin";
import { DeletedUserRepositoryRepository } from "../../database/deleted_users/deleted_user_repository";
import { UserRecord } from "firebase-admin/auth";
import { HttpsError, logger } from "../../runtime/firebase";
import { describeError } from "../../utils/describe_error";
import { detachFromTeams } from "../../billing/linked_teams";

interface DeleteAccountData {
  uid: string;
}

/**
 * Supprime le compte `uid` : archive (deleted_users), compte Auth, fiche Firestore et ses
 * sous-collections, puis fichiers Storage du dossier users/{uid}. Chaque étape est attendue ;
 * un échec remonte une HttpsError. La purge Storage est la seule étape non bloquante : le compte
 * et ses données sont déjà supprimés quand elle s'exécute.
 */
export default async (data: DeleteAccountData): Promise<true> => {
  let user: UserRecord;
  try {
    user = await auth().getUser(data.uid);
  } catch (e: any) {
    if (e?.code === "auth/user-not-found") {
      throw new HttpsError("not-found", "Compte introuvable.");
    }
    logger.error(`[Error] deleteAccount: lecture du compte impossible : ${describeError(e)}`);
    throw new HttpsError("internal", "La suppression du compte a échoué, réessayez.");
  }

  try {
    // Comptes d'équipe liés : supprimés avec leur propriétaire (ou place libérée si c'est un compte lié).
    await detachFromTeams(user.uid);
  } catch (e) {
    logger.error(`[Error] deleteAccount: comptes d'équipe non supprimés : ${describeError(e)}`);
    throw new HttpsError("internal", "La suppression du compte a échoué, réessayez.");
  }

  try {
    await DeletedUserRepositoryRepository.instance.addFromUserRecord(user);
    await auth().deleteUser(user.uid);
  } catch (e) {
    logger.error(`[Error] deleteAccount: archivage ou suppression du compte impossible : ${describeError(e)}`);
    throw new HttpsError("internal", "La suppression du compte a échoué, réessayez.");
  }

  try {
    await firestore().recursiveDelete(firestore().collection("users").doc(user.uid));
  } catch (e) {
    // Le compte Auth est déjà supprimé : un nouvel essai échouerait sur « Compte introuvable ».
    logger.error(`[Error] deleteAccount: suppression Firestore incomplète après suppression du compte : ${describeError(e)}`);
    throw new HttpsError("internal", "Le compte a été supprimé mais ses données n'ont pas pu être entièrement effacées.");
  }

  try {
    // storage().bucket() lève une exception SYNCHRONE quand aucun bucket n'est configuré.
    await storage().bucket().deleteFiles({ prefix: `users/${user.uid}/` });
  } catch (e) {
    logger.warn(`[Warn] deleteAccount: purge Storage partielle : ${describeError(e)}`);
  }

  return true;
};
