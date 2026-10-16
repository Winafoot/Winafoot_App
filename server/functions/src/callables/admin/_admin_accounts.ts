import { randomInt, randomUUID } from "crypto";
import { auth, firestore } from "firebase-admin";
import type { UserRecord } from "firebase-admin/auth";
import { AdminAuditRepository, type AdminAuditAction } from "../../database/admin_audit/admin_audit_repository";
import { HttpsError } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";

/**
 * Un administrateur est un compte Firebase Auth portant le custom claim `admin: true`
 * (le même que lit `assertAdmin`, runtime/v2_admin.ts, et le back-office). Aucune fiche
 * Firestore : Auth fait foi.
 */
export interface AdminAccount {
  uid: string;
  email: string;
  displayName: string;
  disabled: boolean;
  emailVerified: boolean;
  /** Nombre de seconds facteurs inscrits (0 = mot de passe seul). */
  secondFactors: number;
  createdAt: string | null;
  lastSignInAt: string | null;
}

export const DISPLAY_NAME_MAX_LENGTH = 80;

// Caractères de contrôle et de direction (U+202A à U+202E, U+2066 à U+2069) : ils n'ont rien à faire dans un
// nom et servent à tromper l'affichage (nom inversé, ligne cachée) dans le back-office, l'audit et les e-mails.
const FORBIDDEN_NAME_CHARACTERS = /[\u0000-\u001F\u007F‪-‮⁦-⁩]/;

/** Le nom est déjà « trimé » : refuse un nom trop long ou contenant des caractères trompeurs. */
export function validateDisplayName(name: string): void {
  if (name.length > DISPLAY_NAME_MAX_LENGTH) {
    throw new HttpsError("invalid-argument", `Le nom ne doit pas dépasser ${DISPLAY_NAME_MAX_LENGTH} caractères.`);
  }
  if (FORBIDDEN_NAME_CHARACTERS.test(name)) {
    throw new HttpsError("invalid-argument", "Le nom contient des caractères non autorisés.");
  }
}

/**
 * Message des callables « coach » (deleteCoach, setCoachDisabled) quand on leur désigne un administrateur :
 * sans ce refus, ils contourneraient les garde-fous des comptes administrateurs (dernier admin, soi-même).
 */
export const ADMIN_TARGET_MESSAGE = "Ce compte est un administrateur : gérez-le depuis la vue « Administrateurs ».";

export function isAdminRecord(record: UserRecord): boolean {
  return record.customClaims?.admin === true;
}

function isoOrNull(value: string | undefined): string | null {
  if (value == null) {
    return null;
  }
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

export function toAdminAccount(record: UserRecord): AdminAccount {
  return {
    uid: record.uid,
    email: record.email ?? "",
    displayName: record.displayName ?? "",
    disabled: record.disabled,
    emailVerified: record.emailVerified,
    secondFactors: record.multiFactor?.enrolledFactors.length ?? 0,
    createdAt: isoOrNull(record.metadata.creationTime),
    lastSignInAt: isoOrNull(record.metadata.lastSignInTime),
  };
}

/** Auth ne sait pas filtrer sur un claim : on parcourt les pages et on garde les administrateurs. */
export async function listAdminRecords(): Promise<UserRecord[]> {
  const admins: UserRecord[] = [];
  let pageToken: string | undefined;
  do {
    const page = await auth().listUsers(1000, pageToken);
    admins.push(...page.users.filter(isAdminRecord));
    pageToken = page.pageToken;
  } while (pageToken != null);
  return admins;
}

/** Administrateurs ACTIFS autres que `excludeUid` : à 0, retirer ou désactiver ce compte verrouillerait le back-office. */
export function otherEnabledAdmins(admins: UserRecord[], excludeUid: string): number {
  return admins.filter((admin) => admin.uid !== excludeUid && !admin.disabled).length;
}

export async function getUserByEmailOrNull(email: string): Promise<UserRecord | null> {
  try {
    return await auth().getUserByEmail(email);
  } catch (e: any) {
    if (e?.code === "auth/user-not-found") {
      return null;
    }
    throw e;
  }
}

export async function getUserOrNull(uid: string): Promise<UserRecord | null> {
  try {
    return await auth().getUser(uid);
  } catch (e: any) {
    if (e?.code === "auth/user-not-found") {
      return null;
    }
    throw e;
  }
}

/**
 * Trace l'échec dans la piste d'audit puis le remonte à l'appelant. Un refus de garde-fou
 * (se supprimer soi-même, retirer le dernier administrateur…) est une tentative à garder.
 */
export async function refuse(
  caller: AdminCaller,
  action: AdminAuditAction,
  target: { uid: string; email?: string },
  code: ConstructorParameters<typeof HttpsError>[0],
  message: string,
  details?: string,
): Promise<never> {
  await AdminAuditRepository.instance.record({
    action,
    targetUid: target.uid,
    targetEmail: target.email,
    adminUid: caller.uid,
    adminEmail: caller.email,
    outcome: "failure",
    error: message,
    details,
  });
  throw new HttpsError(code, message);
}

// Le contrôle « il reste un autre administrateur actif » lit puis écrit : deux administrateurs qui se
// retirent l'un l'autre au même instant passeraient tous deux. Ce verrou court (Firestore, un seul
// document, l'Admin SDK seul y accède : le catch-all des règles refuse les clients) les sérialise.
const LOCK_TTL_MS = 30_000;
const lockRef = () => firestore().collection("admin_locks").doc("accounts");

export async function withAdminLock<T>(work: () => Promise<T>): Promise<T> {
  const holder = randomUUID();
  const acquired = await firestore().runTransaction(async (tx) => {
    const snap = await tx.get(lockRef());
    const until = snap.get("until") as firestore.Timestamp | undefined;
    if (until != null && until.toMillis() > Date.now()) {
      return false;
    }
    tx.set(lockRef(), { holder, until: firestore.Timestamp.fromMillis(Date.now() + LOCK_TTL_MS) });
    return true;
  });

  if (!acquired) {
    throw new HttpsError("aborted", "Une autre opération sur les comptes administrateurs est en cours, réessayez dans un instant.");
  }

  try {
    return await work();
  } finally {
    // Ne libère que son propre verrou : s'il a expiré et été repris, on n'y touche pas.
    await firestore()
      .runTransaction(async (tx) => {
        const snap = await tx.get(lockRef());
        if (snap.get("holder") === holder) {
          tx.delete(lockRef());
        }
      })
      .catch(() => undefined);
  }
}

const UPPER = "ABCDEFGHJKLMNPQRSTUVWXYZ";
const LOWER = "abcdefghijkmnopqrstuvwxyz";
const DIGITS = "23456789";
const SYMBOLS = "!@#$%^&*-_=+";

function pick(characters: string): string {
  return characters[randomInt(characters.length)];
}

/**
 * Mot de passe provisoire d'un compte tout juste créé : personne ne le voit ni ne le garde, il
 * n'existe que pour que le compte soit créé. L'administrateur choisit le sien par le lien de
 * l'invitation. Respecte la politique du projet (majuscule, minuscule, chiffre, caractère spécial).
 */
export function generateStrongPassword(): string {
  const all = UPPER + LOWER + DIGITS + SYMBOLS;
  const characters = [pick(UPPER), pick(LOWER), pick(DIGITS), pick(SYMBOLS)];
  while (characters.length < 28) {
    characters.push(pick(all));
  }
  for (let i = characters.length - 1; i > 0; i--) {
    const j = randomInt(i + 1);
    [characters[i], characters[j]] = [characters[j], characters[i]];
  }
  return characters.join("");
}
