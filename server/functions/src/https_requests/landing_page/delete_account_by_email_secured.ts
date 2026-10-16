import { auth, firestore, storage } from "firebase-admin";
import { LIMITS } from "../../config/rate_limits";
import { DeletedUserRepositoryRepository } from "../../database/deleted_users/deleted_user_repository";
import { isAdminRecord } from "../../callables/admin/_admin_accounts";
import { logger } from "../../runtime/firebase";
import { authUserByEmail, landingEndpoint } from "./_landing_endpoint";
import { describeError } from "../../utils/describe_error";

// randomBytes(48).toString("hex") : le jeton sert d'identifiant de document, donc
// on n'accepte aucun autre format (chemins, identifiants réservés...).
const TOKEN_PATTERN = /^[0-9a-f]{96}$/;
const FAILURE = { message: "Account deletion failed" };

/**
 * Confirmation de suppression (public/confirm-delete.html : POST { email, token }). Le jeton fait
 * foi, l'e-mail du corps est ignoré.
 *
 * - Le format du jeton est contrôlé avant toute lecture Firestore.
 * - Le jeton est consommé de façon atomique AVANT la suppression (usage unique, même sous deux
 *   requêtes simultanées), et lié au compte (uid) qui l'a demandé : si l'adresse a changé de
 *   titulaire entre la demande et la confirmation, le nouveau titulaire n'est pas supprimé.
 * - Tout ce qui est lié au compte est supprimé : compte Auth, fiche et sous-collections, fichiers
 *   Storage ; l'adresse est archivée dans deleted_users.
 * - Un compte administrateur n'est jamais supprimé ici : il passe par la vue « Administrateurs »
 *   (callable deleteAdmin), qui a son verrou, sa protection du dernier administrateur et son audit.
 */
export default landingEndpoint(async (body, _config, res) => {
  const token = body.token;
  if (typeof token !== "string" || !TOKEN_PATTERN.test(token)) {
    res.status(400).send(FAILURE);
    return;
  }

  try {
    const request = await consumeToken(token);
    const account = request == null ? undefined : await authUserByEmail(request.email);
    if (account == null || (request?.uid != null && request.uid !== account.uid)) {
      res.status(400).send(FAILURE);
      return;
    }

    if (isAdminRecord(account)) {
      logger.warn("[Security] deleteAccountByEmail: suppression refusée, le compte est un compte administrateur");
      res.status(400).send(FAILURE);
      return;
    }

    await DeletedUserRepositoryRepository.instance.addFromUserRecord(account);
    await auth().deleteUser(account.uid);
    await purgeUserData(account.uid);

    res.status(200).send({ message: "User deleted successfully" });
  } catch (e: any) {
    // Message seulement : l'erreur peut citer le chemin du document, donc le jeton.
    logger.error(`[Error] deleteAccountByEmail: ${e?.message ?? "erreur inconnue"}`);
    res.status(400).send(FAILURE);
  }
}, { scope: "delete-confirm", perIp: LIMITS.deleteConfirmIp });

/** Lit et supprime le jeton dans une transaction. Renvoie sa demande s'il est valide et non expiré. */
async function consumeToken(token: string): Promise<{ email: string; uid?: string } | undefined> {
  const ref = firestore().collection("accountDeletionRequests").doc(token);

  return firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return undefined;

    tx.delete(ref); // consommé même s'il est expiré
    const email = snap.get("email");
    const uid = snap.get("uid");
    const expiresAt = snap.get("expiresAt");
    const valid = typeof email === "string" && typeof expiresAt?.toMillis === "function" && expiresAt.toMillis() >= Date.now();
    return valid ? { email, uid: typeof uid === "string" ? uid : undefined } : undefined;
  });
}

/** Le compte Auth est déjà supprimé et irrécupérable : on journalise un échec, on ne le rejoue pas. */
async function purgeUserData(uid: string): Promise<void> {
  try {
    await firestore().recursiveDelete(firestore().collection("users").doc(uid));
  } catch (e: any) {
    logger.error(`[Error] deleteAccountByEmail: suppression Firestore incomplète : ${describeError(e)}`);
  }

  try {
    // storage().bucket() lève une exception SYNCHRONE quand aucun bucket n'est configuré.
    await storage().bucket().deleteFiles({ prefix: `users/${uid}/` });
  } catch (e: any) {
    logger.warn(`[Warn] deleteAccountByEmail: purge Storage partielle : ${describeError(e)}`);
  }
}
