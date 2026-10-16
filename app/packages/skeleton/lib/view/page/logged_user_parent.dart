import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:local_auth/local_auth.dart';
import 'package:skeleton/controller/user_controller.dart';
import 'package:skeleton/skeleton.dart';
import 'package:ui_kosmos_v4/checkbox/checkbox.dart';

class LoggedUserAppCorePage extends StatefulHookConsumerWidget {
  const LoggedUserAppCorePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _LoggedUserAppCorePageState();
}

class _LoggedUserAppCorePageState extends ConsumerState<LoggedUserAppCorePage>
    with WidgetsBindingObserver {
  bool isCguShown = false;
  bool isprofilCompletedShown = false;
  bool fcmTokenIsRefresh = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late final SkeletonAppConfig? config = getAppModel()
      .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");

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
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _initPermission();
    UserFirestoreController.setOnline(true);
    if (ref.read(userProvider).user == null) {
      ref.read(userProvider.notifier).init(context);
    }
    execAfterBuild(() {
      if (!ref.read(notificationStreamProvider)) {
        ref.read(notificationStreamProvider.notifier).state = true;
        initPushNotification();
      }
      EventController.execInitialNotification(context, ref);
    });
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      /// Mets à jour l'utilisateur en "connected"

      UserFirestoreController.setOnline(true);
    } else {
      /// Mets à jour l'utilisateur en "disconnected"
      UserFirestoreController.setOnline(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).user;
    final security = ref.watch(userProvider).securityMetadata;
    final isLoaded = (user != null && security != null);

    if (isLoaded) {
      if (!fcmTokenIsRefresh && FirebaseAuth.instance.currentUser != null) {
        fcmTokenIsRefresh = true;
        NotifPermissionController.refreshFcmToken(ref);
      }
      if (security.cguAccepted != true && !isCguShown) {
        isCguShown = true;
        execAfterBuild(() => _showCguDialog(context));
        return HeroControllerScope(
          controller: HeroController(),
          child: const Scaffold(body: AutoRouter()),
        );
      }

      if ((config?.authentificationConfig.requireProfilCompletion ?? true) &&
          security.profilCompleted != true &&
          !isprofilCompletedShown) {
        isprofilCompletedShown = true;
        execAfterBuild(() =>
            config?.authentificationConfig.showCompleteProfil
                ?.call(context, user) ??
            _showCompleteProfil(context, user));
        return HeroControllerScope(
          controller: HeroController(),
          child: const Scaffold(body: AutoRouter()),
        );
      }

      if (!ref.read(localAuthVerifiedProvider) &&
          (security.forceEnableLoginAtEachAuth) &&
          (security.enableBiometricLogin)) {
        execAfterBuild(() async => await _verifyAuth(context));
      }
      execAfterBuild(() {
        if (!ref.watch(notificationStreamProvider.notifier).state) {
          ref.read(notificationStreamProvider.notifier).state = true;
          initPushNotification();
          EventController.execInitialNotification(context, ref);
        }
      });

      return HeroControllerScope(
        controller: HeroController(),
        child: const Scaffold(body: AutoRouter()),
      );
    }

    return Scaffold(
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

  Future<void> _showCguDialog(BuildContext context,
      [AuthTemplateThemeData? theme]) async {
    final ScrollController scrollController = ScrollController();
    final future = AppMetadataController.getMetadataConfig();
    final themeData = loadThemeData<AuthTemplateThemeData>(
      theme,
      "authentication_theme",
      () => const AuthTemplateThemeData(),
      isDark: ref.read(isDarkModeProvider).isDarkMode,
    );

    final rep = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeData.popupBackgroundColor ??
          Theme.of(context).scaffoldBackgroundColor,
      isDismissible: false,
      shape: themeData.modalBottomSheetShapeBorder ??
          RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(r(55)))),
      builder: (ctx) {
        bool cgvuAccepted = false;
        return StatefulBuilder(builder: (_, newState) {
          return Padding(
            padding: themeData.formPadding ??
                EdgeInsets.symmetric(horizontal: formatWidth(29)),
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
                  onChanged: (val) =>
                      newState(() => cgvuAccepted = !cgvuAccepted),
                  isChecked: cgvuAccepted,
                ),
                sh(33),
                Center(
                  child: config?.authentificationConfig.cgvuButtonCustom?.call(
                        context,
                        ref,
                        () {
                          Navigator.pop(context, true);
                        },
                      ) ??
                      Button(
                        text: config?.authentificationConfig
                                    .cgvuButtonTitleBuilder ==
                                null
                            ? "utils.continue".tr()
                            : null,
                        height: formatHeight(54),
                        width: formatWidth(
                            config?.authentificationConfig.cgvuButtonWidth ??
                                170),
                        enabled: cgvuAccepted,
                        onTap: () {
                          Navigator.pop(context, true);
                        },
                        child: config
                            ?.authentificationConfig.cgvuButtonTitleBuilder
                            ?.call(context, ref),
                      ),
                ),
                SizedBox(
                    height: MediaQuery.of(context).padding.bottom +
                        formatHeight(12)),
              ],
            ),
          );
        });
      },
    );
    if (rep != true && mounted) {
      PopupAlert.toast(context, FToast().init(context),
          title: "utils.error".tr(),
          subtitle: "package.skeleton.new-cgu-must-be-accepted".tr());
      await _showCguDialog(context, themeData);
      return;
    }
    await UserController.acceptCgu();
    isCguShown = false;
  }

  void _showCompleteProfil(BuildContext context, UserModel user) async {
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

  Future<void> _verifyAuth(BuildContext context) async {
    ref.read(localAuthVerifiedProvider.notifier).state = true;

    final t = await LocalConfigController.getData<bool>("biometrics");
    if (!(t ?? false)) return;

    final LocalAuthentication auth = LocalAuthentication();

    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();
    if (!canAuthenticate) return;

    try {
      final bool didAuthenticate =
          await auth.authenticate(localizedReason: 'login');
      if (didAuthenticate) return;
    } catch (e) {
      printExcept(e);
      // ignore: use_build_context_synchronously
      await UserController.logoutUser(context, ref);
      return;
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
