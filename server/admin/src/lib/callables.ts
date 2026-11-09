import { httpsCallable } from "firebase/functions";
import { functions } from "./firebase";

const call = <In, Out>(name: string) => (data: In) => httpsCallable<In, Out>(functions(), name)(data).then((r) => r.data);

// Coachs
export const createCoach = call<
  { email: string; password: string; firstname?: string; teamFormat: number; teamName?: string; category?: string; division?: string; subscription?: { teams: number; days: number } },
  { uid: string }
>("createCoach");
export const resendInvite = call<{ uid: string }, { sent: true }>("resendInvite");
export const setCoachDisabled = call<{ uid: string; disabled: boolean }, { disabled: boolean }>("setCoachDisabled");
export const deleteCoach = call<{ uid: string }, { deleted: true }>("deleteCoach");
/** Supprime une équipe liée dont le compte principal n'existe plus ; le serveur refuse toute autre équipe. */
export const deleteOrphanTeam = call<{ uid: string }, { deleted: true }>("deleteOrphanTeam");

/** Abonnement offert (comptes de test) : attribué ou retiré à la main, sans passer par les stores. `untilMs` : fin de l'accès, null après un retrait. */
export const setCoachSubscription = call<
  { uid: string; action: "grant" | "revoke"; teams?: number; days?: number },
  { action: "grant" | "revoke"; untilMs: number | null }
>("setCoachSubscription");

/** Offre de réduction Apple créée dans App Store Connect : `batchId` pour un lot de codes à usage unique, `customCode` pour un code personnalisé. */
export interface AppleOfferResult {
  offerId: string;
  appliedPrice: number;
  appliedPercentOff: number;
  batchId?: string;
  customCode?: string;
}
export const createAppleOfferCode = call<
  {
    subscriptionId: string;
    name: string;
    basePrice: number;
    percentOff?: number;
    months?: number;
    territory?: string;
    expirationDate: string;
    customCode?: string;
    numberOfCodes?: number;
  },
  AppleOfferResult
>("createAppleOfferCode");
export const getAppleOfferCodeValues = call<{ batchId: string }, { codes: string[] }>("getAppleOfferCodeValues");

export interface AppleSubscription {
  id: string;
  name: string;
  productId: string;
  appName: string;
  groupName: string;
}
export interface AppleTerritory {
  id: string;
  currency: string;
}
/** Sans argument : abonnements et territoires d'App Store Connect. Avec `subscriptionId` : le prix actuel (`price`) dans le territoire. */
export const listAppleSubscriptions = call<
  { subscriptionId?: string; territory?: string; basePrice?: number; percentOff?: number },
  { subscriptions: AppleSubscription[]; territories: AppleTerritory[]; price?: number; discounted?: { price: number; percentOff: number } }
>("listAppleSubscriptions");

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

// Équipes et statistiques d'usage (lecture seule). Le bilan d'une équipe est journalisé côté serveur.
export interface TeamActivity {
  uid: string;
  players: number;
  matches: number;
  finished: number;
  lastFinishedAt: string | null;
}
export const getTeamActivity = call<Record<string, never>, { teams: TeamActivity[]; truncated: boolean; limit: number }>("getTeamActivity");

export interface TeamPlayerLine {
  id: string;
  name: string;
  position: string;
  matches: number;
  goals: number;
  assists: number;
  yellowCards: number;
  redCards: number;
  /** Total de chaque statistique saisie (clés de `stat-catalog.ts`), valeurs non nulles seulement. */
  stats: Record<string, number>;
  history: { matchId: string; opponent: string; finishedAt: string | null; stats: Record<string, number> }[];
}
export interface TeamMatchLine {
  id: string;
  opponent: string;
  scoreUs: number;
  scoreThem: number;
  result: "win" | "draw" | "loss";
  finishedAt: string | null;
  elapsedSeconds: number;
  scorers: { name: string; goals: number }[];
  yellowCards: number;
  redCards: number;
}
export interface TeamStats {
  record: { played: number; wins: number; draws: number; losses: number; goalsFor: number; goalsAgainst: number };
  matches: TeamMatchLine[];
  players: TeamPlayerLine[];
  truncated: boolean;
  limit: number;
}
export const getTeamStats = call<{ uid: string }, TeamStats>("getTeamStats");

export interface UsageWeek {
  weekStart: string;
  matches: number;
  activeTeams: number;
}
export const getUsageStats = call<Record<string, never>, { generatedAt: string; weeks: UsageWeek[]; truncated: boolean; limit: number }>("getUsageStats");

/** Note interne d'un coach (visible des administrateurs seuls). Un texte vide efface la note. */
export interface CoachNote {
  text: string;
  updatedAt: string | null;
  updatedBy: string | null;
}
export const getCoachNote = call<{ uid: string }, CoachNote>("getCoachNote");
export const setCoachNote = call<{ uid: string; text: string }, CoachNote>("setCoachNote");

/** Offres à code d'App Store Connect avec leurs lots de codes et codes personnalisés. */
export interface AppleOffer {
  id: string;
  name: string;
  subscription: string;
  mode: string;
  duration: string;
  periods: number;
  active: boolean;
  batches: { id: string; codes: number; expirationDate: string | null; active: boolean }[];
  customCodes: { id: string; code: string; uses: number; expirationDate: string | null; active: boolean }[];
}
export const listAppleOffers = call<Record<string, never>, { offers: AppleOffer[] }>("listAppleOffers");

/** Niveau des clients par catégorie et classement des meilleurs joueurs, avec leur nom et leur équipe. */
export interface CategoryBenchmark {
  category: string;
  teams: number;
  matches: number;
  goalsForPerMatch: number;
  goalsAgainstPerMatch: number;
  winRate: number;
  passAccuracy: number | null;
  yellowCardsPerMatch: number;
}
export interface RankedPlayer {
  rank: number;
  name: string;
  teamName: string;
  teamUid: string;
  playerId: string;
  category: string;
  matches: number;
  goals: number;
  assists: number;
  goalsPerMatch: number;
}
export const getPlayerBenchmarks = call<
  Record<string, never>,
  { categories: CategoryBenchmark[]; topScorers: RankedPlayer[]; topAssisters: RankedPlayer[]; generatedAt: string; matchesUsed: number; truncated: boolean; limit: number }
>("getPlayerBenchmarks");

/** Un joueur de l'app avec son équipe et ses totaux ; `teamUid` ouvre la fiche équipe. */
export interface PlayerRow {
  teamUid: string;
  teamName: string;
  category: string;
  id: string;
  name: string;
  position: string;
  matches: number;
  goals: number;
  assists: number;
  yellowCards: number;
  redCards: number;
}
export const getAllPlayers = call<Record<string, never>, { players: PlayerRow[]; truncated: boolean }>("getAllPlayers");

/** Modifie des champs de la configuration de l'app (`mail.*` en clé pointée). Une valeur vide supprime un champ facultatif. */
export const updateAppConfig = call<{ changes: Record<string, string> }, { changed: string[] }>("updateAppConfig");
