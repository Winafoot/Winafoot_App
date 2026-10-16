import { buildCollection } from "@firecms/core";

export type AdminAuditEntry = {
  action: string;
  targetUid: string;
  targetEmail?: string;
  adminUid: string;
  adminEmail?: string;
  outcome: string;
  error?: string;
  details?: string;
  at: Date;
};

export const adminAuditCollection = buildCollection<AdminAuditEntry>({
  id: "admin_audit",
  path: "admin_audit",
  name: "Journal d'audit",
  singularName: "Entrée",
  description: "Actions effectuées depuis le back-office.",
  initialSort: ["at", "desc"],
  permissions: () => ({ read: true, create: false, edit: false, delete: false }),
  properties: {
    at: { dataType: "date", name: "Date", readOnly: true },
    action: {
      dataType: "string",
      name: "Action",
      readOnly: true,
      enumValues: {
        create: "Création",
        resend: "Invitation renvoyée",
        disable: "Désactivation",
        enable: "Réactivation",
        delete: "Suppression",
        admin_create: "Administrateur invité",
        admin_update: "Administrateur modifié",
        admin_delete: "Administrateur supprimé",
      },
    },
    targetEmail: { dataType: "string", name: "Compte concerné", readOnly: true },
    adminEmail: { dataType: "string", name: "Administrateur", readOnly: true },
    outcome: {
      dataType: "string",
      name: "Résultat",
      readOnly: true,
      enumValues: { success: "Succès", failure: "Échec" },
    },
    error: { dataType: "string", name: "Erreur", readOnly: true },
    details: { dataType: "string", name: "Détail", readOnly: true },
    targetUid: { dataType: "string", name: "UID du compte", readOnly: true },
    adminUid: { dataType: "string", name: "UID administrateur", readOnly: true },
  },
});
