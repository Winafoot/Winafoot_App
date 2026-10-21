# Wina — backend Firebase

Backend du projet Firebase `wina-c4c4a` : Cloud Functions, back-office, règles de sécurité et leurs
tests. Région des fonctions : `europe-west9`.

## Contenu

```
functions/              Cloud Functions (TypeScript, 2e génération)
functions/scripts/      scripts d'administration (administrateurs, recherche, effectif)
cms/                    back-office (FireCMS), publié sur le site Hosting wina-admin (voir cms/README.md)
tests/                  tests des règles, dans les émulateurs
firestore.rules         règles Firestore
firestore.indexes.json  index et durées de vie (TTL) Firestore
storage.rules           règles Storage
firebase.json           déploiements, en-têtes du back-office, émulateurs
```

## Cloud Functions

TypeScript, `firebase-functions` 7 (API v2, Cloud Run), `firebase-admin` 13, Node.js 22. Chaque
fonction est déclarée dans l'index de sa famille et pointe vers un module `export default`, chargé à
la demande par un adaptateur (`src/runtime/`) :

| Index | Rôle |
|---|---|
| `src/callables/` | Appels de l'app et du back-office |
| `src/https_requests/` | Points d'entrée HTTP des formulaires de la landing |
| `src/triggers/` | Réactions aux écritures Firestore et aux alertes de budget |

Les autres dossiers de `src/` : `config/` (réglages : App Check, limites, secrets, Algolia,
reCAPTCHA, second facteur), `database/` (accès Firestore), `model/`, `provider/`, `search/`
(synchronisation Algolia), `template/` (e-mails), `utils/`.

### Fonctions et protections

Toutes les callables exigent un jeton App Check (`enforceAppCheck`, `src/config/app_check.ts`) et
plafonnent leurs instances. Une callable agit toujours sur le compte du jeton d'authentification,
jamais sur un identifiant fourni par le client. Les limites de débit sont comptées dans Firestore
(`src/utils/rate_limit.ts`, collection `rate_limits`, expiration automatique des compteurs).

| Fonction | Appelant | Protection |
|---|---|---|
| `emailIsAlreadyUsed`, `phoneIsAlreadyUsed` | App, avant connexion | Réponse constante (`true`), sans lecture de compte |
| `sendResetPassword` | App, avant connexion | Réponse identique que le compte existe ou non ; limites par IP, par compte et globale |
| `sendEmailVerification` | App, connecté | Adresse du compte Auth de l'appelant ; un envoi toutes les 6 h ; limite par compte |
| `registerCoach` | App, avant connexion | Inscription d'un coach (e-mail, mot de passe, prénom, CGU) ; limite par IP ; crée le compte et ses fiches, sans rien conserver en cas d'échec |
| `deleteAccount` | App, connecté | Son propre compte ; le compte d'un autre seulement pour un administrateur (contrôles ci-dessous, audit) ; jamais un administrateur |
| `addNotification` | App, connecté | Expéditeur et destinataire = l'appelant ; limite par compte |
| `createPlayer`, `deletePlayer` | App, connecté | Effectif de l'appelant, plafond appliqué en transaction sur le nombre réel de joueurs ; limite par compte |
| `getSearchKey` | App, connecté | Clé de recherche restreinte aux enregistrements de l'appelant ; limite par compte |
| `createCoach`, `resendInvite`, `setCoachDisabled`, `deleteCoach` | Back-office | Administrateur ; audit |
| `listAdmins`, `createAdmin`, `updateAdmin`, `deleteAdmin` | Back-office | Administrateur ; verrou, dernier administrateur protégé, audit |
| `onSendLandingPageMail`, `onSendLandingPageMailDeleteAccount` | Landing (HTTP) | POST, CORS limité à la landing, limite par IP, reCAPTCHA Enterprise, plafonds globaux |
| `deleteAccountByEmail` | Landing (HTTP) | Jeton à usage unique reçu par e-mail, lié au compte ; limite par IP |
| `onCreateUser`, `onDeleteUser`, `onUpdateSecurityMetadata` | Fiche `users/{uid}` | E-mail de bienvenue ; nettoyage des sous-documents ; recopie de `profilCompleted` |
| `onCreateNotification` | Collection `notifications` | Envoi des notifications push |
| `onCreateReport` | Collection `reports` | E-mail à l'adresse de contact de l'app |
| `onUpdateAppConfig` | `app_config/{id}` | Nouvelle acceptation des CGU quand elles changent |
| `onWriteCompositionSearch`, `onWriteMatchSearch` | Compositions et matchs | Synchronisation Algolia |
| `onBudgetAlert` | Topic Pub/Sub `budget-alerts` | Coupe-circuit budgétaire (section dédiée) |

