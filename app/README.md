# Wina — application tablette

Application Flutter pour tablette, Android et iPad, destinée aux entraîneurs de football. L'entraîneur
gère son effectif et ses maillots, prépare ses compositions, mène le match en direct (coup d'envoi,
statistiques, mi-temps, remplacements) et consulte les bilans individuels et collectifs, exportables
en PDF.

## Pile technique

| Domaine | Choix |
|---|---|
| Flutter | 3.41.9 (Dart 3.11.5), épinglé par fvm (`.fvmrc`) |
| État | Riverpod (`hooks_riverpod`) |
| Navigation | `auto_route` 5 (`lib/routes/`), avec gardes de connexion et de permissions |
| Modèles | `freezed` et `json_serializable` (fichiers générés `*.freezed.dart`, `*.g.dart`, `*.gr.dart`) |
| Traductions | `easy_localization`, `assets/translations/fr-FR.json` |
| Backend | Firebase : Authentication, Firestore, Cloud Functions, Cloud Messaging, App Check |
| Recherche | Algolia, avec une clé de recherche temporaire délivrée par une Cloud Function |
| PDF | `pdf` et `printing` (bilans) |

Identifiant d'application : `fr.winafoot.app` sur Android comme sur iOS. Android : SDK minimal 24,
cible 36. iOS : 15.0 minimum, iPad seul, paysage plein écran. L'interface est dessinée sur un gabarit
de 1194 × 834 (voir `DESIGN.md`).

## Organisation

```
lib/
├── main.dart        lancement : Firebase, App Check, configuration des paquets, routeur, thème
├── config/          configuration des paquets (connexion, paramètres, permissions, notifications),
│                    thème, maintenance et mise à jour forcée
├── data/            lecture et écriture Firestore (joueurs, maillots, compositions, matchs,
│                    notifications), recherche
├── models/          joueurs, compositions, matchs, statistiques, profil de l'entraîneur
├── providers/       état Riverpod : effectif, compositions, match en direct, recherche
├── routes/          routes auto_route
├── services/        export PDF des bilans, synchronisation de l'adresse e-mail
└── view/
    ├── page/        écrans (Mon équipe, Coup d'envoi, match en direct, bilans, réglages…)
    └── widget/      composants partagés
packages/            paquets Kosmos, en dépendances path (voir packages/README.md)
assets/              polices, images, icônes, traductions
tool/branding/       images sources de l'icône et de l'écran de démarrage (non embarquées)
test/                tests unitaires et de widgets ; test/e2e : parcours pilotés par adb
```

## Fonctionnement

**Démarrage.** `Application.launch` (paquet `core_kosmos`) initialise Firebase et App Check, puis
charge la configuration publique `app_config/metadata` (textes légaux, politique de mot de passe,
informations de contact). `main.dart` ajoute ensuite :

- la purge des identifiants laissés sur l'appareil par d'anciennes versions (voir Connexion) ;
- `MaintenanceGate`, qui écoute `app_config/metadata` en temps réel (maintenance, mise à jour forcée) ;
- `EmailSync`, qui tient à jour l'adresse e-mail du compte dans Firestore.

**Données.** Tout est rangé sous le compte de l'entraîneur, `users/{uid}` : profil de l'équipe, puis
les sous-collections `players`, `jerseys`, `compositions`, `matches` et `notifications`. La création
et la suppression de joueurs passent par les Cloud Functions `createPlayer` et `deletePlayer`, qui
appliquent le plafond d'effectif du format de l'équipe.

**Matchs.** L'assistant « Coup d'envoi » crée le match (adversaire, maillot, composition,
statistiques suivies). Pendant le match, l'app enregistre le score, le temps de jeu, la mi-temps et
les statistiques par joueur dans `users/{uid}/matches/{id}`. Les bilans se calculent à partir de ces
documents et s'exportent en PDF (`lib/services/stats_pdf_export.dart`).

**Connexion.** Par e-mail et mot de passe (paquet `skeleton`), comptes créés par l'administration.
La connexion biométrique du skeleton est désactivée (`enableLocalAuth: false` dans
`lib/config/skeleton_config.dart`). Si elle est activée un jour, l'e-mail et le mot de passe ne sont
conservés que si l'utilisateur l'a choisie, et alors uniquement dans le trousseau iOS ou le Keystore
Android (`flutter_secure_storage`) ; ils sont effacés à la déconnexion.

