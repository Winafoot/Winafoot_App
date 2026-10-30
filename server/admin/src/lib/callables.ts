import { httpsCallable } from "firebase/functions";
import { functions } from "./firebase";

const call = <In, Out>(name: string) => (data: In) => httpsCallable<In, Out>(functions(), name)(data).then((r) => r.data);

// Coachs
export const createCoach = call<
  { email: string; password: string; firstname?: string; teamFormat: number; teamName?: string; category?: string; division?: string },
  { uid: string }
>("createCoach");
export const resendInvite = call<{ uid: string }, { sent: true }>("resendInvite");
export const setCoachDisabled = call<{ uid: string; disabled: boolean }, { disabled: boolean }>("setCoachDisabled");
export const deleteCoach = call<{ uid: string }, { deleted: true }>("deleteCoach");

// Administrateurs : le serveur applique les garde-fous, la vue n'en affiche que le message.
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
export const listAdmins = call<Record<string, never>, { admins: AdminAccount[]; self: string }>("listAdmins");
export const createAdmin = call<{ email: string; displayName?: string }, { uid: string; inviteSent: boolean }>("createAdmin");
export const updateAdmin = call<
  { uid: string; displayName?: string; disabled?: boolean; resetSecondFactor?: true; revokeSessions?: true; sendInvite?: true },
  { admin: AdminAccount; inviteSent?: boolean }
>("updateAdmin");
export const deleteAdmin = call<{ uid: string }, { deleted: true }>("deleteAdmin");

// Tableau de bord et données de l'app (lecture seule, côté serveur).
export interface AdminStats {
  generatedAt: string;
  coaches: { total: number; linked: number; disabled: number };
  content: { players: number; matches: number; compositions: number; reports: number };
  subscriptions: Record<"trial" | "active" | "grace" | "expired" | "refunded", number>;
  signups: { month: string; count: number }[];
}
export const getAdminStats = call<Record<string, never>, AdminStats>("getAdminStats");

export interface CoachData {
  players: Record<string, unknown>[];
  matches: Record<string, unknown>[];
  compositions: Record<string, unknown>[];
  linkedTeams: Record<string, unknown>[];
  truncated: boolean;
  limit: number;
}
export const getCoachData = call<{ uid: string }, CoachData>("getCoachData");

export const listReports = call<Record<string, never>, { reports: Record<string, unknown>[]; limit: number }>("listReports");

export type NotificationSegment = "profile_incomplete" | "no_subscription" | "subscribed" | "trial" | "format_5" | "format_8" | "format_11";
export type NotificationAudience = { kind: "all" } | { kind: "segment"; segment: NotificationSegment } | { kind: "uids"; uids: string[] };

/** `dryRun` : compte les destinataires sans rien envoyer. */
export const sendAdminNotification = call<{ title: string; body: string; audience: NotificationAudience; dryRun?: boolean }, { recipients: number; sent: boolean }>("sendAdminNotification");

/** Mot de passe d'un compte d'équipe lié, à la demande du propriétaire. Renvoie l'identifiant du compte. */
export const resetLinkedTeamPasswordByAdmin = call<{ uid: string; password: string }, { identifier: string }>("resetLinkedTeamPasswordByAdmin");

/** Message lisible d'une erreur de callable (le serveur écrit déjà des messages en français). */
export function errorMessage(error: unknown, fallback = "L'opération a échoué."): string {
  return error instanceof Error && error.message ? error.message : fallback;
}
