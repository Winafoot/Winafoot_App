import { oneTimeCodeValues } from "../../billing/app_store_connect";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import { describeError } from "../../utils/describe_error";

export interface GetAppleOfferCodeValuesResult {
  /** Vide tant qu'Apple prépare le lot : réessayer dans quelques instants. */
  codes: string[];
}

/** Lit les codes d'un lot à usage unique créé par createAppleOfferCode. Lecture seule : les codes ne sont jamais conservés ici. */
export default async (data: { batchId: string }, _caller: AdminCaller): Promise<GetAppleOfferCodeValuesResult> => {
  if (typeof data?.batchId !== "string" || data.batchId.trim() === "") throw new HttpsError("invalid-argument", "Lot manquant.");
  try {
    return { codes: await oneTimeCodeValues(data.batchId.trim()) };
  } catch (e: any) {
    if (e instanceof HttpsError) throw e;
    logger.error(`[Error] getAppleOfferCodeValues: ${describeError(e)}`);
    throw new HttpsError("internal", "La lecture des codes a échoué, réessayez.");
  }
};
