import { logger, type CallableRequest } from "./firebase";

/**
 * Journalise un refus d'accès sur un callable.
 *
 * Le message est structuré pour alimenter une métrique basée sur les journaux :
 * filtre `jsonPayload.event="access-denied"`, regroupement par `jsonPayload.reason`.
 * N'écrit que des identifiants (uid, nom du service, code d'erreur Auth) : jamais
 * l'e-mail ni le contenu du jeton.
 */
export function logAccessDenied(request: CallableRequest<unknown>, reason: string, code?: string): void {
  logAccessDeniedFor(request.auth?.uid, reason, code);
}

/** Même journal, depuis un handler qui ne dispose que de l'uid de l'appelant (refus métier). */
export function logAccessDeniedFor(uid: string | undefined, reason: string, code?: string): void {
  logger.warn("access-denied", {
    event: "access-denied",
    reason,
    code,
    uid,
    fn: process.env.K_SERVICE,
  });
}
