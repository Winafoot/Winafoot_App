import { auth } from "firebase-admin";
import { HttpsError, logger } from "../../runtime/firebase";
import { describeError } from "../../utils/describe_error";
import { assertPasswordPolicy } from "../admin/_password_policy";
import { validateDisplayName } from "../admin/_admin_accounts";
import { isLinkedEmail } from "../../billing/linked_teams";
import { removeCoachDocuments, writeCoachDocuments } from "./_coach_documents";

export interface RegisterCoachData {
  email: string;
  password: string;
  firstname: string;
  acceptedCgu: boolean;
}

export interface RegisterCoachResult {
  uid: string;
}

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const EMAIL_MAX_LENGTH = 254;

/**
 * Inscription d'un coach depuis l'app (page 1 : e-mail, mot de passe, prénom, CGU).
 *
 * Appelable sans authentification ; la limite par IP est posée par l'adaptateur (callables/index.ts).
 * Crée le compte Auth puis les trois documents que l'app attend (voir createCoach) : `users/{uid}`,
 * `users/{uid}/metadata/security` et `users/{uid}/metadata/metadata`. Le format du club, la
 * catégorie et la division sont saisis à la page 2 (« Finalisez votre profil »), d'où
 * `profilCompleted: false`. Pas de `invitedByAdmin` : onCreateUser envoie l'e-mail de bienvenue.
 *
 * Si l'écriture Firestore échoue, le compte Auth et les documents déjà écrits sont supprimés :
 * aucun compte à moitié créé ne reste, l'appelant peut réessayer avec la même adresse.
 */
export default async (data: RegisterCoachData): Promise<RegisterCoachResult> => {
  // Types contrôlés avant tout trim : un objet ou un nombre serait converti en chaîne.
  if (typeof data?.email !== "string" || typeof data?.firstname !== "string") {
    throw new HttpsError("invalid-argument", "Données d'inscription invalides.");
  }
  const email: string = data.email.trim().toLowerCase();
  const firstname: string = data.firstname.trim();

  if (!EMAIL_PATTERN.test(email) || email.length > EMAIL_MAX_LENGTH) {
    throw new HttpsError("invalid-argument", "Adresse e-mail invalide.");
  }
  // Cette adresse est celle des comptes d'équipe liés : un coach ne peut pas s'en servir.
  if (isLinkedEmail(email)) {
    throw new HttpsError("invalid-argument", "Adresse e-mail invalide.");
  }
  if (firstname.length === 0) {
    throw new HttpsError("invalid-argument", "Le prénom est obligatoire.");
  }
  validateDisplayName(firstname);
  // L'Admin SDK n'applique pas la politique de mot de passe du projet : sans ce contrôle, le coach
  // recevrait un compte qu'il ne pourrait pas rouvrir après un changement de mot de passe.
  assertPasswordPolicy(data.password);
  if (data.acceptedCgu !== true) {
    throw new HttpsError("failed-precondition", "Vous devez accepter les conditions générales d'utilisation.");
  }

  let uid: string;
  try {
    const record = await auth().createUser({ email, password: data.password, emailVerified: false, disabled: false });
    uid = record.uid;
  } catch (e: any) {
    if (e?.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "Un compte existe déjà pour cette adresse.");
    }
    if (e?.code === "auth/invalid-password") {
      throw new HttpsError(
        "invalid-argument",
        "Mot de passe refusé : il doit respecter la politique de sécurité (majuscule, minuscule, chiffre et caractère spécial).",
      );
    }
    logger.error(`[Error] registerCoach: auth().createUser a échoué : ${describeError(e)}`);
    throw new HttpsError("internal", "La création du compte a échoué, réessayez.");
  }

  try {
    await writeCoachDocuments(uid, email, firstname);
  } catch (e: any) {
    logger.error(`[Error] registerCoach: compensation en cours : ${describeError(e)}`);
    await removeCoachDocuments(uid);
    await auth().deleteUser(uid).catch(() => undefined);
    throw new HttpsError("internal", "La création du compte a échoué, aucun compte n'a été conservé. Réessayez.");
  }

  return { uid };
};
