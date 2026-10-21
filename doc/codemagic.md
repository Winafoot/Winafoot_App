# Mise en place de Wina sur Codemagic

Le fichier `codemagic.yaml` (à la racine du dépôt) définit deux workflows, déclenchés par un tag `v*` :

| Workflow | Machine | Résultat |
|---|---|---|
| `android-release` | `linux_x2` | AAB signé, envoyé sur Google Play (piste **internal**, en brouillon) |
| `ios-release` | `mac_mini_m2` | IPA signée, envoyée sur **TestFlight** |

Les deux : `flutter pub get`, `flutter analyze`, `flutter test`, build, puis publication et e-mail à `mayaconnect2025@gmail.com`. Le projet Flutter est dans `app/` (`working_directory: app`).

Identifiants de l'app : `fr.winafoot.app` (Android et iOS), équipe Apple `H2B6ZK5Q35`, projet Firebase `wina-c4c4a`.

---

## 1. Avant de commencer (hors Codemagic)

- [ ] Le dépôt `Winafoot/Winafoot_App` sur GitHub contient bien `codemagic.yaml` (il est encore non suivi par git : le commiter et le pousser).
- [ ] `app/packages/*` (core_kosmos, kosmos_auth, skeleton, etc.) est commité : ce sont des dépendances `path:` du `pubspec.yaml`, le build échoue s'ils manquent.
- [ ] `google-services.json` et `GoogleService-Info.plist` sont commités (c'est le cas aujourd'hui).
- [ ] Un compte **Apple Developer** payant et un compte **Google Play Console** existent.
- [ ] L'app existe dans **App Store Connect** (Mes apps, bundle ID `fr.winafoot.app`) et dans la **Play Console**.

## 2. Connecter le dépôt

