import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:skeleton/controller/user_controller.dart';
import 'package:skeleton/skeleton.dart';
import 'package:ui_kosmos_v4/checkbox/checkbox.dart';

class MaybeLoggedUserAppCorePage extends StatefulHookConsumerWidget {
  const MaybeLoggedUserAppCorePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MaybeLoggedUserAppCorePageState();
}

class _MaybeLoggedUserAppCorePageState
    extends ConsumerState<MaybeLoggedUserAppCorePage>
    with WidgetsBindingObserver {
  bool _notifInitDone = false;
  bool isCguShown = false;
  bool isprofilCompletedShown = false;
  bool fcmTokenIsRefresh = false;
  Color? scaffoldBackgroundColorLight;
  Color? scaffoldBackgroundColorDark;
  late final SkeletonAppConfig? config = getAppModel()
      .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AndroidNotificationChannel channel = const AndroidNotificationChannel(
      'default_channel', 'notif',
      description: "", importance: Importance.high);

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    if (GetIt.instance.isRegistered<AppTheme>()) {
      AppTheme apptheme = GetIt.instance.get<AppTheme>();
      scaffoldBackgroundColorLight =
          apptheme.themeData?.scaffoldBackgroundColor;
      scaffoldBackgroundColorDark =
          apptheme.themeDataDark?.scaffoldBackgroundColor;
    }

    if (FirebaseAuth.instance.currentUser != null) {
      _initPermission();
      UserFirestoreController.setOnline(true);
    }
    if (ref.read(userProvider).user == null &&
        FirebaseAuth.instance.currentUser != null) {
      ref.read(userProvider.notifier).init(context);
    }
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (FirebaseAuth.instance.currentUser == null) return;

    if (state == AppLifecycleState.resumed) {
      /// Mets à jour l'utilisateur en "connected"
      UserFirestoreController.setOnline(true);
    } else {
      /// Mets à jour l'utilisateur en "disconnected"
      UserFirestoreController.setOnline(false);
    }
  }

  void _updateNotificationContext(BuildContext routerContext) {
    if (!_notifInitDone && FirebaseAuth.instance.currentUser != null) {
      _notifInitDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!ref.read(notificationStreamProvider)) {
          ref.read(notificationStreamProvider.notifier).state = true;
          _initPushNotificationWithContext(routerContext);
        }
        EventController.execInitialNotification(routerContext, ref);
      });
    }
  }

  void _initPushNotificationWithContext(BuildContext routerContext) async {
    bool authorizedPushNotif =
        await LocalConfigController.getData<bool?>("authorized_push_notif") ==
            true;
    if (authorizedPushNotif &&
        ref.read(userProvider).metadata?.enablePushNotification != false &&
        FirebaseAuth.instance.currentUser != null) {
      final EventConfiguration config = getAppModel()
              .getDependenciesFromName<EventConfiguration>(
                  "kosmos_event_config") ??
          EventConfiguration();
      AndroidNotificationChannel channel = AndroidNotificationChannel(
          'default_channel', 'notif',
          description: "",
          importance: Importance.max,
          playSound: true,
          sound: config.soundAndroid == null
              ? null
              : RawResourceAndroidNotificationSound(config.soundAndroid));
      EventController.initPushNotifs(
          routerContext, flutterLocalNotificationsPlugin, channel, ref);
    }
  }

  void initPushNotification() async {
    bool authorizedPushNotif =
        await LocalConfigController.getData<bool?>("authorized_push_notif") ==
            true;
    if (authorizedPushNotif &&
        ref.read(userProvider).metadata?.enablePushNotification != false &&
        FirebaseAuth.instance.currentUser != null) {
      final EventConfiguration config = getAppModel()
              .getDependenciesFromName<EventConfiguration>(
                  "kosmos_event_config") ??
          EventConfiguration();
      AndroidNotificationChannel channel = AndroidNotificationChannel(
          'default_channel', 'notif',
          description: "",
          importance: Importance.max,
          playSound: true,
          sound: config.soundAndroid == null
              ? null
              : RawResourceAndroidNotificationSound(config.soundAndroid));
      EventController.initPushNotifs(
          context, flutterLocalNotificationsPlugin, channel, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider).isDarkMode;
    final scaffoldBackgroundColor =
        isDarkMode ? scaffoldBackgroundColorDark : scaffoldBackgroundColorLight;
    printWarning(
        "MaybeLoggedUserAppCorePage build: ${FirebaseAuth.instance.currentUser?.uid}");
    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        body: AutoRouter(
          builder: (routerContext, content) {
            return content;
          },
        ),
        backgroundColor: scaffoldBackgroundColor,
      );
    }

    if (ref.read(userProvider).user == null &&
        ref.read(userProvider).userStream == null) {
      printWarning("Init user provider");
      ref.read(userProvider.notifier).init(context);
    }

    final user = ref.watch(userProvider).user;
    final security = ref.watch(userProvider).securityMetadata;
    final isLoaded = (user != null) && (security != null);

    printDebug("isLoaded: $isLoaded");

    if (isLoaded) {
      if (!fcmTokenIsRefresh) {
        printDebug("refreshFcmToken");
        fcmTokenIsRefresh = true;
        NotifPermissionController.refreshFcmToken(ref);
      }
      if (security.cguAccepted != true && !isCguShown) {
        printDebug("showCguDialog");
        isCguShown = true;
        execAfterBuild(() => _showCguDialog(context, ref));
        return HeroControllerScope(
          controller: HeroController(),
          child: Scaffold(
            body: AutoRouter(
              builder: (routerContext, content) {
                _updateNotificationContext(routerContext);
                return content;
              },
            ),
            backgroundColor: scaffoldBackgroundColor,
          ),
        );
      }
      if ((config?.authentificationConfig.requireProfilCompletion ?? true) &&
          security.profilCompleted != true &&
          !isprofilCompletedShown &&
          FirebaseAuth.instance.currentUser != null) {
        printDebug("showCompleteProfil");
        isprofilCompletedShown = true;
        execAfterBuild(() => _showCompleteProfil(context, user));
        return HeroControllerScope(
          controller: HeroController(),
          child: Scaffold(
            body: AutoRouter(
              builder: (routerContext, content) {
                _updateNotificationContext(routerContext);
                return content;
              },
            ),
            backgroundColor: scaffoldBackgroundColor,
          ),
        );
      }
      printDebug("return Scaffold");

      return HeroControllerScope(
        controller: HeroController(),
        child: Scaffold(
          body: AutoRouter(
            builder: (routerContext, content) {
              _updateNotificationContext(routerContext);
              return content;
            },
          ),
          backgroundColor: scaffoldBackgroundColor,
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const LoaderClassique(),
            Text("utils.loading".tr(),
                style: DefaultAppStyle.darkBlue(13, FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Future<void> _showCguDialog(BuildContext context, WidgetRef ref,
      [AuthTemplateThemeData? theme]) async {
    final ScrollController scrollController = ScrollController();
    final future = AppMetadataController.getMetadataConfig();
    final themeData = loadThemeData<AuthTemplateThemeData>(
      theme,
      "authentication_theme",
      () => const AuthTemplateThemeData(),
      isDark: ref.read(isDarkModeProvider).isDarkMode,
    );

    bool cgvuAccepted = false;
    final rep = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: themeData.modalBottomSheetShapeBorder ??
          RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(r(55)))),
      builder: (ctx) {
        return StatefulBuilder(builder: (sheetContext, newState) {
          return Padding(
            padding: themeData.formPadding ??
                EdgeInsets.symmetric(horizontal: formatWidth(27.5)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sh(16),
                Center(
                  child: Container(
                    width: formatWidth(43),
                    height: 4,
                    decoration: BoxDecoration(
                        color: themeData.dividerColor ?? DefaultColor.lightGrey,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                sh(19.5),
                Center(
                  child: Text(
                    "utils.cgvu-and-confidentiality".tr(),
                    style: themeData.popupTitleStyle ??
                        DefaultAppStyle.darkBlue(17),
                    textAlign: TextAlign.center,
                  ),
                ),
                sh(19),
                SizedBox(
                  height: formatHeight(430),
                  child: FutureBuilder<AppMetadataConfig?>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final cgvu = snapshot.data?.cgvu;
                      return Scrollbar(
                        controller: scrollController,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          child: HtmlWidget(
                            cgvu ?? "",
                            textStyle: themeData.htmlTextStyle,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                sh(16),
                Selector(
                  type: CheckboxType.square,
                  sideText: "utils.accept-cgvu-and-confidentiality".tr(),
                  onChanged: (val) => newState(() => cgvuAccepted = !val),
                  isChecked: cgvuAccepted,
                ),
                sh(33),
                Center(
                  child: Button(
                    text: "utils.continue".tr(),
                    height: formatHeight(54),
                    width: formatWidth(170),
                    enabled: cgvuAccepted,
                    onTap: () {
                      Navigator.pop(sheetContext, true);
                    },
                  ),
                ),
                SizedBox(
                    height: MediaQuery.of(sheetContext).padding.bottom +
                        formatHeight(12)),
              ],
            ),
          );
        });
      },
    );
    if (rep != true && mounted) {
      await _showCguDialog(context, ref, themeData);
      return;
    }
    await UserController.acceptCgu();
    isCguShown = false;
  }

  void _showCompleteProfil(BuildContext context, UserModel user) {
    printInfo(
        "User profil is not completed, redirecting to profil completion page");
    if (config?.authentificationConfig.profilCompletionRoutesPerUser
            .containsKey(user.userType) ??
        false) {
      AutoRouter.of(context).replaceNamed(config!.authentificationConfig
              .profilCompletionRoutesPerUser[user.userType] ??
          "profil-completion");
    } else {
      AutoRouter.of(context).replaceNamed("profil-completion");
    }
  }

  void _initPermission() async {
    if (!notificationFcmProvider) {
      if (await LocalConfigController.getData<bool?>("authorized_push_notif") ==
              true &&
          ref.read(userProvider).metadata?.enablePushNotification != false &&
          FirebaseAuth.instance.currentUser != null) {
        await NotifPermissionController.refreshFcmToken(ref);
      }
      //  else if (ref.read(userProvider).metadata?.enablePushNotification ==
      //     true) {
      //   await NotifPermissionController.refreshFcmToken(ref);
      // }
      notificationFcmProvider = true;
    }
  }
}
