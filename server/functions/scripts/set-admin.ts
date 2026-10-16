/**
 * Attribue (ou retire) le custom claim `admin` à un compte Firebase Auth. L'accès au back-office
 * exige en plus une adresse e-mail vérifiée.
 *
 *   npm --prefix functions run set-admin -- staff@example.com
 *   npm --prefix functions run set-admin -- staff@example.com --revoke
 *
 * Nécessite des identifiants applicatifs par défaut :
 *   gcloud auth application-default login
 */
import * as admin from "firebase-admin";

async function main(): Promise<void> {
  const [email, flag] = process.argv.slice(2);
  const revoke = flag === "--revoke";

  if (email == null || email.trim().length === 0) {
    console.error("Usage: set-admin <email> [--revoke]");
    process.exit(1);
  }

  admin.initializeApp({ projectId: "wina-c4c4a" });

  const user = await admin.auth().getUserByEmail(email.trim().toLowerCase());
  const claims = { ...(user.customClaims ?? {}) };

  if (revoke) {
    const hadAdminClaim = claims.admin === true;
    delete claims.admin;
    await admin.auth().setCustomUserClaims(user.uid, claims);
    // Force le rafraîchissement du jeton côté navigateur à la prochaine connexion.
    await admin.auth().revokeRefreshTokens(user.uid);

    if (hadAdminClaim) {
      console.log(`Retiré : admin sur ${user.email} (${user.uid})`);
    } else {
      console.log(`Pas de claim admin à retirer pour ${user.email} (${user.uid})`);
    }
  } else {
    claims.admin = true;
    await admin.auth().setCustomUserClaims(user.uid, claims);
    // Force le rafraîchissement du jeton côté navigateur à la prochaine connexion.
    await admin.auth().revokeRefreshTokens(user.uid);

    console.log(`Attribué : admin sur ${user.email} (${user.uid})`);
    if (!user.emailVerified) {
      // Les règles Firestore et les callables d'administration exigent aussi une adresse vérifiée.
      console.warn("Adresse non vérifiée : l'accès au back-office reste fermé tant qu'elle ne l'est pas (lien d'invitation ou de réinitialisation du mot de passe, vue « Administrateurs »).");
    }
  }
}

main().catch((e) => {
  let message = "Erreur inattendue";

  if (e instanceof Error) {
    const firebaseError = e as any;
    if (firebaseError.code) {
      const codeMessages: Record<string, string> = {
        "auth/user-not-found": "Utilisateur non trouvé",
        "auth/invalid-email": "Email invalide",
      };
      message = codeMessages[firebaseError.code] || e.message;
    } else {
      message = e.message;
    }
  }

  console.error(message);
  process.exit(1);
});