1. codemagic.io, **Add application**, choisir GitHub, autoriser l'accès au dépôt `Winafoot_App`.
2. Type de projet : **Flutter App**, et choisir la configuration **`codemagic.yaml`**.
3. Branche : celle qui porte le fichier (aujourd'hui `feature/inscription-coach`, à fusionner dans `main` avant de taguer).
4. Vérifier le webhook GitHub (Settings du dépôt, Webhooks) : sans lui, le tag ne déclenche rien.

## 3. Android

### 3.1 Keystore d'upload
1. Créer le keystore **hors du dépôt** (il ne doit jamais être commité, `.gitignore` l'exclut) :
   ```bash
   keytool -genkey -v -keystore winafoot-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Codemagic, **Teams, Code signing identities, Android keystores, Upload keystore**. Renseigner le fichier, son mot de passe, l'alias et le mot de passe de la clé.
3. **Nom de référence : `winafoot_keystore`** (c'est la valeur de `android_signing` dans le yaml, elle doit être identique).
4. Sauvegarder le `.jks` et les mots de passe dans un gestionnaire de mots de passe : perdre la clé d'upload oblige à passer par le support Google.

Le script « Signature (key.properties) » du yaml génère `android/key.properties` à partir des variables `CM_KEYSTORE_PATH`, `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, `CM_KEY_PASSWORD`, fournies par Codemagic. `android/app/build.gradle` refuse de produire un AAB sans ce fichier.

### 3.2 Publication Google Play
1. **Premier AAB à envoyer à la main** dans la Play Console (piste interne) : l'API Google Play ne peut pas créer la première version d'une app. Activer **Play App Signing** à ce moment.
2. Google Cloud Console : créer un **compte de service**, générer une clé JSON.
3. Play Console, **Utilisateurs et autorisations**, inviter ce compte de service avec le droit de publier des versions de l'app.
4. Codemagic, **Teams, Global variables and secrets** (ou variables de l'app), créer le groupe **`google_play`** avec la variable **`GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`** = contenu complet du JSON, cochée **Secure**.
5. Le yaml publie sur la piste `internal` en brouillon (`submit_as_draft: true`) : il faut valider la version dans la Play Console. Le brouillon est obligatoire tant que l'app n'a pas passé la première revue.

### 3.3 Empreintes (obligatoire pour Firebase et App Check)
Après le premier envoi, récupérer dans la Play Console (Intégrité de l'app, signature) les empreintes **SHA-1 et SHA-256 de Play App Signing**, puis :
- les ajouter à l'app Android du projet **Firebase** ;
- ajouter le SHA-1 à la restriction de la clé d'API Android (Google Cloud) ;
- ajouter le SHA-256 dans `assetlinks.json` (liens de l'app).

Sans cela, **Play Integrity (App Check) refuse les requêtes** de la version publiée, et comme les fonctions serveur exigent un jeton App Check, connexion, inscription et mot de passe oublié échouent avec « Une erreur est survenue ».

## 4. iOS

### 4.1 Clé API App Store Connect
1. App Store Connect, **Utilisateurs et accès, Intégrations, Clés API App Store Connect**, créer une clé avec le rôle **App Manager** (ou Admin). Télécharger le `.p8` (une seule fois), noter le **Issuer ID** et le **Key ID**.
2. Codemagic, **Teams, Integrations, Developer Portal (Apple)**, ajouter la clé.
3. **Nom : `winafoot_asc`** (valeur de `integrations.app_store_connect` dans le yaml).

### 4.2 Signature automatique
Le yaml demande `ios_signing: distribution_type: app_store` pour `fr.winafoot.app`. Codemagic crée ou récupère le certificat de distribution et le profil via la clé API ci-dessus. Rien à uploader à la main, sauf si vous préférez fournir votre propre certificat (Teams, Code signing identities, iOS).

Le bundle ID doit avoir ces capacités activées dans le Developer Portal (Identifiers) : **Push Notifications, App Attest, Associated Domains**.

### 4.3 Variable à corriger dans le yaml
`APP_STORE_APPLE_ID: 0000000000` est un **placeholder**. Remplacer par l'Apple ID numérique de l'app (App Store Connect, Informations sur l'app, Apple ID). Il n'est pas utilisé par les scripts actuels, mais à corriger avant de s'en servir.

### 4.4 Push et App Check
- Enregistrer la **clé APNs (`.p8`)** dans Firebase, Paramètres du projet, Cloud Messaging, sinon pas de notifications sur la version publiée.
- App Attest est utilisé en release : rien à configurer côté Codemagic, mais l'app iOS doit être enregistrée dans **Firebase App Check** avec le fournisseur App Attest.

## 5. Lancer un build

1. Mettre à jour la version dans `app/pubspec.yaml` (`version: 1.0.0+1`). Le numéro de build (après `+`) est **remplacé** par `$BUILD_NUMBER` de Codemagic à chaque build ; seule la partie `1.0.0` compte.
2. Taguer et pousser :
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. Les deux workflows démarrent. Suivi dans Codemagic, Builds. En cas de succès, e-mail reçu, l'AAB arrive sur Play (brouillon) et l'IPA sur TestFlight (traitement Apple 10 à 30 min).

On peut aussi lancer à la main : Codemagic, Start new build, choisir le workflow.

## 6. Points à vérifier dans le dépôt avant le premier build

1. **Deux fichiers Gradle coexistent** : `android/app/build.gradle` (applicationId `fr.winafoot.app`) et `android/app/build.gradle.kts` (applicationId `fr.winafoot.wina`, signature debug). Idem pour `settings.gradle` / `settings.gradle.kts`. Garder **un seul** format, avec `fr.winafoot.app`, sinon le build ou la signature peut viser le mauvais identifiant. Le `google-services.json` attend `fr.winafoot.app`.
2. **Chemin des artefacts** : dans Codemagic, les chemins `artifacts` sont relatifs à la racine du dépôt, pas à `working_directory`. `build/**/outputs/**/*.aab` ne trouvera probablement rien : utiliser `app/build/**/outputs/**/*.aab` et `app/build/ios/ipa/*.ipa`. Sans cela le build réussit mais rien n'est envoyé.
3. **`flutter analyze` et `flutter test` bloquent la publication** s'ils échouent. Lancer les deux en local avant de taguer.
4. **Version Flutter** : `flutter: stable` suit la dernière version stable. Si un build casse après une mise à jour de Flutter, figer une version précise (par ex. `flutter: 3.x.y`), compatible avec `sdk: ">=3.7.2 <4.0.0"`.
5. **Jetons de debug App Check** : retirer ceux enregistrés dans la console Firebase avant la publication (voir `server/README.md`, section App Check).

## 7. Checklist de résumé

| Élément | Où | Nom exact attendu |
|---|---|---|
| Keystore Android | Codemagic, Code signing | `winafoot_keystore` |
| Groupe de variables | Codemagic, variables | `google_play` |
| Variable secrète | dans ce groupe | `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` |
| Clé API Apple | Codemagic, Integrations | `winafoot_asc` |
| Bundle ID | Developer Portal | `fr.winafoot.app` |
| Apple ID de l'app | `codemagic.yaml` | remplacer `0000000000` |
| Empreintes Play App Signing | Firebase, Google Cloud, assetlinks | SHA-1 et SHA-256 |
| Clé APNs | Firebase, Cloud Messaging | `.p8` |
| Premier AAB | Play Console | envoi manuel |
