import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/data/coach_profile_repository.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/formation.dart' show PlayerCount;
import 'package:wina/providers/auth_providers.dart';

/// Flux temps réel du profil coach / équipe (nom d'équipe, catégorie, division,
/// nom du coach) affiché dans l'entête de « Mon équipe ». Rattaché à
/// [authUidProvider] pour se reconstruire à chaque changement de session.
final coachProfileProvider = StreamProvider<CoachProfile>((ref) {
  final String? uid = ref.watch(authUidProvider).valueOrNull;
  if (uid == null) {
    return Stream<CoachProfile>.value(
      CoachProfile.fromJson(const <String, dynamic>{}),
    );
  }
  return CoachProfileRepository.watchCoachProfile();
});

/// Format du club (5 / 8 / 11 joueurs) : `null` tant que le profil charge et
/// pour les comptes qui n'en ont pas (comportement historique).
///
/// Pendant un rechargement (changement de compte), `valueOrNull` garde le profil
/// du compte précédent : on l'ignore, sinon le nouveau compte hériterait un
/// instant du format — donc du plafond — de l'ancien.
final teamFormatProvider = Provider<PlayerCount?>((ref) {
  final AsyncValue<CoachProfile> profile = ref.watch(coachProfileProvider);
  return profile.isLoading ? null : profile.valueOrNull?.teamFormat;
});

/// Flux temps réel des maillots de l'équipe (sélecteur de l'entête).
final jerseysProvider = StreamProvider<List<Jersey>>((ref) {
  final String? uid = ref.watch(authUidProvider).valueOrNull;
  if (uid == null) return Stream<List<Jersey>>.value(const <Jersey>[]);
  return CoachProfileRepository.watchJerseys();
});
