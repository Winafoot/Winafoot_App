import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it, vi } from "vitest";
// Câblage ACTIF : on vérifie les secrets et réglages avec l'interrupteur à true (sa valeur dans le dépôt, figée ici).
// L'état inerte est prouvé dans test/algolia_inert_wiring.test.ts.
vi.mock("../src/config/algolia", async (importActual) => ({ ...(await importActual<typeof import("../src/config/algolia")>()), ALGOLIA_ENABLED: true }));

import * as callables from "../src/callables/index";
import * as triggers from "../src/triggers/index";
import * as httpRequests from "../src/https_requests/index";
import { ADMIN_MAX_INSTANCES, BUDGET_ALERT_MAX_INSTANCES, PUBLIC_MAX_INSTANCES, TRIGGER_MAX_INSTANCES } from "../src/config/rate_limits";

// Garde-fou de la surface exposée. ATTENTION : un export retiré est SUPPRIMÉ de la
// production au prochain déploiement (avec confirmation, défaut « non » ; sans
// terminal le déploiement échoue ; `--force` supprime TOUTES les fonctions absentes
// du code). Tout ce que l'app, ses paquets du socle ou la landing appellent doit
// donc rester exporté.
describe("exposed surface", () => {
  // Landing (support, suppression de compte) : exigés pour la soumission aux stores.
  it("keeps the three HTTP endpoints of the landing page, and only those", () => {
    expect(Object.keys(httpRequests).sort()).toEqual(["deleteAccountByEmail", "onSendLandingPageMail", "onSendLandingPageMailDeleteAccount"]);
  });

  it("keeps the nine background triggers, and only those", () => {
    expect(Object.keys(triggers).sort()).toEqual([
      "onBudgetAlert",
      "onCreateNotification",
      "onCreateReport",
      "onCreateUser",
      "onDeleteUser",
      "onUpdateAppConfig",
      "onUpdateSecurityMetadata",
      "onWriteCompositionSearch",
      "onWriteMatchSearch",
    ]);
  });

  // Aucune fonction planifiée : src/index.ts n'expose que les callables, les endpoints HTTP et les triggers.
  it("exports no scheduled function", () => {
    const entry = readFileSync(join(__dirname, "../src/index.ts"), "utf8");
    expect(entry.match(/^export \* from "\.\/(\w+)\/index";$/gm)).toEqual([
      'export * from "./callables/index";',
      'export * from "./https_requests/index";',
      'export * from "./triggers/index";',
    ]);
  });

  it.each([
    // Tout ce que l'app et le back-office appellent doit rester exporté : un export retiré est
    // SUPPRIMÉ de la production au prochain déploiement.
    "emailIsAlreadyUsed", // « Mot de passe oublié » s'arrête s'il disparaît
    "phoneIsAlreadyUsed",
    "sendResetPassword",
    "sendEmailVerification",
    "deleteAccount",
    "addNotification",
    "createPlayer",
    "deletePlayer",
    "getSearchKey",
    "createCoach",
    "resendInvite",
    "setCoachDisabled",
    "deleteCoach",
    "listAdmins",
    "createAdmin",
    "updateAdmin",
    "deleteAdmin",
  ])("keeps the %s callable", (name) => {
    expect(callables).toHaveProperty(name);
  });

  // Le changement d'adresse passe par l'écran Paramètres de l'app (verifyBeforeUpdateEmail, côté client) :
  // les callables du socle sendChangeEmail et changeEmail n'avaient aucun appelant atteignable.
  it("exposes exactly seventeen callables", () => {
    expect(Object.keys(callables)).toHaveLength(17);
    expect(callables).not.toHaveProperty("sendChangeEmail");
    expect(callables).not.toHaveProperty("changeEmail");
  });
});

