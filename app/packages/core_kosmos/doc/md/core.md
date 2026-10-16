# Créer un Projet - Kosmos Digital

- [Créer un Projet - Kosmos Digital](#créer-un-projet---kosmos-digital)
  - [Instancier un projet](#instancier-un-projet)
  - [Configurer Firebase](#configurer-firebase)
  - [Configurer les Clouds Functions](#configurer-les-clouds-functions)
  - [Configurer Apple Developper et Android](#configurer-apple-developper-et-android)
- [Configurer les Pushs Notifications](#configurer-les-pushs-notifications)
  - [Configurer le package de notification](#configurer-le-package-de-notification)
  - [Envoyer une notification](#envoyer-une-notification)
  - [Configurer la Cloud Functions](#configurer-la-cloud-functions)
- [Configurer le Router](#configurer-le-router)

## Instancier un projet

Dans la majorité des cas, lorsque vous prendrez un nouveau projet, celui-ci aura déjà ses repository créés et son code base (_uniquement si utilisation du skeleton_).

Le cas échéant, merci de vous rapprocher d'un de vos Chefs de projet technique afin de d'initialiser ce dernier.

**/!\ Attention**, afin d'avoir accès aux clouds functions et plusieurs exemples de codes, pensez à demander un accès au Github (Compte Reporter).

## Configurer Firebase

Le skeleton, ainsi que la plus grande partie des packages sont dépendants d'un Back-End Firebase (Firestore, Auth, Realtime, Storage, ..).
Il faut donc vérifier que les services suivants soient correctement initialiser et configurer :

1. _Firebase_Auth_ :

   - Connexion par email / mot de passe
   - Connexion par numéro de télphone (uniquement si présent dans maquette /CDC)
   - Connexion Google / Apple (uniquement si présent dans CDC)

2. Firebase_Firestore :
   - Firebase instancier dans une région Europe
   - Règle de sécurité correctement instancier (voir avec un Chef de projet)
   - Metadata du projet correctement setup (_voir exemple ci-dessous_).

```JSON
// Pour configurer les metadatas nécessaire à votre projet, merci de prendre exemple sur l'aborescence ci-dessous.

1. Créer une collection "app_config" au root.
2. Créer un document avec pour ID "metadata" dans cette collection.
3. Votre document doit comporter les élements suivants :

{
    "appName": "Your_app_name",

    "baseUrl": "https://console.(...)/...", // Doit correspondre à l'URL de votre Firebase Firestore, trouvable dans la barre de recherche de votre navigateur lorsque vous êtes au root de votre Firestore.

    "storageUrl": "https://console.(...)/...", // Doit correspondre à l'URL de votre Firebase Storage, trouvable dans la barre de recherche de votre navigateur lorsque vous êtes au root de votre Storage.

    "contactEmail": "contact@example.com", // Email de contact de l'application. Celle-ci sera majoritairement utilisé pour les emails automatiques de votre application.

    "contactPhone": "+33600000000", // Numéro de téléphone de l'application.

    "mail": {
        "from": "noreply@example.com",
        "fromName": "Nom de l'application",
        "replyTo": "contact@example.com"
    }, // Correspond à la configurationd des emails automatiques de votre projet. "from" et "fromName" sont les informations du sender et "replyTo" permet de définir à qui l'utilisateur peut répondre. par défaut cette valeur doit être nulle ou égale à l'emaildu support de votre projet.

    "passwordSecurityConfig": {
        "atLeast1Character": true,
        "atLeast1Number": true,
        "atLeast1SpecialCharacter": false,
        "atLeast1Uppercase": true,
        "atLeast6Character": true,
    }, // Permet de configurer la force / sécurité du mot de passe de la solution. Cela influera également sur l'affichage des erreurs de mot de passe dans la création de compte et la page de changement de ce dernier.

    "cgvu": "<p>Texte HTML</p>", // Permet de définir les CGVUs de l'application. au format HTML
    "confidentialityPolicy": "<p>Texte HTML</p>", // Permet de définir les Politiques de confidentialité de l'application. au format HTML
    "legalNotice": "<p>Texte HTML</p>", // Permet de définir les mentions légales de l'application. au format HTML
    "about": "<p>Texte HTML</p>", // Permet de définir les inforamtions "À propos" de l'application. au format HTML

    // Les champs suivants permettent de configurer les informations des réseaux sociaux de l'application.
    "facebookUrl": "https://www.facebook.com/",
    "instagramUrl": "https://www.instagram.com/",
    "snapchatUrl": "https://www.snapchat.com/",
    "twitterUrl": "https://www.twitter.com/",
    "youtubeUrl": "https://www.youtube.com/",
    "linkedinUrl": "https://www.linkedin.com/",
}
```

Afin de correctement charger ces données, la ligne `onInit: () async => AppMetadataController.stockMetadataForApp()` doit être présente dans votre main.dart.

```Dart
return Application.launch(
    ..., // Autres configurations
    onInit: () async => AppMetadataController.stockMetadataForApp(),
);
```

---

## Configurer les Clouds Functions

Plusieurs Clouds Functions doivent être présente dans votre projet pour que ce dernier fonctionne correctement.
**_Si des clouds functions sont manquantes, vous devez les récupérer depuis l'exemple du package Skeleton._**

**/!\ Attention**, vous devez également configuré la clé MailerSend pour pouvoir utiliser les fonctions d'email.

Pour configurer la clé `MailerSend` merci d'utiliser la commande suivante:

```Shell
firebase functions:config:set "mailer.api_key"=<key_value>
```

1. Callable d'authentification

Les fonctions d'authentification du skeleton ont besoin de vérifier que le numéro de téléphone et l'adresse e-mail soient disponible dans les bases de données.

```Typescript
export const emailIsAlreadyUsed = https.onCall(lazy('./callables/auth/email_is_already_used'));
export const phoneIsAlreadyUsed = https.onCall(lazy('./callables/auth/phone_is_already_used'));
```

2. Email Automatique

Afin de remplacer les emails d'authentication et/ou modification de mot de passe et email.

```Typescript
export const sendEmailVerification = https.onCall(lazy('./callables/auth/send_email_verification'));
export const sendResetPassword = https.onCall(lazy('./callables/auth/send_reset_password'));
export const sendChangeEmail = https.onCall(lazy('./callables/auth/send_change_email'));
```

3. Configurer Triggers pour l'email de bienvenue

À chaque inscription d'un nouvel utilisateur, un email générique de bienvenue doit être envoyé.
Afin de configurer ce dernier, il doit être en mode Triggers :

```Typescript
export const sendWelcomeEmail = firestore
  .document("users/{userId}")
  .onCreate(lazy("./triggers/auth/send_welcome_email"));
```

4. Configurer la modification des CGVUs

Lorsque le propriétaire de votre projet souhaite modifier ses CGVUs (via son Firebase), celle-ci doivent être re-accepté par chaque utilisateur de l'application.

Afin de notifier les utilisateurs de ce changement, vous devez configurer l'événement suivant :

```Typescript
export const cgvuIsUpdated = firestore
  .document("app_config/{document}")
  .onUpdate(lazy("./triggers/core/update_cgu"));
```

---

## Configurer Apple Developper et Android

Dès le lancement de l'application vous devez paramètrer les configurations et permissions de votre application.

1. IOS / Apple

Afin que les packages et votre projet fonctionne correctement sur IOS vous devez vérifier et configurer si besoin les éléments suivants :

- GoogleService-Info.plist présent et importer dans XCode.
- Push Notifications ajouté dans les `Singning & Capabilities`. **Uniquement si push notification dans votre application**
- Background Modes (avecbackground Fetch & Remote notications) ajouté dans les `Singning & Capabilities`. **Uniquement si push notification dans votre application**
- `CFBundleURLSchemes` (pour la connexion par numéro de téléphone) configuré dans le Info.plist :

```plist
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_GOOGLE_REVERSE_ID</string>
        </array>
    </dict>
</array>
```

**/!\ Attention**, vous devrez également configurer les permissions en fonction des packages que vous utilisez.

---
----
# Configurer les Pushs Notifications

Les Pushs Notifications sont nativement intégrées dans le *Skeleton*. Par défaut, le skeleton affichera la notification via le package `flutter_local_notification` une fois que celle-ci est reçu.

Vous pouvez toutefois configuré cet événement via la configuration.

**/!\ Attention**, afin de configurer les pushs notifications vous devez avoir suivi les étapes [Configurer Apple Developper et Android](#configurer-apple-developper-et-android). Vous devez également avoir généré les APNs Tokens sur [Apple Developer](https://appstoreconnect.apple.com/) et les avoir upload sur Firebase.

---
## Configurer le package de notification

1. Initialiser la configuration.

Pour configurer le package de notification vous devez utiliser un objet `EventConfiguration` dans la configuration des packages.

```Dart
"kosmos_event_config": EventConfiguration(
    enablePushNotificationConfig: true, // Permet d'activer le pushs notifications
    ...,
),
```

2. Modifier le callback lors de la réception.

Par défaut, les notifications sont affichées via le package `flutter_local_notification`, vous pouvez cependant configurer votre propre callback via la méthode `onMessage`.

```Dart
onMessage: (RemoteMessage message) {
    // j'affiche mon propre message
},
```

3. Configurer les évenements des notifications.

Vous pouvez configurer les événements lorsqu'on clique sur le message.

```Dart
// L'application est déjà lancé, mais on clique sur les données.
onTapWhenLaunched: (Map<dynamic, dynamic> messageData) {
    printDebug(messageData);
},
// L'application est en background, on ouvre donc l'application et éxécute la fonction.
onMessageBackground: (RemoteMessage message) {
    printDebug(message.data);
},
```

---
## Envoyer une notification

Afin d'envoyer une notification, vous ne devez que l'upload, sous forme de Document, sur la collection "notifications" sur FirebaseFirestore.

Vous avez à votre disposition la méthode `NotifPermissionController.sendNotification` pour pouvoir uploader automatiquement la notification.

```Dart
floatingActionButton: FloatingActionButton(
child: const Icon(Icons.notification_add_outlined),
    onPressed: () async {
        NotifPermissionController.sendNotification(
            [FirebaseAuth.instance.currentUser!.uid], // ID des utilisateurs qui doivent recevoir la notification
            title: "Test DEV TITLE",
            body: "Test DEV",
            type: "test", // Permet de définir / filtrer les notifications
            metadata: {"type": "test"}, // Données supplémentaires à fournir via la notification.
        );
    },
),
```

Les utilisateurs ne recevront la notification que si ces derniers n'ont autorisé les pushs notifications.

---
## Configurer la Cloud Functions

Une fois la notifiation uploadé sur Firestore, celle-ci va être envoyé par une Cloud Functions.

Afin de configuré cette dernière, vous devez l'ajouter et ajouter le triggers suivant :

```Typescript
export const sendPushNotification = firestore
  .document("notifications/{notificationId}")
  .onCreate(lazy("./triggers/event/on_notification"));
```

Vous êtes libre de modifier la fonction en fonction de votre projet.

---
---
# Configurer le Router

Votre projet, et ses packages doivent intégralement fonctionné via le package `auto_router`.
La plus grande partie des routes des skelettes doivent suivre une nomenclature stricte.

**/!\ Attention**, la plus grande partie des transitions des routes utilise le système de Push: `AutoRouter.of(context).push(...)`, vous devez docn faire attention au logique de navigation en arrière de vos page.

1. Router Principal

Vous trouverez ci-dessous une configuration standart du Router.

```Dart
import 'package:skeleton/skeleton.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    
    ...,

    /// Si la route est inconnu, nous redirigeons vers la route principale
    RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class $AppRouter {
  $AppRouter();
}
```

2. Route d'authentification & de page légale

Vous trouverez ci-dessous les routes des pages d'authentication, ainsi que la page permettant d'afficher les textes légaux de l'application.

```Dart
@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    /// Auth Route
    AutoRoute(
      path: "/auth",
      page: AuthParentPage,
      guards: [IsNotConnectedGuard], // Permet d'accéder d'afficher la page uniquement si l'utilisateur n'est pas connecté. Le cas échéant, nous redirigeons vers la page principale de l'application.
      children: [
        AutoRoute(path: "login", page: LoginPage, initial: true),
        AutoRoute(path: "login-with-phone", page: PhoneLoginPage),
        AutoRoute(path: "create-account", page: CreateAccountPage),
      ],
    ),

    /// App Legal Route
    AutoRoute(path: "legal-information/:info", page: LegalInformationPage),
  ],
)
```

3. Page parent de l'application

Plusieurs fonctionnalité sont intialiser par les Page Parent.

```Dart
@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    /// Profil Completion Route
    AutoRoute(path: "profil-completion", page: CompleteProfilDefaultDataPage),

    AutoRoute(
      path: "app",
      page: LoggedUserAppCorePage, // ou MaybeLoggedUserAppCorePage
      initial: true,
      guards: [IsConnectedGuard], // Permet d'afficher les page uniquement si l'utilisateur est connecté. Si vous devez utilisé une MaybeLoggedUserAppCorePage, vous devez retiré ce guard et le mettre uniquement sur les pages en ayant besoin. Exemple, les pages de profil.
      children: [
        
        ...,

        /// Page de profil
        AutoRoute(
          path: "profile",
          page: ProfileParentPage,
          guards: [IsConnectedGuard],
          children: [
            /// Page des settings
            AutoRoute(path: "settings", page: SettingsPage, initial: true),
            AutoRoute(path: "settings/:nodeTag", page: SubNodePage),

            /// Page de changement de données de sécurité.
            AutoRoute(path: "security/email", page: ChangeEmailPage),
            AutoRoute(path: "security/password", page: ChangePasswordPage),
            AutoRoute(path: "security/phone-number", page: ChangePhonePage),
          ],
        ),
      ],
    ),
  ],
)
```