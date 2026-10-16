// Messages en français pour les erreurs Firebase Auth de la connexion et du second facteur.
// Volontairement sobres : l'identifiant technique n'est repris que pour les cas non prévus.
// Un identifiant inconnu et un mauvais mot de passe donnent le même message.
const MESSAGES: Record<string, string> = {
  "auth/invalid-credential": "Adresse e-mail ou mot de passe incorrect.",
  "auth/invalid-login-credentials": "Adresse e-mail ou mot de passe incorrect.",
  "auth/wrong-password": "Adresse e-mail ou mot de passe incorrect.",
  "auth/user-not-found": "Adresse e-mail ou mot de passe incorrect.",
  "auth/invalid-email": "Adresse e-mail invalide.",
  "auth/missing-email": "Saisissez votre adresse e-mail.",
  "auth/missing-password": "Saisissez votre mot de passe.",
  "auth/user-disabled": "Ce compte est désactivé. Contactez un administrateur.",
  "auth/invalid-verification-code":
    "Code incorrect ou expiré. Saisissez le code actuellement affiché dans votre application d'authentification.",
  "auth/code-expired": "Le délai est dépassé. Recommencez la procédure depuis le début.",
  "auth/invalid-verification-id": "Le délai est dépassé. Recommencez la procédure depuis le début.",
  "auth/missing-verification-id": "Le délai est dépassé. Recommencez la procédure depuis le début.",
  "auth/invalid-multi-factor-session": "La session de connexion a expiré. Recommencez la connexion.",
  "auth/network-request-failed": "Connexion impossible. Vérifiez votre réseau puis réessayez.",
  "auth/too-many-requests": "Trop de tentatives. Patientez quelques minutes puis réessayez.",
  "auth/requires-recent-login":
    "Par sécurité, cette opération exige une connexion récente. Déconnectez-vous, reconnectez-vous puis réessayez.",
  "auth/unverified-email":
    "L'adresse e-mail de ce compte n'est pas vérifiée : Firebase refuse d'activer un second facteur tant qu'elle ne l'est pas. Contactez l'équipe technique.",
  "auth/second-factor-already-in-use":
    "Un second facteur est déjà inscrit sur ce compte. Rechargez la page pour vérifier son état.",
};

export function getAuthErrorCode(error: unknown): string | undefined {
  const code = (error as { code?: unknown } | null)?.code;
  return typeof code === "string" ? code : undefined;
}

export function getAuthErrorMessage(error: unknown): string {
  const code = getAuthErrorCode(error);
  if (code && MESSAGES[code]) {
    return MESSAGES[code];
  }
  return `Une erreur est survenue${code ? ` (${code})` : ""}. Réessayez ; si elle persiste, contactez l'équipe technique.`;
}