**Adresse e-mail.** Le changement d'adresse passe par `verifyBeforeUpdateEmail` : Firebase Auth ne
bascule sur la nouvelle adresse qu'après le clic sur le lien reçu. `EmailSync` recopie ensuite
l'adresse dans `users/{uid}.email`, au lancement, à la connexion et au retour au premier plan.

**Notifications.** Firebase Cloud Messaging et notifications locales. Une notification tapée ouvre
la liste des notifications.

## Firebase

Projet unique `wina-c4c4a`. Les Cloud Functions tournent en `europe-west9` (`kCloudRegion`,
`lib/config/skeleton_config.dart`).

Configuration des applications : `android/app/google-services.json` et
`ios/Runner/GoogleService-Info.plist`. Ces fichiers sont publics par nature : ils identifient le
projet, sans donner de droit. Les clés d'API qu'ils contiennent sont restreintes dans la console
Google Cloud : clé Android limitée à `fr.winafoot.app` et aux empreintes SHA-1 enregistrées, clé iOS
limitée à l'identifiant de bundle. L'accès aux données est contrôlé par les règles Firestore et par
App Check (dépôt `server`).

Cloud Functions appelées par l'app : `createPlayer`, `deletePlayer`, `addNotification`,
`getSearchKey`, ainsi que `emailIsAlreadyUsed` et `sendResetPassword` (mot de passe oublié, écran
de connexion).

## App Check

Activé dans `lib/main.dart` (`excuteAfterFirebaseInitialized`, juste après l'initialisation de
Firebase) :

- en release : Play Integrity sur Android, App Attest sur iOS ;
- en debug et en profile : fournisseurs de debug.

Côté Firebase, App Check est exigé (Enforce) pour Firestore, Storage et les Cloud Functions : une
requête sans jeton valide est refusée. Un échec d'activation est journalisé (`developer.log`, nom
`AppCheck`) et n'empêche pas le démarrage.

**Développement.** Au premier lancement d'un build debug ou profile, le jeton de debug s'affiche
dans les journaux (Logcat sur Android, console Xcode sur iOS). L'enregistrer dans la console
Firebase : App Check, Applications, menu de l'app, Gérer les jetons de débogage. Le projet servant
aussi à la production, les jetons de debug sont à retirer avant la publication.

**Publication.** Play Integrity demande l'empreinte SHA-256 du certificat de signature de Play App
Signing dans l'application Android du projet Firebase ; App Attest demande la capacité App Attest
(environnement `production`, déjà dans `Runner.entitlements`) sur l'identifiant d'app iOS.

## Recherche

Les écrans de recherche filtrent d'abord les données locales, puis complètent avec Algolia
(`lib/data/search/`). L'app ne contient aucune clé Algolia : la Cloud Function `getSearchKey` délivre
une clé sécurisée d'une heure, limitée aux index de Wina et aux données de l'entraîneur connecté.
La clé reste en mémoire et se renouvelle avant son échéance ; sans clé, la recherche reste locale.

## Maintenance et mise à jour forcée

`MaintenanceGate` (`lib/config/maintenance_gate.dart`) lit en temps réel trois champs facultatifs
de `app_config/metadata` :

```
maintenance: true | false
minBuild: { android: <numéro de build>, ios: <numéro de build> }
storeUrl: { android: "<lien de la fiche Play Store>", ios: "<lien de la fiche App Store>" }
```

- `maintenance: true` : toute l'app affiche l'écran de maintenance (le coupe-circuit budgétaire du
  dépôt `server` pose ce champ).
- Numéro de build installé (`versionCode` sur Android, `CFBundleVersion` sur iOS) inférieur à
  `minBuild` de sa plateforme : écran « Mise à jour nécessaire », non fermable, avec un bouton vers
  `storeUrl`.
- Champ absent, mal formé ou plateforme non renseignée : aucun blocage. La maintenance prime.

La bascule vaut aussi pour une app déjà ouverte. Pour retirer une version du service : publier la
nouvelle version, attendre sa disponibilité sur les deux stores, puis porter `minBuild` au numéro de
build de cette version.

## Liens de l'app

Les liens `https://wina-c4c4a.web.app/share…` (page `share.html` de la landing) ouvrent l'app quand
elle est installée : App Links sur Android (`intent-filter` avec `autoVerify` dans
`AndroidManifest.xml`), liens universels sur iOS (`applinks:wina-c4c4a.web.app` dans
`Runner.entitlements`). L'app s'ouvre sur son écran courant : le routage Flutter des liens est
désactivé (`flutter_deeplinking_enabled`, `FlutterDeepLinkingEnabled`).

