// Configuration de l'app web Firebase « Wina » (wina-c4c4a). La clé API web n'est pas un secret : elle est livrée
// dans toute application cliente Firebase. L'accès est contrôlé par les règles Firestore et le custom claim
// `admin`, pas par cette clé.
export const firebaseConfig = {
  apiKey: "AIzaSyBlcWXRyDS9SnpNhuNF_uE8e5LIEJ5ARbc",
  authDomain: "wina-c4c4a.firebaseapp.com",
  projectId: "wina-c4c4a",
  storageBucket: "wina-c4c4a.firebasestorage.app",
  messagingSenderId: "1074102338688",
  appId: "1:1074102338688:web:78ce9e7f14e0d752c25265",
  measurementId: "G-86M7FCSV73",
};

// Clé de SITE reCAPTCHA Enterprise de Firebase App Check (publique par conception, limitée au domaine
// wina-admin.web.app dans Google Cloud). Chaîne vide : App Check désactivé.
export const appCheckSiteKey: string = "6LeVwOwtAAAAAKmSSLXmjAD1vBx6oseORAfzdVFW";
