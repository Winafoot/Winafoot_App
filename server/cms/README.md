# Wina — back-office

Back-office de l'application, construit avec FireCMS 3 (React 19, Vite 6, Tailwind 4, TypeScript),
publié sur Firebase Hosting (site `wina-admin`). Il sert à créer et gérer les comptes des coachs, à
gérer les administrateurs et à consulter la piste d'audit.

## Accès

Connexion par e-mail et mot de passe. L'accès est réservé aux comptes qui portent le custom claim
`admin` et dont l'adresse e-mail est vérifiée ; les règles Firestore et les callables
d'administration appliquent la même règle. Les administrateurs se gèrent depuis la vue
« Administrateurs » ; le premier se crée avec le script `set-admin` (README du dépôt, section
« Administrateurs »).

Un administrateur peut inscrire un second facteur (code d'une application d'authentification) depuis
la vue « Sécurité du compte » ; la connexion le demande alors.

## Contenu

| Entrée | Rôle |
|---|---|
| Collection « Coachs » (`users`) | Liste et fiches des coachs, en lecture. Actions : renvoyer l'invitation (lien pour choisir un mot de passe), désactiver ou réactiver, supprimer définitivement |
| Collection « Journal d'audit » (`admin_audit`) | Actions faites depuis le back-office, réussies ou refusées |
| Vue « Créer un coach » | Crée le compte avec l'adresse et le mot de passe saisis (aucun e-mail n'est envoyé), le format du club et, au choix, l'équipe, la catégorie et la division |
| Vue « Administrateurs » | Inviter, modifier, supprimer les administrateurs |
| Vue « Sécurité du compte » | Inscrire ou retirer son second facteur |

Toutes les modifications passent par des callables (`src/callables.ts`, région `europe-west9`) : le
back-office n'écrit jamais directement dans Firestore.

Le mot de passe d'un coach suit la politique du projet (6 caractères au moins, une minuscule, une
majuscule, un chiffre, un caractère spécial de la liste de Firebase). La vue l'applique avant l'envoi
(`src/password_policy.ts`), et `createCoach` à la réception.

## App Check

`src/App.tsx` active App Check avec reCAPTCHA Enterprise avant toute requête, avec la clé de site de
`src/firebase_config.ts` (clé de type score, limitée au domaine `wina-admin.web.app`). Chaîne vide :
App Check désactivé.

En développement sur `localhost`, le SDK utilise un jeton de débogage, affiché dans la console du
navigateur au premier chargement : l'enregistrer dans la console Firebase (App Check, Applications,
Gérer les jetons de débogage), puis le retirer quand il ne sert plus.

## En-têtes du site

Définis dans `firebase.json` (bloc `hosting`) : interdiction d'affichage dans un cadre
(`X-Frame-Options`, `frame-ancestors`), `nosniff`, politique de référent, politique de permissions
minimale, et une politique de sécurité du contenu complète en mode rapport
(`Content-Security-Policy-Report-Only`) : les écarts s'affichent dans la console du navigateur sans
rien bloquer. Après un parcours complet sans écart (connexion, second facteur, création de coach,
administrateurs), la renommer en `Content-Security-Policy` pour l'appliquer. Le build ne publie pas de
source maps.

## Services tiers

Le back-office n'envoie aucune donnée à des services tiers de journalisation. FireCMS envoie à chaque
connexion une requête à `api.firecms.co/access_log` (jeton d'identité et adresse e-mail de
l'administrateur), sans option pour la couper : `src/third_party_guard.ts`, installé dans
`src/main.tsx` avant le rendu, répond localement à toute requête vers firecms.co, sans réseau. La
politique de sécurité du contenu n'autorise pas ce domaine.

À chaque mise à jour de FireCMS, lancer les tests des fonctions :
`functions/test/back_office/third_party_guard.test.ts` échoue si FireCMS accède au réseau autrement
que par `fetch` ou vers une autre adresse de firecms.co.

## Organisation

```
src/
├── main.tsx, App.tsx       point d'entrée, App Check, authentification, collections et vues
├── firebase_config.ts      configuration web Firebase et clé de site App Check
├── callables.ts            appels des Cloud Functions
├── collections/            coachs (et leurs actions), journal d'audit
├── views/                  créer un coach, administrateurs, sécurité du compte, connexion avec second facteur
├── team_options.ts         catégories, divisions et formats du club (miroir de l'app)
├── password_policy.ts      politique de mot de passe (miroir de functions/)
├── third_party_guard.ts    réponse locale aux requêtes vers firecms.co
└── auth_errors.ts          messages d'erreur d'authentification
```

## Commandes

```bash
npm ci
npm run dev       # serveur de développement
npm run build     # build dans build/, puis vérification TypeScript
firebase deploy --only hosting:wina-admin --project wina-c4c4a    # publication, après le build
```
