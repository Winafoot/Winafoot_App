import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// Accès d'un compte, tel que le serveur l'écrit dans `users/{uid}` (billing/store.ts) :
/// `access: { active, until }`, et pour un compte lié `ownerUid` et `teamIndex`.
class AccessInfo {
  const AccessInfo({
    this.active = false,
    this.until,
    this.ownerUid,
    this.teamIndex,
    this.teamsAllowed,
    this.expiresAt,
    this.productId,
    this.period,
  });

  factory AccessInfo.fromUserData(Map<String, dynamic>? data) {
    if (data == null) return const AccessInfo();
    final Object? access = data['access'];
    final Object? subscription = data['subscription'];
    final Map<String, dynamic>? a =
        access is Map<String, dynamic> ? access : null;
    final Map<String, dynamic>? s =
        subscription is Map<String, dynamic> ? subscription : null;
    final Object? teamIndex = data['teamIndex'];
    final Object? teamsAllowed = s?['teamsAllowed'];
    return AccessInfo(
      active: a?['active'] == true,
      until:
          a?['until'] is Timestamp ? (a!['until'] as Timestamp).toDate() : null,
      ownerUid: data['ownerUid'] is String ? data['ownerUid'] as String : null,
      teamIndex: teamIndex is int ? teamIndex : null,
      teamsAllowed: teamsAllowed is int ? teamsAllowed : null,
      productId: s?['productId'] is String ? s!['productId'] as String : null,
      period: s?['period'] is String ? s!['period'] as String : null,
      expiresAt:
          s?['expiresAt'] is Timestamp
              ? (s!['expiresAt'] as Timestamp).toDate()
              : null,
    );
  }

  final bool active;
  final DateTime? until;
  final String? ownerUid;
  final int? teamIndex;
  final int? teamsAllowed;
  final DateTime? expiresAt;

  /// Produit et période de l'abonnement en cours (`subscription.productId` / `period`), pour proposer un
  /// changement de formule.
  final String? productId;
  final String? period;

  /// Compte d'équipe lié : il hérite de l'abonnement de son propriétaire.
  bool get isLinked => ownerUid != null;

  bool activeAt(DateTime now) => active && until != null && until!.isAfter(now);
}

enum AccessDecision { open, paywall, linkedBlocked }

/// Ce que l'app affiche. Le mur désactivé (`app_config/config.paywall_enforced` absent ou faux) laisse tout
/// ouvert, comme les règles Firestore.
AccessDecision decideAccess({
  required bool paywallEnforced,
  required AccessInfo info,
  required DateTime now,
}) {
  if (!paywallEnforced) return AccessDecision.open;
  if (info.activeAt(now)) return AccessDecision.open;
  return info.isLinked ? AccessDecision.linkedBlocked : AccessDecision.paywall;
}

/// Équipes liées encore à créer pour un propriétaire dont l'abonnement est actif.
int missingTeams(
  AccessInfo info, {
  required int linkedCount,
  required DateTime now,
}) {
  if (info.isLinked || !info.activeAt(now)) return 0;
  final int missing = (info.teamsAllowed ?? 1) - 1 - linkedCount;
  return missing < 0 ? 0 : missing;
}
