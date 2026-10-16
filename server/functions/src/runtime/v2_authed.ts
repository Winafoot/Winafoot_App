/**
 * Adaptateur callable authentifiant (utilisateur connecté).
 *
 * Même principe que runtime/v2_admin.ts : le `callableAdapter` du socle
 * (runtime/v2.ts) ne transmet que `request.data`. Cet adaptateur exige une
 * authentification et transmet l'identité de l'appelant au handler.
 */
import * as path from "path";
import { HttpsError, type CallableRequest } from "./firebase";
import { logAccessDenied } from "./access_denied";

export interface AuthedCaller {
  uid: string;
  token: Record<string, unknown>;
  /** Jeton d'identité brut : un handler qui doit contrôler sa révocation le relit (verifyAdmin). */
  rawToken?: string;
}

export type AuthedHandler<TData, TResult> = (data: TData, caller: AuthedCaller) => Promise<TResult>;

/** Exige un utilisateur authentifié et renvoie son identité. */
export function assertAuthed(request: CallableRequest<unknown>): AuthedCaller {
  if (request.auth == null) {
    logAccessDenied(request, "unauthenticated");
    throw new HttpsError("unauthenticated", "Authentification requise.");
  }

  return {
    uid: request.auth.uid,
    token: (request.auth.token as Record<string, unknown>) ?? {},
    rawToken: request.auth.rawToken,
  };
}

export function authedCallableAdapter<TData = any, TResult = any>(modulePath: string) {
  return async (request: CallableRequest<TData>): Promise<TResult> => {
    const caller = assertAuthed(request);
    const fullPath = path.join(__dirname, "..", modulePath);
    const handler = require(fullPath).default as AuthedHandler<TData, TResult>;
    return handler(request.data, caller);
  };
}
