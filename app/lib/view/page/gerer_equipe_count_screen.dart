import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/composition_providers.dart';
import 'package:wina/view/page/gerer_equipe_nav.dart';
import 'package:wina/view/page/gerer_equipe_numbers_screen.dart';

/// Ouvre le sous-flux « Gérer mon équipe » depuis un brouillon vierge.
///
/// Il n'y a plus d'écran de choix du nombre de joueurs : le format du club
/// (`teamFormat`) fait foi, et un compte qui n'en a pas (comptes anciens)
/// retombe sur le foot à 11.
Future<void> startGererEquipeFlow(BuildContext context, WidgetRef ref) async {
  ref.read(compositionDraftProvider.notifier).reset();
  final PlayerCount format = ref.read(teamFormatProvider) ?? PlayerCount.eleven;
  await continueWithPlayerCount(context, ref, format.value);
}

/// Pose le nombre de joueurs puis ouvre « Attribuez les numéros ». Les numéros
/// des remplaçants se choisissent depuis cet écran (bouton « Ajouter les
/// remplaçants »), plus dans une popup préalable.
Future<void> continueWithPlayerCount(
  BuildContext context,
  WidgetRef ref,
  int count,
) async {
  ref.read(compositionDraftProvider.notifier).setCount(count);
  await openGererScreen(
    context,
    kGererNumbersRoute,
    () => const GererEquipeNumbersScreen(),
  );
}
