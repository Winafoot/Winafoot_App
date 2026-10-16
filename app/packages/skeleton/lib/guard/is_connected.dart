import 'package:core_kosmos/core_kosmos.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:kosmos_auth/controller/auth.dart';
import 'package:skeleton/model/skeleton_config.dart';

/// {@category Guards}
/// {@category Auth}
///
/// Vérifie si l'utilisateur est connecté via [FirebaseAuth]
/// - Si l'utilisateur est connecté, il le laisse accéder à la prochaine page
/// - Si l'utilisateur est connecté mais que son email n'est pas vérifié, il est déconnecté et redirigé vers la page de connexion, par défaut "/login"
/// - Si l'utilisateur n'est pas connecté, il est redirigé vers la page de connexion, par défaut "/login"
///
class IsConnectedGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final skeletonConfig = GetIt.instance<AppModel>()
        .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");
    final loginRoute =
        skeletonConfig?.authentificationConfig.loginDefaultRoute ??
            "/auth/login";

    if (FirebaseAuth.instance.currentUser == null) {
      router.replaceNamed(loginRoute);
      return;
    } else {
      if (!FirebaseAuth.instance.currentUser!.emailVerified &&
          (skeletonConfig?.authentificationConfig.emailMustBeVerified ??
              false)) {
        if (skeletonConfig
                ?.authentificationConfig.sendEmailVerificationIfNotVerified ??
            false) {
          KosmosAuth.sendEmailVerification(
            FirebaseAuth.instance.currentUser!.uid,
            region: skeletonConfig?.cloudRegion ?? "us-central1",
          ).then((value) => printDebug("SendVerificationEmail: $value"));
        }
        FirebaseAuth.instance
            .signOut()
            .then((value) => router.replaceNamed(loginRoute));
        return;
      }
      resolver.next(true);
    }
  }
}