Les tests de `functions/test/` verrouillent ce câblage : liste exacte des fonctions exportées, App
Check sur chaque callable, adaptateur et limite de chaque callable, plafond d'instances de chaque
fonction, secrets déclarés.

### E-mails

Envoyés par MailerSend (`src/utils/send_email.ts`). L'expéditeur, le nom de l'app et l'adresse de
contact viennent de `app_config/metadata` : `mail.from` (obligatoire, sur un domaine vérifié dans
MailerSend), `mail.fromName`, `mail.replyTo`, `appName`, `contactEmail`. Sans `mail.from`, rien ne
part. Sans `contactEmail`, les e-mails n'affichent pas de lien de contact, et les signalements et le
formulaire de support ne sont pas envoyés. Un échec d'envoi est journalisé avec son motif ; il ne fait
échouer ni la création d'une fiche, ni un signalement, ni la création d'un administrateur.

### Configuration lue dans `app_config/metadata`

| Champ | Usage côté serveur |
|---|---|
| `appName`, `contactEmail`, `mail` | E-mails (ci-dessus) |
| `landingUrl` | URL https de la landing, pour le lien de suppression de compte et le CORS (à défaut, l'hébergement du projet) |
| `maintenance` | Posé à `true` par le coupe-circuit budgétaire |
| `cgvu` | Une modification remet à zéro l'acceptation des CGU des comptes |

Le document est lisible sans connexion par l'app (règles Firestore) : il ne contient aucun secret.

## Secrets

Tous dans Secret Manager, déclarés par `defineSecret` (`src/config/secrets.ts`) et liés fonction par
fonction dans ses options (`secrets`). Cloud Run les monte au démarrage de l'instance.
`test/secrets.test.ts` vérifie que chaque fonction déclare exactement les secrets que lit son code.

| Secret | Usage | Fonctions |
|---|---|---|
| `MAILER_API_KEY` | Envoi des e-mails (MailerSend) | `sendResetPassword`, `sendEmailVerification`, `resendInvite`, `createAdmin`, `updateAdmin`, `onCreateUser`, `onCreateReport`, `onSendLandingPageMail`, `onSendLandingPageMailDeleteAccount` |
| `ALGOLIA_WRITE_KEY` | Écriture dans les index Algolia | `onWriteCompositionSearch`, `onWriteMatchSearch` |
| `ALGOLIA_SEARCH_KEY` | Clé parente des clés de recherche temporaires | `getSearchKey` |

Créer ou changer un secret, puis redéployer les fonctions qui l'utilisent :

```bash
firebase functions:secrets:set MAILER_API_KEY --project wina-c4c4a     # la valeur est demandée, non affichée
```

Contrôler la longueur de chaque version, sans afficher la valeur : passée dans un tuyau
(`--data-file -`), la commande ci-dessus peut créer une version vide.

```bash
gcloud secrets versions list MAILER_API_KEY --project wina-c4c4a
gcloud secrets versions access latest --secret=MAILER_API_KEY --project wina-c4c4a | wc -c
# Version vide : en ajouter une, saisie au clavier puis Ctrl-D
gcloud secrets versions add MAILER_API_KEY --data-file=- --project wina-c4c4a
```

Le compte d'exécution des fonctions doit pouvoir lire chaque secret (section « Comptes d'exécution ») ;
le déploiement le lui accorde quand le déployeur est propriétaire du projet.

