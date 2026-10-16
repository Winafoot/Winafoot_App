/**
 * Réindexe les compositions et les matchs terminés dans Algolia (README, section « Recherche »).
 *
 *   read -rs ALGOLIA_REINDEX_KEY && ALGOLIA_REINDEX_KEY="$ALGOLIA_REINDEX_KEY" npm --prefix functions run algolia-reindex -- --dry-run
 *
 *   --dry-run          n'écrit rien chez Algolia (combinable avec les modes ci-dessous)
 *   --settings-only    applique les réglages des 2 index (les crée vides), aucun enregistrement
 *   (aucun mode)       indexation complète des comptes présents dans Firebase Auth
 *   --purge-orphans    purge par réconciliation : supprime tout enregistrement qui ne correspond à aucun document
 *                      indexable d'un compte présent dans Firebase Auth (comptes ET documents supprimés).
 *                      À lancer en période calme, puis relancer l'indexation complète.
 *
 * La clé (`wina-setup`, TEMPORAIRE) se saisit avec `read -rs` puis se passe à UNE seule commande : jamais
 * `export`, jamais dans un fichier. Le script est idempotent : en cas de doute, le relancer après une période calme.
 * La sortie ne contient que des compteurs : jamais un nom, un uid ni la clé.
 *
 * Refuse de démarrer si FIRESTORE_EMULATOR_HOST ou FIREBASE_AUTH_EMULATOR_HOST est défini : le script cible la production.
 *
 * Nécessite des identifiants applicatifs par défaut :
 *   gcloud auth application-default login
 */
import * as admin from "firebase-admin";
import { ALGOLIA_APP_ID } from "../src/config/algolia";
import { assertNotEmulated, formatError, parseArgs, runReindex } from "../src/search/reindex";
import { createReindexClient } from "../src/search/reindex_client";

async function main(): Promise<void> {
  assertNotEmulated(process.env);
  const { mode, dryRun } = parseArgs(process.argv.slice(2));
  const apiKey = process.env.ALGOLIA_REINDEX_KEY;
  if (apiKey == null || apiKey.trim().length === 0) {
    throw new Error("ALGOLIA_REINDEX_KEY absente : la saisir avec `read -rs` (voir l'en-tête du script).");
  }

  admin.initializeApp({ projectId: "wina-c4c4a" });
  await runReindex(mode, dryRun, {
    db: admin.firestore(),
    auth: admin.auth(),
    client: createReindexClient(ALGOLIA_APP_ID, apiKey),
    log: (line) => console.log(line),
  });
}

main().catch((error) => {
  // Jamais l'objet d'erreur : celui du SDK Algolia embarque la clé en clair.
  console.error(`Échec : ${formatError(error)}`);
  process.exit(1);
});
