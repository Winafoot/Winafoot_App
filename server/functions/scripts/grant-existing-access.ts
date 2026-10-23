/**
 * Accorde l'accès aux comptes existants AVANT l'activation du mur de paiement.
 *
 *   npm --prefix functions run grant-existing-access -- --dry-run
 *   npm --prefix functions run grant-existing-access
 *
 * Pose `access: { active: true, until: 2099-12-31 }` et `manualGrant: true` sur chaque fiche
 * `users/{uid}` qui n'a pas encore de champ `access` et qui n'est pas un compte lié. Sans lui, tous
 * les comptes actuels seraient bloqués dès que `app_config/config.paywall_enforced` passe à true.
 *
 * Idempotent : une fiche qui a déjà `access` n'est pas touchée. Les comptes accordés à la main se
 * retrouvent par `manualGrant == true` (pour les retirer, ou les convertir en abonnés).
 *
 * Nécessite des identifiants applicatifs par défaut :
 *   gcloud auth application-default login
 */
import * as admin from "firebase-admin";

const FAR_FUTURE = admin.firestore.Timestamp.fromDate(new Date("2099-12-31T00:00:00Z"));

async function main(): Promise<void> {
  const dryRun = process.argv.slice(2).includes("--dry-run");

  admin.initializeApp({ projectId: "wina-c4c4a" });
  const db = admin.firestore();

  const users = await db.collection("users").get();
  let granted = 0;
  let skipped = 0;

  for (const user of users.docs) {
    if (user.get("access") != null || user.get("ownerUid") != null) {
      skipped++;
      continue;
    }
    console.log(`${dryRun ? "[dry-run] " : ""}accès accordé : ${user.id}`);
    if (!dryRun) {
      await user.ref.update({ access: { active: true, until: FAR_FUTURE }, manualGrant: true });
    }
    granted++;
  }

  console.log(
    `${granted} compte(s) ${dryRun ? "à accorder" : "accordé(s)"}, ${skipped} ignoré(s).`
  );
  if (dryRun) console.log("Aucune écriture (--dry-run).");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
