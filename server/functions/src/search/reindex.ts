import { type firestore } from "firebase-admin";
import { type Auth } from "firebase-admin/auth";
import { ALGOLIA_INDICES } from "../config/algolia";
import { AlgoliaFailure } from "./algolia_client";
import { objectId, ownerKey } from "./ids";
import { type SearchFields, type SearchRecord, toRecord } from "./records";
import { INDEX_SETTINGS, type IndexSettings } from "./settings";
import { SYNC_TARGETS } from "./sync";

/** Logique de scripts/algolia-reindex.ts, injectable (Firestore, Auth, client Algolia) pour être testée sous émulateurs. */

/** Client Algolia du script : chaque appel lève une AlgoliaFailure (voir reindex_client.ts). */
export interface ReindexClient {
  setSettings(indexName: string, settings: IndexSettings): Promise<void>;
  saveRecords(indexName: string, records: SearchRecord[]): Promise<void>;
  browseObjectIds(indexName: string): Promise<string[]>;
  deleteRecords(indexName: string, objectIDs: string[]): Promise<void>;
}

export type ReindexMode =
  | { kind: "index" }
  | { kind: "settings-only" }
  | { kind: "purge-orphans" };

export interface ReindexDeps {
  db: firestore.Firestore;
  auth: Auth;
  client: ReindexClient;
  log: (line: string) => void;
}

type PerIndex = Record<string, number>;

/** Compteurs par index : jamais un nom, un uid ou un contenu. */
export interface ReindexReport {
  indexed: PerIndex;
  notIndexable: PerIndex;
  noAccount: PerIndex;
  deleted: PerIndex;
  /** Hachés (ownerKey) : pour un nettoyage manuel, sans exposer un uid. */
  ignoredOwnerKeys: string[];
}

const USAGE = "Usage : algolia-reindex [--dry-run] [--settings-only | --purge-orphans]";
const AUTH_BATCH = 100;
const INDEX_NAMES: string[] = Object.values(ALGOLIA_INDICES);
const COLLECTIONS = Object.keys(SYNC_TARGETS) as (keyof typeof SYNC_TARGETS)[];
// `.select()` : un match peut peser 1 Mio, on ne lit que les champs projetés.
const SELECTED_FIELDS: Record<keyof typeof SYNC_TARGETS, string[]> = {
  compositions: ["name", "formationLabel"],
  matches: ["status", "finishedAt", "opponent.name"],
};

const zeroes = (): PerIndex => Object.fromEntries(INDEX_NAMES.map((name) => [name, 0]));

export function parseArgs(argv: string[]): { mode: ReindexMode; dryRun: boolean } {
  let dryRun = false;
  const modes: ReindexMode[] = [];
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--dry-run") dryRun = true;
    else if (arg === "--settings-only") modes.push({ kind: "settings-only" });
    else if (arg === "--purge-orphans") modes.push({ kind: "purge-orphans" });
    else throw new Error(USAGE);
  }
  if (modes.length > 1) throw new Error(USAGE);
  return { mode: modes[0] ?? { kind: "index" }, dryRun };
}

/** Message sûr à afficher : jamais l'objet d'erreur (le SDK y embarque la requête brute, clé comprise). */
export function formatError(error: unknown): string {
  if (error instanceof AlgoliaFailure) return `Algolia ${error.status ?? "(réseau)"} : ${error.message}`;
  return error instanceof Error ? error.message : "erreur inconnue";
}

/** Le script écrit en production : il refuse de démarrer si un émulateur Firebase est désigné par l'environnement. */
export function assertNotEmulated(env: NodeJS.ProcessEnv): void {
  const set = ["FIRESTORE_EMULATOR_HOST", "FIREBASE_AUTH_EMULATOR_HOST"].filter((name) => (env[name] ?? "") !== "");
  if (set.length > 0) throw new Error(`Variable(s) d'émulateur définie(s) (${set.join(", ")}) : le script cible la production, démarrage refusé.`);
}

export async function runReindex(mode: ReindexMode, dryRun: boolean, deps: ReindexDeps): Promise<ReindexReport> {
  const report: ReindexReport = { indexed: zeroes(), notIndexable: zeroes(), noAccount: zeroes(), deleted: zeroes(), ignoredOwnerKeys: [] };
  if (dryRun) deps.log("--dry-run : aucune écriture chez Algolia.");

  if (mode.kind === "settings-only") await applySettings(dryRun, deps);
  else if (mode.kind === "index") await indexAll(dryRun, deps, report);
  else await purgeOrphans(dryRun, deps, report);
  return report;
}

async function applySettings(dryRun: boolean, { client, log }: ReindexDeps): Promise<void> {
  for (const indexName of INDEX_NAMES) {
    if (!dryRun) await client.setSettings(indexName, INDEX_SETTINGS[indexName]);
    log(`${indexName} : réglages ${dryRun ? "à appliquer" : "appliqués"}.`);
  }
}

interface Candidate {
  uid: string;
  docId: string;
  fields: SearchFields;
}

