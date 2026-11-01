import { getApp, getApps, initializeApp, type FirebaseApp } from "firebase/app";
import { initializeAppCheck, ReCaptchaEnterpriseProvider } from "firebase/app-check";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getFunctions } from "firebase/functions";
import { appCheckSiteKey, firebaseConfig } from "./firebase-config";

// L'app Firebase et App Check sont créés ensemble, avant toute instance Auth / Firestore / Functions : sinon leurs
// premières requêtes partiraient sans jeton App Check. Le module n'est évalué qu'une fois par chargement de page.
function init(): FirebaseApp {
  if (getApps().length > 0) return getApp();
  const app = initializeApp(firebaseConfig);
  if (appCheckSiteKey) {
    if (process.env.NODE_ENV === "development" && ["localhost", "127.0.0.1"].includes(location.hostname)) {
      // Jeton de débogage : affiché dans la console du navigateur au premier lancement, à enregistrer dans la
      // console Firebase (App Check, Applications, Gérer les jetons de débogage). Réservé à localhost en dev.
      Object.assign(self, { FIREBASE_APPCHECK_DEBUG_TOKEN: true });
    }
    initializeAppCheck(app, {
      provider: new ReCaptchaEnterpriseProvider(appCheckSiteKey),
      isTokenAutoRefreshEnabled: true,
    });
  } else {
    console.warn("App Check désactivé : appCheckSiteKey est vide dans firebase-config.ts.");
  }
  return app;
}

export const app = (): FirebaseApp => init();
export const auth = () => getAuth(app());
export const db = () => getFirestore(app());
// Les fonctions Wina sont déployées en europe-west9.
export const functions = () => getFunctions(app(), "europe-west9");
