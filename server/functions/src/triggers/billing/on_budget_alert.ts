import * as admin from "firebase-admin";
import type { CloudEvent } from "firebase-functions/v2";
import type { MessagePublishedData } from "firebase-functions/v2/pubsub";
import { logger } from "../../runtime/firebase";
import { describeError } from "../../utils/describe_error";

/**
 * Notification de budget Cloud Billing (données du message Pub/Sub). Les deux seuils ne sont
 * présents que lorsqu'un seuil configuré est dépassé.
 */
export interface BudgetNotification {
  budgetDisplayName: string;
  costAmount: number;
  costIntervalStart: string;
  budgetAmount: number;
  budgetAmountType: string;
  currencyCode: string;
  alertThresholdExceeded?: number;
  forecastThresholdExceeded?: number;
}

const REQUIRED_STRINGS = ["budgetDisplayName", "costIntervalStart", "budgetAmountType", "currencyCode"] as const;
const REQUIRED_AMOUNTS = ["costAmount", "budgetAmount"] as const;
const OPTIONAL_THRESHOLDS = ["alertThresholdExceeded", "forecastThresholdExceeded"] as const;
/** Attributs posés par Cloud Billing sur chaque notification de budget. */
const REQUIRED_ATTRIBUTES = ["billingAccountId", "budgetId"] as const;

type BudgetParse = { notification: BudgetNotification } | { problems: string[] };

/**
 * Contrôle la forme d'un message reçu sur le topic : données JSON avec les champs d'une notification
 * de budget (montants numériques finis, chaînes attendues) et attributs de Cloud Billing. Renvoie la
 * notification, ou la liste des champs en cause (noms seulement).
 */
export function parseBudgetMessage(message: { json?: unknown; attributes?: Record<string, string> } | undefined): BudgetParse {
  let data: unknown;
  try {
    data = message?.json;
  } catch {
    return { problems: ["données (JSON illisible)"] };
  }
  if (data == null || typeof data !== "object" || Array.isArray(data)) {
    return { problems: ["données (objet JSON attendu)"] };
  }

  const fields = data as Record<string, unknown>;
  const problems: string[] = [];
  for (const name of REQUIRED_STRINGS) {
    if (typeof fields[name] !== "string") problems.push(name);
  }
  for (const name of REQUIRED_AMOUNTS) {
    if (typeof fields[name] !== "number" || !Number.isFinite(fields[name])) problems.push(name);
  }
  for (const name of OPTIONAL_THRESHOLDS) {
    if (fields[name] !== undefined && (typeof fields[name] !== "number" || !Number.isFinite(fields[name]))) problems.push(name);
  }
  for (const name of REQUIRED_ATTRIBUTES) {
    const value = message?.attributes?.[name];
    if (typeof value !== "string" || value.length === 0) problems.push(`attribut ${name}`);
  }

  return problems.length > 0 ? { problems } : { notification: fields as unknown as BudgetNotification };
}

/** Accès extérieurs du coupe-circuit, remplaçables en test. */
export interface BudgetGuardDeps {
  projectId: () => string | undefined;
  accessToken: () => Promise<string | undefined>;
  fetch: typeof fetch;
}

const DEFAULT_DEPS: BudgetGuardDeps = {
  projectId: () => process.env.GCLOUD_PROJECT,
  accessToken: async () => (await admin.app().options.credential?.getAccessToken())?.access_token,
  fetch: (input, init) => fetch(input, init),
};

/**
 * Coupe la facturation du projet (retour au plan Spark) quand la dépense dépasse le montant du
 * budget Cloud Billing lié au topic Pub/Sub `budget-alerts`.
 *
 * Un message qui n'a pas la forme d'une notification de budget est ignoré et journalisé (champs en
 * cause seulement). Sinon : si la dépense dépasse le budget, l'app passe en maintenance
 * (`app_config/metadata.maintenance`), puis le compte de facturation est détaché du projet.
 *
 * Détacher le compte de facturation arrête immédiatement tous les services payants (Cloud Functions,
 * Storage hors US, etc.) : c'est le rôle d'un coupe-circuit. Le compte d'exécution de cette fonction
 * (BUDGET_GUARD_SERVICE_ACCOUNT, config/service_accounts.ts) porte le rôle « Project Billing Manager »
 * (roles/billing.projectManager) sur le projet ; aucune autre fonction ne l'a.
 */
export async function onBudgetAlertHandler(event: CloudEvent<MessagePublishedData>, deps: BudgetGuardDeps = DEFAULT_DEPS): Promise<void> {
  const parsed = parseBudgetMessage(event.data?.message);
  if ("problems" in parsed) {
    logger.error(`[onBudgetAlert] message ignoré : ce n'est pas une notification de budget (${parsed.problems.join(", ")})`);
    return;
  }

  const data = parsed.notification;
  logger.info(`[onBudgetAlert] budget "${data.budgetDisplayName}" : coût ${data.costAmount} / plafond ${data.budgetAmount} ${data.currencyCode}`);
  if (data.costAmount <= data.budgetAmount) {
    return;
  }

  // 1. Bascule l'app en maintenance (Firestore reste lisible en plan Spark,
  // les apps affichent « Application en maintenance »)
  try {
    await admin.firestore().doc("app_config/metadata").set({ maintenance: true }, { merge: true });
    logger.warn("[onBudgetAlert] app_config/metadata.maintenance = true");
  } catch (e) {
    logger.error(`[onBudgetAlert] échec de l'écriture du drapeau maintenance : ${describeError(e)}`);
  }

  // 2. Détache la facturation → retour au plan Spark
  const projectId = deps.projectId();
  const token = await deps.accessToken();
  const res = await deps.fetch(`https://cloudbilling.googleapis.com/v1/projects/${projectId}/billingInfo`, {
    method: "PUT",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ billingAccountName: "" }),
  });
  if (!res.ok) {
    logger.error(`[onBudgetAlert] échec du détachement de la facturation : ${res.status} ${await res.text()}`);
    return;
  }
  logger.warn(
    `[onBudgetAlert] facturation détachée : projet ${projectId} repassé en plan Spark (dépense ${data.costAmount} > ${data.budgetAmount} ${data.currencyCode}).`
  );
}
