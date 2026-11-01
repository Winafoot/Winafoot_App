import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/data/assistant_repository.dart';
import 'package:wina/data/live_match_sync_repository.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/live_match_sync.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/auth_providers.dart';
import 'package:wina/providers/live_match_providers.dart';

/// Uid du coach dont le compte connecté est l'adjoint ; `null` pour un coach ou une équipe liée.
/// Se recalcule à chaque changement de compte.
final assistantOfProvider = FutureProvider<String?>((ref) {
  ref.watch(authUidProvider);
  return AssistantRepository.currentAssistantOf();
});

/// Adjoint du coach connecté (Paramètres → « Mon adjoint »), en temps réel.
final myAssistantProvider = StreamProvider<Assistant?>((ref) {
  final String? uid = ref.watch(authUidProvider).valueOrNull;
  if (uid == null) return Stream<Assistant?>.value(null);
  return AssistantRepository.watch(uid);
});

/// Match en cours publié par le coach, vu par l'adjoint ; `null` tant qu'aucun match n'a commencé.
/// Flux Firestore : les valeurs changent à l'écran sans rechargement.
final assistantSnapshotProvider = StreamProvider<LiveMatchSnapshot?>((ref) {
  final String? coach = ref.watch(
    assistantOfProvider.select((AsyncValue<String?> v) => v.valueOrNull),
  );
  if (coach == null) return Stream<LiveMatchSnapshot?>.value(null);
  return LiveMatchSyncRepository.watch(coach);
});

/// Joueurs du match en cours, tels que le coach les publie (l'adjoint ne lit pas l'effectif).
final assistantPlayersProvider = Provider<List<Player>>((ref) {
  final LiveMatchSnapshot? s = ref.watch(assistantSnapshotProvider).valueOrNull;
  return s == null ? const <Player>[] : s.players.values.toList();
});

/// Couleur du maillot de l'équipe, publiée par le coach.
final assistantKitProvider = Provider<JerseyColorOption?>((ref) {
  return ref.watch(assistantSnapshotProvider).valueOrNull?.kit;
});

/// Le coach n'a rien publié depuis plus d'une minute (appli fermée, plantée ou hors connexion) : l'adjoint
/// attend son retour, chrono arrêté.
final assistantCoachAwayProvider = StateProvider<bool>((ref) => false);

class _Pending {
  _Pending(this.eventId, this.isRemove) : at = DateTime.now();

  final String eventId;
  final bool isRemove;
  final DateTime at;
}

/// État du match côté adjoint : le miroir de l'état publié par le coach, avec l'affichage immédiat de ses
/// propres saisies. Chaque saisie part en commande vers le coach ; tant que l'état publié ne la reflète pas
/// encore, elle est rejouée par-dessus (aucun clignotement quand un état un peu ancien arrive).
class AssistantLiveNotifier extends LiveMatchNotifier {
  AssistantLiveNotifier(this._ref, this._coachUid) {
    _ref.listen<AsyncValue<LiveMatchSnapshot?>>(
      assistantSnapshotProvider,
      (_, AsyncValue<LiveMatchSnapshot?> next) => _onRemote(next.valueOrNull),
      fireImmediately: true,
    );
  }

  final Ref _ref;
  final String _coachUid;

  /// Dernière publication du coach vue, et quand : le coach publie au moins toutes les 15 s.
  int? _lastStamp;
  DateTime _lastBeat = DateTime.now();
  static const Duration _awayAfter = Duration(seconds: 60);
  final List<_Pending> _pending = <_Pending>[];

  /// Sens du terrain demandé par l'adjoint, tant que l'état publié ne l'a pas encore repris.
  bool? _pendingSwap;
  DateTime _pendingSwapAt = DateTime.now();

  static const Duration _pendingTtl = Duration(seconds: 20);

