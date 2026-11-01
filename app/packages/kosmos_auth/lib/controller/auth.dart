import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart' show Either, Right, Left;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kosmos_auth/utils/error_handler.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// {@category Controller}
/// {@category Auth}
///
/// Cette class permet de gérer l'authentification et les sytèmes de [FirebaseAuth]
///
/// - [getEmailFromIdentifier] permet de récupérer l'adresse email de l'utilisateur via son "identifier" stocké sur [FirebaseFirestore]
/// - [signInWithEmail] permet de se connecter en utilisant un email et un mot de passe
/// - [signInWithPhone] permet de se connecter en utilisant un numéro de téléphone
/// - [signUpWithEmail] permet de créer un compte en utilisant un email et un mot de passe
/// - [signUpWithPhone] permet de créer un compte en utilisant un numéro de téléphone
/// - [resetPassword] permet d'envoyer un email pour réinitialiser le mot de passe (via l'email custom au sein de la cloud Function)
/// - [phoneDoesExist] permet de vérifier si un numéro de téléphone existe déjà dans la base de données
/// - [emailDoesExist] permet de vérifier si un email existe déjà dans la base de données
/// - [deleteAccount] permet de supprimer le compte de l'utilisateur
/// - [verifPhoneNumberAndGetCredential] permet de vérifier un numéro de téléphone et de récupérer le code de vérification
/// - [getGoogleCredential] permet de récupérer les informations de l'utilisateur via Google
/// - [getAppleCredential] permet de récupérer les informations de l'utilisateur via Apple
/// - [linkCurrentUserWithGoogleCredential] permet de lier le compte actuel de l'utilisateur avec un compte Google
/// - [linkCurrentUserWithAppleCredential] permet de lier le compte actuel de l'utilisateur avec un compte Apple
/// - [signInWithGoogle] permet de se connecter via Google
/// - [signInWithApple] permet de se connecter via Apple
/// - [sendEmailVerification] permet d'envoyer un email de vérification
/// - [sendEmailChange] permet d'envoyer un email de changement d'adresse email
/// - [updatePassword] permet de mettre à jour le mot de passe de l'utilisateur
/// - [updateEmail] permet de mettre à jour l'adresse email de l'utilisateur
/// - [updatePhoneNumber] permet de mettre à jour le numéro de téléphone de l'utilisateur
/// - [verifyPhoneNumberAndLinkToCurrentAccount] permet de vérifier un numéro de téléphone et de lier le compte actuel de l'utilisateur
///
abstract class KosmosAuth {
  /// Afin de faire fonctionner l'authentification par identifiant, vous
  /// devez récupérer l'email de l'utilisateur via son document [FirebaseFirestore].
  ///
  /// Par défaut, le nom de la collection est "users" mais vous pouvez le changer.
  ///
  /// /!\ Attention, l'identiant doit être unique pour chaque utilisateur et doit
  /// être stocké dans le document de l'utilisateur sous le nom "identifier"
  ///
  /// Une fois l'email en votre possession, vous pouvez vous connecter normalement
  /// via la fonction [FirebaseAuth.signInWithEmailAndPassword].
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<Either<String, String?>> getEmailFromIdentifier(
      String identifier,
      [String userCollection = "users"]) async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return Left("package.kosmos-auth.error-internet".tr());
      }

      final res = await FirebaseFirestore.instance
          .collection(userCollection)
          .where("identifier", isEqualTo: identifier)
          .get();
      if (res.docs.isEmpty) {
        return Left("package.kosmos-auth.user-not-found".tr());
      }
      return Right(res.docs.first.get("email"));
    } on FirebaseAuthException catch (e) {
      printExcept("[FirebaseException] ${e.message}");
      return Left(FirebaseErrorHandler.getErrorMessage(e));
    } catch (e) {
      printExcept(e);
      return Left("package.kosmos-auth.error-default".tr());
    }
  }

  /// Permet de se connecter en utilisant un email et un mot de passe.
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<Either<String, UserCredential?>> signInWithEmail(
      String email, String password) async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return Left("package.kosmos-auth.error-internet".tr());
      }

      final UserCredential user = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      return Right(user);
    } on FirebaseAuthException catch (e) {
      printExcept("[FirebaseException] ${e.message}");
      return Left(FirebaseErrorHandler.getErrorMessage(e));
    } catch (e) {
      printExcept(e);
      return Left("package.kosmos-auth.error-with-code"
          .tr(args: <String>[e.runtimeType.toString()]));
    }
  }

  /// Permet de se connecter en utilisant un numéro de téléphone
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<Either<String, UserCredential?>> signInWithPhone({
    required String codeId,
    required String code,
  }) async {
    try {
      final AuthCredential credential =
          PhoneAuthProvider.credential(verificationId: codeId, smsCode: code);
      final user = await FirebaseAuth.instance.signInWithCredential(credential);
      return Right(user);
    } on FirebaseAuthException catch (e) {
      printExcept(e);
      return Left(FirebaseErrorHandler.getErrorMessage(e));
    } catch (e) {
      printExcept(e);
      return Left("package.kosmos-auth.error-default".tr());
    }
  }

  /// Permet de créer un compte en utilisant un email et un mot de passe.
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<Either<String, UserCredential?>> signUpWithEmail(
      String email, String password,
      [bool sendVerificationEmail = true]) async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return Left("package.kosmos-auth.error-internet".tr());
      }

      final UserCredential user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: email.trim(), password: password);
      return Right(user);
    } on FirebaseAuthException catch (e) {
      printExcept("[FirebaseException] ${e.message}");
      return Left(FirebaseErrorHandler.getErrorMessage(e));
    } catch (e) {
      printExcept(e);
      return Left("package.kosmos-auth.error-default".tr());
    }
  }

  /// Permet de créer son compte en utilisant un numéro de téléphone.
  /// Une fois le compte créé, l'email et le mot de passe sont automatiquement
  /// ajouté au compte pour permettre l'authentification par email / mot de passe.
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<Either<String, UserCredential?>> signUpWithPhone({
    required String codeId,
    required String code,
    String? email,
    String? password,
  }) async {
    try {
      final AuthCredential credential =
          PhoneAuthProvider.credential(verificationId: codeId, smsCode: code);
      final user = await FirebaseAuth.instance.signInWithCredential(credential);

      if (email != null && password != null) {
        final emailCredential =
            EmailAuthProvider.credential(email: email, password: password);
        await user.user!.linkWithCredential(emailCredential);
      }
      return Right(user);
    } on FirebaseAuthException catch (e) {
      printExcept(e);
      return Left(FirebaseErrorHandler.getErrorMessage(e));
    } catch (e) {
      printExcept(e);
      return Left("package.kosmos-auth.error-default".tr());
    }
  }

  /// Envoi un email de réinitialisation de mot de passe.
  /// L'email est un template customiser disponible au sein de la cloud
  /// function: "sendResetPassword".
  ///
  /// /!\ Attention, la cloud function doit forcément être upload sur Firebase.
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<Either<String, bool>> resetPassword(String email,
      {String region = 'us-central1'}) async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return Left("package.kosmos-auth.error-internet".tr());
      }

      final res = await FirebaseFunctions.instanceFor(region: region)
          .httpsCallable("sendResetPassword")
          .call({"email": email});
      if (res.data is bool) return Right(res.data as bool);
      return const Right(false);
    } on FirebaseAuthException catch (e) {
      printExcept("[FirebaseException] ${e.message}");
      return Left(FirebaseErrorHandler.getErrorMessage(e));
    } catch (e) {
      printExcept(e);
      return Left("package.kosmos-auth.error-default".tr());
    }
  }

  /// Termine une réinitialisation de mot de passe : échange le code à 6 chiffres
  /// reçu par e-mail (voir [resetPassword]) contre un nouveau mot de passe.
  ///
  /// /!\ Attention, la cloud function "confirmPasswordReset" doit forcément être
  /// upload sur Firebase.
  ///
  /// Renvoie `Right(true)` si le mot de passe a été changé, sinon `Left` avec un
  /// message affichable (code invalide ou expiré, mot de passe refusé...).
  static Future<Either<String, bool>> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
    String region = 'us-central1',
  }) async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return Left("package.kosmos-auth.error-internet".tr());
      }

      final res = await FirebaseFunctions.instanceFor(region: region)
          .httpsCallable("confirmPasswordReset")
          .call({"email": email, "code": code, "newPassword": newPassword});
      return Right(res.data == true);
    } on FirebaseFunctionsException catch (e) {
      printExcept("[FirebaseFunctionsException] ${e.code} ${e.message}");
      return Left(_codeErrorMessage(e));
    } catch (e) {
      printExcept(e);
      return Left("package.kosmos-auth.error-default".tr());
    }
  }

  /// Vérifie l'adresse e-mail du compte connecté avec le code à 6 chiffres reçu
  /// par [sendEmailVerification].
  ///
  /// /!\ Attention, la cloud function "verifyEmailCode" doit forcément être
  /// upload sur Firebase.
  ///
  /// Renvoie `Right(true)` quand l'adresse est vérifiée, sinon `Left` avec un
  /// message affichable. Le jeton est rafraîchi pour que `emailVerified` soit à
  /// jour côté client.
  static Future<Either<String, bool>> verifyEmailCode(String code,
      {String region = 'us-central1'}) async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return Left("package.kosmos-auth.error-internet".tr());
      }

      final res = await FirebaseFunctions.instanceFor(region: region)
          .httpsCallable("verifyEmailCode")
          .call({"code": code});
      if (res.data != true) {
        return Left("package.kosmos-auth.error-default".tr());
      }
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      await user?.getIdToken(true);
      return const Right(true);
    } on FirebaseFunctionsException catch (e) {
      printExcept("[FirebaseFunctionsException] ${e.code} ${e.message}");
      return Left(_codeErrorMessage(e));
    } catch (e) {
      printExcept(e);
      return Left("package.kosmos-auth.error-default".tr());
    }
  }

  /// Message affichable d'un refus de "verifyEmailCode" / "confirmPasswordReset".
  static String _codeErrorMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'invalid-argument':
        final message = e.message?.trim();
        return message != null && message.isNotEmpty
            ? message
            : "package.kosmos-auth.error-default".tr();
      case 'resource-exhausted':
        return "package.kosmos-auth.too-many-requests".tr();
      default:
        return "package.kosmos-auth.error-default".tr();
    }
  }

  /// One-Time Data Sharing: Apple provides the user's email address only during the first authentication. After that, subsequent sign-ins will not include the email field in the credential response.
  /// so we must store this email in databse with
  static Future<bool> storeEmailInDatabse(
    String appleUserIdentifier,
    String email,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection("AppleEmailStore")
          .doc(appleUserIdentifier)
          .set({
        "email": email,
      });

      return true;
    } catch (e) {
      printExcept(e);
      return false;
    }
  }

  static Future<String?> getAppleEmailFromDatabase(
    String appleUserIdentifier,
  ) async {
    try {
      final data = await FirebaseFirestore.instance
          .collection("AppleEmailStore")
          .doc(appleUserIdentifier)
          .get();
      String? email = data.get("email");
      return email;
    } catch (e) {
      printExcept(e);
      return null;
    }
  }

  /// Supprime le compte de l'utilisateur et les données de la base de donnée.
  /// Une fois le compte supprimé, une ligne contenant l'email, l'UID ainsi que la date
  /// de suppression de l'utilisateur est ajouté dans la base de donnée Firebase. (dans la
  /// collection "deleted_users")
  ///
  /// /!\ Attention, la cloud function doit forcément être upload sur Firebase.
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<Either<String, bool>> deleteAccount(String uid,
      {String region = 'us-central1'}) async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return Left("package.kosmos-auth.error-internet".tr());
      }

      final res = await FirebaseFunctions.instanceFor(region: region)
          .httpsCallable("deleteAccount")
          .call({"uid": uid});
      if (res.data is bool) return Right(res.data as bool);
      return const Right(false);
    } on FirebaseAuthException catch (e) {
      printExcept("[FirebaseException] ${e.message}");
      return Left(FirebaseErrorHandler.getErrorMessage(e));
    } catch (e) {
      printExcept(e);
      return Left("package.kosmos-auth.error-default".tr());
    }
  }

  /// Envoit un email pour confirmer son adresse email.
  /// L'email est un template customiser disponible au sein de la cloud
  /// function: "sendEmailVerification".
  ///
  /// /!\ Attention, la cloud function doit forcément être upload sur Firebase.
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<bool> sendEmailVerification(String uid,
      {String region = 'us-central1'}) async {
    try {
      final data = await FirebaseFunctions.instanceFor(region: region)
          .httpsCallable("sendEmailVerification")
          .call({"uid": uid});
      if (data.data is bool) return data.data;
      return true;
    } catch (e) {
      printExcept(e);
      return false;
    }
  }

  /// Envoit un email pour confirmer le changement d'adresse email.
  /// L'email est un template customiser disponible au sein de la cloud
  /// function: "sendChangeEmail".
  ///
  /// /!\ Attention, la cloud function doit forcément être upload sur Firebase.
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<bool> sendEmailChange(String uid, String email,
      {String region = 'us-central1'}) async {
    try {
      final data = await FirebaseFunctions.instanceFor(region: region)
          .httpsCallable("sendChangeEmail")
          .call({"uid": uid, "newEmail": email});
      if (data.data is bool) return data.data;
      return true;
    } catch (e) {
      printExcept(e);
      return false;
    }
  }

  /// Permet de vérifier si le numéro de téléphone existe déjà dans la base de donnée.
  ///
  /// /!\ Attention, nous vérifions si le numéro de téléphone existe dans [FirebaseAuth].
  ///
  /// Cette fonction utilise une cloud function qui doit forcément être upload sur Firebase.
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<Either<String, bool>> phoneDoesExist(String phone,
      {String region = 'us-central1'}) async {
    try {
      final res = await FirebaseFunctions.instanceFor(region: region)
          .httpsCallable("phoneIsAlreadyUsed")
          .call({"phone": phone});
      if (res.data is bool) return Right(res.data as bool);
      return const Right(false);
    } catch (e) {
      printExcept(e);
      return Left("package.kosmos-auth.error-default".tr());
    }
  }

  /// Permet de vérifier si l'email existe déjà dans la base de donnée.
  ///
  /// /!\ Attention, nous vérifions si l'email existe dans [FirebaseAuth].
  ///
  /// Cette fonction utilise une cloud function qui doit forcément être upload sur Firebase.
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<Either<String, bool>> emailDoesExist(String email,
      {String region = 'us-central1'}) async {
    try {
      final res = await FirebaseFunctions.instanceFor(region: region)
          .httpsCallable("emailIsAlreadyUsed")
          .call({"email": email});
      if (res.data is bool) return Right(res.data as bool);
      return const Right(false);
    } catch (e) {
      printExcept(e);
      return Left("package.kosmos-auth.error-default".tr());
    }
  }

  static int? forceResendingToken;

  /// Permet d'envoyer un code de vérification par SMS.
  ///
  ///
  static Future<void> verifPhoneNumberAndGetCredential({
    required String phone,
    required Function(UserCredential credential) connexionDone,
    required Function(String verificationId, int? forecResendToken) codeSent,
    required Function redirectAfterTimeOut,
    required Function setLoading,
    void Function(FirebaseAuthException e)? verificationFailed,
    void Function(FirebaseAuthException e)? verificationError,
    void Function(String verificationId)? codeAutoRetrievalTimeout,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 120),
      forceResendingToken: forceResendingToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          UserCredential userCred =
              await FirebaseAuth.instance.signInWithCredential(credential);
          connexionDone(userCred);
        } on FirebaseAuthException catch (e) {
          if (verificationError != null) {
            verificationError(e);
          }
        }
      },
      verificationFailed: verificationFailed ?? (_) {},
      codeSent: (String verifCode, int? resendToken) {
        forceResendingToken = resendToken;
        codeSent(verifCode, forceResendingToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  static Future<void> verifyPhoneNumberAndLinkToCurrentAccount({
    required String phone,
    required Function(PhoneAuthCredential credential) connexionDone,
    required Function(String verificationId, int? forecResendToken) codeSent,
    required Function redirectAfterTimeOut,
    required Function setLoading,
    void Function(FirebaseAuthException e)? verificationFailed,
    void Function(FirebaseAuthException e)? verificationError,
    void Function(String verificationId)? codeAutoRetrievalTimeout,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 120),
      forceResendingToken: forceResendingToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await FirebaseAuth.instance.currentUser!
              .linkWithCredential(credential);
          connexionDone(credential);
        } on FirebaseAuthException catch (e) {
          if (verificationError != null) {
            verificationError(e);
          }
        }
      },
      verificationFailed: verificationFailed ?? (_) {},
      codeSent: (String verifCode, int? resendToken) {
        forceResendingToken = resendToken;
        codeSent(verifCode, forceResendingToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// Update PhoneNumber
  ///
  ///
  static Future<void> verifPhoneNumberAndUpdate({
    required String phone,
    required Function(PhoneAuthCredential credential) connexionDone,
    required Function(String verificationId, int? forecResendToken) codeSent,
    required Function redirectAfterTimeOut,
    required Function setLoading,
    void Function(FirebaseAuthException e)? verificationFailed,
    void Function(FirebaseAuthException e)? verificationError,
    void Function(String verificationId)? codeAutoRetrievalTimeout,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 120),
      forceResendingToken: forceResendingToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await FirebaseAuth.instance.currentUser!
              .updatePhoneNumber(credential);
          connexionDone(credential);
        } on FirebaseAuthException catch (e) {
          if (verificationError != null) {
            verificationError(e);
          }
        }
      },
      verificationFailed: verificationFailed ?? (_) {},
      codeSent: (String verifCode, int? resendToken) {
        forceResendingToken = resendToken;
        codeSent(verifCode, forceResendingToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  static Future<Either<String, UserCredential?>>
      linkEmailAuthProviderWithCurrentUser({
    UserCredential? user,
    String? email,
    String? password,
  }) async {
    try {
      if (email != null && password != null && user != null) {
        final emailCredential =
            EmailAuthProvider.credential(email: email, password: password);
        await user.user!.linkWithCredential(emailCredential);
      }
      return Right(user);
    } on FirebaseAuthException catch (e) {
      printExcept(e);
      return Left(FirebaseErrorHandler.getErrorMessage(e));
    } catch (e) {
      printExcept(e);
      return Left("package.kosmos-auth.error-default".tr());
    }
  }

  /// Permet de demande à l'utilisateur de choisir un compte google et de
  /// récupérer les crédentials.
  ///
  static Future<GoogleSignInAccount?> getGoogleCredential() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      return googleUser;
    } catch (e) {
      printExcept(e);
      return null;
    }
  }

  /// Permet de demande à l'utilisateur de choisir un compte apple et de
  /// récupérer les crédentials.
  ///
  static Future<AuthorizationCredentialAppleID?> getAppleCredential(
      [String? giverRawNonce, String? giverNonce]) async {
    try {
      final rawNonce = giverRawNonce ?? generateNonce();
      final nonce = giverNonce ?? sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      return appleCredential;
    } catch (e) {
      printExcept(e);
      return null;
    }
  }

  /// Permet de lier le compte courant avec les crédentials google.
  ///
  /// /!\ Attention, le compte courant doit être connecté.
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<bool> linkCurrentUserWithGoogleCredential(
      GoogleSignInAccount googleUser) async {
    try {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
      return true;
    } catch (e) {
      printExcept(e);
      return false;
    }
  }

  /// Permet de lier le compte courant avec les crédentials apple.
  ///
  /// /!\ Attention, le compte courant doit être connecté.
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<bool> linkCurrentUserWithAppleCredential(
      AuthorizationCredentialAppleID appleCredential, String? rawNonce) async {
    try {
      final oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
      return true;
    } catch (e) {
      printExcept(e);
      return false;
    }
  }

  /// Permet de se connecter avec les crédentials Google.
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<Either<String, UserCredential?>> signInWithGoogle(
      GoogleSignInAccount googleUser) async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return Left("package.kosmos-auth.error-internet".tr());
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential user =
          await FirebaseAuth.instance.signInWithCredential(credential);
      return Right(user);
    } on FirebaseAuthException catch (e) {
      printExcept("[FirebaseException] ${e.message}");
      return Left(FirebaseErrorHandler.getErrorMessage(e));
    } catch (e) {
      printExcept(e);
      return Left("package.kosmos-auth.error-default".tr());
    }
  }

  /// Permet de se connecter avec les crédentials Apple.
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<Either<String, UserCredential?>> signInWithApple(
      AuthorizationCredentialAppleID appleCredential, String rawNonce) async {
    try {
      final oauthCredential = OAuthProvider("apple.com").credential(
        accessToken: appleCredential.authorizationCode,
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final UserCredential user =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      return Right(user);
    } on FirebaseAuthException catch (e) {
      printExcept("[FirebaseException] ${e.message}");
      return Left(FirebaseErrorHandler.getErrorMessage(e));
    } catch (e) {
      printExcept(e);
      return Left("package.kosmos-auth.error-default".tr());
    }
  }

  static String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  static String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Permet de modifier le mot de passe.
  /// Afin de pouvoir modifier le mot de passe, la fonction reconnecte
  /// l'utilisateur avec son email et son ancien mot de passe.
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<String?> updatePassword(
      String email, String oldPassword, String password,
      [String userCollection = "users"]) async {
    try {
      final rep = await signInWithEmail(email, oldPassword);
      return await rep.fold((l) async => l, (r) async {
        try {
          if (r?.user?.email != email)
            return "package.kosmos-auth.user-not-found".tr();
          await r!.user!.updatePassword(password);
          FirebaseFirestore.instance
              .collection(userCollection)
              .doc(r.user!.uid)
              .collection("metadata")
              .doc("security")
              .update({"lastPasswordUpdate": FieldValue.serverTimestamp()});
          return null;
        } on FirebaseAuthException catch (e) {
          return FirebaseErrorHandler.getErrorMessage(e);
        } catch (e) {
          printExcept(e);
          return "package.kosmos-auth.error-default".tr();
        }
      });
    } catch (e) {
      printExcept(e);
      return "package.kosmos-auth.error-default".tr();
    }
  }

  /// Adds an email to the current user's credential and updates the email in the user collection.
  ///
  /// The [email] parameter specifies the email to be added.
  /// The [password] parameter specifies the password for the email.
  /// The [userCollection] parameter specifies the collection name where the user data is stored (default is "users").
  ///
  /// Returns `null` if the email is added successfully.
  /// Returns an error message if there is an authentication error.
  static Future<String?> addEmailToCurrentCredential(String email, password,
      [String userCollection = "users"]) async {
    try {
      final emailCredential =
          EmailAuthProvider.credential(email: email, password: password);
      UserCredential r = await FirebaseAuth.instance.currentUser!
          .linkWithCredential(emailCredential);

      sendEmailVerification(r.user!.uid);
      FirebaseFirestore.instance
          .collection(userCollection)
          .doc(r.user!.uid)
          .update({"email": email}).then((value) {
        FirebaseFirestore.instance
            .collection(userCollection)
            .doc(r.user!.uid)
            .collection("metadata")
            .doc("security")
            .update({"lastEmailVerification": false});
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return FirebaseErrorHandler.getErrorMessage(e);
    } catch (e) {
      printExcept(e);
      return "package.kosmos-auth.error-default".tr();
    }
  }

  /// Permet de modifier l'email.
  /// Afin de pouvoir modifier l'email, la fonction reconnecte
  /// l'utilisateur avec son ancien email et son mot de passe.
  ///
  /// Les messages d'erreur sont automatiquement formatés en fonction
  /// de la langue de l'utilisateur.
  ///
  static Future<String?> updateEmail(
      String email, String newEmail, String password,
      [String userCollection = "users", String region = 'us-central1']) async {
    try {
      final rep = await signInWithEmail(email, password);
      return await rep.fold((l) async => l, (r) async {
        try {
          if (r?.user?.email != email) {
            return "package.kosmos-auth.user-not-found".tr();
          }
          final res = await FirebaseFunctions.instanceFor(region: region)
              .httpsCallable("changeEmail")
              .call({"email": email, "newEmail": newEmail});
          if (res.data == false ||
              (res.data is Map && (res.data as Map)["error"] != null)) {
            return "package.kosmos-auth.error-default".tr();
          }
          final uid = r!.user!.uid;
          final newSignIn = await signInWithEmail(newEmail, password);
          await newSignIn.fold((l) async => null, (r) async {
            sendEmailVerification(r!.user!.uid);
          });
          FirebaseFirestore.instance
              .collection(userCollection)
              .doc(uid)
              .update({"email": newEmail}).then((value) {
            FirebaseFirestore.instance
                .collection(userCollection)
                .doc(uid)
                .collection("metadata")
                .doc("security")
                .update({"lastEmailVerification": false});
          });
          return null;
        } on FirebaseAuthException catch (e) {
          return FirebaseErrorHandler.getErrorMessage(e);
        } catch (e) {
          printExcept(e);
          return "package.kosmos-auth.error-default".tr();
        }
      });
    } catch (e) {
      printExcept(e);
      return "package.kosmos-auth.error-default".tr();
    }
  }

  /// Permet de modifier le numéro de téléphone.
  static Future<String?> updatePhoneNumber(PhoneAuthCredential credential,
      [String userCollection = "users"]) async {
    try {
      await FirebaseAuth.instance.currentUser!.updatePhoneNumber(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      printExcept("[FirebaseException] ${e.message}");
      return FirebaseErrorHandler.getErrorMessage(e);
    } catch (e) {
      printExcept(e);
      return "package.kosmos-auth.error-default".tr();
    }
  }
}
