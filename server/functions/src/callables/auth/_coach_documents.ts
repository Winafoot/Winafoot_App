import { firestore } from "firebase-admin";

/**
 * Les trois documents que l'app attend pour un coach inscrit depuis l'app (par e-mail ou par Google /
 * Apple) : `users/{uid}`, `users/{uid}/metadata/security` et `users/{uid}/metadata/metadata`. Le format
 * du club, la catégorie et la division sont saisis à la page 2 (« Finalisez votre profil »), d'où
 * `profilCompleted: false`. Pas de `invitedByAdmin` : onCreateUser envoie l'e-mail de bienvenue.
 */
function refs(uid: string) {
  const userRef = firestore().collection("users").doc(uid);
  return {
    userRef,
    securityRef: userRef.collection("metadata").doc("security"),
    clientMetadataRef: userRef.collection("metadata").doc("metadata"),
  };
}

export async function writeCoachDocuments(uid: string, email: string, firstname: string): Promise<void> {
  const { userRef, securityRef, clientMetadataRef } = refs(uid);
  const now: firestore.Timestamp = firestore.Timestamp.now();

  await userRef.set({
    id: uid,
    email,
    firstname,
    // Pré-remplit « Finalisez votre profil » ; le coach pourra le compléter (nom complet).
    coachName: firstname,
    userType: "client",
    createdAt: now,
    cguAccepted: true,
    cguAcceptedDate: now,
    profilCompleted: false,
    disabled: false,
  });

  // OBLIGATOIRE : sans ce document l'app reste sur le loader (voir createCoach).
  await securityRef.set({
    email,
    profilCompleted: false,
    cguAccepted: true,
    cguAcceptedDate: now,
    isFirstLogin: true,
    createdAt: now,
  });

  // OBLIGATOIRE : document attendu par les paquets du socle (voir createCoach).
  await clientMetadataRef.set({
    cguAccepted: true,
    cguAcceptedDate: now,
    enablePushNotification: false,
    enableEmailNotification: false,
    createdAt: now,
  });
}

/** Supprime ce que writeCoachDocuments a pu écrire (compensation après un échec en cours d'écriture). */
export async function removeCoachDocuments(uid: string): Promise<void> {
  const { userRef, securityRef, clientMetadataRef } = refs(uid);
  await clientMetadataRef.delete().catch(() => undefined);
  await securityRef.delete().catch(() => undefined);
  await userRef.delete().catch(() => undefined);
}
