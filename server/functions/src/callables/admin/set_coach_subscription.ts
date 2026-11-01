import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { grantAccess, parseGrant, revokeAccess } from "../../billing/admin_access";
import { HttpsError, logger } from "../../runtime/firebase";
import { AdminCaller } from "../../runtime/v2_admin";
import { describeError } from "../../utils/describe_error";

export interface SetCoachSubscriptionData {
  uid: string;
  action: "grant" | "revoke";
  /** Pour `grant` : nombre d'équipes (1 par défaut). */
  teams?: number;
  /** Pour `grant` : durée en jours (30 par défaut, 365 au plus). */
  days?: number;
}

export interface SetCoachSubscriptionResult {
  action: "grant" | "revoke";
  /** Fin de l'accès (ms depuis 1970) ; `null` après un retrait. */
  untilMs: number | null;
}

/**
 * Attribue ou retire un abonnement offert à un coach, depuis le back-office : comptes de test et invités
 * qui n'ont pas à passer par les stores. Refuse les comptes d'équipe liée et les abonnements achetés sur un
 * store. Chaque appel laisse une trace dans la piste d'audit.
 */
export default async (data: SetCoachSubscriptionData, caller: AdminCaller): Promise<SetCoachSubscriptionResult> => {
  if (typeof data?.uid !== "string" || data.uid === "") throw new HttpsError("invalid-argument", "Compte manquant.");
  if (data.action !== "grant" && data.action !== "revoke") throw new HttpsError("invalid-argument", "Action inconnue.");

  const grant = data.action === "grant" ? parseGrant(data) : undefined;
  const details = grant == null ? undefined : `teams=${grant.teams}, days=${grant.days}`;
  const record = (outcome: "success" | "failure", error?: string) =>
    AdminAuditRepository.instance.record({
      action: data.action === "grant" ? "grant_subscription" : "revoke_subscription",
      targetUid: data.uid,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome,
      details,
      error,
    });

  try {
    const untilMs = grant == null ? null : (await grantAccess(data.uid, grant)).expiresAtMs;
    if (grant == null) await revokeAccess(data.uid);
    await record("success");
    return { action: data.action, untilMs };
  } catch (e: any) {
    await record("failure", String(e?.message ?? e)).catch(() => undefined);
    if (e instanceof HttpsError) throw e;
    logger.error(`[Error] setCoachSubscription: ${describeError(e)}`);
    throw new HttpsError("internal", "La mise à jour de l'abonnement a échoué, réessayez.");
  }
};
