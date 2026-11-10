import { firestore } from "firebase-admin";
import { AdminAuditRepository } from "../../database/admin_audit/admin_audit_repository";
import type { AdminCaller } from "../../runtime/v2_admin";
import { computeBenchmarks, type Benchmarks } from "./_benchmarks";

const MAX_MATCHES = 5000;
const MAX_USERS = 2000;
const MAX_PLAYERS = 5000;

export interface GetPlayerBenchmarksResult extends Benchmarks {
  generatedAt: string;
  matchesUsed: number;
  /** Vrai quand il y a plus de matchs que `limit` : les chiffres portent alors sur un échantillon. */
  truncated: boolean;
  limit: number;
}

/**
 * Niveau des clients par catégorie (agrégats) et classement des meilleurs joueurs avec leur nom et leur équipe.
 * Lit les matchs terminés (jusqu'à 5 000), les joueurs et la catégorie de chaque compte. Journalisée : le
 * classement affiche des noms de joueurs, parfois mineurs.
 */
export default async (_data: unknown, caller: AdminCaller): Promise<GetPlayerBenchmarksResult> => {
  const db = firestore();
  const [users, players, matches] = await Promise.all([
    db.collection("users").select("category", "teamName").limit(MAX_USERS).get(),
    db.collectionGroup("players").select("firstName", "lastName").limit(MAX_PLAYERS).get(),
    db.collectionGroup("matches").where("finishedAt", ">", firestore.Timestamp.fromMillis(0)).limit(MAX_MATCHES).get(),
  ]);

  const categories = new Map(users.docs.map((d) => [d.id, String(d.get("category") ?? "")]));
  const rows = matches.docs.flatMap((d) => {
    const uid = d.ref.parent.parent?.id;
    return uid == null ? [] : [{ uid, data: d.data() as Record<string, unknown> }];
  });

  const teams = new Map(users.docs.map((d) => [d.id, String(d.get("teamName") ?? "")]));
  const names = new Map(
    players.docs.flatMap((d) => {
      const uid = d.ref.parent.parent?.id;
      const name = `${d.get("firstName") ?? ""} ${d.get("lastName") ?? ""}`.trim();
      return uid == null || name === "" ? [] : [[`${uid}/${d.id}`, name] as [string, string]];
    }),
  );

  await AdminAuditRepository.instance.record({
    action: "view_coach_data",
    targetUid: "all",
    adminUid: caller.uid,
    adminEmail: caller.email,
    outcome: "success",
    details: "player ranking",
  });

  return {
    ...computeBenchmarks(categories, rows, { players: names, teams }),
    generatedAt: new Date().toISOString(),
    matchesUsed: rows.filter((r) => r.data.status === "finished").length,
    truncated: matches.size >= MAX_MATCHES || players.size >= MAX_PLAYERS,
    limit: MAX_MATCHES,
  };
};
