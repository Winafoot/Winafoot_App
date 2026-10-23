import * as admin from "firebase-admin";
import { beforeEach } from "vitest";

process.env.GCLOUD_PROJECT = "demo-wina";
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST ?? "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST ?? "127.0.0.1:9099";
// utils/send_email.ts reads this through EnvProvider; tests mock the send itself.
process.env.MAILER_API_KEY = process.env.MAILER_API_KEY ?? "test-mailer-key";
// https_requests/billing/revenuecat_webhook.ts : le webhook lit ce secret par readSecret.
process.env.REVENUECAT_WEBHOOK_SECRET = process.env.REVENUECAT_WEBHOOK_SECRET ?? "test-webhook-secret";

if (admin.apps.length === 0) {
  admin.initializeApp({ projectId: "demo-wina" });
  // Même réglage que src/index.ts : les handlers du socle écrivent des champs
  // optionnels non définis (ex. sender.userProfileImage), que Firestore refuse sinon.
  admin.firestore().settings({ ignoreUndefinedProperties: true });
}

async function reset(host: string | undefined, path: string): Promise<void> {
  const response = await fetch(`http://${host}${path}`, { method: "DELETE" });
  if (!response.ok) {
    throw new Error(`Emulator reset failed for ${path}: ${response.status}`);
  }
}

beforeEach(async () => {
  await reset(process.env.FIRESTORE_EMULATOR_HOST, "/emulator/v1/projects/demo-wina/databases/(default)/documents");
  await reset(process.env.FIREBASE_AUTH_EMULATOR_HOST, "/emulator/v1/projects/demo-wina/accounts");
});
