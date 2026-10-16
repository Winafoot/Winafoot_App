/**
 * reCAPTCHA Enterprise vérifié côté serveur sur les deux endpoints HTTP de la landing qui envoient
 * des mails : `onSendLandingPageMail` et `onSendLandingPageMailDeleteAccount`. Le navigateur envoie le
 * jeton dans le champ `recaptchaToken` du corps JSON. Voir le README, section « Landing ».
 */
export const RECAPTCHA = {
  projectId: "wina-c4c4a",
  /** Clé de site de type case à cocher, autorisée sur les deux domaines Firebase Hosting ci-dessous. */
  siteKey: "6LfKUe0tAAAAAHxnM9AC-zdPhUlHxr8DlkY3Q7PY",
  /**
   * Domaines pour lesquels Google doit avoir émis le jeton (`tokenProperties.hostname`). Un jeton valide
   * pour le site d'un tiers est refusé. À compléter si la landing passe sur un domaine personnalisé
   * (qu'il faut aussi autoriser dans la clé, côté console reCAPTCHA).
   */
  allowedHostnames: ["wina-c4c4a.web.app", "wina-c4c4a.firebaseapp.com"] as ReadonlyArray<string>,
  /**
   * Score minimal (0 = robot probable, 1 = humain probable). Un jeton en dessous est refusé. À relever si
   * des robots passent, à baisser si des humains sont refusés : les refus sont journalisés avec leur score.
   */
  minScore: 0.3,
  /** Au-delà, Google est considéré injoignable (503, rien n'est envoyé). */
  timeoutMs: 5_000,
  /**
   * Longueur maximale d'un jeton transmis à Google. Un vrai jeton fait quelques ko ; au-delà, l'appel
   * (une évaluation facturable) est inutile : refus direct. Large pour ne jamais écarter un vrai jeton.
   */
  maxTokenLength: 16_384,
};
