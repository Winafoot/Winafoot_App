import { auth, firestore } from "firebase-admin";
import { UserRecord } from "firebase-admin/auth";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { HttpsError, logger } from "../../runtime/firebase";
import { AdminCaller } from "../../runtime/v2_admin";
import { assertPasswordPolicy } from "./_password_policy";
import { describeError } from "../../utils/describe_error";

export interface CreateCoachData {
  email: string;
  password: string;
  firstname?: string;
  teamFormat: number;
  teamName?: string;
  category?: string;
  division?: string;
}

export interface CreateCoachResult {
  uid: string;
}

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Format du club = users/{uid}.teamFormat : nombre de joueurs sur le terrain.
// firestore.rules (maxPlayers) en dérive le plafond d'effectif : 5 -> 9,
// 8 -> 14, 11 -> 20. Le coach ne peut pas l'écrire : seul ce callable le pose.
const TEAM_FORMATS: readonly number[] = [5, 8, 11];

// Aligné sur maxLength du nom d'équipe adverse dans l'app (coup_denvoi_step1).
const TEAM_NAME_MAX_LENGTH = 40;

// MIROIR de lib/models/coach_profile.dart (app : enums TeamCategory et
// TeamDivision), à tenir synchronisé à la main avec cms/src/team_options.ts.
// Clés = `enum.name`, lues telles quelles par l'app (CoachProfile.fromJson).
const TEAM_CATEGORIES: readonly string[] = [
  "u6", "u7", "u8", "u9", "u10", "u11", "u12", "u13", "u14", "u15", "u16", "u17", "u18", "u19",
  "seniors", "veterans",
];
const TEAM_DIVISIONS: readonly string[] = ["r1", "r2", "r3", "d1", "d2", "d3", "d4", "d5"];

