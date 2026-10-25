import { auth } from "firebase-admin";
import { HttpsError } from "../../runtime/firebase";
import type { AuthedCaller } from "../../runtime/v2_authed";
import { consumeCode } from "../../utils/otp_code";

/**
 * verifyEmailCode : callable authentifié, appelé par l'écran « Confirmez votre adresse e-mail ».
 *
 * L'identité vient du jeton. Le code (6 chiffres, reçu par sendEmailVerification) est consommé dès
 * qu'il est bon, puis l'adresse du compte est marquée vérifiée avec l'Admin SDK : le client ne peut
 * pas poser `emailVerified` lui-même. Un code faux, expiré ou épuisé répond `invalid-argument`, sans
 * autre indice. Le plafond d'essais est porté par le code (utils/otp_code.ts), la limite de débit
 * par l'adaptateur (runtime/v2_limited.ts).
 */
export default async (data: { code?: unknown }, caller: AuthedCaller): Promise<boolean> => {
  const account = await auth().getUser(caller.uid);
  if (account.emailVerified) return true;

  if (!(await consumeCode("verify-email", caller.uid, data?.code))) {
    throw new HttpsError("invalid-argument", "Code invalide ou expiré.");
  }

  await auth().updateUser(caller.uid, { emailVerified: true });
  return true;
};
