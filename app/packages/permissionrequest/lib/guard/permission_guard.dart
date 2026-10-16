import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// {@category Guards}
/// {@category Permission}
///
/// Permet de vérifier si l'utilisateur a déjà lancé les permissions
/// sinon on le redirige vers la page de permission.
///
class PermissionGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    LocalConfigController.getData<bool>("permission_already_launched").then((value) {
      if (FirebaseAuth.instance.currentUser != null) {
        FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser!.uid).collection("metadata").doc("metadata").get().then((v) {
          if (!v.exists) {
            return _handleNavigate(resolver, router, value ?? false);
          }
          return _handleNavigate(resolver, router, (value ?? false) && ((v.data()?["permissionLaunched"] as bool?) ?? false));
        });
      } else {
        return _handleNavigate(resolver, router, value ?? false);
      }
    });
  }

  void _handleNavigate(NavigationResolver resolver, StackRouter router, bool value) {
    if (value == true) return resolver.next();
    printWarning("Redirection to Permission");
    router.replaceNamed("permission");
  }
}
