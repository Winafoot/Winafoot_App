import { firestore } from "firebase-admin";

export type AdminAuditAction =
  | "create"
  | "resend"
  | "disable"
  | "enable"
  | "delete"
  // Consultation des données d'un coach (effectif, matchs, compositions) : tracée, elles concernent des joueurs.
  | "view_coach_data"
  // Message envoyé à un groupe de comptes (jamais le texte, seulement l'audience) et mot de passe d'une équipe liée redéfini.
  | "send_notification"
  | "linked_reset_password"
  // Comptes administrateurs (vue « Administrateurs » du back-office).
  | "admin_create"
  | "admin_update"
  | "admin_delete";

export interface AdminAuditEntry {
  action: AdminAuditAction;
  targetUid: string;
  targetEmail?: string;
  adminUid: string;
  adminEmail?: string;
  outcome: "success" | "failure";
  error?: string;
  /** Pour `admin_update` : ce qui a été demandé (ex. « disabled=true, resetSecondFactor »). Jamais de secret. */
  details?: string;
  /**
   * Pour une suppression en échec : l'étape qui a échoué. Permet de distinguer
   * un échec sans danger (rien n'a encore été supprimé, on peut réessayer)
   * d'un échec dangereux (le compte Auth a été supprimé mais ses données
   * Firestore ne l'ont pas été).
   */
  failedStage?: "archive" | "teams" | "auth_delete" | "firestore_delete";
  /** Pour une suppression réussie : la purge Storage a-t-elle bien abouti. */
  storagePurged?: boolean;
}

/**
 * Piste d'audit des actions du back-office.
 * Collection racine `admin_audit` : écrite uniquement par l'Admin SDK,
 * lisible par les administrateurs, jamais inscriptible depuis un client.
 */
export class AdminAuditRepository {
  private static _instance: AdminAuditRepository = new AdminAuditRepository();

  public static get instance(): AdminAuditRepository {
    return AdminAuditRepository._instance;
  }

  public async record(entry: AdminAuditEntry): Promise<void> {
    await firestore().collection("admin_audit").add({
      action: entry.action,
      targetUid: entry.targetUid,
      targetEmail: entry.targetEmail ?? null,
      adminUid: entry.adminUid,
      adminEmail: entry.adminEmail ?? null,
      outcome: entry.outcome,
      error: entry.error ?? null,
      details: entry.details ?? null,
      failedStage: entry.failedStage ?? null,
      storagePurged: entry.storagePurged ?? null,
      at: firestore.Timestamp.now(),
    });
  }
}
