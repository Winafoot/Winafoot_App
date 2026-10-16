import { auth, firestore } from "firebase-admin";
import type { UpdateRequest } from "firebase-admin/auth";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import {
  getUserOrNull,
  isAdminRecord,
  listAdminRecords,
  otherEnabledAdmins,
  refuse,
  toAdminAccount,
  validateDisplayName,
  withAdminLock,
  type AdminAccount,
} from "./_admin_accounts";
import { sendAdminInvite } from "./_send_admin_invite";
import { describeError } from "../../utils/describe_error";

export interface UpdateAdminData {
  uid: string;
  /** Chaîne vide : efface le nom. Absent : inchangé. */
  displayName?: string;
  disabled?: boolean;
  /** Retire les seconds facteurs (perte du téléphone) : le compte se reconnecte avec son mot de passe seul. */
  resetSecondFactor?: true;
  /** Invalide les sessions ouvertes : l'administrateur doit se reconnecter. */
  revokeSessions?: true;
  /** Envoie un nouveau lien de définition de mot de passe. */
  sendInvite?: true;
}

export interface UpdateAdminResult {
  admin: AdminAccount;
  /** Présent seulement si `sendInvite` était demandé. */
  inviteSent?: boolean;
}

const UID_MAX_LENGTH = 128;

export default async (data: UpdateAdminData, caller: AdminCaller): Promise<UpdateAdminResult> => {
  const uid = data?.uid;
  if (typeof uid !== "string" || uid.length === 0 || uid.length > UID_MAX_LENGTH) {
    throw new HttpsError("invalid-argument", "Compte invalide.");
  }
  for (const flag of ["resetSecondFactor", "revokeSessions", "sendInvite"] as const) {
    if (data[flag] !== undefined && data[flag] !== true) {
      throw new HttpsError("invalid-argument", "Paramètre invalide.");
    }
  }
  if (data.disabled !== undefined && typeof data.disabled !== "boolean") {
    throw new HttpsError("invalid-argument", "Paramètre invalide.");
  }
  if (data.displayName !== undefined && typeof data.displayName !== "string") {
    throw new HttpsError("invalid-argument", "Nom invalide.");
  }
  const displayName: string | undefined = data.displayName?.trim();
  if (displayName !== undefined) {
    validateDisplayName(displayName);
  }

  const changes: string[] = [];
  if (displayName !== undefined) changes.push("displayName");
  if (data.disabled !== undefined) changes.push(`disabled=${data.disabled}`);
  if (data.resetSecondFactor) changes.push("resetSecondFactor");
  if (data.revokeSessions) changes.push("revokeSessions");
  if (data.sendInvite) changes.push("sendInvite");
  if (changes.length === 0) {
    throw new HttpsError("invalid-argument", "Aucune modification demandée.");
  }
  const details = changes.join(", ");

  if (uid === caller.uid) {
    const self = { uid, email: caller.email };
    if (data.disabled === true) {
      return refuse(caller, "admin_update", self, "failed-precondition", "Vous ne pouvez pas désactiver votre propre compte.", details);
    }
    if (data.resetSecondFactor || data.revokeSessions) {
      return refuse(
        caller,
        "admin_update",
        self,
        "failed-precondition",
        "Pour votre propre compte, utilisez « Sécurité du compte » ou déconnectez-vous.",
        details,
      );
    }
  }

  return withAdminLock(async () => {
    const record = await getUserOrNull(uid);
    if (record == null) {
      return refuse(caller, "admin_update", { uid }, "not-found", "Compte introuvable.", details);
    }
    const target = { uid, email: record.email };
    if (!isAdminRecord(record)) {
      return refuse(caller, "admin_update", target, "failed-precondition", "Ce compte n'est pas un administrateur.", details);
    }
    if (data.disabled === true && !record.disabled && otherEnabledAdmins(await listAdminRecords(), uid) === 0) {
      return refuse(caller, "admin_update", target, "failed-precondition", "Impossible : ce compte est le dernier administrateur actif.", details);
    }

    try {
      const patch: UpdateRequest = {};
      if (displayName !== undefined) patch.displayName = displayName.length > 0 ? displayName : null;
      if (data.disabled !== undefined) patch.disabled = data.disabled;
      if (data.resetSecondFactor) patch.multiFactor = { enrolledFactors: null };
      if (Object.keys(patch).length > 0) {
        await auth().updateUser(uid, patch);
      }
    } catch (e: any) {
      logger.error(`[Error] updateAdmin: mise à jour Auth échouée : ${describeError(e)}`);
      await AdminAuditRepository.instance.record({
        action: "admin_update",
        targetUid: uid,
        targetEmail: record.email,
        adminUid: caller.uid,
        adminEmail: caller.email,
        outcome: "failure",
        error: String(e?.message ?? e),
        details,
      });
      throw new HttpsError("internal", "La mise à jour du compte a échoué, réessayez.");
    }

    // Le compte est modifié : ce qui suit complète la modification. S'il échoue, on le dit tel quel : un audit
    // « échec » pour une modification déjà appliquée tromperait, et une réactivation ultérieure rendrait leur
    // validité à des sessions que cette étape devait couper.
    try {
      // Désactiver ne révoque pas les jetons de rafraîchissement : sans cela, réactiver le compte
      // rendrait leur validité à des sessions volées avant la désactivation.
      if (data.disabled === true || data.resetSecondFactor || data.revokeSessions) {
        await auth().revokeRefreshTokens(uid);
      }
      if (data.disabled !== undefined) {
        await mirrorDisabledOnCoachProfile(uid, data.disabled);
      }
    } catch (e: any) {
      logger.error(`[Error] updateAdmin: finalisation échouée après la modification : ${describeError(e)}`);
      await AdminAuditRepository.instance.record({
        action: "admin_update",
        targetUid: uid,
        targetEmail: record.email,
        adminUid: caller.uid,
        adminEmail: caller.email,
        outcome: "failure",
        error: String(e?.message ?? e),
        details: `${details} (modification appliquée, sessions ou fiche non finalisées)`,
      });
      throw new HttpsError(
        "internal",
        "Le compte a été modifié, mais la coupure des sessions ou la mise à jour de sa fiche n'a pas abouti : recommencez l'opération.",
      );
    }

    let inviteSent: boolean | undefined;
    if (data.sendInvite) {
      try {
        await sendAdminInvite(record.email ?? "", displayName ?? record.displayName ?? undefined);
        inviteSent = true;
      } catch (e: any) {
        logger.error(`[Error] updateAdmin: envoi de l'invitation échoué : ${describeError(e)}`);
        inviteSent = false;
      }
    }

    await AdminAuditRepository.instance.record({
      action: "admin_update",
      targetUid: uid,
      targetEmail: record.email,
      adminUid: caller.uid,
      adminEmail: caller.email,
      outcome: "success",
      details: inviteSent === false ? `${details} (invitation non envoyée)` : details,
    });

    const admin = toAdminAccount(await auth().getUser(uid));
    return inviteSent === undefined ? { admin } : { admin, inviteSent };
  });
};

/**
 * Un compte à la fois administrateur et coach (promu par scripts/set-admin.ts) a une fiche que le
 * back-office affiche et filtre ; setCoachDisabled refuse les administrateurs, donc la recopie se
 * fait ici. Sans fiche, rien à faire.
 */
async function mirrorDisabledOnCoachProfile(uid: string, disabled: boolean): Promise<void> {
  const ref = firestore().collection("users").doc(uid);
  if (!(await ref.get()).exists) {
    return;
  }
  await ref.update({ disabled, disabledAt: disabled ? firestore.Timestamp.now() : null });
}
