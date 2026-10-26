import { auth, firestore } from "firebase-admin";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AuthedCaller } from "../../runtime/v2_authed";
import { describeError } from "../../utils/describe_error";
import { isLinkedEmail } from "../../billing/linked_teams";
import { validateDisplayName } from "../admin/_admin_accounts";
import { removeCoachDocuments, writeCoachDocuments } from "./_coach_documents";

export interface CompleteSocialSignupData {
  acceptedCgu?: unknown;
  firstname?: unknown;
}

export interface CompleteSocialSignupResult {
  /** `true` si la fiche vient d'être créée, `false` si le compte en avait déjà une. */
  created: boolean;
}

/** Fournisseurs « Se connecter avec… » acceptés (Firebase Authentication). */
const SOCIAL_PROVIDERS = ["google.com", "apple.com"];

const FIRSTNAME_FALLBACK = "Coach";

/**
 * completeSocialSignup : callable authentifié, appelé juste après une première connexion Google ou Apple.
 *
 * Les règles Firestore interdisent au client de créer sa fiche : comme `registerCoach` pour l'inscription
 * par e-mail, c'est le serveur qui écrit les trois documents (Admin SDK). L'identité vient du jeton ; le
 * compte Auth doit avoir un fournisseur Google ou Apple (un compte e-mail / mot de passe passe par
 * `registerCoach`, pas par ici) et c'est SON adresse qui est écrite, jamais une adresse envoyée par le client.
 *
 * Idempotent : un compte qui a déjà une fiche reçoit `created: false` et rien n'est modifié.
 * Le prénom vient du client (Apple ne le donne qu'à la première connexion), à défaut du nom affiché du
 * compte, à défaut de « Coach » ; un prénom invalide ne bloque pas l'inscription.
 */
export default async (data: CompleteSocialSignupData, caller: AuthedCaller): Promise<CompleteSocialSignupResult> => {
  const account = await auth().getUser(caller.uid);

  if (!account.providerData.some((p) => SOCIAL_PROVIDERS.includes(p.providerId))) {
    throw new HttpsError("failed-precondition", "Ce compte n'a pas été créé avec Google ou Apple.");
  }
  const email: string | undefined = account.email?.trim().toLowerCase();
  if (email == null || email.length === 0 || isLinkedEmail(email)) {
    throw new HttpsError("failed-precondition", "Adresse e-mail indisponible pour ce compte.");
  }

  const existing = await firestore().collection("users").doc(caller.uid).get();
  if (existing.exists && existing.get("createdAt") != null) {
    return { created: false };
  }

  if (data?.acceptedCgu !== true) {
    throw new HttpsError("failed-precondition", "Vous devez accepter les conditions générales d'utilisation.");
  }

  const firstname = pickFirstname(data?.firstname, account.displayName);

  try {
    await writeCoachDocuments(caller.uid, email, firstname);
  } catch (e) {
    logger.error(`[Error] completeSocialSignup: compensation en cours : ${describeError(e)}`);
    await removeCoachDocuments(caller.uid);
    throw new HttpsError("internal", "La création du profil a échoué, réessayez.");
  }

  return { created: true };
};

/** Prénom saisi, sinon premier mot du nom affiché, sinon « Coach » ; une valeur refusée par la validation est écartée. */
function pickFirstname(sent: unknown, displayName: string | undefined): string {
  const candidates: string[] = [typeof sent === "string" ? sent : "", (displayName ?? "").trim().split(/\s+/)[0] ?? ""];
  for (const raw of candidates) {
    const name = raw.trim();
    if (name.length === 0) continue;
    try {
      validateDisplayName(name);
      return name;
    } catch {
      // Prénom refusé : on essaie le suivant.
    }
  }
  return FIRSTNAME_FALLBACK;
}
