import { firestore } from "firebase-admin";
import type { AdminCaller } from "../../runtime/v2_admin";
import { toJson } from "./_serialize";

const LIMIT = 100;

export interface ListReportsResult {
  reports: Record<string, unknown>[];
  limit: number;
}

/** Derniers signalements envoyés depuis l'app (collection racine `reports`, fermée aux clients). Lecture seule. */
export default async (_data: unknown, _caller: AdminCaller): Promise<ListReportsResult> => {
  const snap = await firestore().collection("reports").orderBy("sendAt", "desc").limit(LIMIT).get();
  return {
    reports: snap.docs.map((d) => ({ id: d.id, ...(toJson(d.data()) as Record<string, unknown>) })),
    limit: LIMIT,
  };
};
