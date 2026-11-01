import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/data/composition_repository.dart';
import 'package:wina/models/custom_composition.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/providers/auth_providers.dart';

/// Taille du pool de numéros remplaçants (grille bleue « Numéros des
/// remplaçants », design 1:424). Ce pool commence APRÈS celui des titulaires
/// (12 à 16 dans un 11 contre 11) : les numéros étant uniques dans toute
/// l'équipe, des pools qui se recouvrent rendraient tout numéro de remplaçant
/// indisponible dès que les titulaires occupent 1 à 5.
const int kSubPoolSize = 5;

/// Plus grand numéro proposé par la grille « Sélectionnez les numéros des
/// remplaçants » (36 puces à la maquette, 6 par ligne sur 6 lignes).
const int kJerseyGridMax = 36;

/// Composition en cours de construction dans le sous-flux « Gérer mon équipe »
/// (nombre de joueurs → numéros/capitaine/remplaçants → schéma → placement).
/// Tenue en mémoire ; validée puis rattachée au match à la sortie du sous-flux.
@immutable
class CompositionDraft {
  const CompositionDraft({
    this.playerCount,
    this.formation,
    this.formationName,
    this.assignments = const <int, String>{},
    this.numbers = const <String, int>{},
    this.captainId,
    this.substituteIds = const <String>{},
    this.subNumbers = const <int>{},
  });

  final int? playerCount;
  final Formation? formation;

  /// Nom de la composition personnalisée choisie (`null` pour un standard).
  final String? formationName;

  /// Joueur placé sur chaque emplacement : index d'emplacement → playerId.
  final Map<int, String> assignments;

  /// Numéro de maillot attribué à chaque joueur : playerId → numéro.
  final Map<String, int> numbers;

  /// Joueur portant le brassard de capitaine (`null` si aucun).
  final String? captainId;

  /// Joueurs marqués comme remplaçants.
  final Set<String> substituteIds;

  /// Numéros que le coach a réservés aux remplaçants, choisis librement dans la
  /// popup qui précède l'étape « Attribuez les numéros ». Vide = repli sur
  /// l'ancien intervalle contigu `playerCount + 1 .. + kSubPoolSize`, ce qui
  /// garde valides les brouillons rechargés depuis une composition existante.
  final Set<int> subNumbers;

  bool get hasCount => playerCount != null;
  bool get hasFormation => formation != null;
  int get slotCount => formation?.slots.length ?? 0;
  int get placedCount => assignments.length;
  bool get allPlaced => hasFormation && placedCount == slotCount;

  CompositionDraft copyWith({
    int? playerCount,
    Formation? formation,
    String? formationName,
    Map<int, String>? assignments,
    Map<String, int>? numbers,
    String? captainId,
    bool clearCaptain = false,
    Set<String>? substituteIds,
    Set<int>? subNumbers,
  }) {
    return CompositionDraft(
      playerCount: playerCount ?? this.playerCount,
      formation: formation ?? this.formation,
      formationName: formationName ?? this.formationName,
      assignments: assignments ?? this.assignments,
      numbers: numbers ?? this.numbers,
      captainId: clearCaptain ? null : (captainId ?? this.captainId),
      substituteIds: substituteIds ?? this.substituteIds,
      subNumbers: subNumbers ?? this.subNumbers,
    );
  }
}

class CompositionDraftNotifier extends StateNotifier<CompositionDraft> {
  CompositionDraftNotifier() : super(const CompositionDraft());

  void reset() => state = const CompositionDraft();

  /// Choisit le nombre de joueurs (réinitialise tout le reste : nouvelle équipe).
  void setCount(int count) => state = CompositionDraft(playerCount: count);

  /// Numéros réservés aux remplaçants, choisis librement parmi les 36 de la
  /// grille — y compris ceux que la grille titulaire propose aussi : c'est un
  /// choix du coach, et l'unicité reste garantie à l'attribution par
  /// `setNumber`, qui retire le numéro à celui qui le portait.
  ///
  /// Les numéros déjà attribués à un remplaçant qui sortent du choix lui sont
  /// retirés : sans cela il garderait un numéro que plus aucune grille
  /// n'affiche, donc invisible et impossible à modifier.
  void setSubNumbers(Set<int> numbers) {
    final Set<int> next = <int>{...numbers};
    final Map<String, int> keptNumbers = <String, int>{
      for (final MapEntry<String, int> e in state.numbers.entries)
        if (!state.substituteIds.contains(e.key) || next.contains(e.value))
          e.key: e.value,
    };
    state = state.copyWith(
      subNumbers: next,
      numbers: keptNumbers,
      substituteIds: state.substituteIds.intersection(keptNumbers.keys.toSet()),
    );
  }

