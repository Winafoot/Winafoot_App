import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { createCustomCode, createOffer, createOneTimeCodes, discountedPrice, listPricePoints, pickPricePoint } from "../../billing/app_store_connect";
import { HttpsError, logger } from "../../runtime/firebase";
import { AdminCaller } from "../../runtime/v2_admin";
import { describeError } from "../../utils/describe_error";

export interface CreateAppleOfferCodeData {
  /** Identifiant Apple de l'abonnement (App Store Connect > Abonnements > Identifiant Apple). */
  subscriptionId: string;
  /** Nom interne de l'offre, visible dans App Store Connect. */
  name: string;
  /** Prix actuel de l'abonnement (€) : sert à viser le palier Apple le plus proche de la réduction. */
  basePrice: number;
  /** Réduction visée, 10 par défaut. */
  percentOff?: number;
  /** Nombre de mois au prix réduit, 1 par défaut. */
  months?: number;
  /** Territoire Apple, « FRA » par défaut. */
  territory?: string;
  /** Date limite d'utilisation des codes, `AAAA-MM-JJ`. */
  expirationDate: string;
  /** Code personnalisé (ex. WINA10) ; sinon un lot de codes à usage unique. */
  customCode?: string;
  /** Codes à usage unique à générer (ou utilisations du code personnalisé). 10 par défaut. */
  numberOfCodes?: number;
}

export interface CreateAppleOfferCodeResult {
  offerId: string;
  /** Prix réellement appliqué : Apple n'accepte que ses paliers. */
  appliedPrice: number;
  appliedPercentOff: number;
  /** Lot de codes à usage unique (valeurs à relire avec getAppleOfferCodeValues) ; absent pour un code personnalisé. */
  batchId?: string;
  customCode?: string;
}

function required(value: unknown, message: string): string {
  if (typeof value !== "string" || value.trim() === "") throw new HttpsError("invalid-argument", message);
  return value.trim();
}

/**
 * Crée dans App Store Connect une offre « prix réduit pendant N mois » pour les nouveaux abonnés, puis ses codes
 * (lot à usage unique ou code personnalisé). Chaque appel laisse une trace dans la piste d'audit, sans les codes.
 */
export default async (data: CreateAppleOfferCodeData, caller: AdminCaller): Promise<CreateAppleOfferCodeResult> => {
  const subscriptionId = required(data?.subscriptionId, "Identifiant d'abonnement manquant.");
  const name = required(data?.name, "Nom de l'offre manquant.");
  const expirationDate = required(data?.expirationDate, "Date d'expiration manquante.");
  if (!/^\d{4}-\d{2}-\d{2}$/.test(expirationDate) || Date.parse(expirationDate) <= Date.now()) {
    throw new HttpsError("invalid-argument", "La date d'expiration doit être future (AAAA-MM-JJ).");
  }
  const basePrice = Number(data.basePrice);
  const percentOff = Number(data.percentOff ?? 10);
  const months = Number(data.months ?? 1);
  const numberOfCodes = Number(data.numberOfCodes ?? 10);
  const territory = (data.territory ?? "FRA").trim().toUpperCase();
  const customCode = data.customCode == null || data.customCode.trim() === "" ? undefined : data.customCode.trim().toUpperCase();
  if (!(basePrice > 0)) throw new HttpsError("invalid-argument", "Prix de l'abonnement invalide.");
  if (!(percentOff > 0 && percentOff < 100)) throw new HttpsError("invalid-argument", "La réduction doit être comprise entre 0 et 100 %.");
  if (!Number.isInteger(months)) throw new HttpsError("invalid-argument", "Durée invalide.");
  if (!Number.isInteger(numberOfCodes) || numberOfCodes < 1 || numberOfCodes > 500) throw new HttpsError("invalid-argument", "Entre 1 et 500 codes.");
  if (customCode != null && !/^[A-Z0-9]{4,20}$/.test(customCode)) throw new HttpsError("invalid-argument", "Code personnalisé : 4 à 20 lettres ou chiffres.");

  const details = `offer=${name}, -${percentOff}% x${months} mois, ${customCode != null ? "code personnalisé" : `${numberOfCodes} codes`}`;
  const record = (outcome: "success" | "failure", error?: string) =>
    AdminAuditRepository.instance.record({ action: "create_offer_code", targetUid: subscriptionId, adminUid: caller.uid, adminEmail: caller.email, outcome, details, error });

  try {
    const point = pickPricePoint(await listPricePoints(subscriptionId, territory), discountedPrice(basePrice, percentOff));
    if (point == null) throw new HttpsError("failed-precondition", "Aucun palier de prix trouvé pour cet abonnement et ce territoire.");
    if (point.price >= basePrice) throw new HttpsError("failed-precondition", "Aucun palier Apple inférieur au prix actuel : vérifiez le prix saisi.");

    const offerId = await createOffer({ subscriptionId, name, territory, pricePointId: point.id, months });
    const result: CreateAppleOfferCodeResult = {
      offerId,
      appliedPrice: point.price,
      appliedPercentOff: Math.round((1 - point.price / basePrice) * 1000) / 10,
    };
    if (customCode != null) {
      await createCustomCode(offerId, customCode, numberOfCodes, expirationDate);
      result.customCode = customCode;
    } else {
      result.batchId = await createOneTimeCodes(offerId, numberOfCodes, expirationDate);
    }
    await record("success");
    return result;
  } catch (e: any) {
    await record("failure", String(e?.message ?? e)).catch(() => undefined);
    if (e instanceof HttpsError) throw e;
    logger.error(`[Error] createAppleOfferCode: ${describeError(e)}`);
    throw new HttpsError("internal", "La création de l'offre a échoué, réessayez.");
  }
};
