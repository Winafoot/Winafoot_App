import { getApp } from "firebase/app";
import { getFunctions, httpsCallable } from "firebase/functions";

// Les functions Wina sont déployées en europe-west9 (setGlobalOptions).
const functions = () => getFunctions(getApp(), "europe-west9");

export const createCoach = (data: {
  email: string;
  password: string;
  firstname?: string;
  teamFormat: number;
  teamName?: string;
  category?: string;
  division?: string;
}) => httpsCallable<typeof data, { uid: string }>(functions(), "createCoach")(data);

export const resendInvite = (uid: string) =>
  httpsCallable<{ uid: string }, { sent: true }>(functions(), "resendInvite")({ uid });

export const setCoachDisabled = (uid: string, disabled: boolean) =>
  httpsCallable<{ uid: string; disabled: boolean }, { disabled: boolean }>(functions(), "setCoachDisabled")({ uid, disabled });

export const deleteCoach = (uid: string) =>
  httpsCallable<{ uid: string }, { deleted: true }>(functions(), "deleteCoach")({ uid });

// Comptes administrateurs. Le serveur (functions/src/callables/admin/*_admin*.ts) applique les garde-fous :
// la vue ne fait qu'en afficher le message.
export interface AdminAccount {
  uid: string;
  email: string;
  displayName: string;
  disabled: boolean;
  emailVerified: boolean;
  /** Nombre de seconds facteurs inscrits (0 = mot de passe seul). */
  secondFactors: number;
  createdAt: string | null;
  lastSignInAt: string | null;
}

export const listAdmins = () =>
  httpsCallable<Record<string, never>, { admins: AdminAccount[]; self: string }>(functions(), "listAdmins")({});

export const createAdmin = (data: { email: string; displayName?: string }) =>
  httpsCallable<typeof data, { uid: string; inviteSent: boolean }>(functions(), "createAdmin")(data);

export const updateAdmin = (data: {
  uid: string;
  displayName?: string;
  disabled?: boolean;
  resetSecondFactor?: true;
  revokeSessions?: true;
  sendInvite?: true;
}) => httpsCallable<typeof data, { admin: AdminAccount; inviteSent?: boolean }>(functions(), "updateAdmin")(data);

export const deleteAdmin = (uid: string) =>
  httpsCallable<{ uid: string }, { deleted: true }>(functions(), "deleteAdmin")({ uid });
