# Wina

Wina est l'application des entraîneurs de football : gestion de l'effectif et des maillots,
préparation des compositions, suivi du match en direct (coup d'envoi, statistiques, mi-temps,
remplacements) et bilans individuels et collectifs exportables en PDF.

Ce dépôt contient l'application mobile et tout son backend.

| Dossier | Contenu | Documentation |
|---|---|---|
| [`app/`](app/) | Application Flutter (tablette Android et iPad) | [`app/README.md`](app/README.md) |
| [`server/`](server/) | Backend Firebase : Cloud Functions, règles de sécurité, tests | [`server/README.md`](server/README.md) |
| [`server/cms/`](server/cms/) | Back-office FireCMS publié sur le site Hosting `wina-admin` | [`server/cms/README.md`](server/cms/README.md) |
| `codemagic.yaml` | Pipelines de build et de publication (Android et iOS) | — |

## Pile technique

- **Application** : Flutter 3.41.9 (épinglé par fvm), Riverpod, `auto_route`, `freezed`,
  `easy_localization`. Identifiant `fr.winafoot.app` sur Android et iOS.
- **Backend** : projet Firebase `wina-c4c4a` (Authentication, Firestore, Storage, Cloud Functions
  en TypeScript sur Node.js 22, Cloud Messaging, App Check), région `europe-west9`.
- **Abonnements** : RevenueCat (`purchases_flutter`) avec les achats intégrés App Store et Google Play.
- **Recherche** : Algolia, avec une clé temporaire délivrée par une Cloud Function.

## Démarrage

Prérequis : [fvm](https://fvm.app), Node.js 22 et la CLI Firebase.

```bash
# Application
cd app
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run

# Backend
cd server/functions
npm ci
npm run build
npm test
```

Les clés RevenueCat ne sont pas dans le code : elles se passent à la compilation avec
`--dart-define=RC_IOS_KEY=appl_…` et `--dart-define=RC_ANDROID_KEY=goog_…`.

## Connexion et conditions d'utilisation

- L'inscription par e-mail demande d'accepter les conditions générales d'utilisation.
- La connexion Google ou Apple utilise la case à cocher de l'écran de connexion : sans elle,
  aucun nouveau compte n'est créé. Les comptes existants peuvent toujours se connecter.
- Le texte affiché vient du champ `cgvu` de `app_config/metadata` dans Firestore ; le modifier remet à
  zéro l'acceptation des comptes.

## Publication

Le détail est dans [`app/README.md`](app/README.md), sections « Publication Android » et
« Publication iOS ». À vérifier avant chaque envoi aux stores :

- les clés RevenueCat sont bien fournies au build de production ;
- la clé de signature Android (`android/key.properties`) est présente ;
- `PrivacyInfo.xcprivacy` (iOS) et les formulaires de confidentialité des stores décrivent les mêmes
  données collectées ;
- les conditions générales et la politique de confidentialité sont rédigées et publiques.

## Backend et sécurité

Les règles Firestore et Storage, les secrets, les comptes administrateurs, App Check et le
coupe-circuit budgétaire sont décrits dans [`server/README.md`](server/README.md).
