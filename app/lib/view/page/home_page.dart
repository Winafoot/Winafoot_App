import 'package:flutter/material.dart';
import 'package:wina/view/page/access_guard.dart';
import 'package:wina/view/page/mon_equipe_screen.dart';

/// Onglet d'accueil de l'utilisateur connecté : la page « Mon équipe », derrière la garde d'accès.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Le mur de paiement s'applique aussi en debug : les règles Firestore le font respecter côté serveur,
    // l'ignorer ici ne ferait qu'afficher des erreurs permission-denied.
    return const AccessGuard(child: MonEquipeScreen());
  }
}
