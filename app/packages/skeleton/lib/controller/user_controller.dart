// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:skeleton/skeleton.dart';

abstract class UserController {
  static Future<bool> isSocialCredentialExist(String credentialAppleClientID,
      [String userCollection = "users"]) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection(userCollection)
          .where("credentialAppleClientID", isEqualTo: credentialAppleClientID)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<void> createNewUserDocument(
    String uid,
    String? email,
    String? phone,
    PhoneNumber? phoneNumber, [
    String userCollection = "users",
    String? userType,
    String? credentialAppleClientID,
    String? firstname,
    String? lastname,
  ]) async {
    final user = await FirebaseFirestore.instance
        .collection(userCollection)
        .doc(uid)
        .get();
    if (user.exists && user.data()?["createdAt"] != null) {
      return;
    } else if (user.exists) {
      await FirebaseFirestore.instance
          .collection(userCollection)
          .doc(uid)
          .update({
        "id": uid,
        "email": email,
        "phone": phone,
        if (firstname != null) "firstname": firstname,
        if (lastname != null) "lastname": lastname,
        "credentialAppleClientID": credentialAppleClientID,
        if (phoneNumber != null)
          "phoneNumber": const PhoneNumberConverter().toJson(phoneNumber),
        "cguAccepted": true,
        "cguAcceptedDate": Timestamp.now(),
        "profilCompleted": false,
      });
      await FirebaseFirestore.instance
          .collection(userCollection)
          .doc(uid)
          .collection("metadata")
          .doc("security")
          .update({
        "cguAccepted": true,
        "cguAcceptedDate": Timestamp.now(),
        "profilCompleted": false,
        "createdAt": Timestamp.now(),
      });
      return;
    }
    await FirebaseFirestore.instance.collection(userCollection).doc(uid).set({
      "id": uid,
      "email": email,
      if (firstname != null) "firstname": firstname,
      if (lastname != null) "lastname": lastname,
      "credentialAppleClientID": credentialAppleClientID,
      "phone": phone,
      if (phoneNumber != null)
        "phoneNumber": const PhoneNumberConverter().toJson(phoneNumber),
      "userType": userType,
      "cguAccepted": true,
      "cguAcceptedDate": Timestamp.now(),
      "profilCompleted": false,
      "createdAt": Timestamp.now(),
    });
    await FirebaseFirestore.instance
        .collection(userCollection)
        .doc(uid)
        .collection("metadata")
        .doc("security")
        .set({
      "cguAccepted": true,
      "cguAcceptedDate": Timestamp.now(),
      "profilCompleted": false,
      "createdAt": Timestamp.now(),
    });
    await FirebaseFirestore.instance
        .collection(userCollection)
        .doc(uid)
        .collection('metadata')
        .doc('metadata')
        .set(
      {
        "createdAt": Timestamp.now(),
        "cguAccepted": true,
        "cguAcceptedDate": Timestamp.now(),
      },
    );
    await FirebaseFirestore.instance
        .collection(userCollection)
        .doc(uid)
        .collection('metadata')
        .doc('stripe')
        .set({});
    await FirebaseFirestore.instance
        .collection(userCollection)
        .doc(uid)
        .collection('metadata')
        .doc('notifications')
        .set({});
  }

  static Future<void> logoutUser(BuildContext context, WidgetRef ref,
      [bool redirectToRoot = true, bool deleteAccount = false]) async {
    final user = FirebaseAuth.instance.currentUser;
    final SkeletonAppConfig? config = getAppModel()
        .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");
    if (user != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("metadata")
          .doc("metadata")
          .update({"fcmToken": null});
    }
    await LocalConfigController.setData("authorized_push_notif",
        boolValue: null);
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      ref.read(userProvider).clear(false);
    }

    await LocalAuthController.forgetCredentials();
    EasyLoading.dismiss();

    if (redirectToRoot && !deleteAccount) {
      AutoRouter.of(context).popUntilRoot();
      AutoRouter.of(context).replaceNamed(
          "${config?.authentificationConfig.loginDefaultRoute ?? "/auth/login"}?logout=true&deleteAccount=$deleteAccount");
    }
  }

  static Future<void> acceptCgu() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
      "cguAccepted": true,
      "cguAcceptedDate": Timestamp.now(),
    });
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("metadata")
        .doc("metadata")
        .update({
      "cguAccepted": true,
      "cguAcceptedDate": Timestamp.now(),
    });
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("metadata")
        .doc("security")
        .update({
      "cguAccepted": true,
      "cguAcceptedDate": Timestamp.now(),
    });
  }

  static Future<bool> isCguAccepted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("metadata")
        .doc("security")
        .get();
    return userDoc.data()?["cguAccepted"] ?? false;
  }

  static Future<bool> isAuthorizedPushNotif() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("metadata")
        .doc("metadata")
        .get();
    return userDoc.data()?["enablePushNotification"] ?? false;
  }
}
