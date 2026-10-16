import { buildCollection } from "@firecms/core";
import { deleteCoachAction, resendInviteAction, toggleDisabledAction } from "./coach_actions";
import { TEAM_CATEGORIES, TEAM_DIVISIONS, TEAM_FORMATS } from "../team_options";

export type Coach = {
  email: string;
  firstname?: string;
  coachName?: string;
  teamName?: string;
  category?: string;
  division?: string;
  teamFormat?: number;
  profilCompleted?: boolean;
  disabled?: boolean;
  createdAt?: Date;
  lastInviteSentAt?: Date;
};

export const coachesCollection = buildCollection<Coach>({
  id: "coaches",
  path: "users",
  name: "Coachs",
  singularName: "Coach",
  description: "Comptes coach de l'application Wina.",
  textSearchEnabled: false,
  // Lecture seule : toute mutation passe par les callables Admin SDK.
  permissions: () => ({ read: true, create: false, edit: false, delete: false }),
  entityActions: [resendInviteAction, toggleDisabledAction, deleteCoachAction],
  properties: {
    email: { dataType: "string", name: "E-mail", readOnly: true },
    firstname: { dataType: "string", name: "Prénom", readOnly: true },
    teamName: { dataType: "string", name: "Équipe", readOnly: true },
    coachName: { dataType: "string", name: "Nom du coach", readOnly: true },
    category: {
      dataType: "string",
      name: "Catégorie",
      readOnly: true,
      enumValues: TEAM_CATEGORIES,
    },
    division: {
      dataType: "string",
      name: "Division",
      readOnly: true,
      enumValues: TEAM_DIVISIONS,
    },
    teamFormat: {
      dataType: "number",
      name: "Format",
      readOnly: true,
      enumValues: TEAM_FORMATS.map(({ value, label }) => ({ id: value, label })),
    },
    profilCompleted: { dataType: "boolean", name: "Profil complété", readOnly: true },
    disabled: { dataType: "boolean", name: "Désactivé", readOnly: true },
    createdAt: { dataType: "date", name: "Créé le", readOnly: true },
    lastInviteSentAt: { dataType: "date", name: "Dernière invitation", readOnly: true },
  },
});
