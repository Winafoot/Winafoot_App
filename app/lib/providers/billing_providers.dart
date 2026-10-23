import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/billing/access_info.dart';
import 'package:wina/billing/billing_service.dart';
import 'package:wina/billing/offers.dart';
import 'package:wina/billing/test_billing_service.dart';
import 'package:wina/data/linked_team_repository.dart';
import 'package:wina/providers/auth_providers.dart';

/// RevenueCat, sauf `--dart-define=TEST_BILLING=true` (build non release) : achats simulés côté serveur.
final billingServiceProvider = Provider<BillingService>(
  (ref) => TestBillingService.isActive ? TestBillingService() : RevenueCatBillingService(),
);

/// Offres à vendre, par nombre d'équipes (1, 2, 3), prix issus du store. Erreur [BillingUnavailable]
/// quand les clés RevenueCat ne sont pas dans le build.
final offersProvider = FutureProvider<Map<int, TeamsOffer>>((ref) async {
  final BillingService service = ref.watch(billingServiceProvider);
  if (!service.isAvailable) throw const BillingUnavailable();
  final Map<int, TeamsOffer> grouped = groupOffers(await service.loadOffers());
  return Map<int, TeamsOffer>.fromEntries(grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
});

/// Interrupteur du mur de paiement : `app_config/config.paywall_enforced` (lisible par tous). Absent,
/// faux ou illisible : mur désactivé, comme dans les règles Firestore.
final paywallEnforcedProvider = StreamProvider<bool>((ref) {
  return FirebaseFirestore.instance
      .collection('app_config')
      .doc('config')
      .snapshots()
      .map((DocumentSnapshot<Map<String, dynamic>> d) => d.data()?['paywall_enforced'] == true)
      // `handleError` avalerait l'erreur sans rien émettre : la garde resterait en chargement. On émet `false`.
      .transform(
        StreamTransformer<bool, bool>.fromHandlers(
          handleError: (Object _, StackTrace __, EventSink<bool> sink) => sink.add(false),
        ),
      );
});

/// Accès du compte connecté (`users/{uid}`), `null` sans session. Rattaché à [authUidProvider] pour se
/// reconstruire à chaque changement de session.
final accessInfoProvider = StreamProvider<AccessInfo?>((ref) {
  final String? uid = ref.watch(authUidProvider).valueOrNull;
  if (uid == null) return Stream<AccessInfo?>.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((DocumentSnapshot<Map<String, dynamic>> d) => AccessInfo.fromUserData(d.data()));
});

/// Équipes liées du propriétaire connecté (vide pour un compte lié ou sans session).
final linkedTeamsProvider = StreamProvider<List<LinkedTeam>>((ref) {
  final String? uid = ref.watch(authUidProvider).valueOrNull;
  final AccessInfo? info = ref.watch(accessInfoProvider).valueOrNull;
  if (uid == null || info == null || info.isLinked) return Stream<List<LinkedTeam>>.value(const <LinkedTeam>[]);
  return LinkedTeamRepository.watch(uid);
});

typedef CreateLinkedTeamFn = Future<void> Function(Map<String, Object?> args);

/// Création d'une équipe liée : le vrai appel serveur, surchargeable dans les tests.
final createLinkedTeamProvider = Provider<CreateLinkedTeamFn>((ref) {
  return (Map<String, Object?> a) => LinkedTeamRepository.create(
    identifier: a['identifier']! as String,
    password: a['password']! as String,
    teamName: a['teamName']! as String,
    category: a['category']! as String,
    division: a['division']! as String,
    teamFormat: a['teamFormat']! as int,
  );
});
