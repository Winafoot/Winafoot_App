# Wina — back-office (Next.js)

Nouveau back-office, en remplacement de `../cms` (FireCMS). Next.js 15 (App Router) en **export statique**,
React 19, TypeScript, Tailwind 4 et composants shadcn/ui. Il est servi par Firebase Hosting, sans serveur Next.js :
toutes les données passent par le SDK Firebase (règles Firestore) et les callables d'administration.

L'ancien back-office reste en ligne (site `wina-admin`) jusqu'à la bascule.

## Pages

| Route | Rôle | Source des données |
|---|---|---|
| `/` | Tableau de bord : coachs, abonnés, équipes liées, joueurs, matchs, compositions, signalements, inscriptions par mois | callable `getAdminStats` (agrégations `count()`) |
| `/coachs/` | Liste des coachs : recherche, tri, filtre par statut | lecture directe de `users` |
| `/coachs/detail/?uid=` | Fiche : profil, abonnement, équipes liées (quota, identifiants, réinitialisation du mot de passe), actions (invitation, désactivation, suppression), données de l'équipe | `users/{uid}` et équipes liées en direct ; `getCoachData` à la demande ; callable `resetLinkedTeamPasswordByAdmin` |
| `/abonnements/` | Abonnements par statut, échéances sous 14 jours, équipes créées sur le quota | lecture directe de `users` (`subscription`, `access`) |
| `/creer-coach/` | Création d'un compte coach | callable `createCoach` |
| `/administrateurs/` | Inviter, modifier, désactiver, supprimer les administrateurs | callables `listAdmins`, `createAdmin`, `updateAdmin`, `deleteAdmin` |
| `/audit/` | Journal d'audit | lecture directe de `admin_audit` |
| `/securite/` | Second facteur (TOTP) du compte connecté | SDK Firebase Auth |

## Accès et sécurité

Mêmes règles que l'ancien back-office :

- Connexion par e-mail et mot de passe, puis code du second facteur si le compte en a un. Accès réservé aux comptes qui
  portent le custom claim `admin` et dont l'adresse est vérifiée (`src/lib/auth-provider.tsx`) ; les règles Firestore et les
  callables appliquent la même règle.
- App Check (reCAPTCHA Enterprise) est initialisé avant toute requête (`src/lib/firebase.ts`). En développement sur
  `localhost`, un jeton de débogage s'affiche dans la console : l'enregistrer dans la console Firebase.
- Le back-office n'écrit jamais directement dans Firestore. Les écritures et les lectures que les règles refusent aux
  administrateurs (joueurs, matchs, compositions, signalements, statistiques) passent par des callables Admin SDK, en lecture
  seule, bornées, et la consultation des données d'un coach est tracée dans `admin_audit` (`view_coach_data`).
- Aucune donnée n'est envoyée à des services tiers : pas de FireCMS, donc plus de requête vers `api.firecms.co`.

## Développement

```bash
npm install
npm run dev        # http://localhost:3000
npm run typecheck
npm run build      # export statique dans out/
```

## Publication

La configuration Hosting est dans `../firebase.admin.json` (site `wina-admin-next`, dossier `admin/out`), séparée de
`../firebase.json` pour ne pas toucher à la production.

1. Créer le site : `firebase hosting:sites:create wina-admin-next --project wina-c4c4a`.
2. Ajouter le domaine `wina-admin-next.web.app` à la clé reCAPTCHA Enterprise « Wina back-office App Check » (Google Cloud),
   sinon App Check refuse les appels du nouveau site.
3. Déployer les nouvelles callables : `firebase deploy --only functions:getAdminStats,functions:getCoachData,functions:listReports,functions:sendAdminNotification,functions:resetLinkedTeamPasswordByAdmin --project wina-c4c4a`.
4. Compiler et publier :

   ```bash
   npm run build
   firebase deploy --only hosting --config firebase.admin.json --project wina-c4c4a   # depuis server/
   ```

La politique de sécurité du contenu est en mode rapport (`Content-Security-Policy-Report-Only`), comme l'ancien site, avec
`'unsafe-inline'` en `script-src` pour les petits scripts d'hydratation de Next.js. Après un parcours complet sans écart, la
renommer en `Content-Security-Policy`.

## Bascule

Quand le nouveau site couvre tout l'usage : pointer le site `wina-admin` vers `admin/out` dans `firebase.json`, déployer,
puis supprimer `../cms`, `src/third_party_guard.ts` côté ancien projet et les mentions de FireCMS dans le README du serveur.
