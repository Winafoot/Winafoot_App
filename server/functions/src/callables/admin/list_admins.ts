import type { AdminCaller } from "../../runtime/v2_admin";
import { listAdminRecords, toAdminAccount, type AdminAccount } from "./_admin_accounts";

export interface ListAdminsResult {
  admins: AdminAccount[];
  /** uid de l'appelant : la vue s'en sert pour griser « se désactiver / se supprimer ». */
  self: string;
}

/** Liste des comptes administrateurs, triés par adresse. Lecture seule, rien n'est journalisé. */
export default async (_data: unknown, caller: AdminCaller): Promise<ListAdminsResult> => {
  const admins = (await listAdminRecords()).map(toAdminAccount);
  admins.sort((a, b) => a.email.localeCompare(b.email));
  return { admins, self: caller.uid };
};
