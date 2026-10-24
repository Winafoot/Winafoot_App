import 'package:flutter/material.dart';

/// Noms des routes du sous-flux « Gérer mon équipe ».
const String kGererNumbersRoute = 'gerer-equipe-numbers';
const String kGererCompositionRoute = 'gerer-equipe-composition';
const String kGererPlacementRoute = 'gerer-equipe-placement';

final Map<String, Route<void>> _openRoutes = <String, Route<void>>{};

/// Ouvre un écran du sous-flux « Gérer mon équipe » sans jamais l'empiler deux
/// fois : s'il est déjà ouvert plus bas dans la pile, on y revient (les écrans
/// au-dessus sont fermés) au lieu d'en pousser un second. Sinon,
/// numéros → composition → placement → numéros… s'accumulait et le retour
/// repassait par chaque étape.
Future<void> openGererScreen(
  BuildContext context,
  String name,
  Widget Function() builder,
) async {
  final NavigatorState navigator = Navigator.of(context);
  final Route<void>? existing = _openRoutes[name];
  // On compare la route elle-même (encore active dans CE navigator) et non le
  // seul nom : une route détruite sans avoir été dépilée ne doit pas bloquer.
  if (existing != null &&
      existing.isActive &&
      existing.navigator == navigator) {
    navigator.popUntil((Route<dynamic> route) => route == existing);
    return;
  }
  final Route<void> route = MaterialPageRoute<void>(
    settings: RouteSettings(name: name),
    builder: (_) => builder(),
  );
  _openRoutes[name] = route;
  try {
    await navigator.push(route);
  } finally {
    if (_openRoutes[name] == route) _openRoutes.remove(name);
  }
}
