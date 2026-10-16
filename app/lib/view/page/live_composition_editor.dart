import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/models/match_composition.dart';
import 'package:wina/providers/composition_providers.dart';
import 'package:wina/providers/live_match_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/view/page/coup_denvoi_step3_screen.dart';
import 'package:wina/view/page/gerer_equipe_composition_screen.dart';

/// Ouvre le sous-flux « Modifier composition » en cours de match — partagé
/// entre l'écran de coupure (« Pause » / « Mi-temps ») et l'écran de match en
/// direct.
///
/// Pré-charge la composition jouée (schéma + placements + numéros), ouvre
/// « composition → placement » (réattribution des seuls joueurs déjà sur le
/// terrain), puis applique la composition validée au match en direct — en
/// conservant statistiques, score, chrono et historique. Si rien n'est validé,
/// le direct reste inchangé.
void openLiveCompositionEditor(BuildContext context, WidgetRef ref) {
  final LiveMatch? live = ref.read(liveMatchProvider);
  if (live == null) return;
  final Set<String> onField = <String>{
    for (final String? id in live.assignments)
      if (id != null) id,
  };
  // Pré-charge l'état courant (schéma + placements + numéros) pour l'édition.
  ref
      .read(compositionDraftProvider.notifier)
      .loadFromComposition(
        MatchComposition(
          formationLabel: live.formationLabel,
          playerCount: live.slots.length,
          slots: live.slots,
          assignments: live.assignments,
          numbers: live.numbers,
          substituteIds: live.substituteIds,
        ),
      );
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      // Nommée comme le hub « Coup d'envoi » : le popUntil du placement remonte
      // jusqu'à cette route-frontière, qui applique alors la composition au
      // direct puis se referme.
      settings: const RouteSettings(name: kCoupDEnvoiHubRoute),
      builder: (_) => _LiveCompoEditor(allowedPlayerIds: onField),
    ),
  );
}

/// Route-frontière du sous-flux « Modifier composition » en cours de match :
/// ouvre « composition → placement », applique la composition validée au match
/// en direct, puis se referme.
class _LiveCompoEditor extends ConsumerStatefulWidget {
  const _LiveCompoEditor({required this.allowedPlayerIds});

  final Set<String> allowedPlayerIds;

  @override
  ConsumerState<_LiveCompoEditor> createState() => _LiveCompoEditorState();
}

class _LiveCompoEditorState extends ConsumerState<_LiveCompoEditor> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final MatchComposition? before = ref.read(matchDraftProvider).composition;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => GererEquipeCompositionScreen(
              allowedPlayerIds: widget.allowedPlayerIds,
            ),
      ),
    );
    if (!mounted) return;
    // Le placement écrit une nouvelle instance via setComposition. Si rien n'a
    // été validé, la composition est inchangée : on ne touche pas au direct.
    final MatchComposition? after = ref.read(matchDraftProvider).composition;
    if (after != null && !identical(after, before)) {
      ref.read(liveMatchProvider.notifier).applyComposition(after);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColor.background,
      body: SizedBox.shrink(),
    );
  }
}
