import { auth, firestore } from "firebase-admin";
import { removeAssistant } from "./assistant";

/**
 * Comptes d'équipe liés : une formule à 2 ou 3 équipes donne un compte par équipe, rattaché au compte
 * propriétaire (celui qui paie, e-mail réel). Un compte lié se connecte par un identifiant choisi par
 * le coach, qui se traduit en adresse technique : `<identifiant>@equipes.wina.invalid`. Le domaine
 * `.invalid` n'existe pas (RFC 2606) : aucun e-mail n'y est jamais délivré. L'adresse ne se stocke pas
 * ailleurs, l'unicité de l'identifiant est celle de l'adresse dans Firebase Auth.
 */
export const LINKED_EMAIL_DOMAIN = "equipes.wina.invalid";

/** 3 à 30 caractères : minuscules, chiffres et tirets, sans tiret en tête ni en queue. */
export const IDENTIFIER_PATTERN = /^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$/;

/** Places d'équipe réservées (`team_slots/{ownerUid}_{teamIndex}`) : verrou contre deux créations simultanées. */
export const TEAM_SLOTS = "team_slots";

export function linkedEmail(identifier: string): string {
  return `${identifier}@${LINKED_EMAIL_DOMAIN}`;
}

export function isLinkedEmail(email: string): boolean {
  return email.trim().toLowerCase().endsWith(`@${LINKED_EMAIL_DOMAIN}`);
}

export function slotRef(ownerUid: string, teamIndex: number): firestore.DocumentReference {
  return firestore().collection(TEAM_SLOTS).doc(`${ownerUid}_${teamIndex}`);
}

/**
 * À appeler AVANT de supprimer le compte `uid` (idempotent : un nouvel essai après échec est sans risque).
 * - Propriétaire : supprime ses comptes liés (Auth, fiche et sous-collections) et libère leurs places.
 * - Compte lié : libère sa place.
 * Les comptes liés ne sont pas archivés dans `deleted_users` : leur adresse technique n'a aucune valeur.
 */
export async function detachFromTeams(uid: string): Promise<void> {
  const db = firestore();

  await removeAssistant(uid);

  const own =await db.collection("users").doc(uid).get();
  const ownerUid: unknown = own.get("ownerUid");
  const ownIndex: unknown = own.get("teamIndex");
  if (typeof ownerUid === "string" && typeof ownIndex === "number") {
    await slotRef(ownerUid, ownIndex).delete();
  }

  const children = await db.collection("users").where("ownerUid", "==", uid).get();
  for (const child of children.docs) {
    await auth()
      .deleteUser(child.id)
      .catch((e: any) => {
        if (e?.code !== "auth/user-not-found") throw e;
      });
    await db.recursiveDelete(child.ref);
    const index: unknown = child.get("teamIndex");
    if (typeof index === "number") await slotRef(uid, index).delete();
  }
}
