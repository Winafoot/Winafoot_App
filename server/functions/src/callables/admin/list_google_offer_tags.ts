import { groupOfferTags, listGoogleOffers, type OfferTag } from "../../billing/google_play";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import { describeError } from "../../utils/describe_error";

/** Tags posés sur les offres d'abonnement Google Play (liste déroulante du formulaire de code promo). Lecture seule. */
export default async (_data: unknown, _caller: AdminCaller): Promise<{ tags: OfferTag[] }> => {
  try {
    return { tags: groupOfferTags(await listGoogleOffers()) };
  } catch (e: any) {
    if (e instanceof HttpsError) throw e;
    logger.error(`[Error] listGoogleOfferTags: ${describeError(e)}`);
    throw new HttpsError("internal", "La lecture de Google Play a échoué, réessayez.");
  }
};