  void _onRemote(LiveMatchSnapshot? snap) {
    if (snap == null || snap.ended) {
      _pending.clear();
      state = null;
      return;
    }
    if (snap.updatedAtMs == null || snap.updatedAtMs != _lastStamp) {
      _lastStamp = snap.updatedAtMs;
      _lastBeat = DateTime.now();
      if (_ref.read(assistantCoachAwayProvider)) {
        _ref.read(assistantCoachAwayProvider.notifier).state = false;
      }
    }
    final DateTime now = DateTime.now();
    bool? swap = _pendingSwap;
    if (swap != null &&
        (swap == snap.live.swapSides ||
            now.difference(_pendingSwapAt) > _pendingTtl)) {
      _pendingSwap = swap = null;
    }
    state = snap.live.copyWith(
      selectedPlayerId: state?.selectedPlayerId,
      swapSides: swap,
    );
    _pending.removeWhere((_Pending p) {
      final bool present = snap.live.events.any(
        (MatchEvent e) => e.id == p.eventId,
      );
      return (p.isRemove ? !present : present) ||
          now.difference(p.at) > _pendingTtl;
    });
    for (final _Pending p in _pending) {
      if (p.isRemove) {
        super.removeEventById(p.eventId);
      } else {
        final MatchEvent? e = _optimistic[p.eventId];
        if (e != null) {
          super.bumpFor(
            playerId: e.playerId,
            statKey: e.statKey,
            statLabel: e.statLabel,
            playerName: e.playerName,
            delta: e.delta,
            eventId: e.id,
          );
        }
      }
    }
    _optimistic.removeWhere(
      (String id, MatchEvent _) => !_pending.any((_Pending p) => p.eventId == id),
    );
  }

  /// Saisies de l'adjoint en attente de confirmation, par identifiant d'événement.
  final Map<String, MatchEvent> _optimistic = <String, MatchEvent>{};

  @override
  void bumpFor({
    required String playerId,
    required String statKey,
    required String statLabel,
    required String playerName,
    required int delta,
    String? eventId,
  }) {
    final String id = eventId ?? newEventId();
    super.bumpFor(
      playerId: playerId,
      statKey: statKey,
      statLabel: statLabel,
      playerName: playerName,
      delta: delta,
      eventId: id,
    );
    final LiveMatch? s = state;
    // Plafond atteint : aucun événement créé, rien à envoyer.
    if (s == null || !s.events.any((MatchEvent e) => e.id == id)) return;
    _optimistic[id] = MatchEvent(
      id: id,
      atSeconds: s.elapsedSeconds,
      playerId: playerId,
      playerName: playerName,
      statKey: statKey,
      statLabel: statLabel,
      delta: delta,
      half: s.half,
    );
    _pending.add(_Pending(id, false));
    LiveMatchSyncRepository.sendBump(
      _coachUid,
      eventId: id,
      playerId: playerId,
      playerName: playerName,
      statKey: statKey,
      statLabel: statLabel,
      delta: delta,
    ).catchError((Object _) {
      _pending.removeWhere((_Pending p) => p.eventId == id);
      _optimistic.remove(id);
      super.removeEventById(id);
    });
  }

  @override
  void tick() {
    final bool away = DateTime.now().difference(_lastBeat) > _awayAfter;
    if (_ref.read(assistantCoachAwayProvider) != away) {
      _ref.read(assistantCoachAwayProvider.notifier).state = away;
    }
    if (!away) super.tick();
  }

  @override
  void setSwapSides(bool value) {
    if (state == null || state!.swapSides == value) return;
    super.setSwapSides(value);
    _pendingSwap = value;
    _pendingSwapAt = DateTime.now();
    LiveMatchSyncRepository.sendSwap(_coachUid, value).catchError((Object _) {
      _pendingSwap = null;
    });
  }

  @override
  void removeEvent(int index) {
    final LiveMatch? s = state;
    if (s == null || index < 0 || index >= s.events.length) return;
    final String id = s.events[index].id;
    if (id.isEmpty) return;
    super.removeEvent(index);
    _pending.add(_Pending(id, true));
    LiveMatchSyncRepository.sendRemove(_coachUid, id).catchError((Object _) {
      _pending.removeWhere((_Pending p) => p.eventId == id);
    });
  }
}
