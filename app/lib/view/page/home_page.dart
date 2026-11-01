import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/providers/assistant_providers.dart';
import 'package:wina/view/page/access_guard.dart';
import 'package:wina/view/page/assistant_home_page.dart';
import 'package:wina/view/page/mon_equipe_screen.dart';
import 'package:wina/view/widget/app_loader.dart';
import 'package:wina/view/widget/resume_match_gate.dart';

/// Onglet d'accueil de l'utilisateur connecté : la page « Mon équipe », derrière la garde d'accès. Un adjoint
/// n'a pas d'équipe ni d'abonnement : il arrive sur l'accueil du match en cours.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String?> assistantOf = ref.watch(assistantOfProvider);
    if (assistantOf.isLoading && !assistantOf.hasValue) {
      return const AppLoader();
    }
    if (assistantOf.valueOrNull != null) return const AssistantHomePage();

    // Le mur de paiement s'applique aussi en debug : les règles Firestore le font respecter côté serveur,
    // l'ignorer ici ne ferait qu'afficher des erreurs permission-denied.
    return const AccessGuard(child: ResumeMatchGate(child: MonEquipeScreen()));
  }
}
