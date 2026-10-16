import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/data/player_repository.dart';
import 'package:wina/models/formation.dart' show PlayerCount;
import 'package:wina/models/player.dart';
import 'package:wina/providers/auth_providers.dart';
import 'package:wina/providers/coach_providers.dart';

/// Flux temps réel de l'effectif du coach connecté
/// (`users/{uid}/players`). Émet à chaque création / modification /
/// suppression de joueur. Rattaché à [authUidProvider] pour se reconstruire à
/// chaque changement de session (déconnexion / reconnexion).
final playersStreamProvider = StreamProvider<List<Player>>((ref) {
  final String? uid = ref.watch(authUidProvider).valueOrNull;
  if (uid == null) return Stream<List<Player>>.value(const <Player>[]);
  return PlayerRepository.watchPlayers();
});

/// Plafond d'effectif effectif : celui du format du club (`teamFormat`, 5 → 9,
/// 8 → 14, 11 → 20) s'il est connu, sinon `app_config/config.max_players`
/// (repli 20 : jamais le plafond d'un petit format).
///
/// Exposé comme provider pour que l'INTERFACE dise la même chose que
/// l'enforcement : les libellés « X sur N joueurs » et les boutons désactivés
/// s'alignaient jusqu'ici sur la constante de repli, si bien qu'un plafond
/// différent appliqué par les règles Firestore n'aurait jamais été affiché.
/// Dérivé du profil, lui-même rattaché à [authUidProvider] : le plafond suit le
/// compte connecté, sans cache propre.
///
/// Utiliser `ref.watch(maxSquadSizeProvider).valueOrNull ?? kMaxSquadSize` :
/// pendant le chargement, mieux vaut le repli historique qu'un « X sur 0 ».
final maxSquadSizeProvider = FutureProvider<int>((ref) async {
  final PlayerCount? format = ref.watch(teamFormatProvider);
  return format?.maxSquadSize ?? await PlayerRepository.configMaxSquadSize();
});
