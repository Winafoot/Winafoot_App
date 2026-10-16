import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/data/match_repository.dart';
import 'package:wina/models/career_stats.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/providers/auth_providers.dart';

/// Brouillon du match en cours de construction dans l'assistant « Coup
/// d'envoi ». Tenu en mémoire pendant l'assistant ; persisté via
/// [MatchRepository] aux transitions clés.
class MatchDraftNotifier extends StateNotifier<GameMatch> {
  MatchDraftNotifier() : super(const GameMatch());

  /// Réinitialise l'assistant (nouvel appui sur « Coup d'envoi »).
  void reset() => state = const GameMatch();

  void setId(String id) => state = state.copyWith(id: id);

  // ── Étape 1 — adversaire ────────────────────────────────────────────────
  void setOpponentName(String name) =>
      state = state.copyWith(opponent: state.opponent.copyWith(name: name));

  void setOpponentCategory(TeamCategory category) =>
      state = state.copyWith(
        opponent: state.opponent.copyWith(category: category),
      );

  void setOpponentDivision(TeamDivision division) =>
      state = state.copyWith(
        opponent: state.opponent.copyWith(division: division),
      );

  // ── Étape 2 — maillots ──────────────────────────────────────────────────
  void setOwnJersey(Jersey jersey) => state = state.copyWith(ownJersey: jersey);

  void setOpponentJerseyColor(JerseyColorOption color) =>
      state = state.copyWith(
        opponent: state.opponent.copyWith(jerseyColor: color),
      );

  // ── Hub — composition (« Gérer mon équipe ») ─────────────────────────────
  void setComposition(MatchComposition composition) =>
      state = state.copyWith(composition: composition);

  // ── Hub — statistiques (« Paramétrer les statistiques ») ─────────────────
  void setEnabledStats(List<String> keys) =>
      state = state.copyWith(enabledStatKeys: keys);
}

/// Brouillon du match courant (assistant « Coup d'envoi »).
final matchDraftProvider = StateNotifierProvider<MatchDraftNotifier, GameMatch>(
  (ref) => MatchDraftNotifier(),
);

/// Flux des matchs terminés (onglet « Statistiques Matchs »).
final finishedMatchesProvider = StreamProvider<List<GameMatch>>((ref) {
  final String? uid = ref.watch(authUidProvider).valueOrNull;
  if (uid == null) return Stream<List<GameMatch>>.value(const <GameMatch>[]);
  return MatchRepository.watchFinishedMatches();
});

/// Cumul des statistiques carrière par joueur (tous matchs terminés) :
/// `playerId → { statKey → cumul }`. Vide tant que le flux n'a pas chargé.
final careerStatsProvider = Provider<Map<String, Map<String, int>>>((ref) {
  final List<GameMatch> matches =
      ref.watch(finishedMatchesProvider).valueOrNull ?? const <GameMatch>[];
  return aggregateCareerStats(matches);
});
