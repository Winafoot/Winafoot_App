import { firestore } from "firebase-admin";
import type { AdminCaller } from "../../runtime/v2_admin";

const SUBSCRIPTION_STATUSES = ["trial", "active", "grace", "expired", "refunded"] as const;
const MONTHS = 12;

export interface AdminStats {
  generatedAt: string;
  coaches: { total: number; linked: number; disabled: number };
  content: { players: number; matches: number; compositions: number; reports: number };
  subscriptions: Record<(typeof SUBSCRIPTION_STATUSES)[number], number>;
  /** Inscriptions par mois, du plus ancien au plus récent (mois en cours inclus). */
  signups: { month: string; count: number }[];
}

async function count(query: firestore.Query): Promise<number> {
  return (await query.count().get()).data().count;
}

/**
 * Chiffres du tableau de bord. Uniquement des agrégations `count()` : aucun document n'est lu ni renvoyé, le
 * coût est d'une lecture par tranche de 1 000 entrées comptées. Lecture seule, rien n'est journalisé.
 */
export default async (_data: unknown, _caller: AdminCaller): Promise<AdminStats> => {
  const db = firestore();
  const users = db.collection("users");

  const now = new Date();
  const months: { month: string; from: Date; to: Date }[] = [];
  for (let i = MONTHS - 1; i >= 0; i--) {
    const from = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - i, 1));
    const to = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - i + 1, 1));
    months.push({ month: from.toISOString().slice(0, 7), from, to });
  }

  const [total, linked, disabled, players, matches, compositions, reports, ...rest] = await Promise.all([
    count(users),
    count(users.where("ownerUid", "!=", null)),
    count(users.where("disabled", "==", true)),
    count(db.collectionGroup("players")),
    count(db.collectionGroup("matches")),
    count(db.collectionGroup("compositions")),
    count(db.collection("reports")),
    ...SUBSCRIPTION_STATUSES.map((s) => count(users.where("subscription.status", "==", s))),
    ...months.map((m) =>
      count(users.where("createdAt", ">=", firestore.Timestamp.fromDate(m.from)).where("createdAt", "<", firestore.Timestamp.fromDate(m.to))),
    ),
  ]);

  const subscriptions = Object.fromEntries(SUBSCRIPTION_STATUSES.map((s, i) => [s, rest[i]])) as AdminStats["subscriptions"];
  const signups = months.map((m, i) => ({ month: m.month, count: rest[SUBSCRIPTION_STATUSES.length + i] }));

  return {
    generatedAt: now.toISOString(),
    coaches: { total: total - linked, linked, disabled },
    content: { players, matches, compositions, reports },
    subscriptions,
    signups,
  };
};
