import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../routes/app_router.gr.dart';

/// Orientation de l'application.
///
/// - Tablette : paysage partout (design de référence 1194x834).
/// - Téléphone : portrait sur le parcours d'entrée (connexion, inscription,
///   « Finalisez votre profil »), paysage ailleurs.
///
/// Les écrans d'authentification sont des routes : le routeur est écouté
/// ([attach]). « Finalisez votre profil » est poussé par un `Navigator`, que le
/// routeur ne voit pas : ces écrans s'enveloppent dans un [PortraitScope].
abstract final class OrientationController {
  /// Plus petit côté (en dp) à partir duquel l'appareil est une tablette.
  static const double tabletShortestSide = 600;

  /// Routes de l'auth qui s'affichent en portrait sur téléphone.
  static final Set<String> _portraitRoutes = <String>{
    AuthParentRoute.name,
    LoginRoute.name,
    PhoneLoginRoute.name,
    RegisterRoute.name,
  };

  static int _portraitScopes = 0;
  static bool _portraitRoute = false;
  static bool? _applied;

  static bool get isPhone {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize.shortestSide / view.devicePixelRatio <
        tabletShortestSide;
  }

  /// Suit le routeur : portrait tant qu'une route d'auth est affichée.
  static void attach(StackRouter router) {
    void sync() {
      _portraitRoute = _portraitRoutes.contains(router.topRoute.name);
      apply();
    }

    router.addListener(sync);
    // Pas de lecture de la route ici : le routeur n'est pas encore monté.
    apply();
  }

  static void enterPortraitScope() {
    _portraitScopes++;
    apply();
  }

  static void leavePortraitScope() {
    if (_portraitScopes > 0) _portraitScopes--;
    apply();
  }

  /// Verrouille l'orientation voulue ; sans effet si elle est déjà appliquée.
  static void apply() {
    final bool portrait = isPhone && (_portraitRoute || _portraitScopes > 0);
    if (portrait == _applied) return;
    _applied = portrait;
    SystemChrome.setPreferredOrientations(portrait ? _portrait : _landscape);
  }

  static const List<DeviceOrientation> _portrait = <DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ];

  static const List<DeviceOrientation> _landscape = <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];
}

/// Force le portrait sur téléphone tant qu'il est affiché.
///
/// Pour les écrans que le routeur ne voit pas (poussés par un `Navigator`).
class PortraitScope extends StatefulWidget {
  final Widget child;

  const PortraitScope({super.key, required this.child});

  @override
  State<PortraitScope> createState() => _PortraitScopeState();
}

class _PortraitScopeState extends State<PortraitScope> {
  @override
  void initState() {
    super.initState();
    OrientationController.enterPortraitScope();
  }

  @override
  void dispose() {
    OrientationController.leavePortraitScope();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
