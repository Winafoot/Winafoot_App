import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/data/live_match_sync_repository.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/live_match_sync.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/live_match_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/providers/player_providers.dart';

/// Côté coach : publie l'état du match pour l'adjoint (`users/{coach}/liveMatch/current`) et applique ses
/// commandes (+1, retrait d'un événement) avec la logique habituelle de [LiveMatchNotifier]. Le téléphone du
/// coach reste la seule source de vérité ; tout se passe en tâche de fond, sans toucher à l'écran.
///
/// Une publication a lieu à chaque changement de jeu (pas à chaque seconde du chrono) et toutes les 15 s
/// pour recaler le chrono de l'adjoint. Toutes les erreurs réseau sont avalées : le coach joue d'abord,
/// la synchronisation reprend d'elle-même au retour de la connexion.
class LiveMatchCoachSync {
  LiveMatchCoachSync(this._ref);

  final WidgetRef _ref;
  ProviderSubscription<LiveMatch?>? _liveSub;
  StreamSubscription<List<LiveCommand>>? _commandSub;
  Timer? _heartbeat;
  LiveMatch? _last;
  bool _ended = false;
  bool _disposed = false;
  bool _seen = false;
  final Set<String> _applied = <String>{};

  Future<void> start() async {
    // Commandes d'un match précédent : à ne jamais rejouer.
    try {
      await LiveMatchSyncRepository.clearCommands();
    } catch (_) {}
    if (_disposed) return;
    _commandSub = LiveMatchSyncRepository.watchCommands().listen(
      _onCommands,
      onError: (Object _) {},
    );
    _liveSub = _ref.listenManual<LiveMatch?>(
      liveMatchProvider,
      (LiveMatch? prev, LiveMatch? next) => _onLive(next),
      fireImmediately: true,
    );
    _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
      final LiveMatch? s = _ref.read(liveMatchProvider);
      if (s != null && !_ended) _publish(s);
    });
  }

  void _onLive(LiveMatch? live) {
    // L'écran démarre le match juste après sa création : un état encore vide n'est pas une fin.
    if (live == null) {
      if (_seen) end();
      return;
    }
    _seen = true;
    if (_ended) return;
    final LiveMatch? last = _last;
    if (last != null && _sameGame(last, live)) return;
    _publish(live);
    if (live.status == MatchStatus.finished) _ended = true;
  }

  /// Vrai si seul le chrono (ou la sélection locale) a changé : rien à republier.
  static bool _sameGame(LiveMatch a, LiveMatch b) =>
      identical(a.playerStats, b.playerStats) &&
      identical(a.events, b.events) &&
      identical(a.assignments, b.assignments) &&
      identical(a.substituteIds, b.substituteIds) &&
      identical(a.numbers, b.numbers) &&
      identical(a.enabledStatKeys, b.enabledStatKeys) &&
      identical(a.slots, b.slots) &&
      identical(a.halfTimeStatKeys, b.halfTimeStatKeys) &&
      a.formationLabel == b.formationLabel &&
      a.scoreUs == b.scoreUs &&
      a.scoreThem == b.scoreThem &&
      a.half == b.half &&
      a.swapSides == b.swapSides &&
      a.status == b.status;

  void _publish(LiveMatch live) {
    _last = live;
    final Map<String, Player> players = <String, Player>{
      for (final Player p
          in _ref.read(playersStreamProvider).valueOrNull ?? const <Player>[])
        if (p.id != null) p.id!: p,
    };
    final GameMatch draft = _ref.read(matchDraftProvider);
    LiveMatchSyncRepository.publish(
      LiveMatchSnapshot.toJson(
        live,
        players: players,
        kit: draft.ownJersey?.color,
        opponentName: draft.opponent.name,
        matchId: draft.id,
        ended: live.status == MatchStatus.finished,
      ),
    ).catchError((Object _) {
      // État complet refusé ou perdu : au moins fermer le match pour l'adjoint.
      if (live.status == MatchStatus.finished) {
        LiveMatchSyncRepository.end().catchError((Object _) {});
      }
    });
  }

  void _onCommands(List<LiveCommand> commands) {
    final LiveMatchNotifier notifier = _ref.read(liveMatchProvider.notifier);
    for (final LiveCommand c in commands) {
      if (!_applied.add(c.id)) continue;
      final LiveMatch? live = _ref.read(liveMatchProvider);
      if (live != null && !_ended) {
        if (c.type == 'bump') {
          final String? pid = c.playerId;
          final String? key = c.statKey;
          if (pid != null &&
              key != null &&
              (c.delta == 1 || c.delta == -1) &&
              live.enabledStatKeys.contains(key)) {
            notifier.bumpFor(
              playerId: pid,
              statKey: key,
              statLabel: c.statLabel ?? key,
              playerName: c.playerName ?? '',
              delta: c.delta,
              eventId: c.eventId,
            );
          }
        } else if (c.type == 'remove') {
          notifier.removeEventById(c.eventId);
        } else if (c.type == 'swap') {
          notifier.setSwapSides(c.delta > 0);
        }
      }
      LiveMatchSyncRepository.deleteCommand(c.id).catchError((Object _) {});
    }
  }

  /// Ferme le match côté adjoint (fin, abandon ou sortie de l'écran) ; sans effet la 2e fois.
  void end() {
    if (_ended) return;
    _ended = true;
    LiveMatchSyncRepository.end().catchError((Object _) {});
  }

  void dispose() {
    _disposed = true;
    end();
    _heartbeat?.cancel();
    _commandSub?.cancel();
    _liveSub?.close();
  }
}
