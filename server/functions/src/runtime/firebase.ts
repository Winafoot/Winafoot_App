import * as logger from "firebase-functions/logger";

export { logger };
export { HttpsError, type CallableRequest, type Request } from "firebase-functions/v2/https";

export interface LegacyEventContext<P extends Record<string, string> = Record<string, string>> {
  params: P;
}

/** Contexte d'un trigger « written » : ajoute l'horodatage et l'identifiant de l'événement (garde d'âge, journaux). */
export interface LegacyWrittenEventContext<P extends Record<string, string> = Record<string, string>> extends LegacyEventContext<P> {
  eventTime: string;
  eventId: string;
}

export interface LegacyDocumentChange<T> {
  before: T;
  after: T;
}
