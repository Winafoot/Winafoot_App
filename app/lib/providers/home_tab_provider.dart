import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Onglet courant de la barre de navigation basse (`MonEquipeScreen`) : 0 =
/// « Mon équipe », 1 = IA, 2 = Statistiques, 3 = Test équipe.
///
/// Tenu hors de l'écran parce que le logo « wina » (`WinaWordmark`) doit
/// pouvoir ramener sur l'accueil depuis n'importe quelle entête : les trois
/// autres onglets vivent dans le même `IndexedStack`, donc `popUntil` +
/// `navigate(HomeRoute)` n'y changent rien tant que l'index reste sur eux.
final homeTabProvider = StateProvider<int>((ref) => 0);
