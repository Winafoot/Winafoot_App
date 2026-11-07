import { discountedPrice, listPricePoints, listSubscriptions, listTerritories, pickPricePoint, subscriptionPrice, type AppleSubscription, type AppleTerritory } from "../../billing/app_store_connect";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import { describeError } from "../../utils/describe_error";

export interface ListAppleSubscriptionsData {
  /** Avec un abonnement et un territoire : renvoie aussi le prix actuel (`price`), pour préremplir le formulaire. */
  subscriptionId?: string;
  territory?: string;
  /** Avec `percentOff` : calcule le nouveau prix (palier Apple le plus proche) à partir de ce prix, ou du prix actuel à défaut. */
  basePrice?: number;
  percentOff?: number;
}

export interface ListAppleSubscriptionsResult {
  subscriptions: AppleSubscription[];
  territories: AppleTerritory[];
  price?: number;
  /** Prix réduit réellement appliqué par Apple (palier le plus proche) et réduction effective en %. */
  discounted?: { price: number; percentOff: number };
}

/** Abonnements et territoires d'App Store Connect (listes déroulantes du back-office), et prix actuel à la demande. Lecture seule. */
export default async (data: ListAppleSubscriptionsData, _caller: AdminCaller): Promise<ListAppleSubscriptionsResult> => {
  try {
    if (typeof data?.subscriptionId === "string" && data.subscriptionId !== "") {
      const territory = (data.territory ?? "FRA").trim().toUpperCase();
      const subscriptionId = data.subscriptionId.trim();
      const price = await subscriptionPrice(subscriptionId, territory);
      const base = Number(data.basePrice ?? price);
      const percentOff = Number(data.percentOff);
      if (!(base > 0) || !(percentOff > 0 && percentOff < 100)) return { subscriptions: [], territories: [], price };
      const point = pickPricePoint(await listPricePoints(subscriptionId, territory), discountedPrice(base, percentOff));
      const discounted = point == null ? undefined : { price: point.price, percentOff: Math.round((1 - point.price / base) * 1000) / 10 };
      return { subscriptions: [], territories: [], price, discounted };
    }
    const [subscriptions, territories] = await Promise.all([listSubscriptions(), listTerritories()]);
    return { subscriptions, territories };
  } catch (e: any) {
    if (e instanceof HttpsError) throw e;
    logger.error(`[Error] listAppleSubscriptions: ${describeError(e)}`);
    throw new HttpsError("internal", "La lecture d'App Store Connect a échoué, réessayez.");
  }
};