En local, l'émulateur Functions lit les secrets dans `functions/.secret.local` (ignoré par Git et
exclu de l'envoi des fonctions).

## Administrateurs

Un administrateur est un compte Firebase Auth qui porte le custom claim `admin: true` **et** dont
l'adresse e-mail est vérifiée. La même règle s'applique aux callables d'administration
(`verifyAdmin`, `src/runtime/v2_admin.ts`), aux règles Firestore (`isAdmin()`) et au back-office.
Les callables vérifient en plus que le jeton n'est ni révoqué ni celui d'un compte désactivé.

- **Vue « Administrateurs » du back-office** : lister, inviter, renommer, désactiver, retirer le second
  facteur, déconnecter partout, renvoyer l'invitation, supprimer. Une invitation crée le compte avec un
  mot de passe provisoire aléatoire, jamais transmis ; la personne choisit le sien par le lien reçu,
  valable une heure, ce qui vérifie aussi son adresse. On ne se désactive ni ne se supprime soi-même, et
  le dernier administrateur actif ne peut être ni désactivé ni supprimé (verrou `admin_locks/accounts`).
- **Script `set-admin`**, pour le premier administrateur ou pour retirer le rôle (identifiants
  applicatifs par défaut) :

  ```bash
  gcloud auth application-default login
  gcloud auth application-default set-quota-project wina-c4c4a
  npm --prefix functions run set-admin -- adresse@exemple.fr
  npm --prefix functions run set-admin -- adresse@exemple.fr --revoke
  ```

  Le compte doit exister dans Firebase Auth. Le script révoque les jetons du compte (reconnexion
  nécessaire) et prévient si l'adresse n'est pas vérifiée.
- **Second facteur (TOTP)** : activé au niveau du projet, facultatif. Chaque administrateur l'inscrit
  depuis la vue « Sécurité du compte ». Pour l'exiger : faire inscrire chaque administrateur, vérifier
  qu'une connexion demande le code, puis passer `REQUIRE_ADMIN_MFA` à `true`
  (`src/config/admin_mfa.ts`), compiler et redéployer les callables d'administration.
- **Audit** : chaque action du back-office, réussie ou refusée, est écrite dans `admin_audit`, lisible
  par les administrateurs, jamais par un client autre.

Les refus d'accès des callables sont journalisés en avertissement structuré
(`jsonPayload.event="access-denied"`, motif dans `jsonPayload.reason`, uid seulement) : base possible
d'une métrique et d'une alerte Cloud Monitoring.

## Recherche

Les barres de recherche de l'app interrogent Algolia (application `UV1NCQERZ5`, index
`wina_compositions` et `wina_matches`).

- **Synchronisation** : `onWriteCompositionSearch` et `onWriteMatchSearch` recopient les compositions et
  les matchs terminés avec la clé `ALGOLIA_WRITE_KEY` (ajout et suppression seulement). Un échec
  transitoire est rejoué pendant 24 h.
- **Clé de recherche** : l'app ne contient aucune clé. Elle demande à `getSearchKey` une clé sécurisée,
  dérivée de `ALGOLIA_SEARCH_KEY`, valable une heure, restreinte aux deux index et aux enregistrements
  de l'appelant (filtre `ownerKey`, `userToken`), puis la garde en mémoire et la renouvelle.
- **Interrupteur** `ALGOLIA_ENABLED` (`src/config/algolia.ts`), en service (`true`). À `false`, les
  trois fonctions sont inertes et ne lient aucun secret ; compiler et redéployer ces trois fonctions.
- **Réindexation** (`functions/scripts/algolia-reindex.ts`, voir `functions/scripts/README.md`) :
  réglages des index, indexation complète, purge des enregistrements orphelins.

## Landing

Les formulaires de la landing appellent trois points d'entrée HTTP, dont les noms ne changent pas :
`https://europe-west9-wina-c4c4a.cloudfunctions.net/` suivi de `onSendLandingPageMail` (support),
`onSendLandingPageMailDeleteAccount` (demande de suppression de compte) et `deleteAccountByEmail`
(confirmation). Ils acceptent POST et le préflight, limitent le CORS aux origines de la landing et
comptent les appels par IP.

