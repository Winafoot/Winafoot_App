import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { deactivateOffer } from "../../billing/app_store_connect";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import { describeError } from "../../utils/describe_error";

export interface DeactivateAppleOfferData {
  /** Identifiant Apple de l'offre (listAppleOffers). */
  offerId: string;
  /** Nom de l'offre, pour la piste d'audit seulement. */
  name?: string;
}

/**
 * Désactive une offre Apple (« suppression » du back-office : Apple n'en propose pas d'autre). Définitif : l'offre ne se
 * réactive pas et ses codes cessent de fonctionner ; les abonnés qui les ont déjà utilisés gardent leur remise.
 * Chaque appel est journalisé (offre, jamais de code ni de donnée client).
 */
export default async (data: DeactivateAppleOfferData, caller: AdminCaller): Promise<{ offerId: string }> => {
  const offerId = typeof data?.offerId === "string" ? data.offerId.trim() : "";
  if (!/^[A-Za-z0-9_-]{1,64}$/.test(offerId)) throw new HttpsError("invalid-argument", "Identifiant d'offre invalide.");
  const name = typeof data?.name === "string" ? data.name.trim().slice(0, 100) : "";
  const details = `desactivation offer=${name || offerId}`;
  const record = (outcome: "success" | "failure", error?: string) =>
    AdminAuditRepository.instance.record({ action: "deactivate_offer_code", targetUid: offerId, adminUid: caller.uid, adminEmail: caller.email, outcome, details, error });

  try {
    await deactivateOffer(offerId);
    await record("success");
    return { offerId };
  } catch (e: any) {
    await record("failure", String(e?.message ?? e)).catch(() => undefined);
    if (e instanceof HttpsError) throw e;
    logger.error(`[Error] deactivateAppleOffer: ${describeError(e)}`);
    throw new HttpsError("internal", "La désactivation de l'offre a échoué, réessayez.");
  }
};