export default async (data: CreateCoachData, caller: AdminCaller): Promise<CreateCoachResult> => {
  const email: string = (data.email ?? "").trim().toLowerCase();
  const password: unknown = data.password;
  const firstname: string | undefined = data.firstname?.trim() || undefined;
  // Type contrôlé avant le trim : sans cela, un objet/nombre/booléen serait
  // converti en chaîne et écrit tel quel dans users/{uid}.teamName.
  if (data.teamName != null && typeof data.teamName !== "string") {
    throw new HttpsError("invalid-argument", "Nom de l'équipe invalide.");
  }
  const teamName: string | undefined = data.teamName?.trim() || undefined;
  const category: string | undefined = data.category || undefined;
  const division: string | undefined = data.division || undefined;

  if (!EMAIL_PATTERN.test(email)) {
    throw new HttpsError("invalid-argument", "Adresse e-mail invalide.");
  }

  // Choisi par l'administrateur, et contrôlé ici : l'Admin SDK n'applique pas la politique du projet.
  assertPasswordPolicy(password);

  if (!TEAM_FORMATS.includes(data.teamFormat)) {
    throw new HttpsError("invalid-argument", "Format du club invalide : choisissez foot à 5, à 8 ou à 11.");
  }

  if (teamName !== undefined && teamName.length > TEAM_NAME_MAX_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      `Le nom de l'équipe ne doit pas dépasser ${TEAM_NAME_MAX_LENGTH} caractères.`,
    );
  }

  if (category !== undefined && !TEAM_CATEGORIES.includes(category)) {
    throw new HttpsError("invalid-argument", "Catégorie invalide.");
  }

  if (division !== undefined && !TEAM_DIVISIONS.includes(division)) {
    throw new HttpsError("invalid-argument", "Division invalide.");
  }

  if (await emailExists(email)) {
    throw new HttpsError("already-exists", "Un compte existe déjà pour cette adresse.");
  }

  // La création du compte Auth est hors du try/catch de compensation ci-dessous
  // (rien à compenser si elle échoue), mais un échec ici — p. ex. un mot de passe
  // refusé par la politique de complexité — doit remonter un message français et
  // laisser une trace, pas un « internal » opaque.
  let record: UserRecord;
  try {
    record = await auth().createUser({
      email,
      // Compte provisionné par l'admin avec un mot de passe connu : aucun e-mail
      // de vérification n'est envoyé, on marque donc l'adresse comme vérifiée.
      emailVerified: true,
      password,
      disabled: false,
    });
  } catch (e: any) {
    logger.error(`[Error] createCoach: auth().createUser a échoué : ${describeError(e)}`);
    await AdminAuditRepository.instance.record({
      action: "create",
      targetUid: "",
      targetEmail: email,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      error: String(e?.message ?? e),
    });
    if (e?.code === "auth/invalid-password") {
      throw new HttpsError(
        "invalid-argument",
        "Mot de passe refusé : il doit respecter la politique de sécurité (majuscule, minuscule, chiffre et caractère spécial).",
      );
    }
    throw new HttpsError("internal", "La création du compte a échoué.");
  }

  const uid: string = record.uid;
  const userRef = firestore().collection("users").doc(uid);
  const securityRef = userRef.collection("metadata").doc("security");
  const clientMetadataRef = userRef.collection("metadata").doc("metadata");

  try {
    const now: firestore.Timestamp = firestore.Timestamp.now();

    await userRef.set({
      id: uid,
      email,
      firstname: firstname ?? null,
      userType: "client",
      createdAt: now,
      createdByAdmin: caller.uid,
      invitedByAdmin: true,
      cguAccepted: false,
      profilCompleted: false,
      disabled: false,
      teamFormat: data.teamFormat,
      // Profil : les noms de champs sont ceux que lit l'app
      // (CoachProfileRepository / CoachProfile.fromJson) et pré-remplissent
      // « Finalisez votre profil ». Le nom du coach n'est pas dupliqué :
      // `firstname` le pré-remplit déjà (loadInitialCoachName).
      ...(teamName ? { teamName } : {}),
      ...(category ? { category } : {}),
      ...(division ? { division } : {}),
    });

    // OBLIGATOIRE : sans ce document, l'app reste bloquée indéfiniment sur le
    // loader (logged_user_parent.dart : isLoaded = user != null && security != null,
    // et le listener metadata/security n'a ni else ni timeout).
    await securityRef.set({
      email,
      profilCompleted: false,
      cguAccepted: false,
      isFirstLogin: true,
      createdAt: now,
    });

    // OBLIGATOIRE : document attendu par les paquets du socle de l'app (app/packages).
    // UserProvider.init le lit et acceptCgu / les réglages de notification
    // l'écrivent via update(). Un coach provisionné par l'admin saute
    // l'onboarding qui le crée normalement ; sans ce seed, le premier update()
    // côté app (p. ex. l'acceptation des CGU) porte sur un document inexistant,
    // échoue (permission-denied) et bloque la connexion. Champs limités à la
    // liste blanche des règles Firestore (clientOwnedMetadataFields).
    await clientMetadataRef.set({
      cguAccepted: false,
      enablePushNotification: false,
      enableEmailNotification: false,
      createdAt: now,
    });
  } catch (e: any) {
    logger.error(`[Error] createCoach: compensation en cours : ${describeError(e)}`);
    await clientMetadataRef.delete().catch(() => undefined);
    await securityRef.delete().catch(() => undefined);
    await userRef.delete().catch(() => undefined);
    await auth().deleteUser(uid).catch(() => undefined);

    await AdminAuditRepository.instance.record({
      action: "create",
      targetUid: uid,
      targetEmail: email,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "failure",
      error: String(e?.message ?? e),
    });

    throw new HttpsError("internal", "La création du compte a échoué, aucun compte n'a été conservé.");
  }

  await AdminAuditRepository.instance.record({
    action: "create",
    targetUid: uid,
    targetEmail: email,
    adminUid: caller.uid,
    adminEmail: caller.email,
    outcome: "success",
  });

  return { uid };
};

async function emailExists(email: string): Promise<boolean> {
  try {
    await auth().getUserByEmail(email);
    return true;
  } catch (e: any) {
    if (e?.code === "auth/user-not-found") {
      return false;
    }
    throw e;
  }
}
