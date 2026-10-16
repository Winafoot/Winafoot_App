import 'package:core_kosmos/core_kosmos.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:skeleton/model/skeleton_config.dart';

/// {@category Guards}
/// {@category Auth}
///
/// Vérifie si l'utilisateur est connecté via [FirebaseAuth]
/// - Si l'utilisateur est connecté, il le redirige vers la page d'accueil
/// - Si l'utilisateur n'est pas connecté, il laisse accéder à la prochaine page
///
class IsNotConnectedGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final skeletonConfig = GetIt.instance<AppModel>().getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");
    final mainRouteInfo = skeletonConfig?.mainRouteInfo;

    if (FirebaseAuth.instance.currentUser == null) {
      resolver.next(true);
    } else {
      mainRouteInfo == null ? router.replaceNamed("/") : router.pushAndPopUntil(mainRouteInfo, predicate: (route) => false);
    }
  }
}