  /// Choisit le schéma (réinitialise seulement les placements : les
  /// emplacements changent). Numéros / capitaine / remplaçants sont conservés
  /// car ils portent sur les joueurs, pas sur le schéma. [name] porte le nom de
  /// la composition personnalisée choisie (`null` pour un schéma standard).
  void setFormation(Formation formation, {String? name}) =>
      state = CompositionDraft(
        playerCount: state.playerCount,
        formation: formation,
        formationName: name,
        numbers: state.numbers,
        captainId: state.captainId,
        substituteIds: state.substituteIds,
      );

  /// Attribue [number] à [playerId] depuis le pool titulaire ou remplaçant
  /// (design « Attribuer les numéros » / « Numéros des remplaçants », deux
  /// grilles séparées : cf. Figma 1:421 / 1:424). Un numéro est unique dans
  /// TOUTE l'équipe : il est retiré du joueur qui le portait éventuellement,
  /// quel que soit son pool (un titulaire et un remplaçant ne peuvent pas
  /// partager le même numéro). Le statut remplaçant de [playerId] suit
  /// automatiquement le pool choisi — c'est le pool qui fait foi, il n'y a
  /// plus de bascule manuelle indépendante : le bloc Remplaçants liste tous
  /// les joueurs ayant un numéro de remplaçant attribué.
  void setNumber(String playerId, int number, {required bool isSubstitute}) {
    // Porteur actuel de ce numéro, titulaire ou remplaçant (au plus un,
    // l'unicité étant maintenue à chaque attribution) : il en est dépossédé.
    String? previous;
    for (final MapEntry<String, int> e in state.numbers.entries) {
      if (e.value == number && e.key != playerId) {
        previous = e.key;
      }
    }
    final Map<String, int> nextNumbers =
        Map<String, int>.from(state.numbers)
          ..remove(previous)
          ..[playerId] = number;
    final Set<String> nextSubs = Set<String>.from(state.substituteIds);
    // Un remplaçant dépossédé de son numéro sort aussi du bloc « Remplaçants » :
    // ce bloc est la liste des joueurs ayant un numéro de remplaçant, le laisser
    // dans `substituteIds` sans entrée dans `numbers` le ferait réapparaître en
    // match sans numéro de maillot.
    if (previous != null) nextSubs.remove(previous);
    if (isSubstitute) {
      nextSubs.add(playerId);
    } else {
      nextSubs.remove(playerId);
    }
    state = state.copyWith(numbers: nextNumbers, substituteIds: nextSubs);
  }

  void clearNumber(String playerId) {
    final Map<String, int> nextNumbers = Map<String, int>.from(state.numbers)
      ..remove(playerId);
    final Set<String> nextSubs = Set<String>.from(state.substituteIds)
      ..remove(playerId);
    state = state.copyWith(numbers: nextNumbers, substituteIds: nextSubs);
  }

  /// Bascule le brassard de capitaine sur [playerId] (exclusif).
  void toggleCaptain(String playerId) {
    if (state.captainId == playerId) {
      state = state.copyWith(clearCaptain: true);
    } else {
      state = state.copyWith(captainId: playerId);
    }
  }

  /// Place [playerId] sur l'emplacement [slot]. Un joueur n'occupe qu'un seul
  /// emplacement : il est retiré de son emplacement précédent le cas échéant.
  void assign(int slot, String playerId) {
    final Map<int, String> next =
        Map<int, String>.from(state.assignments)
          ..removeWhere((int _, String id) => id == playerId)
          ..[slot] = playerId;
    state = state.copyWith(assignments: next);
  }

  void unassign(int slot) {
    final Map<int, String> next = Map<int, String>.from(state.assignments)
      ..remove(slot);
    state = state.copyWith(assignments: next);
  }

