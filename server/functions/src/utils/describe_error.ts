/**
 * Motif lisible d'une erreur, pour les journaux : code et message, jamais l'objet complet.
 *
 * Une erreur réseau (gaxios, utilisé par les SDK) embarque la requête, en-tête Authorization
 * compris, et une erreur Firebase peut porter des données de la requête : journaliser l'objet
 * tel quel les écrirait dans Cloud Logging. Le SDK Resend ne lève pas, il renvoie l'erreur de l'API
 * (`{ statusCode, name, message }`) que sendEmail relance ; un motif imbriqué est lu dans
 * `body.message`.
 */
export function describeError(error: unknown): string {
  if (typeof error === "string") return error;

  const e = error as { code?: unknown; statusCode?: unknown; message?: unknown; body?: { message?: unknown } } | null | undefined;
  const code =
    typeof e?.code === "string" || typeof e?.code === "number"
      ? String(e.code)
      : typeof e?.statusCode === "number"
        ? String(e.statusCode)
        : undefined;
  const message = typeof e?.body?.message === "string" ? e.body.message : typeof e?.message === "string" ? e.message : undefined;

  if (code != null && message != null) return `${code} : ${message}`;
  return message ?? code ?? "erreur inconnue";
}
