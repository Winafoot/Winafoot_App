import 'package:core_kosmos/core_kosmos.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AnalyticsController {
  static Future<void> connectUser(String userId) async {
    await FirebaseAnalytics.instance.setUserId(id: userId);
    printInfo("Analytics: Connect User");
  }

  static Future<void> disconnectUser() async {
    await FirebaseAnalytics.instance.setUserId(id: null);
    printInfo("Analytics: Disconnect User");
  }

  static Future<void> openApp() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await AnalyticsController.connectUser(
          FirebaseAuth.instance.currentUser!.uid);
    }
    await FirebaseAnalytics.instance.logAppOpen();
    printInfo("Analytics: Open App");
  }

  static Future<void> openScreen(String name,
      {Map<String, dynamic>? parameters}) async {
    await FirebaseAnalytics.instance
        .logScreenView(screenName: name, screenClass: name);
  }

  static Future<void> logEvent(String name,
      {Map<String, Object>? parameters}) async {
    await FirebaseAnalytics.instance
        .logEvent(name: name, parameters: parameters);
  }
}

abstract class AnalyticsAuthController {
  static Future<void> login([String loginMethod = "email-password"]) async {
    if (FirebaseAuth.instance.currentUser != null) {
      await AnalyticsController.connectUser(
          FirebaseAuth.instance.currentUser!.uid);
    }
    await FirebaseAnalytics.instance.logLogin(loginMethod: loginMethod);
    printInfo("Analytics: Login");
  }

  static Future<void> signUp() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await AnalyticsController.connectUser(
          FirebaseAuth.instance.currentUser!.uid);
    }
    await FirebaseAnalytics.instance.logSignUp(signUpMethod: "email-password");
    printInfo("Analytics: Sign Up");
  }

  static Future<void> logout() async {
    await FirebaseAnalytics.instance.logEvent(name: 'logout');
    await AnalyticsController.disconnectUser();
    printInfo("Analytics: Logout");
  }
}
