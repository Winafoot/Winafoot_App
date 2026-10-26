import 'package:flutter/foundation.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/player.dart';

/// Match en direct tel que le coach le publie dans `users/{coach}/liveMatch/current` et que l'adjoint le
/// lit : l'état de jeu, les joueurs concernés (l'adjoint ne peut pas lire l'effectif), la couleur du
/// maillot et l'adversaire. La sélection d'un joueur reste locale à chaque téléphone.
@immutable
class LiveMatchSnapshot {
  const LiveMatchSnapshot({
    required this.live,
    required this.players,
    required this.ended,
    this.kit,
    this.opponentName = '',
    this.matchId,
    this.updatedAtMs,
  });

  final LiveMatch live;
  final Map<String, Player> players;
  final bool ended;
  final JerseyColorOption? kit;
  final String opponentName;
  final String? matchId;

  /// Instant (serveur) de la dernière publication du coach : l'adjoint s'en sert pour savoir si le coach
  /// est toujours là. `null` tant que l'écriture n'est pas confirmée par le serveur.
  final int? updatedAtMs;

  /// Document Firestore publié par le coach. `ended: true` ferme le match côté adjoint.
  static Map<String, dynamic> toJson(
    LiveMatch live, {
    required Map<String, Player> players,
    JerseyColorOption? kit,
    String opponentName = '',
    String? matchId,
    bool ended = false,
  }) {
    final Set<String> ids = <String>{
      for (final String? a in live.assignments)
        if (a != null) a,
      ...live.substituteIds,
    };
    return <String, dynamic>{
      'matchId': matchId,
      'status': ended ? 'ended' : (live.isPaused ? 'paused' : 'live'),
      'half': live.half,
      'elapsedSeconds': live.elapsedSeconds,
      'scoreUs': live.scoreUs,
      'scoreThem': live.scoreThem,
      'formationLabel': live.formationLabel,
      'slots': <Map<String, dynamic>>[
        for (final FormationSlot s in live.slots)
          <String, dynamic>{'role': s.role.name, 'x': s.x, 'y': s.y},
      ],
      'assignments': live.assignments,
      'numbers': live.numbers,
      'substituteIds': live.substituteIds,
      'enabledStatKeys': live.enabledStatKeys,
      'halfTimeStatKeys': live.halfTimeStatKeys,
      'swapSides': live.swapSides,
      'playerStats': live.playerStats,
      'events': <Map<String, dynamic>>[
        for (final MatchEvent e in live.events)
          <String, dynamic>{
            'id': e.id,
            'at': e.atSeconds,
            'pid': e.playerId,
            'pn': e.playerName,
            'sk': e.statKey,
            'sl': e.statLabel,
            'd': e.delta,
            'h': e.half,
          },
      ],
      'players': <String, dynamic>{
        for (final String id in ids)
          if (players[id] != null) id: players[id]!.toJson(),
      },
      'kit': kit?.name,
      'opponentName': opponentName,
    };
  }

  static int _int(Object? v, [int fallback = 0]) =>
      v is num ? v.toInt() : fallback;

  factory LiveMatchSnapshot.fromJson(Map<String, dynamic> json) {
    final String status = (json['status'] as String?) ?? 'ended';
    final List<dynamic> rawSlots = (json['slots'] as List<dynamic>?) ?? const [];
    final Map<dynamic, dynamic> rawStats =
        (json['playerStats'] as Map<dynamic, dynamic>?) ?? const {};
    final Map<dynamic, dynamic> rawNumbers =
        (json['numbers'] as Map<dynamic, dynamic>?) ?? const {};
    final Map<dynamic, dynamic> rawPlayers =
        (json['players'] as Map<dynamic, dynamic>?) ?? const {};

    final LiveMatch live = LiveMatch(
      formationLabel: (json['formationLabel'] as String?) ?? '',
      slots: <FormationSlot>[
        for (final dynamic s in rawSlots)
          if (s is Map) FormationSlot.fromJson(s),
      ],
      assignments: <String?>[
        for (final dynamic a in (json['assignments'] as List<dynamic>?) ?? const [])
          a is String ? a : null,
      ],
      enabledStatKeys:
          ((json['enabledStatKeys'] as List<dynamic>?) ?? const [])
              .whereType<String>()
              .toList(),
      numbers: <String, int>{
        for (final MapEntry<dynamic, dynamic> e in rawNumbers.entries)
          if (e.key is String) e.key as String: _int(e.value),
      },
      substituteIds:
          ((json['substituteIds'] as List<dynamic>?) ?? const [])
              .whereType<String>()
              .toList(),
      playerStats: <String, Map<String, int>>{
        for (final MapEntry<dynamic, dynamic> p in rawStats.entries)
          if (p.key is String && p.value is Map)
            p.key as String: <String, int>{
              for (final MapEntry<dynamic, dynamic> s
                  in (p.value as Map<dynamic, dynamic>).entries)
                if (s.key is String) s.key as String: _int(s.value),
            },
      },
      swapSides: json['swapSides'] == true,
      scoreUs: _int(json['scoreUs']),
      scoreThem: _int(json['scoreThem']),
      elapsedSeconds: _int(json['elapsedSeconds']),
      half: _int(json['half'], 1),
      status: status == 'paused' ? MatchStatus.paused : MatchStatus.live,
      events: <MatchEvent>[
        for (final dynamic e in (json['events'] as List<dynamic>?) ?? const [])
          if (e is Map)
            MatchEvent(
              id: (e['id'] as String?) ?? '',
              atSeconds: _int(e['at']),
              playerId: (e['pid'] as String?) ?? '',
              playerName: (e['pn'] as String?) ?? '',
              statKey: (e['sk'] as String?) ?? '',
              statLabel: (e['sl'] as String?) ?? '',
              delta: _int(e['d'], 1),
              half: _int(e['h'], 1),
            ),
      ],
      halfTimeStatKeys:
          (json['halfTimeStatKeys'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(),
    );

    return LiveMatchSnapshot(
      live: live,
      players: <String, Player>{
        for (final MapEntry<dynamic, dynamic> e in rawPlayers.entries)
          if (e.key is String && e.value is Map)
            e.key as String: Player.fromDoc(
              e.key as String,
              Map<String, dynamic>.from(e.value as Map),
            ),
      },
      ended: status == 'ended',
      kit: JerseyColorOption.values.asNameMap()[json['kit']],
      opponentName: (json['opponentName'] as String?) ?? '',
      matchId: json['matchId'] as String?,
      updatedAtMs: (json['updatedAtMs'] as num?)?.toInt(),
    );
  }
}