/** `users/{uid}/<collection>/{id}` seulement : l'uid est le parent du parent. */
function userIdOf(ref: firestore.DocumentReference): string | null {
  const segments = ref.path.split("/");
  return segments.length === 4 && segments[0] === "users" ? segments[1] : null;
}

async function readCandidates(db: firestore.Firestore, collection: keyof typeof SYNC_TARGETS): Promise<{ candidates: Candidate[]; notIndexable: number }> {
  const candidates: Candidate[] = [];
  let notIndexable = 0;
  const query = db.collectionGroup(collection).select(...SELECTED_FIELDS[collection]);
  for await (const snapshot of query.stream() as AsyncIterable<firestore.QueryDocumentSnapshot>) {
    const uid = userIdOf(snapshot.ref);
    if (uid == null) continue;
    const fields = SYNC_TARGETS[collection].project(snapshot);
    if (fields == null) notIndexable += 1;
    else candidates.push({ uid, docId: snapshot.id, fields });
  }
  return { candidates, notIndexable };
}

/** Uid présents dans Firebase Auth, par lots de 100. */
async function existingUids(auth: Auth, uids: string[]): Promise<Set<string>> {
  const found = new Set<string>();
  for (let i = 0; i < uids.length; i += AUTH_BATCH) {
    const { users } = await auth.getUsers(uids.slice(i, i + AUTH_BATCH).map((uid) => ({ uid })));
    users.forEach((user) => found.add(user.uid));
  }
  return found;
}

/** Collecte commune à l'indexation et à la purge : documents de chaque collection + uid présents dans Firebase Auth. */
async function collect({ db, auth }: ReindexDeps) {
  const read = await Promise.all(COLLECTIONS.map((collection) => readCandidates(db, collection)));
  const uids = [...new Set(read.flatMap((r) => r.candidates.map((c) => c.uid)))];
  return { read, existing: await existingUids(auth, uids) };
}

async function indexAll(dryRun: boolean, deps: ReindexDeps, report: ReindexReport): Promise<void> {
  const { client, log } = deps;
  const { read, existing } = await collect(deps);
  const ignored = new Set<string>();

  for (const [i, collection] of COLLECTIONS.entries()) {
    const { indexName } = SYNC_TARGETS[collection];
    const kept = read[i].candidates.filter((c) => existing.has(c.uid));
    read[i].candidates.filter((c) => !existing.has(c.uid)).forEach((c) => ignored.add(ownerKey(c.uid)));
    if (!dryRun && kept.length > 0) await client.saveRecords(indexName, kept.map((c) => toRecord(c.uid, c.docId, c.fields)));

    report.indexed[indexName] = kept.length;
    report.noAccount[indexName] = read[i].candidates.length - kept.length;
    report.notIndexable[indexName] = read[i].notIndexable;
    log(
      `${indexName} : ${kept.length} ${dryRun ? "à indexer" : "indexé(s)"}, ${report.noAccount[indexName]} sans compte Auth (ignoré(s)), ` +
        `${read[i].notIndexable} non indexable(s).`,
    );
  }
  report.ignoredOwnerKeys.push(...[...ignored].sort());
  if (ignored.size > 0) log(`Comptes sans Auth ignorés (hachés, à nettoyer à la main) : ${report.ignoredOwnerKeys.join(", ")}`);
}

/**
 * Purge par réconciliation : supprime de chaque index tout objectID qui ne correspond à aucun document
 * indexable d'un compte présent dans Firebase Auth (comptes supprimés ET documents supprimés ou devenus
 * non indexables chez un compte vivant). À lancer en période calme, puis relancer l'indexation complète.
 */
async function purgeOrphans(dryRun: boolean, deps: ReindexDeps, report: ReindexReport): Promise<void> {
  const { auth, client, log } = deps;
  // Le browse passe AVANT la collecte : un enregistrement lu correspond à un document déjà créé, donc présent
  // dans la collecte qui suit (un document créé entre les deux n'est pas pris pour un orphelin).
  const browsed = await Promise.all(INDEX_NAMES.map(async (indexName) => ({ indexName, ids: await client.browseObjectIds(indexName) })));
  // Garde-fou : un Auth vide (mauvais projet, droits) ferait passer tous les enregistrements pour des orphelins.
  if ((await auth.listUsers(1)).users.length === 0) throw new Error("Firebase Auth ne liste aucun compte : purge des orphelins refusée.");
  const { read, existing } = await collect(deps);

  for (const [i, collection] of COLLECTIONS.entries()) {
    const { indexName } = SYNC_TARGETS[collection];
    const expected = new Set(read[i].candidates.filter((c) => existing.has(c.uid)).map((c) => objectId(c.uid, c.docId)));
    const objectIDs = browsed.find((b) => b.indexName === indexName)!.ids.filter((id) => !expected.has(id));
    if (!dryRun && objectIDs.length > 0) await client.deleteRecords(indexName, objectIDs);
    report.deleted[indexName] = objectIDs.length;
    log(`${indexName} : ${objectIDs.length} enregistrement(s) ${dryRun ? "à supprimer" : "supprimé(s)"}.`);
  }
}
