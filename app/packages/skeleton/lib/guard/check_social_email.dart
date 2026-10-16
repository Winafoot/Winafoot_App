import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/foundation.dart';
import 'package:skeleton/model/skeleton_config.dart';

///
class CheckSocialEmail extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    SkeletonAppConfig? skeletonConfig = GetIt.instance<AppModel>()
        .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");
    final mainRouteInfo = skeletonConfig?.mainRouteInfo;

    if (FirebaseAuth.instance.currentUser == null) {
      mainRouteInfo == null
          ? router.replaceNamed("/")
          : router.pushAndPopUntil(mainRouteInfo, predicate: (route) => false);
    } else {
      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if ((FirebaseAuth.instance.currentUser!.email != null) &&
          doc.exists &&
          (!doc.data()!.containsKey("email") || doc.data()!["email"] == null)) {
        try {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({
            "email": FirebaseAuth.instance.currentUser!.email,
            "socialAccount": true
          });
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
        }
      }
      resolver.next(true);
    }
  }
}
