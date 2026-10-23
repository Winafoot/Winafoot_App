/**
 * Simule un achat pour un compte de test, sans passer par les stores ni RevenueCat.
 *
 *   npm --prefix functions run grant-test-subscription -- --email yoan@coach.test --teams 2 --dry-run
 *   npm --prefix functions run grant-test-subscription -- --email yoan@coach.test --teams 2
 *   npm --prefix functions run grant-test-subscription -- --email yoan@coach.test --remove
 *
 * Pose sur `users/{uid}` les mêmes champs que le webhook RevenueCat (billing/store.ts) :
 * `subscription` (formule à 1, 2 ou 3 équipes, valable 30 jours) et `access`. À l'ouverture de l'app,
 * l'écran « Créer votre équipe » s'ouvre pour les équipes encore à créer ; la création passe ensuite par
 * le vrai callable `createLinkedTeam`, qui crée un vrai compte Auth.
 *
 * `testGrant: true` marque la fiche. `--remove` retire `subscription`, `access` et `testGrant`, sans toucher
 * aux comptes liés déjà créés.
 *
 * Écrit dans le projet réel : à réserver à un compte de test. Nécessite des identifiants applicatifs :
 *   gcloud auth application-default login
 */
import * as admin from "firebase-admin";

const DAY_MS = 24 * 60 * 60 * 1000;
const VALIDITY_DAYS = 30;

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(`--${name}`);
  return i === -1 ? undefined : process.argv[i + 1];
}

async function main(): Promise<void> {
  const email = arg("email")?.trim().toLowerCase();
  const remove = process.argv.includes("--remove");
  const dryRun = process.argv.includes("--dry-run");
  const teams = Number(arg("teams") ?? 2);

  if (!email) throw new Error("--email obligatoire");
  if (!remove && ![1, 2, 3].includes(teams)) throw new Error("--teams doit valoir 1, 2 ou 3");

  admin.initializeApp({ projectId: "wina-c4c4a" });
  const { uid } = await admin.auth().getUserByEmail(email);
  const ref = admin.firestore().collection("users").doc(uid);
  const snap = await ref.get();
  if (!snap.exists) throw new Error(`users/${uid} introuvable`);
  if (snap.get("ownerUid") != null) throw new Error("Compte d'équipe lié : choisissez le compte propriétaire.");

  const { Timestamp, FieldValue } = admin.firestore;

  if (remove) {
    console.log(`${dryRun ? "[dry-run] " : ""}retrait de l'abonnement de test : ${email} (${uid})`);
    if (!dryRun) {
      await ref.update({ subscription: FieldValue.delete(), access: FieldValue.delete(), testGrant: FieldValue.delete() });
    }
    return;
  }

  const now = Date.now();
  const expiresAtMs = now + VALIDITY_DAYS * DAY_MS;
  console.log(`${dryRun ? "[dry-run] " : ""}abonnement de test ${teams} équipe(s), ${VALIDITY_DAYS} jours : ${email} (${uid})`);
  if (!dryRun) {
    await ref.update({
      subscription: {
        productId: `wina_team${teams}:monthly`,
        period: "monthly",
        teamsAllowed: teams,
        status: "active",
        trialEnd: null,
        expiresAt: Timestamp.fromMillis(expiresAtMs),
        store: "play_store",
        lastEventMs: now,
        updatedAt: Timestamp.now(),
      },
      access: { active: true, until: Timestamp.fromMillis(expiresAtMs) },
      testGrant: true,
    });
  }
  if (dryRun) console.log("Aucune écriture (--dry-run).");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
