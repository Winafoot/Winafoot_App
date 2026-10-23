import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeleton/controller/user_controller.dart';
import 'package:wina/billing/access_info.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/linked_team_repository.dart';
import 'package:wina/providers/auth_providers.dart';
import 'package:wina/providers/billing_providers.dart';
import 'package:wina/view/page/abonnement_screen.dart';
import 'package:wina/view/page/creer_equipe_liee_screen.dart';
import 'package:wina/view/widget/app_loader.dart';

/// Entoure le contenu de l'app : selon `app_config/config.paywall_enforced` et `users/{uid}.access`, affiche
/// l'app, le mur de paiement (propriétaire) ou l'écran « équipe bloquée » (compte lié). Les règles Firestore
/// font respecter la même décision côté serveur : cet écran n'est qu'un reflet.
///
/// Une erreur de lecture Firestore ne bloque jamais l'app sur un chargement infini : le mur se désactive
/// (`paywallEnforcedProvider` émet `false` sur erreur) et un accès illisible est traité comme « pas d'accès ».
///
/// Rattache aussi les achats à l'uid du propriétaire (jamais d'un compte lié) et, une fois par session,
/// propose de créer les équipes payées et pas encore créées.
class AccessGuard extends ConsumerStatefulWidget {
  const AccessGuard({super.key, required this.child, this.skipPaywall = false});

  final Widget child;

  /// Développement : ouvre toujours l'app, sans mur de paiement ni invitation à créer des équipes.
  final bool skipPaywall;

  @override
  ConsumerState<AccessGuard> createState() => _AccessGuardState();
}

class _AccessGuardState extends ConsumerState<AccessGuard> {
  String? _loggedInUid;
  bool _prompted = false;

  /// Rattache les achats à l'uid du propriétaire, une seule fois par uid. Les erreurs sont avalées :
  /// un échec RevenueCat ne doit jamais faire échouer le build.
  void _syncPurchases(String? uid, AccessInfo? info) {
    if (uid == null || info == null || info.isLinked || _loggedInUid == uid) return;
    _loggedInUid = uid;
    try {
      unawaited(ref.read(billingServiceProvider).logIn(uid).catchError((Object _) {}));
    } catch (_) {
      // Erreur synchrone du service d'achats : ignorée.
    }
  }

  void _maybePromptTeams(AccessInfo info, List<LinkedTeam> linked) {
    if (_prompted) return;
    final int missing = missingTeams(info, linkedCount: linked.length, now: DateTime.now());
    if (missing == 0) return;
    _prompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CreerEquipeLieeScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.skipPaywall) return widget.child;

    final AsyncValue<bool> enforced = ref.watch(paywallEnforcedProvider);
    final AsyncValue<AccessInfo?> info = ref.watch(accessInfoProvider);
    final AsyncValue<String?> auth = ref.watch(authUidProvider);
    final String? uid = auth.valueOrNull;

    final AccessInfo? access = info.valueOrNull;
    _syncPurchases(uid, access);

    // Chargement uniquement tant qu'une valeur est attendue : une erreur ne bloque pas sur le loader.
    if (enforced.isLoading || info.isLoading || auth.isLoading || (uid != null && access == null && !info.hasError)) {
      return const AppLoader();
    }

    final AccessDecision decision = decideAccess(
      paywallEnforced: enforced.valueOrNull ?? false,
      info: access ?? const AccessInfo(),
      now: DateTime.now(),
    );

    switch (decision) {
      case AccessDecision.paywall:
        return const AbonnementScreen();
      case AccessDecision.linkedBlocked:
        return const _LinkedBlockedScreen();
      case AccessDecision.open:
        // La liste des équipes liées n'est consultée que pour un propriétaire.
        if (access != null && !access.isLinked) {
          final List<LinkedTeam>? linked = ref.watch(linkedTeamsProvider).valueOrNull;
          if (linked != null) _maybePromptTeams(access, linked);
        }
        return widget.child;
    }
  }
}

/// Compte d'équipe lié dont le propriétaire n'a plus d'abonnement actif.
class _LinkedBlockedScreen extends ConsumerWidget {
  const _LinkedBlockedScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'app.access.linked-blocked-title'.tr(),
                textAlign: TextAlign.center,
                style: AppThemeStyle.boldStyle(28, AppColor.primaryLabels),
              ),
              const SizedBox(height: 16),
              Text(
                'app.access.linked-blocked-message'.tr(),
                textAlign: TextAlign.center,
                style: AppThemeStyle.regularStyle(16, AppColor.secondaryLabels),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => UserController.logoutUser(context, ref),
                child: Text('app.access.logout'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
