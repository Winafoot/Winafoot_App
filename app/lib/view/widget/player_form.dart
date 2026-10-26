import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/player.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/custom_back_button.dart';

/// Entête commune des écrans de formulaire joueur : retour, avatar, titre.
class PlayerFormHeader extends StatelessWidget {
  const PlayerFormHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CustomBackButton(onTap: onBack),
        cSw(14),
        Container(width: 1, height: cH(28), color: AppColor.divider),
        cSw(14),
        Icon(
          Iconsax.profile_2user,
          size: cIc(26),
          color: AppColor.primaryColor,
        ),
        cSw(12),
        Text(
          title,
          style: AppThemeStyle.semiBStyle(cFs(28), AppColor.primaryLabels),
        ),
      ],
    );
  }
}

/// Ossature commune des écrans de formulaire joueur : entête + séparateur, puis
/// le [form] centré et défilable.
class PlayerFormScaffold extends StatelessWidget {
  const PlayerFormScaffold({
    super.key,
    required this.title,
    required this.form,
  });

  final String title;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Stack(
          children: [
            const AppBackground(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isPhoneLayout ? 16 : cW(41),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      cSh(isPhoneLayout ? 8 : 18),
                      PlayerFormHeader(
                        title: title,
                        onBack: () => Navigator.of(context).maybePop(),
                      ),
                      cSh(isPhoneLayout ? 6 : 14),
                      Container(height: 1, color: AppColor.divider),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        vertical: isPhoneLayout ? 10 : cH(24),
                      ),
                      child: form,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulaire partagé de création / modification d'un joueur (nom, prénom,
/// pied fort, poste).
///
/// Gère ses propres champs et leur état ; remonte les valeurs VALIDÉES via
/// [onSubmit]. Si un champ obligatoire manque, affiche lui-même une bannière
/// d'erreur et n'appelle pas [onSubmit].
class PlayerForm extends StatefulWidget {
  const PlayerForm({
    super.key,
    this.initialFirstName,
    this.initialLastName,
    this.initialFoot,
    this.initialPosition,
    required this.submitLabel,
    required this.onSubmit,
  });

  final String? initialFirstName;
  final String? initialLastName;
  final StrongFoot? initialFoot;
  final PlayerPosition? initialPosition;
  final String submitLabel;
  final Future<void> Function(
    String firstName,
    String lastName,
    StrongFoot foot,
    PlayerPosition position,
  )
  onSubmit;

  @override
  State<PlayerForm> createState() => _PlayerFormState();
}

class _PlayerFormState extends State<PlayerForm> {
  late final TextEditingController _nom;
  late final TextEditingController _prenom;
  StrongFoot? _foot;
  PlayerPosition? _position;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nom = TextEditingController(text: widget.initialLastName ?? '');
    _prenom = TextEditingController(text: widget.initialFirstName ?? '');
    _foot = widget.initialFoot;
    _position = widget.initialPosition;
  }

  @override
  void dispose() {
    _nom.dispose();
    _prenom.dispose();
    super.dispose();
  }

  /// Vrai dès le premier envoi refusé : les champs vides passent alors en
  /// rouge, comme sur l'écran de complétion de profil.
  bool _submitted = false;

  void _onFieldChanged(String _) {
    if (_submitted) setState(() {});
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final String nom = _nom.text.trim();
    final String prenom = _prenom.text.trim();
    if (nom.isEmpty || prenom.isEmpty || _foot == null || _position == null) {
      setState(() => _submitted = true);
      showAppNotif(
        context,
        title: 'app.player-form.champs-obligatoires-titre'.tr(),
        subTitle: 'app.player-form.champs-obligatoires-message'.tr(),
        success: false,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(prenom, nom, _foot!, _position!);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cW(430),
      padding: EdgeInsets.symmetric(horizontal: cW(28), vertical: cH(28)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CpLabel('app.player-form.nom-label'.tr()),
          cSh(8),
          CpTextField(
            controller: _nom,
            hint: 'app.player-form.nom-hint'.tr(),
            onChanged: _onFieldChanged,
            error: _submitted && _nom.text.trim().isEmpty,
          ),
          cSh(20),
          CpLabel('app.player-form.prenom-label'.tr()),
          cSh(8),
          CpTextField(
            controller: _prenom,
            hint: 'app.player-form.prenom-hint'.tr(),
            onChanged: _onFieldChanged,
            error: _submitted && _prenom.text.trim().isEmpty,
          ),
          cSh(20),
          CpLabel('app.player-form.pied-fort-label'.tr()),
          cSh(8),
          CpDropdown<StrongFoot>(
            value: _foot,
            values: StrongFoot.values,
            labelOf: (StrongFoot v) => v.label,
            onChanged: (StrongFoot v) => setState(() => _foot = v),
            error: _submitted && _foot == null,
          ),
          cSh(20),
          CpLabel('app.player-form.poste-label'.tr()),
          cSh(8),
          CpDropdown<PlayerPosition>(
            value: _position,
            values: PlayerPosition.values,
            labelOf: (PlayerPosition v) => v.singular,
            onChanged: (PlayerPosition v) => setState(() => _position = v),
            error: _submitted && _position == null,
          ),
          cSh(28),
          CpButton(
            label: widget.submitLabel,
            onTap: () {
              _submit();
            },
            radius: 14,
          ),
          cSh(14),
          const CpRequiredNote(),
        ],
      ),
    );
  }
}

// Les champs du formulaire (label / boîte / champ texte / liste déroulante /
// bouton) utilisent le kit partagé Cp* de check_profil_form.dart.
