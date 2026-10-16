// Configuration de l'app web Firebase "Wina" (wina-c4c4a).
// La clé API web n'est pas un secret : elle est livrée dans toute application
// cliente Firebase. L'accès est contrôlé par les règles Firestore et le custom
// claim `admin` (cf. scripts/set-admin.ts), pas par cette clé.
export const firebaseConfig = {
  apiKey: "AIzaSyBlcWXRyDS9SnpNhuNF_uE8e5LIEJ5ARbc",
  authDomain: "wina-c4c4a.firebaseapp.com",
  projectId: "wina-c4c4a",
  storageBucket: "wina-c4c4a.firebasestorage.app",
  messagingSenderId: "1074102338688",
  appId: "1:1074102338688:web:78ce9e7f14e0d752c25265",
  measurementId: "G-86M7FCSV73",
};

// Clé de SITE reCAPTCHA Enterprise utilisée par Firebase App Check (cf. App.tsx).
// Comme `apiKey`, elle est PUBLIQUE par conception : elle est livrée dans le
// bundle du back-office. Ne jamais y coller une clé secrète ni une clé d'API
// Google Cloud. Dans Google Cloud (reCAPTCHA Enterprise), créer une clé de type SITE WEB
// « score » (une clé case à cocher ne fonctionne pas avec Firebase App Check) et la
// restreindre au domaine `wina-admin.web.app` (le développement local utilise un jeton de
// débogage App Check, pas besoin d'ajouter `localhost`). Le même site est aussi servi
// sur `wina-admin.firebaseapp.com` : avec cette restriction il ne reçoit aucun jeton
// valide (échec fermé, voulu). La politique de sécurité du contenu du site (firebase.json)
// autorise https://www.google.com/recaptcha/ et https://www.gstatic.com/recaptcha/.
// Chaîne vide = App Check désactivé (avertissement console, aucun autre effet).
// Clé « Wina back-office App Check » (type score, domaine wina-admin.web.app).
export const appCheckSiteKey: string = "6LeVwOwtAAAAAKmSSLXmjAD1vBx6oseORAfzdVFW";
