import { listOffers, type AppleOffer } from "../../billing/app_store_connect";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import { describeError } from "../../utils/describe_error";

export interface ListAppleOffersResult {
  offers: AppleOffer[];
}

/** Offres à code d'App Store Connect avec leurs codes et dates limites, pour le suivi des codes promo. Lecture seule. */
export default async (_data: unknown, _caller: AdminCaller): Promise<ListAppleOffersResult> => {
  try {
    return { offers: await listOffers() };
  } catch (e: any) {
    if (e instanceof HttpsError) throw e;
    logger.error(`[Error] listAppleOffers: ${describeError(e)}`);
    throw new HttpsError("internal", "La lecture des offres d'App Store Connect a échoué, réessayez.");
  }
};
