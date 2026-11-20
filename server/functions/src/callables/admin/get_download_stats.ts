import { appleDailyDownloads } from "../../billing/app_store_connect";
import { googleDailyInstalls } from "../../billing/google_play_reports";
import { APPLE_VENDOR_NUMBER, GOOGLE_REPORTS_BUCKET } from "../../config/download_stats";
import { HttpsError, logger } from "../../runtime/firebase";
import type { AdminCaller } from "../../runtime/v2_admin";
import { describeError } from "../../utils/describe_error";

const DEFAULT_DAYS = 30;
const MAX_DAYS = 60;

export interface StoreDownloads {
  /** Faux tant que les réglages de la boutique sont vides (`config/download_stats.ts`) : `error` dit ce qui manque. */
  configured: boolean;
  total: number;
  /** Un point par jour de la période, du plus ancien au plus récent. */
  daily: { date: string; count: number }[];
  error?: string;
}

export interface DownloadStats {
  days: number;
  from: string;
  to: string;
  apple: StoreDownloads;
  google: StoreDownloads;
}

/** Les [days] derniers jours complets, du plus ancien à hier (`AAAA-MM-JJ`, UTC) : les rapports du jour même n'existent pas encore. */
export function lastDays(days: number, now = new Date()): string[] {
  const out: string[] = [];
  for (let i = days; i >= 1; i--) out.push(new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - i)).toISOString().slice(0, 10));
  return out;
}

/** Mois (`AAAA-MM`) couverts par une liste de jours. */
export function monthsOf(dates: string[]): string[] {
  return [...new Set(dates.map((d) => d.slice(0, 7)))];
}

function failure(store: string, e: unknown): StoreDownloads {
  if (!(e instanceof HttpsError)) logger.error(`[Error] getDownloadStats ${store}: ${describeError(e)}`);
  return { configured: true, total: 0, daily: [], error: e instanceof HttpsError ? e.message : "Lecture impossible, réessayez." };
}

const sum = (daily: { count: number }[]) => daily.reduce((a, d) => a + d.count, 0);

/**
 * Téléchargements des dernières semaines : Apple (premiers téléchargements des rapports « Ventes et tendances ») et
 * Google Play (installations des rapports de la Play Console). Chaque boutique est lue à part : l'échec de l'une
 * n'empêche pas d'afficher l'autre. Lecture seule, rien n'est conservé ni journalisé.
 */
export default async (data: { days?: number } | undefined, _caller: AdminCaller): Promise<DownloadStats> => {
  const requested = Number(data?.days ?? DEFAULT_DAYS);
  const days = Number.isInteger(requested) ? Math.min(MAX_DAYS, Math.max(7, requested)) : DEFAULT_DAYS;
  const dates = lastDays(days);

  const apple = async (): Promise<StoreDownloads> => {
    if (APPLE_VENDOR_NUMBER.trim() === "") {
      return { configured: false, total: 0, daily: [], error: "Numéro de fournisseur Apple non renseigné (server/functions/src/config/download_stats.ts)." };
    }
    try {
      const daily = await appleDailyDownloads(APPLE_VENDOR_NUMBER.trim(), dates);
      return { configured: true, total: sum(daily), daily };
    } catch (e) {
      return failure("apple", e);
    }
  };

  const google = async (): Promise<StoreDownloads> => {
    if (GOOGLE_REPORTS_BUCKET.trim() === "") {
      return { configured: false, total: 0, daily: [], error: "Espace de stockage des rapports Google Play non renseigné (server/functions/src/config/download_stats.ts)." };
    }
    try {
      const found = new Map((await googleDailyInstalls(GOOGLE_REPORTS_BUCKET, monthsOf(dates))).map((d) => [d.date, d.count]));
      const daily = dates.map((date) => ({ date, count: found.get(date) ?? 0 }));
      return { configured: true, total: sum(daily), daily };
    } catch (e) {
      return failure("google", e);
    }
  };

  const [appleResult, googleResult] = await Promise.all([apple(), google()]);
  return { days, from: dates[0], to: dates[dates.length - 1], apple: appleResult, google: googleResult };
};
