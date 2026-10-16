/**
 * Socle commun des trois endpoints HTTP de la landing (support, demande de suppression de compte,
 * confirmation de suppression). Ils doivent rester déployés : la page de suppression de compte et
 * le formulaire de support sont exigés pour la soumission aux stores.
 *
 * - POST seulement (et le préflight OPTIONS), CORS limité aux origines de la landing ;
 * - limite de débit par IP ;
 * - travail fait AVANT de répondre (Cloud Run peut brider le CPU après la réponse) ;
 * - corps de requête validé et échappé avant d'entrer dans un mail ou un lien.
 */
import { app, auth } from "firebase-admin";
import type { UserRecord } from "firebase-admin/auth";
import type { Response } from "express";
import { AppConfigRepository } from "../../database/app_config/app_config_repository";
import type { AppMetadataConfig } from "../../model/config/app_metadata_config";
import { logger, type Request } from "../../runtime/firebase";
import { clientIp } from "../../utils/client_ip";
import { consume, type Limit } from "../../utils/rate_limit";
import { verifyRecaptcha } from "../../utils/recaptcha";
import { describeError } from "../../utils/describe_error";

export const EMAIL_MAX_LENGTH = 254;
// Interdit aussi les guillemets et chevrons : l'adresse finit dans du HTML.
const EMAIL_PATTERN = /^[^\s@"<>]+@[^\s@"<>]+\.[^\s@"<>]+$/;

export interface LandingOptions {
  /** Préfixe des compteurs de limitation de débit ; distinct par endpoint. */
  scope: string;
  perIp: Limit;
}

export type LandingHandler = (body: Record<string, unknown>, config: AppMetadataConfig, res: Response) => Promise<void>;

/** Adresse en minuscules et sans espaces si elle est plausible, sinon `undefined`. */
export function normalizeEmail(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const email = value.trim().toLowerCase();
  return email.length <= EMAIL_MAX_LENGTH && EMAIL_PATTERN.test(email) ? email : undefined;
}

export function escapeHtml(value: string): string {
  return value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;");
}

function projectHosting(): string {
  const projectId = process.env.GCLOUD_PROJECT ?? app().options.projectId;
  return `https://${projectId}.web.app`;
}

/**
 * URL de la landing, sans slash final. `app_config/metadata.landingUrl` si c'est
 * une URL https (domaine personnalisé), sinon l'hébergement par défaut du projet.
 * Jamais une valeur venue de la requête : elle finit dans le lien du mail.
 */
export function landingBaseUrl(config: AppMetadataConfig): string {
  const configured = (config as unknown as Record<string, unknown>)["landingUrl"];
  if (typeof configured === "string") {
    try {
      const url = new URL(configured);
      if (url.protocol === "https:") return url.origin + url.pathname.replace(/\/+$/, "");
    } catch {
      // URL invalide : repli sur l'hébergement du projet.
    }
  }
  return projectHosting();
}

function allowedOrigins(config: AppMetadataConfig): Set<string> {
  const projectId = process.env.GCLOUD_PROJECT ?? app().options.projectId;
  return new Set([new URL(landingBaseUrl(config)).origin, projectHosting(), `https://${projectId}.firebaseapp.com`]);
}

function applyCors(req: Request, res: Response, config: AppMetadataConfig): void {
  const origin = req.get("origin");
  if (origin && allowedOrigins(config).has(origin)) {
    res.set("Access-Control-Allow-Origin", origin);
    res.set("Vary", "Origin");
  }
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
}

/** Compte Auth de cette adresse, ou `undefined` s'il n'y en a pas. */
export async function authUserByEmail(email: string): Promise<UserRecord | undefined> {
  try {
    return await auth().getUserByEmail(email);
  } catch (e: any) {
    if (e?.code === "auth/user-not-found") return undefined;
    throw e;
  }
}

/**
 * Vérifie le jeton reCAPTCHA du corps (`recaptchaToken`). Si Google ne l'accepte pas, répond 400 `captcha` ;
 * s'il ne peut pas trancher, 503 `captcha-unavailable` (échec fermé) ; dans les deux cas renvoie `false` et le
 * handler s'arrête là. À appeler après la validation du corps et AVANT toute lecture de compte, tout compteur
 * global et tout envoi : un jeton refusé ne doit rien coûter.
 */
export async function requireCaptcha(body: Record<string, unknown>, res: Response): Promise<boolean> {
  const verdict = await verifyRecaptcha(body.recaptchaToken);
  if (verdict === "invalid") res.status(400).send({ error: "captcha" });
  if (verdict === "unavailable") res.status(503).send({ error: "captcha-unavailable" });
  return verdict === "ok";
}

/** POST uniquement, CORS limité à la landing, limite par IP, travail fait AVANT de répondre. */
export function landingEndpoint(handler: LandingHandler, options: LandingOptions) {
  return async (req: Request, res: Response): Promise<void> => {
    let config: AppMetadataConfig | undefined;
    try {
      config = await AppConfigRepository.instance.getMetadata();
    } catch (e) {
      logger.error(`[Error] landing: app_config/metadata illisible : ${describeError(e)}`);
    }
    if (config == null) {
      res.status(500).send({ message: "Service unavailable" });
      return;
    }

    applyCors(req, res, config);

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "POST") {
      res.set("Allow", "POST, OPTIONS");
      res.status(405).send({ message: "Method not allowed" });
      return;
    }

    // Le préflight n'est pas compté ; tout POST l'est, valide ou non.
    if (!(await consume(`${options.scope}-ip`, clientIp(req), options.perIp))) {
      res.status(429).send({ message: "Too many requests" });
      return;
    }

    try {
      const body = req.body != null && typeof req.body === "object" ? (req.body as Record<string, unknown>) : {};
      await handler(body, config, res);
    } catch (e: any) {
      // Message seulement : une erreur réseau embarque parfois la requête (jeton, adresse).
      logger.error(`[Error] landing: ${e?.message ?? "erreur inconnue"}`);
      if (!res.headersSent) res.status(500).send({ message: "Service unavailable" });
    }
  };
}
