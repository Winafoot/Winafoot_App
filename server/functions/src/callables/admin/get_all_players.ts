import { firestore } from "firebase-admin";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import type { AdminCaller } from "../../runtime/v2_admin";
import { computeTeamStats } from "./_team_stats";

const MAX_PLAYERS = 5000;
const MAX_MATCHES = 5000;
const MAX_USERS = 2000;

export interface PlayerRow {
  /** Compte (équipe) auquel appartient le joueur : sert à ouvrir la fiche équipe. */
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

export interface GetAllPlayersResult {
  players: PlayerRow[];
  /** Vrai quand une liste a été coupée à sa limite : des joueurs ou des matchs manquent alors. */
  truncated: boolean;
}

/**
 * Tous les joueurs de l'app avec leur équipe et leurs totaux (matchs, buts, passes décisives, cartons).
 * Bornée (5 000 joueurs et 5 000 matchs) et journalisée : ces données concernent des joueurs, parfois mineurs.
 * Le détail statistique par joueur reste dans `getTeamStats`.
 */
export default async (_data: unknown, caller: AdminCaller): Promise<GetAllPlayersResult> => {
  const db = firestore();
  const [users, players, matches] = await Promise.all([
    db.collection("users").select("teamName", "category").limit(MAX_USERS).get(),
    db.collectionGroup("players").limit(MAX_PLAYERS).get(),
    db.collectionGroup("matches").where("finishedAt", ">", firestore.Timestamp.fromMillis(0)).limit(MAX_MATCHES).get(),
  ]);

  const teams = new Map(users.docs.map((d) => [d.id, { teamName: String(d.get("teamName") ?? ""), category: String(d.get("category") ?? "") }]));
  const group = (docs: firestore.QueryDocumentSnapshot[]) => {
    const byTeam = new Map<string, Record<string, unknown>[]>();
    for (const d of docs) {
      const uid = d.ref.parent.parent?.id;
      if (uid == null) continue;
      byTeam.set(uid, [...(byTeam.get(uid) ?? []), { id: d.id, ...d.data() }]);
    }
    return byTeam;
  };
  const playersByTeam = group(players.docs);
  const matchesByTeam = group(matches.docs);

  const rows: PlayerRow[] = [];
  for (const uid of new Set([...playersByTeam.keys(), ...matchesByTeam.keys()])) {
    const team = teams.get(uid);
    // Un compte supprimé dont des données traînent encore n'est pas une équipe : on ne l'affiche pas.
    if (team == null) continue;
    for (const p of computeTeamStats(playersByTeam.get(uid) ?? [], matchesByTeam.get(uid) ?? []).players) {
      rows.push({
        teamUid: uid,
        teamName: team.teamName,
        category: team.category,
        id: p.id,
        name: p.name,
        position: p.position,
        matches: p.matches,
        goals: p.goals,
        assists: p.assists,
        yellowCards: p.yellowCards,
        redCards: p.redCards,
      });
    }
  }

  await AdminAuditRepository.instance.record({
    action: "view_coach_data",
    targetUid: "all",
    adminUid: caller.uid,
    adminEmail: caller.email,
    outcome: "success",
    details: "all players",
  });

  return { players: rows, truncated: players.size >= MAX_PLAYERS || matches.size >= MAX_MATCHES };
};
