import { auth } from "firebase-admin";
import { logger } from "../../runtime/firebase";
import { describeError } from "../../utils/describe_error";
import type { AuthedCaller } from "../../runtime/v2_authed";
import { UserProvider } from "../../provider/user_provider";
import sendEmailVerificationSkeleton from "./send_email_verification";

/**
 * Garde devant le handler du socle `send_email_verification`.
 *
 * L'identité vient du jeton. Le socle lit l'adresse à vérifier dans users/{uid}.email, un champ que
 * le client écrit lui-même : le socle n'est appelé que si cette fiche porte bien l'adresse du compte
 * Auth de l'appelant.
 *
 * Le socle répond par un booléen : `true` seulement si l'e-mail est parti. Le délai de 6 h entre deux
 * envois (lastVerifEmailAt) vit dans metadata/security, dont les règles réservent ce champ au serveur.
 */
export default async (_data: unknown, caller: AuthedCaller): Promise<boolean> => {
  try {
    const [account, profile] = await Promise.all([auth().getUser(caller.uid), UserProvider.instance.getUser(caller.uid)]);

    if (account.email == null || profile?.email?.toLowerCase() !== account.email.toLowerCase()) {
      return false;
    }

    return await sendEmailVerificationSkeleton({ uid: caller.uid });
  } catch (e) {
    logger.error(`[Error] sendEmailVerification: ${describeError(e)}`);
    return false;
  }
};
