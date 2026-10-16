# Kosmos Auth Package

Package d'authentification Firebase pour les applications Kosmos Digital.

---

## 📋 Description

Ce package fournit une abstraction complète pour gérer l'authentification Firebase, incluant :
- Connexion par email/mot de passe
- Connexion par numéro de téléphone (SMS)
- Connexion via Google Sign-In
- Connexion via Apple Sign-In
- Gestion des erreurs d'authentification localisées
- Vérification d'email et réinitialisation de mot de passe

---

## ⚙️ Configuration

### Clé de configuration
**Aucune clé de configuration requise** - Ce package est stateless et n'utilise pas le système `PackageConfig`.

### Dépendances requises
```yaml
dependencies:
  kosmos_auth:
    git:
      url: git@github.com:KosmosDigital06270/Package-Auth.git
      ref: v7
```

### Cloud Functions requises
Les fonctions suivantes doivent être déployées sur Firebase :
- `emailIsAlreadyUsed` - Vérifie si un email existe déjà
- `phoneIsAlreadyUsed` - Vérifie si un numéro de téléphone existe déjà
- `sendEmailVerification` - Envoi d'email de vérification personnalisé
- `sendResetPassword` - Envoi d'email de réinitialisation de mot de passe
- `sendChangeEmail` - Envoi d'email pour changement d'adresse
- `deleteAccount` - Suppression de compte utilisateur

---

## 🎨 Thèmes

**Aucun thème spécifique** - Ce package ne définit pas de thème propre.

---

## 📖 Usage

### Connexion par email
```dart
final result = await KosmosAuth.signInWithEmail(email, password);
result.fold(
  (error) => print("Erreur: $error"),
  (credential) => print("Connecté: ${credential?.user?.uid}"),
);
```

### Création de compte par email
```dart
final result = await KosmosAuth.signUpWithEmail(email, password);
result.fold(
  (error) => print("Erreur: $error"),
  (credential) => print("Compte créé: ${credential?.user?.uid}"),
);
```

### Connexion par téléphone
```dart
await KosmosAuth.verifPhoneNumberAndGetCredential(
  phone: "+33612345678",
  connexionDone: (credential) => print("Connecté"),
  codeSent: (verificationId, resendToken) => print("Code envoyé"),
  redirectAfterTimeOut: () => print("Timeout"),
  setLoading: () => print("Chargement..."),
);
```

### Connexion Google
```dart
final googleUser = await KosmosAuth.getGoogleCredential();
if (googleUser != null) {
  final result = await KosmosAuth.signInWithGoogle(googleUser);
  result.fold(
    (error) => print("Erreur: $error"),
    (credential) => print("Connecté via Google"),
  );
}
```

### Connexion Apple
```dart
final rawNonce = KosmosAuth.generateNonce();
final nonce = KosmosAuth.sha256ofString(rawNonce);
final appleCredential = await KosmosAuth.getAppleCredential(rawNonce, nonce);
if (appleCredential != null) {
  final result = await KosmosAuth.signInWithApple(appleCredential, rawNonce);
}
```

### Réinitialisation de mot de passe
```dart
final result = await KosmosAuth.resetPassword(email, region: 'europe-west1');
```

### Mise à jour du mot de passe
```dart
final error = await KosmosAuth.updatePassword(email, oldPassword, newPassword);
if (error == null) print("Mot de passe mis à jour");
```

---

## 🔗 Intégration avec Skeleton

Ce package est utilisé par le package `skeleton` pour les pages d'authentification :
- `LoginPage` - Page de connexion
- `CreateAccountPage` - Page de création de compte
- `PhoneLoginPage` - Connexion par téléphone
- `ResetPasswordPage` - Réinitialisation du mot de passe

---

## 📚 API Principale

| Méthode | Description |
|---------|-------------|
| `signInWithEmail` | Connexion email/password |
| `signUpWithEmail` | Création de compte email |
| `signInWithPhone` | Connexion après vérification SMS |
| `signUpWithPhone` | Création de compte par téléphone |
| `resetPassword` | Envoi email de reset |
| `deleteAccount` | Suppression du compte |
| `phoneDoesExist` | Vérifie si téléphone existe |
| `emailDoesExist` | Vérifie si email existe |
| `signInWithGoogle` | Connexion Google |
| `signInWithApple` | Connexion Apple |
| `updatePassword` | Modification mot de passe |
| `updateEmail` | Modification email |
| `updatePhoneNumber` | Modification téléphone |

---

## 🌐 Traductions requises

```
package.kosmos-auth.error-internet
package.kosmos-auth.user-not-found
package.kosmos-auth.error-default
```
