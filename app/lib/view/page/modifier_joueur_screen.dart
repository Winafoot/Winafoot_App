import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wina/data/player_repository.dart';
import 'package:wina/models/player.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/player_form.dart';

/// Page « Modifier un joueur » : formulaire pré-rempli avec les informations
/// du joueur. « Enregistrer » persiste la modification dans Firestore
/// (`users/{uid}/players`) puis revient en arrière.
class ModifierJoueurScreen extends StatelessWidget {
  const ModifierJoueurScreen({super.key, required this.player});

  final Player player;

  Future<void> _save(
    BuildContext context,
    String firstName,
    String lastName,
    StrongFoot foot,
    PlayerPosition position,
  ) async {
    final Player updated = player.copyWith(
      firstName: firstName,
      lastName: lastName,
      strongFoot: foot,
      position: position,
    );
    try {
      await PlayerRepository.updatePlayer(updated);
    } catch (_) {
      if (!context.mounted) return;
      showAppNotif(
        context,
        title: 'utils.error'.tr(),
        subTitle: 'app.modifier-joueur.erreur-message'.tr(),
        success: false,
      );
      return;
    }
    if (!context.mounted) return;
    showAppNotif(
      context,
      title: 'app.modifier-joueur.succes-titre'.tr(),
      subTitle: 'app.modifier-joueur.succes-message'.tr(),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return PlayerFormScaffold(
      title: 'app.modifier-joueur.titre'.tr(),
      form: PlayerForm(
        initialFirstName: player.firstName,
        initialLastName: player.lastName,
        initialFoot: player.strongFoot,
        initialPosition: player.position,
        submitLabel: 'app.modifier-joueur.valider'.tr(),
        onSubmit:
            (String f, String l, StrongFoot ft, PlayerPosition p) =>
                _save(context, f, l, ft, p),
      ),
    );
  }
}
