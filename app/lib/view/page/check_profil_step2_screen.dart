import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/coach_profile_repository.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/jersey_form.dart';

/// Check profil — étape 2 : « Finalisez votre profil Coach ».
///
/// Configure les maillots, puis « Terminer » les enregistre, bascule
/// `profilCompleted` à vrai et revient à l'application.
class CheckProfilStep2Screen extends StatefulWidget {
  const CheckProfilStep2Screen({super.key});

  @override
  State<CheckProfilStep2Screen> createState() => _CheckProfilStep2ScreenState();
}

class _CheckProfilStep2ScreenState extends State<CheckProfilStep2Screen> {
  final JerseyFormController _jerseys = JerseyFormController();
  bool _busy = false;
  bool _jerseysSaved = false;

  Future<void> _terminer() async {
    if (_busy) return;
    final List<Jersey> jerseys = _jerseys.collect();
    setState(() => _busy = true);
    try {
      // Les maillots ne sont écrits qu'une fois : après un échec de
      // `markProfilCompleted`, un nouvel appui ne les duplique pas.
      if (!_jerseysSaved) {
        await CoachProfileRepository.addJerseys(jerseys);
        _jerseysSaved = true;
      }
      await CoachProfileRepository.markProfilCompleted();
    } catch (e) {
      // Sans `profilCompleted`, l'utilisateur reboucle sur la complétion de
      // profil : on affiche l'échec au lieu d'annoncer un succès.
      if (!mounted) return;
      setState(() => _busy = false);
      showAppNotif(
        context,
        title: 'app.check-profil-data.enregistrement-impossible'.tr(),
        subTitle: '$e',
        success: false,
      );
      return;
    }
    if (!mounted) return;
    showAppNotif(
      context,
      title: 'app.check-profil-step2.profil-complete-titre'.tr(),
      subTitle: 'app.check-profil-step2.profil-complete-message'.tr(),
    );
    // Revient à l'application (sous la pile de complétion de profil).
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return CheckProfilScaffold(
      title: 'app.check-profil-step2.titre'.tr(),
      portraitOnPhone: true,
      onBack: () => Navigator.of(context).maybePop(),
      children: [
        JerseyForm(controller: _jerseys),
        sh(18),
        Container(height: 1, color: AppColor.divider),
        sh(18),
        CpButton(
          label: 'app.check-profil-step2.terminer'.tr(),
          onTap: _terminer,
        ),
        sh(14),
        const CpRequiredNote(),
      ],
    );
  }
}
