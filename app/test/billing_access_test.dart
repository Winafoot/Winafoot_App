import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/billing/access_info.dart';

final DateTime _now = DateTime.utc(2026, 10, 22, 12);

Map<String, dynamic> _doc({bool active = true, DateTime? until, String? ownerUid, int? teamIndex, int teamsAllowed = 2}) => <String, dynamic>{
  'access': <String, dynamic>{'active': active, 'until': Timestamp.fromDate(until ?? _now.add(const Duration(days: 30)))},
  if (ownerUid != null) 'ownerUid': ownerUid,
  if (teamIndex != null) 'teamIndex': teamIndex,
  'subscription': <String, dynamic>{
    'productId': 'wina_team2_yearly',
    'status': 'active',
    'teamsAllowed': teamsAllowed,
    'expiresAt': Timestamp.fromDate(_now.add(const Duration(days: 30))),
  },
};

void main() {
  group('AccessInfo.fromUserData', () {
    test('lit l\'accès, le propriétaire et l\'abonnement', () {
      final AccessInfo info = AccessInfo.fromUserData(_doc(ownerUid: 'o1', teamIndex: 2));
      expect(info.active, isTrue);
      expect(info.isLinked, isTrue);
      expect(info.teamIndex, 2);
      expect(info.teamsAllowed, 2);
    });

    test('une fiche sans accès est inactive', () {
      final AccessInfo info = AccessInfo.fromUserData(<String, dynamic>{'firstname': 'A'});
      expect(info.active, isFalse);
      expect(info.activeAt(_now), isFalse);
      expect(info.isLinked, isFalse);
    });

    test('une fiche absente ou mal formée ne plante pas', () {
      expect(AccessInfo.fromUserData(null).active, isFalse);
      expect(AccessInfo.fromUserData(<String, dynamic>{'access': 'oups'}).active, isFalse);
    });
  });

  group('decideAccess', () {
    test('mur désactivé : toujours ouvert', () {
      expect(decideAccess(paywallEnforced: false, info: const AccessInfo(), now: _now), AccessDecision.open);
    });

    test('mur activé, accès actif : ouvert', () {
      expect(decideAccess(paywallEnforced: true, info: AccessInfo.fromUserData(_doc()), now: _now), AccessDecision.open);
    });

    test('mur activé, accès expiré : mur de paiement pour un propriétaire', () {
      final AccessInfo info = AccessInfo.fromUserData(_doc(until: _now.subtract(const Duration(seconds: 1))));
      expect(decideAccess(paywallEnforced: true, info: info, now: _now), AccessDecision.paywall);
    });

    test('mur activé, accès inactif : équipe bloquée pour un compte lié', () {
      final AccessInfo info = AccessInfo.fromUserData(_doc(active: false, ownerUid: 'o1', teamIndex: 2));
      expect(decideAccess(paywallEnforced: true, info: info, now: _now), AccessDecision.linkedBlocked);
    });
  });

  group('missingTeams', () {
    test('formule à 3 équipes avec 1 équipe liée : il en manque 1', () {
      expect(missingTeams(AccessInfo.fromUserData(_doc(teamsAllowed: 3)), linkedCount: 1, now: _now), 1);
    });

    test('jamais négatif, et 0 sans accès ou pour un compte lié', () {
      expect(missingTeams(AccessInfo.fromUserData(_doc(teamsAllowed: 2)), linkedCount: 5, now: _now), 0);
      expect(missingTeams(AccessInfo.fromUserData(_doc(active: false)), linkedCount: 0, now: _now), 0);
      expect(missingTeams(AccessInfo.fromUserData(_doc(ownerUid: 'o1', teamIndex: 2)), linkedCount: 0, now: _now), 0);
    });
  });
}
