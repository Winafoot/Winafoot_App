import { firestore } from "firebase-admin";
import type { AdminCaller } from "../../runtime/v2_admin";
import { computeBenchmarks, type Benchmarks } from "./_benchmarks";

const MAX_MATCHES = 5000;
const MAX_USERS = 2000;

export interface GetPlayerBenchmarksResult extends Benchmarks {
  generatedAt: string;
  matchesUsed: number;
  /** Vrai quand il y a plus de matchs que `limit` : les chiffres portent alors sur un échantillon. */
  truncated: boolean;
  limit: number;
}

/**
 * Niveau des clients par catégorie et classement ANONYME des joueurs (aucun nom, aucune équipe, aucun
 * identifiant dans la réponse). Lit les matchs terminés (jusqu'à 5 000) et la catégorie de chaque compte.
 */
export default async (_data: unknown, _caller: AdminCaller): Promise<GetPlayerBenchmarksResult> => {
  const db = firestore();
  const [users, matches] = await Promise.all([
    db.collection("users").select("category").limit(MAX_USERS).get(),
    db.collectionGroup("matches").where("finishedAt", ">", firestore.Timestamp.fromMillis(0)).limit(MAX_MATCHES).get(),
  ]);

  const categories = new Map(users.docs.map((d) => [d.id, String(d.get("category") ?? "")]));
  const rows = matches.docs.flatMap((d) => {
    const uid = d.ref.parent.parent?.id;
    return uid == null ? [] : [{ uid, data: d.data() as Record<string, unknown> }];
  });

  return {
    ...computeBenchmarks(categories, rows),
    generatedAt: new Date().toISOString(),
    matchesUsed: rows.filter((r) => r.data.status === "finished").length,
    truncated: matches.size >= MAX_MATCHES,
    limit: MAX_MATCHES,
  };
};