// Les tests des handlers les appellent directement : sans ceci, remettre un
// export sur l'ancien handler du socle ou sur l'adaptateur public passerait
// inaperçu.
describe("wiring of the hardened callables", () => {
  // L'adaptateur authentifié refuse l'appel AVANT de charger le module du handler.
  it.each(["sendEmailVerification", "deleteAccount", "addNotification", "createPlayer", "deletePlayer", "getSearchKey"])(
    "%s rejects an anonymous caller",
    async (name) => {
      const callable = (callables as Record<string, any>)[name];

      await expect(callable.run({ data: {}, rawRequest: {} })).rejects.toMatchObject({ code: "unauthenticated" });
    },
  );

  // L'adaptateur admin refuse l'appel AVANT de charger le module du handler : un export recâblé sur
  // l'adaptateur authentifié ou public ouvrirait la gestion des comptes administrateurs à n'importe qui.
  it.each(["listAdmins", "createAdmin", "updateAdmin", "deleteAdmin"])("%s rejects an anonymous caller", async (name) => {
    const callable = (callables as Record<string, any>)[name];

    await expect(callable.run({ data: {}, rawRequest: {} })).rejects.toMatchObject({ code: "permission-denied" });
  });

  it.each([
    ["listAdmins", "list_admins"],
    ["createAdmin", "create_admin"],
    ["updateAdmin", "update_admin"],
    ["deleteAdmin", "delete_admin"],
  ])("%s points at its admin handler through the admin adapter", (name, module) => {
    const adminSource = readFileSync(join(__dirname, "../src/callables/index.ts"), "utf8");
    expect(adminSource).toMatch(new RegExp(`export const ${name} = onCall\\([^;]*adminCallableAdapter\\("callables/admin/${module}"\\)`));
  });

  // Les callables publics ne peuvent pas être exécutés ici (require d'un
  // module .ts sous Vitest) : on vérifie le module vers lequel ils pointent.
  const source = readFileSync(join(__dirname, "../src/callables/index.ts"), "utf8");
  const httpSource = readFileSync(join(__dirname, "../src/https_requests/index.ts"), "utf8");

  it.each([
    ["emailIsAlreadyUsed", "email_is_already_used_secured"],
    ["phoneIsAlreadyUsed", "phone_is_already_used_secured"],
    ["sendResetPassword", "send_reset_password_secured"],
  ])("%s points at its secured handler", (name, module) => {
    expect(source).toMatch(new RegExp(`export const ${name} = onCall\\([^;]*"callables/auth/${module}"[,)]`));
  });

  // Les handlers du socle prennent urlPath du client et mailent n'importe quelle adresse.
  it.each([
    ["onSendLandingPageMail", "send_landing_page_mail_secured"],
    ["onSendLandingPageMailDeleteAccount", "send_delete_account_mail_secured"],
    ["deleteAccountByEmail", "delete_account_by_email_secured"],
  ])("%s points at its secured handler", (name, module) => {
    expect(httpSource).toMatch(new RegExp(`export const ${name} = onRequest\\([^\\n]*"https_requests/landing_page/${module}"[,)]`));
  });

  // Sans le secret lié, sendEmail lève en production (clé introuvable) et chaque demande échoue.
  it.each(["onSendLandingPageMail", "onSendLandingPageMailDeleteAccount"])("%s binds the mailer secret", (name) => {
    expect(httpSource).toMatch(new RegExp(`export const ${name} = onRequest\\(\\{ secrets: MAILER_SECRET_PARAMS[,\\s}]`));
  });

  // Un export qui n'est pas ré-exporté par src/index.ts n'est pas déployé : il serait supprimé.
  it.each(["callables", "https_requests", "triggers"])("src/index.ts re-exports %s", (module) => {
    const entry = readFileSync(join(__dirname, "../src/index.ts"), "utf8");
    expect(entry).toContain(`export * from "./${module}/index";`);
  });
});

// Sans plafond, une fonction publique monte à 100 instances par défaut : un afflux d'appels
// se transforme alors en facture (le coupe-circuit budgétaire met ensuite toute l'app en
// maintenance).
describe("instance cap of the public functions", () => {
  it.each(["emailIsAlreadyUsed", "phoneIsAlreadyUsed", "sendResetPassword", "sendEmailVerification", "deleteAccount", "addNotification", "getSearchKey"])(
    "callable %s is capped",
    (name) => {
      expect((callables as Record<string, any>)[name].__endpoint.maxInstances).toBe(PUBLIC_MAX_INSTANCES);
    },
  );

  // Un appel anonyme sur un callable admin est refusé DANS le code, donc après le démarrage de l'instance.
  it.each(["createCoach", "resendInvite", "setCoachDisabled", "deleteCoach", "listAdmins", "createAdmin", "updateAdmin", "deleteAdmin"])("admin callable %s is capped", (name) => {
    expect((callables as Record<string, any>)[name].__endpoint.maxInstances).toBe(ADMIN_MAX_INSTANCES);
  });

  it.each(["onSendLandingPageMail", "onSendLandingPageMailDeleteAccount", "deleteAccountByEmail"])("HTTP function %s is capped", (name) => {
    expect((httpRequests as Record<string, any>)[name].__endpoint.maxInstances).toBe(PUBLIC_MAX_INSTANCES);
  });
});

