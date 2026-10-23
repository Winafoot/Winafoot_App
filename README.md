# Wina

Wina est une application de gestion d'équipe de football pour les entraîneurs : effectif, maillots,
compositions, match en direct (statistiques, mi-temps, remplacements), bilans individuels et collectifs
exportables en PDF. Elle est vendue par abonnement (1, 2 ou 3 équipes), géré avec RevenueCat.

Ce dépôt réunit l'application mobile, le backend Firebase, le back-office et la documentation.

## Organisation du dépôt

```
app/             application Flutter (Android et iOS), identifiant fr.winafoot.app
  packages/      paquets Kosmos intégrés au dépôt (socle, connexion, interface, paramètres)
server/          backend du projet Firebase wina-c4c4a
  functions/     Cloud Functions (TypeScript), région europe-west9
  cms/           back-office (FireCMS), publié sur Hosting
  tests/         tests des règles de sécurité
design/          maquettes et ressources graphiques
doc/             documentation : mise en place de Codemagic, diagrammes de classes
codemagic.yaml   publication automatique (Google Play et TestFlight)
```

Chaque sous-projet a son propre README, qui fait référence :

| Sujet | Document |
|---|---|
| Application : pile technique, organisation du code, App Check, publication Android et iOS, tests | [`app/README.md`](app/README.md) |
| Design et gabarit d'interface | [`app/DESIGN.md`](app/DESIGN.md) |
| Paquets Kosmos et leur provenance | [`app/packages/README.md`](app/packages/README.md) |
| Backend : fonctions, secrets, administrateurs, abonnements, règles, déploiement | [`server/README.md`](server/README.md) |
| Back-office | [`server/cms/README.md`](server/cms/README.md) |
| Publication via Codemagic | [`doc/codemagic.md`](doc/codemagic.md) |

## Architecture en bref

```
App Flutter ──► Firebase Auth, Firestore, Storage, Cloud Messaging
     │                │
     │                └─ règles de sécurité (server/firestore.rules)
     ├──────────────► Cloud Functions (appels callables, App Check exigé)
     └──────────────► RevenueCat (achats) ──webhook──► Cloud Functions ──► users/{uid}.access

Back-office (cms) ──► Cloud Functions et Firestore, pour les comptes administrateurs
```

- **Données.** Tout est rangé sous le compte de l'entraîneur, `users/{uid}` : profil, puis les
  sous-collections `players`, `jerseys`, `compositions`, `matches`, `notifications` et `metadata`.
- **Écritures sensibles côté serveur.** Création et suppression de joueurs, comptes d'équipe liés,
  abonnements : ces écritures passent par des Cloud Functions, jamais directement par le client.
- **App Check.** Android utilise Play Integrity, iOS utilise App Attest. Firestore, Storage et les
  Cloud Functions exigent un jeton valide (voir `app/README.md` et `server/README.md`).
- **Configuration publique.** `app_config/metadata` (textes légaux, maintenance, mise à jour forcée) et
  `app_config/config` (interrupteurs ci-dessous) sont lisibles par l'app avant connexion.

## Interrupteurs d'administration

Posés à la main dans la console Firebase, document `app_config/config`. Aucun n'est actif par défaut.

| Champ | Effet |
|---|---|
| `paywall_enforced` | `true` : mur de paiement. Les comptes sans abonnement actif voient l'écran d'abonnement et ne lisent plus les données d'équipe. Absent ou `false` : tout le monde entre. Procédure d'activation dans `server/README.md`, section « Abonnements ». |
| `test_purchases_enabled` | `true` : tant que RevenueCat n'a aucune offre, l'app affiche des prix de démonstration et « S'abonner » donne 30 jours d'abonnement. Dès que RevenueCat renvoie de vraies offres, elles prennent la place, sans nouveau build. **À repasser à `false` avant le lancement public** : tant qu'il est actif, tout compte connecté peut se donner un abonnement gratuit. |

Avant d'activer `paywall_enforced`, accorder l'accès aux comptes existants avec
`npm --prefix functions run grant-existing-access` (d'abord avec `--dry-run`), sans quoi ils seraient tous
bloqués.

## Démarrage rapide

### Application

```bash
cd app
fvm flutter pub get
fvm flutter test
fvm flutter run
```

La version de Flutter est épinglée par fvm. Les clés RevenueCat sont injectées au build avec
`--dart-define=RC_IOS_KEY=…` et `--dart-define=RC_ANDROID_KEY=…` ; sans elles l'app signale « Achats
indisponibles », ou propose des achats simulés si `test_purchases_enabled` est actif. Détail des commandes
dans `app/README.md`.

### Backend

```bash
cd server/functions
npm ci
npm run build
npm test            # tests dans les émulateurs Auth et Firestore (Java 21 ou plus requis)
```

Déploiement par famille, par exemple
`firebase deploy --only functions:createPlayer --project wina-c4c4a` ou
`firebase deploy --only firestore:rules --project wina-c4c4a`. La liste complète est dans
`server/README.md`, section « Déploiement ».

### Back-office

```bash
cd server/cms
npm ci
npm run dev
```

## Publication

Un tag `v*` déclenche deux workflows Codemagic (`codemagic.yaml`) :

| Workflow | Résultat |
|---|---|
| `android-release` | AAB signé envoyé sur Google Play, piste interne, en brouillon |
| `ios-release` | IPA signée envoyée sur TestFlight |

Chaque build lance `flutter analyze` et `flutter test` avant de compiler. La mise en place complète
(keystore, clé App Store Connect, groupes de variables) est décrite dans `doc/codemagic.md`.

Pour iOS, le profil de signature doit porter les capacités de l'identifiant d'app : **Push
Notifications, App Attest et Associated Domains**. Un profil créé avant l'ajout d'une capacité ne la
contient pas : le supprimer dans le portail Apple Developer pour que Codemagic en recrée un.

## Branches

`main` porte le code livrable. Le travail se fait sur des branches `feature/…`, fusionnées par pull
request.
