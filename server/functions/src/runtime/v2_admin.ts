/**
 * Adaptateur callable authentifiant, propre au back-office.
 *
 * Le `callableAdapter` du socle (runtime/v2.ts) ne transmet que `request.data` :
 * un handler n'y connaît pas son appelant. Ce fichier fournit l'équivalent
 * authentifié, réservé aux administrateurs.
 */
import * as path from "path";
import { auth } from "firebase-admin";
import { REQUIRE_ADMIN_MFA } from "../config/admin_mfa";
import { HttpsError, type CallableRequest } from "./firebase";
import { logAccessDenied } from "./access_denied";

export interface AdminCaller {
  uid: string;
  email?: string;
}

export type AdminHandler<TData, TResult> = (data: TData, caller: AdminCaller) => Promise<TResult>;

/** Identité vérifiée par verifyAdmin : celle du jeton de l'appel. */
export interface AdminIdentity {
  uid: string;
  token: Record<string, unknown>;
  /** Jeton d'identité brut, relu par l'Admin SDK pour contrôler sa révocation. */
  rawToken?: string;
}

/** Journalise un refus (motif et code d'erreur Auth éventuel). */
export type DenialLogger = (reason: string, code?: string) => void;

const ADMIN_ONLY = "Réservé aux administrateurs.";

/**
 * Contrôles d'un administrateur, partagés par les callables d'administration (assertAdmin) et par
 * le cas administrateur de deleteAccount :
 * - le custom claim `admin` vaut `true` ;
 * - l'adresse du compte est vérifiée (`email_verified`) ;
 * - quand `REQUIRE_ADMIN_MFA` est vrai (config/admin_mfa.ts), la connexion a validé un second facteur ;
 * - le jeton n'est ni révoqué ni celui d'un compte désactivé : sans cela, un administrateur retiré
 *   garde ses droits jusqu'à l'expiration de son jeton (1 h). Coût : un appel Auth par appel.
 * Chaque refus est journalisé par `deny` avant l'exception. Renvoie l'identité de l'appelant.
 */
export async function verifyAdmin(identity: AdminIdentity, deny: DenialLogger): Promise<AdminCaller> {
  const { token } = identity;

  if (token.admin !== true) {
    deny("not-admin");
    throw new HttpsError("permission-denied", ADMIN_ONLY);
  }

  if (token.email_verified !== true) {
    deny("email-not-verified");
    throw new HttpsError("permission-denied", "Réservé aux administrateurs dont l'adresse e-mail est vérifiée.");
  }

  if (REQUIRE_ADMIN_MFA && !hasSecondFactor(token)) {
    deny("mfa-required");
    throw new HttpsError("permission-denied", "Authentification à deux facteurs requise.");
  }

  try {
    await auth().verifyIdToken(identity.rawToken ?? "", true);
  } catch (e) {
    // Échec fermé : jeton révoqué, compte désactivé, jeton absent, mais aussi service Auth injoignable.
    deny("token-revoked", (e as { code?: string }).code);
    throw new HttpsError("permission-denied", ADMIN_ONLY);
  }

  return {
    uid: identity.uid,
    email: typeof token.email === "string" ? token.email : undefined,
  };
}

/** Callables d'administration : exige un appel authentifié, puis les contrôles de verifyAdmin. */
export async function assertAdmin(request: CallableRequest<unknown>): Promise<AdminCaller> {
  if (request.auth == null) {
    logAccessDenied(request, "unauthenticated");
    throw new HttpsError("permission-denied", ADMIN_ONLY);
  }

  return verifyAdmin(
    { uid: request.auth.uid, token: (request.auth.token as Record<string, unknown>) ?? {}, rawToken: request.auth.rawToken },
    (reason, code) => logAccessDenied(request, reason, code),
  );
}

/** Le jeton porte `firebase.sign_in_second_factor` (ex. "totp") quand la connexion a validé un second facteur. */
function hasSecondFactor(token: Record<string, unknown>): boolean {
  const secondFactor = (token.firebase as { sign_in_second_factor?: unknown } | undefined)?.sign_in_second_factor;
  return typeof secondFactor === "string" && secondFactor.length > 0;
}

export function adminCallableAdapter<TData = any, TResult = any>(modulePath: string) {
  return async (request: CallableRequest<TData>): Promise<TResult> => {
    const caller = await assertAdmin(request);
    const fullPath = path.join(__dirname, "..", modulePath);
    const handler = require(fullPath).default as AdminHandler<TData, TResult>;
    return handler(request.data, caller);
  };
}