Mise en production :

1. Android : ajouter dans `.well-known/assetlinks.json` de la landing l'empreinte SHA-256 du
   certificat de Play App Signing (Play Console, Intégrité de l'application), en plus de celle de la
   clé d'upload, pour `fr.winafoot.app`.
2. iOS : `.well-known/apple-app-site-association` déclare `H2B6ZK5Q35.fr.winafoot.app` et le chemin
   `/share*`. Activer la capacité Associated Domains sur l'identifiant d'app (Apple Developer) et
   régénérer les profils.
3. Domaine personnalisé éventuel : l'ajouter au `intent-filter` et à `Runner.entitlements`, et servir
   les deux fichiers sur ce domaine.
4. Déployer le Hosting de la landing, puis vérifier : API Digital Asset Links pour Android,
   validateur Apple ou ouverture d'un lien depuis Notes sur un iPad.

## Commandes

```bash
fvm install                                                    # Flutter 3.41.9, une fois
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # modèles et routes générés
fvm flutter analyze
fvm flutter test
fvm flutter run                                                # tablette ou émulateur tablette
fvm flutter build appbundle --release                          # Android (clé d'upload requise)
fvm flutter build ipa --release                                # iOS
```

Icône et écran de démarrage : `fvm dart run flutter_launcher_icons` et
`fvm dart run flutter_native_splash:create` (configuration dans `pubspec.yaml`, images dans
`tool/branding/`).

## Versions

La version vient de `pubspec.yaml` (`version: <nom>+<build>`) pour Android comme pour iOS : le nom
devient `versionName` et `CFBundleShortVersionString`, le build `versionCode` et `CFBundleVersion`.
Le numéro de build augmente à chaque envoi aux stores ; c'est lui que compare `minBuild`.

Chaque build envoyé aux stores reçoit un tag `app-v<version>+<build>` (par exemple
`app-v1.0.0+1`) sur le commit compilé.

## Publication Android

1. **Clé d'upload.** Créer un keystore hors du dépôt, puis `android/key.properties` d'après
   `android/key.properties.example` (chemin absolu du keystore, alias, mots de passe). Ni l'un ni
   l'autre ne sont commités (`.gitignore`).
2. **Garde de signature.** Sans `key.properties`, `android/app/build.gradle` signe un APK release
   avec la clé de debug (test local) mais refuse de produire un AAB ; avec un `key.properties`
   incomplet ou un keystore introuvable, le build échoue avec le nom du champ en cause.
3. **Play App Signing.** Au premier envoi de l'AAB, Google conserve la clé de signature de
   l'application ; la clé d'upload ne sert qu'à authentifier les envois.
4. **Empreintes.** Ajouter les SHA-1 de la clé d'upload et de Play App Signing à la restriction de
   la clé d'API Android (console Google Cloud) et à l'application Android du projet Firebase (avec
   les SHA-256), puis la SHA-256 de Play App Signing dans `assetlinks.json` (Liens de l'app).

## Publication iOS

- **iPad seul** : `TARGETED_DEVICE_FAMILY = 2`, paysage, `UIRequiresFullScreen`. Les captures du
  store sont des captures iPad.
- **Signature** : équipe `H2B6ZK5Q35`, identifiant `fr.winafoot.app`, avec les capacités Push
  Notifications, App Attest et Associated Domains.
- **Push** : `Runner.entitlements` porte `aps-environment = development` pour les builds de
  développement ; à l'export pour l'App Store (`flutter build ipa`, ou Archive puis Distribute dans
  Xcode), la signature reprend la valeur `production` du profil de distribution. Une clé APNs
  (`.p8`) doit être enregistrée dans la console Firebase (Cloud Messaging).
- **Descriptions d'usage** : `Info.plist` déclare, en français, celles qu'exige le binaire (appareil
  photo, micro, photothèque, localisation pendant l'utilisation, Face ID). Le `Podfile` compile
  `permission_handler`, `file_picker` et `geolocator` sans les autorisations inutilisées.
- **App Attest** : environnement `production` dans `Runner.entitlements`.

## Tests

```bash
fvm flutter test
```

Tests unitaires et de widgets dans `test/` : modèles, règles de composition et de match en direct,
recherche, export PDF, clés de traduction, mise à jour forcée, stockage des identifiants de la
connexion biométrique, synchronisation de l'adresse e-mail. `test/e2e/` contient des parcours
pilotés par `adb` sur un émulateur tablette, avec captures d'écran (voir `test/e2e/README.md`).
