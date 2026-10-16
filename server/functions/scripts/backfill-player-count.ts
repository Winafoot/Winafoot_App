/**
 * Initialise `users/{uid}.playerCount` sur les comptes existants.
 *
 *   npm --prefix functions run backfill-player-count -- --dry-run
 *   npm --prefix functions run backfill-player-count
 *
 * Le compteur est affiché par le back-office ; createPlayer et deletePlayer le
 * tiennent à jour. Le plafond d'effectif ne dépend pas de lui : createPlayer
 * compte les joueurs réels dans sa transaction. Ce script recale le compteur
 * des comptes créés avant lui.
 *
 * Le script est idempotent : il recompte l'effectif réel et n'écrit que si la
 * valeur diffère. Il peut donc être relancé sans risque.
 *
 * Nécessite des identifiants applicatifs par défaut :
 *   gcloud auth application-default login
 */
import * as admin from "firebase-admin";

async function main(): Promise<void> {
  const dryRun = process.argv.slice(2).includes("--dry-run");

  admin.initializeApp({ projectId: "wina-c4c4a" });
  const db = admin.firestore();

  const users = await db.collection("users").get();
  let written = 0;
  let alreadyCorrect = 0;

  for (const user of users.docs) {
    const real = (await user.ref.collection("players").count().get()).data().count;
    const stored = user.get("playerCount");

    if (stored === real) {
      alreadyCorrect += 1;
      continue;
    }

    console.log(
      `${user.id} : playerCount ${stored ?? "(absent)"} -> ${real}` + (dryRun ? " [dry-run]" : "")
    );
    if (!dryRun) {
      await user.ref.set({ playerCount: real }, { merge: true });
    }
    written += 1;
  }

  console.log(
    `\n${users.size} compte(s) examiné(s) : ${written} à corriger, ${alreadyCorrect} déjà à jour.`
  );
  if (dryRun) console.log("Aucune écriture (--dry-run).");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
