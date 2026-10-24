import 'package:core_kosmos/core_kosmos.dart' show AnalyticsController;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wina/data/player_repository.dart';
import 'package:wina/models/player.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/player_form.dart';

/// Page « Créer un joueur » : formulaire vide (placeholders « Ex. Doe » /
/// « Ex. John », pieds & poste à « Choisir »). « Créer le joueur » ajoute une
/// fiche dans Firestore (`users/{uid}/players`) puis revient en arrière.
class CreerJoueurScreen extends StatelessWidget {
  const CreerJoueurScreen({super.key});

  Future<void> _create(
    BuildContext context,
    String firstName,
    String lastName,
    StrongFoot foot,
    PlayerPosition position,
  ) async {
    try {
      await PlayerRepository.addPlayer(
        Player(
          firstName: firstName,
          lastName: lastName,
          strongFoot: foot,
          position: position,
        ),
      );
    } on SquadFullException {
      // Avant le `catch (_)` générique, sinon le message d'effectif complet
      // serait indiscernable d'une panne réseau.
      //
      // Le plafond annoncé est celui qui fait foi (format du club, sinon
      // `app_config/config`), relu pour le compte connecté : annoncer 20 alors
      // que les règles en appliquent un autre rendrait le message trompeur.
      final int max = await PlayerRepository.maxSquadSize();
      if (!context.mounted) return;
      showAppNotif(
        context,
        title: 'utils.error'.tr(),
        subTitle: 'app.creer-joueur.effectif-plein'.tr(
          namedArgs: <String, String>{'max': '$max'},
        ),
        success: false,
      );
      return;
    } catch (_) {
      if (!context.mounted) return;
      showAppNotif(
        context,
        title: 'utils.error'.tr(),
        subTitle: 'app.creer-joueur.erreur-message'.tr(),
        success: false,
      );
      return;
    }
    AnalyticsController.logEvent('player_created');
    if (!context.mounted) return;
    showAppNotif(
      context,
      title: 'app.creer-joueur.succes-titre'.tr(),
      subTitle: 'app.creer-joueur.succes-message'.tr(),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return PlayerFormScaffold(
      title: 'app.creer-joueur.titre'.tr(),
      form: PlayerForm(
        submitLabel: 'app.creer-joueur.valider'.tr(),
        onSubmit:
            (String f, String l, StrongFoot ft, PlayerPosition p) =>
                _create(context, f, l, ft, p),
      ),
    );
  }
}
