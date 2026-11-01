import { auth } from "firebase-admin";
import { HttpsError, logger } from "../../runtime/firebase";
import { describeError } from "../../utils/describe_error";
import { consumeCode } from "../../utils/otp_code";
import { assertPasswordPolicy } from "../admin/_password_policy";

/**
 * confirmPasswordReset : callable public, appelé par l'écran « Mot de passe oublié » une fois le code
 * reçu par sendResetPassword.
 *
 * Le mot de passe est contrôlé AVANT le code : un mot de passe refusé ne consomme ni essai ni code.
 * Un compte inconnu, un code faux, expiré ou épuisé répondent tous la même chose (`invalid-argument`,
 * « Code invalide ou expiré. ») : la réponse ne révèle pas si l'adresse a un compte. Le code est
 * consommé dès qu'il est bon ; les sessions ouvertes du compte sont ensuite révoquées.
 *
 * Limite de débit par IP dans l'adaptateur (runtime/v2_limited.ts) ; le plafond d'essais par code
 * (utils/otp_code.ts) empêche de deviner les 6 chiffres.
 */
export default async (data: { email?: unknown; code?: unknown; newPassword?: unknown }): Promise<boolean> => {
  if (typeof data?.email !== "string" || data.email.trim().length === 0) {
    throw new HttpsError("invalid-argument", "email est requis.");
  }
  assertPasswordPolicy(data.newPassword);

  let uid: string;
  try {
    uid = (await auth().getUserByEmail(data.email.trim())).uid;
  } catch {
    throw new HttpsError("invalid-argument", "Code invalide ou expiré.");
  }

  if (!(await consumeCode("reset-password", uid, data.code))) {
    throw new HttpsError("invalid-argument", "Code invalide ou expiré.");
  }

  try {
    await auth().updateUser(uid, { password: data.newPassword });
    await auth().revokeRefreshTokens(uid);
  } catch (e) {
    logger.error(`[Error] confirmPasswordReset: ${describeError(e)}`);
    throw new HttpsError("internal", "La réinitialisation a échoué, réessayez.");
  }
  return true;
};