Les deux premiers vérifient côté serveur un jeton reCAPTCHA Enterprise (champ `recaptchaToken` du
corps JSON ; constantes dans `src/config/recaptcha.ts` : clé de site, domaines autorisés, score
minimal). Un jeton refusé répond 400 `captcha`, une vérification impossible 503
`captcha-unavailable`, sans rien envoyer. Si la landing passe sur un domaine personnalisé, l'autoriser
dans la clé reCAPTCHA et dans `allowedHostnames`, et renseigner `app_config/metadata.landingUrl`.

La demande de suppression répond toujours 200 et n'envoie un lien qu'à une adresse qui a un compte ;
le jeton, valable 24 h, est consommé à la confirmation, qui supprime le compte, sa fiche, ses
sous-collections et ses fichiers, et archive l'adresse dans `deleted_users`.

## Règles de sécurité

**Firestore.** Refus par défaut. Sans connexion, seule la configuration `app_config` se lit. Chaque
coach lit et modifie ses propres documents (`users/{uid}` et ses sous-collections) ; les champs qu'il
peut écrire sont listés, avec leur type et leur taille, d'après ce que l'app écrit. Les joueurs se
créent et se suppriment par les callables. Les administrateurs vérifiés lisent les fiches coach et la
piste d'audit ; toutes leurs modifications passent par les callables. Les collections tenues par le
serveur (`rate_limits`, `accountDeletionRequests`, `deleted_users`, `admin_locks`, `reports`,
`notifications`…) sont fermées aux clients.

**Storage.** Tout accès client est refusé : ni l'app ni le back-office n'utilisent Storage.

Les Cloud Functions passent par l'Admin SDK, auquel ces règles ne s'appliquent pas.

### Tests

Dans les émulateurs, sur le projet de démonstration `demo-wina` (aucun service réel joignable), avec
Java 21 ou plus. Ports : Auth 9099, Firestore 8080, Storage 9199, Hosting 5002.

```bash
# Règles Firestore et Storage
cd tests && npm ci && npm test

# Cloud Functions : compilation, puis tests dans les émulateurs Auth et Firestore
cd functions && npm ci && npm run build && npm test
```

## App Check

App Check fait accepter par Firebase les seules requêtes venues de l'app et du back-office d'origine.

- **Clients** : l'app active App Check au lancement (Play Integrity sur Android, App Attest sur iOS,
  fournisseur de débogage hors release) ; le back-office utilise reCAPTCHA Enterprise
  (`cms/src/firebase_config.ts`, jeton de débogage sur `localhost`).
- **Vérification** : Firestore et Storage sont en mode « appliqué » dans la console Firebase (App
  Check, onglet API). Les callables exigent le jeton dans leur code (`enforceAppCheck`) : sans jeton
  valide, elles répondent 401 avant toute exécution. Coupure d'urgence : passer la valeur à `false`
  dans `src/config/app_check.ts`, compiler et redéployer.
- **Exclus** : les trois points d'entrée HTTP de la landing, appelés par des navigateurs sans App
  Check, protégés par reCAPTCHA Enterprise et par le jeton de suppression.

**Ordre de mise en place** : activer App Check dans l'app et le back-office, publier ces versions,
suivre dans la console la part de requêtes vérifiées, puis appliquer la vérification service par
service. Une fois appliquée, une version sans App Check voit ses requêtes refusées. Les jetons de
débogage enregistrés sur le projet sont à retirer avant la publication de l'app.

## Déploiement

```bash
npm --prefix functions run build
firebase deploy --only functions:createPlayer --project wina-c4c4a
firebase deploy --only functions:createPlayer,deletePlayer,getSearchKey --project wina-c4c4a
firebase deploy --only firestore:rules --project wina-c4c4a
firebase deploy --only firestore:indexes --project wina-c4c4a
firebase deploy --only storage --project wina-c4c4a
npm --prefix cms run build && firebase deploy --only hosting:wina-admin --project wina-c4c4a
```

