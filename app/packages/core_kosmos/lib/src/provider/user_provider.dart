// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// only used for chat

bool autoSaveMedia = false;

/// {@category Provider}
/// {@category User}
///
/// Définition du provider de l'utilisateur.
///
final userProvider = ChangeNotifierProvider<UserProvider>((ref) {
  final appModel = getAppModel();

  return UserProvider(fromJson: appModel.userConfig.fromJson);
});

/// {@category Provider}
/// {@category User}
///
/// Permet de Recevoir / Stream toutes les données de l'utilisateur depuis Firebase.
class UserProvider<U> with ChangeNotifier {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? userStream;
  StreamSubscription? userMetadataStream;

  static UserModel<U>? getUserGetIt<U>() {
    try {
      if (GetIt.instance.isRegistered<UserModel<U>>(instanceName: "user")) {
        return GetIt.instance.get<UserModel<U>>(instanceName: "user");
      }
      return null;
    } catch (e) {
      printError("Error while getting user: $e");
      return null;
    }
  }

  final U Function(Map<String, dynamic>? json, String? userType) fromJson;
  UserModel<U>? _user;

  UserMetadataModel? _metadata;
  UserMetadataModel? get metadata => _metadata;

  UserSecurityMetadataModel? _securityMetadata;
  UserSecurityMetadataModel? get securityMetadata => _securityMetadata;

  UserStripeMetadataModel? _stripeMetadata;
  UserStripeMetadataModel? get stripeMetadata => _stripeMetadata;

  U? get userAppData => _user?.userData;
  UserModel<U>? get user => _user;

  UserProvider({required this.fromJson});

  Future<void> init(BuildContext context) async {
    GetIt.instance.allowReassignment = true;
    if (_user != null) {
      printError("UserProvider already initialized, you must clear it first");
      return;
    }
    userStream?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      printError("UserProvider: user is null");
      try {
        await GetIt.instance.unregister(instanceName: "user");
      } catch (e) {
        printError("Error while unregistering user: $e");
      }
      await FirebaseAuth.instance.signOut();
      AutoRouter.of(context).replaceNamed("/");
      return;
    }

    final AppModel appModel = getAppModel();

    userStream = FirebaseFirestore.instance
        .collection(appModel.userConfig.userCollectionName)
        .doc(user.uid)
        .snapshots()
        .listen((event) async {
      if (event.exists) {
        String? userType = event.data()?["userType"];
        _user = UserModel<U>.fromJson(event.data()!, (p0) {
          return fromJson(p0 as Map<String, dynamic>? ?? {}, userType);
        });
        // Using getit to store the user
        try {
          GetIt.instance
              .registerSingleton<UserModel<U>>(_user!, instanceName: "user");
        } catch (e) {
          printError("Error while registering user: $e");
        }

        autoSaveMedia = _user?.autoSaveMedia ?? false;
        notifyListeners();
      } else if (event.metadata.isFromCache) {
        // Réponse du cache seul : la fiche n'y est peut-être pas encore (compte tout juste créé par le
        // serveur, après une lecture 'inexistante' restée en cache). On attend la confirmation du serveur
        // avant de déconnecter.
        printDebug("User ${user.uid} absent du cache, en attente du serveur");
      } else {
        printError("User ${user.uid} not found");
        _user = null;
        autoSaveMedia = false;
        try {
          await FirebaseAuth.instance.signOut();
          AutoRouter.of(context).replaceNamed("/");
        } catch (e) {
          printError("Error while signing out: $e");
        }
        userStream?.cancel();
      }
    });

    userMetadataStream = FirebaseFirestore.instance
        .collection(appModel.userConfig.userCollectionName)
        .doc(user.uid)
        .collection("metadata")
        .snapshots()
        .listen((event) {
      for (final item in event.docs) {
        if (item.id == "stripe") {
          _stripeMetadata = UserStripeMetadataModel.fromJson(item.data());
        } else if (item.id == "metadata") {
          _metadata = UserMetadataModel.fromJson(item.data());
        } else if (item.id == "security") {
          _securityMetadata = UserSecurityMetadataModel.fromJson(item.data());
        }
        notifyListeners();
      }
    });

    final metadataRef = await FirebaseFirestore.instance
        .collection(appModel.userConfig.userCollectionName)
        .doc(user.uid)
        .collection("metadata")
        .doc("metadata")
        .get();
    if (!metadataRef.exists) return;

    final data = metadataRef.data() ?? {};

    if (data["enablePushNotification"] == true &&
        (await LocalConfigController.getData<bool>("authorized_push_notif") ??
            false)) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        await FirebaseFirestore.instance
            .collection(appModel.userConfig.userCollectionName)
            .doc(user.uid)
            .collection("metadata")
            .doc("metadata")
            .update({
          "fcmToken": token,
          "authorized_push_notif_5": true,
        });
      } catch (e) {
        printError("Error while subscribing to push notification: $e");
      }
    }
  }

  void clear([bool notify = true]) {
    userStream?.cancel();
    userStream = null;
    _user = null;
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
