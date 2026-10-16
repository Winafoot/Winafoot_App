import * as admin from "firebase-admin";
import { setGlobalOptions } from "firebase-functions/v2";
import { FUNCTIONS_SERVICE_ACCOUNT } from "./config/service_accounts";

admin.initializeApp();
// Les modèles du socle portent des champs optionnels (`userProfileImage?`, `metadata?`…) que le
// code écrit sans repli : add_notification.ts pose `userProfileImage: userData?.userProfileImage`,
// et aucun coach n'a de photo (l'app n'en propose pas). Firestore refuse un document qui contient
// `undefined` (« Cannot use "undefined" as a Firestore value ») : ce réglage, valable pour toutes
// les écritures, omet ces champs au lieu de faire échouer l'écriture entière.
admin.firestore().settings({ ignoreUndefinedProperties: true });
setGlobalOptions({
  region: "europe-west9",
  // Compte d'exécution dédié ; onBudgetAlert a le sien (src/triggers/index.ts).
  serviceAccount: FUNCTIONS_SERVICE_ACCOUNT,
});

export * from "./callables/index";
export * from "./https_requests/index";
export * from "./triggers/index";
