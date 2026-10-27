import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class FirebaseErrorHandler {
  static String getErrorMessage(FirebaseAuthException error) {
    final String? known = {
      // Firebase renvoie `invalid-credential` pour un mot de passe OU un identifiant incorrect (il ne dit plus
      // lequel, par sécurité) : le message doit couvrir les deux.
      "invalid-credential": "package.kosmos-auth.wrong-credentials".tr(),
      "invalid-login-credentials": "package.kosmos-auth.wrong-credentials".tr(),
      "invalid-email": "package.kosmos-auth.user-not-found".tr(),
      "user-disabled": "package.kosmos-auth.user-disabled".tr(),
      "user-not-found": "package.kosmos-auth.user-not-found".tr(),
      "wrong-password": "package.kosmos-auth.wrong-password".tr(),
      "email-already-in-use": "package.kosmos-auth.email-already-in-use".tr(),
      "operation-not-allowed": "package.kosmos-auth.error-default".tr(),
      "account-exists-with-different-credential":
          "package.kosmos-auth.account-exists-with-different-credential".tr(),
      "requires-recent-login": "package.kosmos-auth.requires-recent-login".tr(),
      "invalid-verification-code":
          "package.kosmos-auth.invalid-verification-code".tr(),
      "invalid-verification-id":
          "package.kosmos-auth.invalid-verification-id".tr(),
      "invalid-phone-number": "package.kosmos-auth.invalid-phone-number".tr(),
      "too-many-requests": "package.kosmos-auth.too-many-requests".tr(),
      "network-request-failed":
          "package.kosmos-auth.network-request-failed".tr(),
    }[error.code];
    // Code inconnu : le code est affiché, pour que l'erreur soit identifiable plutôt que « Une erreur est survenue ».
    return known ??
        "package.kosmos-auth.error-with-code".tr(args: <String>[error.code]);
  }
}
