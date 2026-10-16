import * as admin from "firebase-admin";
import { RECAPTCHA } from "../config/recaptcha";
import { logger } from "../runtime/firebase";

/** `ok` : jeton accepté. `invalid` : refusé (400). `unavailable` : Google n'a pas pu trancher (503, échec fermé). */
export type CaptchaVerdict = "ok" | "invalid" | "unavailable";

interface Assessment {
  tokenProperties?: { valid?: unknown; invalidReason?: unknown; hostname?: unknown };
  riskAnalysis?: { score?: unknown };
}

const ASSESSMENTS_URL = `https://recaptchaenterprise.googleapis.com/v1/projects/${RECAPTCHA.projectId}/assessments`;

/**
 * Fait évaluer le jeton par reCAPTCHA Enterprise avec les identifiants du compte de service de la fonction.
 *
 * Accepté si Google le déclare valide, émis pour un de nos domaines (RECAPTCHA.allowedHostnames) et avec un
 * score d'au moins RECAPTCHA.minScore. Échec fermé : toute erreur d'appel (identifiants, réseau, délai, statut
 * HTTP, réponse illisible) donne `unavailable`, jamais `ok`.
 *
 * Journalise uniquement la raison (invalidReason, score, statut HTTP, message d'erreur) : jamais le jeton
 * reCAPTCHA ni le jeton d'accès, ni le corps de la réponse de Google.
 */
export async function verifyRecaptcha(token: unknown): Promise<CaptchaVerdict> {
  if (typeof token !== "string" || token === "") {
    logger.warn("[Captcha] refusé : jeton absent");
    return "invalid";
  }

  if (token.length > RECAPTCHA.maxTokenLength) {
    logger.warn("[Captcha] refusé : jeton démesuré");
    return "invalid";
  }

  let assessment: Assessment | undefined;
  try {
    const credential = admin.app().options.credential;
    if (credential == null) throw new Error("identifiants applicatifs introuvables");
    const { access_token } = await credential.getAccessToken();

    const response = await fetch(ASSESSMENTS_URL, {
      method: "POST",
      headers: { Authorization: `Bearer ${access_token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ event: { token, siteKey: RECAPTCHA.siteKey } }),
      signal: AbortSignal.timeout(RECAPTCHA.timeoutMs),
    });
    if (!response.ok) {
      logger.error(`[Captcha] indisponible : Google répond HTTP ${response.status}`);
      return "unavailable";
    }
    assessment = await response.json().catch(() => undefined);
  } catch (e: any) {
    // Message seulement : une erreur réseau embarque parfois la requête (jeton, en-tête Authorization).
    logger.error(`[Captcha] indisponible : ${e?.message ?? "erreur inconnue"}`);
    return "unavailable";
  }
  if (assessment == null || typeof assessment !== "object") {
    logger.error("[Captcha] indisponible : réponse de Google illisible");
    return "unavailable";
  }

  const { valid, invalidReason, hostname } = assessment.tokenProperties ?? {};
  const score = assessment.riskAnalysis?.score;
  if (valid !== true) {
    logger.warn(`[Captcha] refusé : jeton invalide (${String(invalidReason ?? "raison inconnue")}), score ${String(score)}`);
    return "invalid";
  }
  if (typeof hostname !== "string" || !RECAPTCHA.allowedHostnames.includes(hostname)) {
    logger.warn(`[Captcha] refusé : jeton émis pour un domaine non autorisé, score ${String(score)}`);
    return "invalid";
  }
  if (typeof score !== "number" || score < RECAPTCHA.minScore) {
    logger.warn(`[Captcha] refusé : score ${String(score)} inférieur au minimum ${RECAPTCHA.minScore}`);
    return "invalid";
  }
  return "ok";
}
