import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/billing/access_info.dart';
import 'package:wina/providers/billing_providers.dart';
import 'package:wina/view/page/abonnement_screen.dart';

/// Porte du lancement d'un match. L'app est gratuite : sans abonnement actif, « Coup d'envoi » ouvre l'écran de
/// paiement au lieu de lancer le match. Renvoie `true` quand le match peut être lancé : l'abonnement n'est pas
/// exigé, il est déjà actif, ou il vient d'être souscrit dans l'écran de paiement.
Future<bool> ensureCanStartMatch(BuildContext context, WidgetRef ref) async {
  // On attend les valeurs plutôt que de lire un état peut-être pas encore chargé : un instant d'attente vaut mieux
  // qu'un match lancé sans abonnement.
  final bool enforced = await ref.read(paywallEnforcedProvider.future);
  AccessInfo info = const AccessInfo();
  try {
    info = await ref.read(accessInfoProvider.future) ?? const AccessInfo();
  } catch (_) {
    // Fiche illisible : traitée comme « pas d'accès », les règles Firestore tranchent de toute façon.
  }
  if (!context.mounted) return false;
  if (canStartMatch(
    paywallEnforced: enforced,
    info: info,
    now: DateTime.now(),
  )) {
    return true;
  }
  final bool? subscribed = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => const AbonnementScreen(asGate: true),
    ),
  );
  return subscribed == true;
}