  /// Recharge le brouillon depuis une composition déjà validée (ex. celle
  /// attachée au match courant, quand on rouvre « Gérer mon équipe » après un
  /// « Copier depuis un match précédent » — cf. `coup_denvoi_step3_screen.dart`).
  ///
  /// [maxSquad] : effectif maximum du format du club. La grille « Attribuer les numéros » propose tous les
  /// maillots jusque-là (9 en foot à 5, 14 à 8, 20 à 11) : sans lui, un numéro de titulaire au-dessus de
  /// `playerCount + kSubPoolSize` serait purgé au rechargement.
  void loadFromComposition(MatchComposition composition, {int? maxSquad}) {
    // Numéros relus : on ne garde que ceux que les deux grilles réunies savent
    // encore offrir (1..playerCount + kSubPoolSize) et on fait tomber les
    // DOUBLONS — c'est le doublon qui pose problème, pas le pool d'origine.
    // Ne pas indexer la plage sur `substituteIds` : ce statut n'est ni stable
    // (une entrée en jeu retire le joueur du banc en lui laissant son numéro de
    // remplaçant) ni rétro-compatible (les compositions déjà en base portent
    // des numéros de remplaçants dans 1..playerCount, ancien pool) — le faire
    // effacerait des numéros parfaitement légitimes.
    // Les titulaires sont servis en premier : en cas de collision héritée,
    // c'est le remplaçant qui perd son numéro (et sort donc du bloc
    // « Remplaçants », cf. `setNumber`). `playerCount <= 0` : composition
    // Firestore sans le champ — on ne filtre que les doublons.
    final int maxNumber =
        composition.playerCount > 0
            ? math.max(composition.playerCount + kSubPoolSize, maxSquad ?? 0)
            : 1 << 30;
    final Map<String, int> nextNumbers = <String, int>{};
    final Set<int> used = <int>{};
    for (final MapEntry<String, int> e in <MapEntry<String, int>>[
      ...composition.numbers.entries.where(
        (MapEntry<String, int> e) => !composition.substituteIds.contains(e.key),
      ),
      ...composition.numbers.entries.where(
        (MapEntry<String, int> e) => composition.substituteIds.contains(e.key),
      ),
    ]) {
      if (e.value < 1 || e.value > maxNumber) continue;
      if (!used.add(e.value)) continue;
      nextNumbers[e.key] = e.value;
    }
    state = CompositionDraft(
      playerCount: composition.playerCount,
      formation: Formation(
        label: composition.formationLabel,
        playerCount: composition.playerCount,
        slots: composition.slots,
      ),
      formationName: composition.name,
      assignments: <int, String>{
        for (int i = 0; i < composition.assignments.length; i++)
          if (composition.assignments[i] != null)
            i: composition.assignments[i]!,
      },
      numbers: nextNumbers,
      captainId: composition.captainId,
      subNumbers: <int>{
        for (final MapEntry<String, int> e in nextNumbers.entries)
          if (composition.substituteIds.contains(e.key)) e.value,
      },
      // Le bloc « Remplaçants » est la liste des joueurs AYANT un numéro de
      // remplaçant : un remplaçant dont le numéro vient de tomber en sort, sans
      // quoi il réapparaîtrait maillot vide en match (même invariant que
      // `setNumber`).
      // Le statut remplaçant suit le pool du numéro — l'invariant que `setNumber`
      // maintient à l'attribution (« c'est le pool qui fait foi »). Le pool
      // titulaire s'arrêtant à `playerCount`, un numéro au-dessus ne peut venir
      // que de la grille des remplaçants. Sans cette dérivation, un joueur entré
      // en jeu pendant un match — `LiveMatchNotifier.substitute` le retire du
      // banc en lui laissant son numéro — revenait ici en maillot d'ÉQUIPE alors
      // que son numéro restait grisé dans la grille des remplaçants.
      substituteIds: <String>{
        for (final MapEntry<String, int> e in nextNumbers.entries)
          if (composition.substituteIds.contains(e.key) ||
              (composition.playerCount > 0 &&
                  e.value > composition.playerCount))
            e.key,
      },
    );
  }
}

final compositionDraftProvider =
    StateNotifierProvider<CompositionDraftNotifier, CompositionDraft>(
      (ref) => CompositionDraftNotifier(),
    );

/// Flux temps réel des compositions personnalisées du coach connecté
/// (`users/{uid}/compositions`). Alimente la section « Mes compositions
/// personnalisées » de l'écran de choix de composition.
final customCompositionsProvider = StreamProvider<List<CustomComposition>>((
  ref,
) {
  final String? uid = ref.watch(authUidProvider).valueOrNull;
  if (uid == null) {
    return Stream<List<CustomComposition>>.value(const <CustomComposition>[]);
  }
  return CompositionRepository.watchCustomCompositions();
});