// Les triggers aussi : sans plafond, une rafale d'écritures démarre jusqu'à 100 instances par fonction.
describe("instance cap of the background triggers", () => {
  it.each(Object.keys(triggers))("trigger %s is capped", (name) => {
    const max = (triggers as Record<string, any>)[name].__endpoint.maxInstances;
    expect(typeof max).toBe("number");
    expect(max).toBeGreaterThanOrEqual(1);
    expect(max).toBeLessThanOrEqual(TRIGGER_MAX_INSTANCES);
  });

  it("runs the budget circuit breaker on a single instance", () => {
    expect((triggers as Record<string, any>).onBudgetAlert.__endpoint.maxInstances).toBe(BUDGET_ALERT_MAX_INSTANCES);
  });
});

// Chaque callable authentifié ou public exposé à un abus passe par l'adaptateur limité.
describe("rate limiting wiring", () => {
  const source = readFileSync(join(__dirname, "../src/callables/index.ts"), "utf8");

  it.each([
    ["sendResetPassword", "limitedPublicCallableAdapter"],
    ["sendEmailVerification", "limitedAuthedCallableAdapter"],
    ["deleteAccount", "limitedAuthedCallableAdapter"],
    ["addNotification", "limitedAuthedCallableAdapter"],
    ["getSearchKey", "limitedAuthedCallableAdapter"],
  ])("%s goes through %s", (name, adapter) => {
    expect(source).toMatch(new RegExp(`export const ${name} = onCall\\([^;]*${adapter}\\(`));
  });

  // Le nom de l'adaptateur ne suffit pas : sans l'option, il ne limite rien.
  it.each([
    ["sendResetPassword", "perIp"],
    ["sendEmailVerification", "perUid"],
    ["deleteAccount", "perUid"],
    ["addNotification", "perUid"],
    ["getSearchKey", "perUid"],
  ])("%s passes a %s limit", (name, option) => {
    expect(source).toMatch(new RegExp(`export const ${name} = onCall\\([^;]*${option}: LIMITS\\.`));
  });
});

// Recherche Algolia : la clé parente (lecture seule) est le SEUL secret lié au callable, la clé d'écriture
// celui des triggers de synchronisation. Un secret de trop élargirait ce qu'une fonction exposée peut lire.
describe("Algolia search wiring", () => {
  const source = readFileSync(join(__dirname, "../src/callables/index.ts"), "utf8");
  const secretNames = (fn: any): string[] => fn.__endpoint.secretEnvironmentVariables.map((s: { key: string }) => s.key);

  it("getSearchKey points at its handler through the authed limited adapter", () => {
    expect(source).toMatch(/export const getSearchKey = onCall\([^;]*limitedAuthedCallableAdapter\("callables\/search\/get_search_key"/);
  });

  it("getSearchKey passes the dedicated per-uid limit", () => {
    expect(source).toMatch(/export const getSearchKey = onCall\([^;]*perUid: LIMITS\.searchKeyUid/);
  });

  it("getSearchKey binds the search secret only", () => {
    expect(secretNames(callables.getSearchKey)).toEqual(["ALGOLIA_SEARCH_KEY"]);
  });
});

// Un document écrit déclenche la synchronisation de son enregistrement Algolia.
describe("search triggers", () => {
  it.each([
    ["onWriteCompositionSearch", "compositions"],
    ["onWriteMatchSearch", "matches"],
  ])("%s", (name, collection) => {
    const endpoint = (triggers as Record<string, any>)[name].__endpoint;

    expect(endpoint.eventTrigger.eventType).toBe("google.cloud.firestore.document.v1.written");
    expect(endpoint.eventTrigger.eventFilterPathPatterns.document).toBe(`users/{userId}/${collection}/{docId}`);
    // Rejoue un échec transitoire (réseau, 429, 5xx, clé absente) pendant 24 h.
    expect(endpoint.eventTrigger.retry).toBe(true);
    // Quota CPU Cloud Run d'europe-west9 saturé : une seule instance.
    expect(endpoint.maxInstances).toBe(1);
    // Écriture seule : jamais la clé de recherche.
    expect(endpoint.secretEnvironmentVariables).toEqual([{ key: "ALGOLIA_WRITE_KEY" }]);
  });
});