- **Une fonction ou un petit groupe à la fois** : le quota de CPU de Cloud Run en `europe-west9` est
  vite atteint par les instances des fonctions qui viennent d'être déployées (« Quota exceeded for
  total allowable CPU per project per region »). Une fonction refusée garde sa révision précédente :
  relancer son déploiement seule, après quelques minutes.
- **Un export retiré du code n'est pas supprimé par un déploiement ciblé** : le supprimer
  explicitement (`firebase functions:delete <nom> --region europe-west9 --project wina-c4c4a`).
- **Sonde après chaque déploiement** : sans jeton App Check, chaque callable doit répondre 401. Un
  403 signale un service Cloud Run sans accès public.

  ```bash
  callables=(emailIsAlreadyUsed phoneIsAlreadyUsed sendResetPassword sendEmailVerification registerCoach deleteAccount addNotification createPlayer deletePlayer getSearchKey createCoach resendInvite setCoachDisabled deleteCoach listAdmins createAdmin updateAdmin deleteAdmin)
  for f in "${callables[@]}"; do
    printf '%s %s\n' "$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d '{"data":{}}' "https://europe-west9-wina-c4c4a.cloudfunctions.net/$f")" "$f"
  done
  ```

- **Accès public des callables** : leurs services Cloud Run portent `roles/run.invoker` pour
  `allUsers` (l'authentification et App Check sont vérifiés par la fonction). À rétablir si un service
  est recréé :

  ```bash
  gcloud run services add-iam-policy-binding <nom en minuscules> --region europe-west9 --member=allUsers --role=roles/run.invoker --project wina-c4c4a
  ```

- **Vérifications** : date de mise à jour de chaque fonction (`gcloud functions list --project
  wina-c4c4a`), journaux d'erreurs des 15 à 30 minutes suivantes, parcours de l'app et du back-office.
  Retour arrière : redéployer depuis le commit précédent.

## Coupe-circuit budgétaire

Un budget Cloud Billing publie ses alertes sur le topic Pub/Sub `budget-alerts`. `onBudgetAlert`
vérifie que le message a la forme d'une notification de budget (montants numériques, champs et
attributs de Cloud Billing) ; un autre message est ignoré et journalisé. Si la dépense dépasse le
montant du budget, la fonction passe l'app en maintenance (`app_config/metadata.maintenance`), puis
détache le compte de facturation du projet, qui repasse au plan Spark : tous les services payants
s'arrêtent. Pour reprendre, rattacher le compte de facturation (console Cloud Billing) et repasser
`maintenance` à `false`.

## Comptes d'exécution

| Compte | Fonctions | Rôles |
|---|---|---|
| `wina-functions@wina-c4c4a.iam.gserviceaccount.com` | Toutes sauf `onBudgetAlert` (`setGlobalOptions`, `src/index.ts`) | `roles/datastore.user`, `roles/firebaseauth.admin`, `roles/firebasecloudmessaging.admin`, `roles/recaptchaenterprise.agent`, `roles/eventarc.eventReceiver` (projet) ; `roles/storage.objectUser` (bucket par défaut) ; `roles/secretmanager.secretAccessor` (sur chacun des trois secrets) ; `roles/run.invoker` (sur chaque service déclenché par Firestore) |
| `wina-budget-guard@wina-c4c4a.iam.gserviceaccount.com` | `onBudgetAlert` | `roles/datastore.user`, `roles/billing.projectManager`, `roles/browser` (projet) ; `roles/run.invoker` (sur le service `onbudgetalert`) |

Le compte d'un déclencheur Eventarc est celui de sa fonction : il doit pouvoir invoquer le service
(`roles/run.invoker`), qui n'est accordé que service par service pour que seul le compte du
coupe-circuit puisse invoquer `onBudgetAlert`. Un nouveau trigger Firestore demande la même liaison
sur son service. Les journaux des fonctions sont collectés depuis la sortie standard, sans rôle
supplémentaire. Le compte App Engine par défaut du projet reste en place : firebase-tools le contrôle
à chaque déploiement.
