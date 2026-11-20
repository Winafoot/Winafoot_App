import { HttpsError } from "../runtime/firebase";
import { accessToken, GOOGLE_PLAY_PACKAGE } from "./google_play";

/**
 * Installations Google Play. L'API Play Developer n'expose pas les téléchargements : la Play Console exporte chaque jour
 * des rapports CSV mensuels dans un espace Cloud Storage privé (`pubsite_prod_rev_…`), lus ici avec le compte de service.
 * Le compte doit voir les informations de l'application (permission globale) et avoir accès en lecture à cet espace.
 */
const STORAGE_SCOPE = "https://www.googleapis.com/auth/devstorage.read_only";

/** Nom de l'espace de stockage, avec ou sans le préfixe `gs://` et sans barre finale. */
export function normalizeBucket(raw: string): string {
  return raw.trim().replace(/^gs:\/\//, "").replace(/\/.*$/, "");
}

/** Chemin du rapport mensuel des installations (aperçu par jour), ex. `stats/installs/installs_fr.winafoot.app_202611_overview.csv`. */
export function installsReportPath(month: string, packageName = GOOGLE_PLAY_PACKAGE): string {
  return `stats/installs/installs_${packageName}_${month.replace("-", "")}_overview.csv`;
}

/** Texte du rapport : Google l'écrit en UTF-16 (avec BOM) ; un fichier UTF-8 reste lisible. */
export function decodeReport(bytes: Buffer): string {
  if (bytes.length >= 2 && bytes[0] === 0xff && bytes[1] === 0xfe) return bytes.subarray(2).toString("utf16le");
  if (bytes.length >= 2 && bytes[0] === 0xfe && bytes[1] === 0xff) return Buffer.from(bytes.subarray(2)).swap16().toString("utf16le");
  return bytes.toString("utf8").replace(/^﻿/, "");
}

/** Découpe une ligne CSV (guillemets et virgules entre guillemets pris en charge). */
export function splitCsvLine(line: string): string[] {
  const cells: string[] = [];
  let cell = "";
  let quoted = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (quoted) {
      if (c === '"' && line[i + 1] === '"') {
        cell += '"';
        i++;
      } else if (c === '"') quoted = false;
      else cell += c;
    } else if (c === '"') quoted = true;
    else if (c === ",") {
      cells.push(cell);
      cell = "";
    } else cell += c;
  }
  cells.push(cell);
  return cells;
}

/**
 * Installations par jour d'un rapport mensuel : colonne « Daily User Installs » (nouveaux utilisateurs qui installent),
 * à défaut « Daily Device Installs ». Les colonnes sont repérées par leur nom.
 */
export function parseInstallsCsv(csv: string): { date: string; count: number }[] {
  const lines = csv.split(/\r?\n/).filter((l) => l.trim() !== "");
  if (lines.length < 2) return [];
  const header = splitCsvLine(lines[0]).map((h) => h.trim());
  const date = header.indexOf("Date");
  let installs = header.indexOf("Daily User Installs");
  if (installs < 0) installs = header.indexOf("Daily Device Installs");
  if (date < 0 || installs < 0) return [];
  const out: { date: string; count: number }[] = [];
  for (const line of lines.slice(1)) {
    const cells = splitCsvLine(line);
    const day = (cells[date] ?? "").trim();
    if (/^\d{4}-\d{2}-\d{2}$/.test(day)) out.push({ date: day, count: Number(cells[installs]) || 0 });
  }
  return out;
}

/** Fichier de l'espace de stockage, `null` s'il n'existe pas (mois sans rapport). */
async function readObject(bucket: string, path: string): Promise<Buffer | null> {
  const url = `https://storage.googleapis.com/storage/v1/b/${encodeURIComponent(bucket)}/o/${encodeURIComponent(path)}?alt=media`;
  const response = await fetch(url, { headers: { Authorization: `Bearer ${await accessToken(STORAGE_SCOPE)}` } });
  if (response.status === 404) return null;
  if (!response.ok) {
    const text = (await response.text()).slice(0, 300);
    let detail = text;
    try {
      detail = JSON.parse(text)?.error?.message ?? text;
    } catch {
      // Réponse non JSON : on garde le début du texte.
    }
    const hint = response.status === 403 ? " Le compte de service doit avoir accès en lecture à cet espace (Play Console, Utilisateurs et autorisations)." : "";
    throw new HttpsError("failed-precondition", `Google Cloud Storage (${response.status}) : ${detail}${hint}`);
  }
  return Buffer.from(await response.arrayBuffer());
}

/** Installations par jour sur les mois demandés (`AAAA-MM`), jours triés ; un mois sans rapport est ignoré. */
export async function googleDailyInstalls(bucketRaw: string, months: string[]): Promise<{ date: string; count: number }[]> {
  const bucket = normalizeBucket(bucketRaw);
  const reports = await Promise.all(months.map((m) => readObject(bucket, installsReportPath(m))));
  const byDay = new Map<string, number>();
  for (const report of reports) {
    if (report == null) continue;
    for (const { date, count } of parseInstallsCsv(decodeReport(report))) byDay.set(date, count);
  }
  return [...byDay.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([date, count]) => ({ date, count }));
}
