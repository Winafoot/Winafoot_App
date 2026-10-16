/**
 * Adaptateurs callables avec limitation de débit.
 *
 * Même principe que runtime/v2_authed.ts (le `callableAdapter` du socle ne transmet
 * que `request.data`), avec en plus un compteur par IP et/ou par uid vérifié AVANT
 * de charger le handler. L'authentification passe d'abord : un appel anonyme sur un
 * callable authentifié ne consomme aucun quota.
 */
import * as path from "path";
import type { CallableRequest } from "./firebase";
import { assertAuthed, type AuthedCaller } from "./v2_authed";
import { clientIp } from "../utils/client_ip";
import { enforce, type Limit } from "../utils/rate_limit";

export interface CallableLimits {
  /** Préfixe des compteurs ; distinct par fonction. */
  scope: string;
  perIp?: Limit;
  perUid?: Limit;
}

type AuthedHandler<TData, TResult> = (data: TData, caller: AuthedCaller) => Promise<TResult>;

/** Callable public (avant connexion) : limité par IP. */
export function limitedPublicCallableAdapter<TData = any, TResult = any>(modulePath: string, limits: CallableLimits) {
  return async (request: CallableRequest<TData>): Promise<TResult> => {
    if (limits.perIp) await enforce(`${limits.scope}-ip`, clientIp(request.rawRequest), limits.perIp);

    const handler = require(path.join(__dirname, "..", modulePath)).default as (data: TData) => Promise<TResult>;
    return handler(request.data);
  };
}

/** Callable authentifié : limité par uid, et éventuellement par IP. */
export function limitedAuthedCallableAdapter<TData = any, TResult = any>(modulePath: string, limits: CallableLimits) {
  return async (request: CallableRequest<TData>): Promise<TResult> => {
    const caller = assertAuthed(request);

    if (limits.perIp) await enforce(`${limits.scope}-ip`, clientIp(request.rawRequest), limits.perIp);
    if (limits.perUid) await enforce(`${limits.scope}-uid`, caller.uid, limits.perUid);

    const handler = require(path.join(__dirname, "..", modulePath)).default as AuthedHandler<TData, TResult>;
    return handler(request.data, caller);
  };
}
