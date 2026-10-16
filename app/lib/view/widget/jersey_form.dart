import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/check_profil_form.dart';

/// Permet au parent de récupérer la liste finale des maillots saisis dans un
/// [JerseyForm] (au moment où il appuie sur « Terminer » / « Enregistrer »).
class JerseyFormController {
  List<Jersey> Function()? _collect;

  /// Maillots ajoutés + un éventuel maillot en cours de saisie valide.
  List<Jersey> collect() => _collect?.call() ?? const <Jersey>[];
}

/// Formulaire de gestion des maillots, partagé entre la complétion de profil
/// (étape 2) et la page « Modifier les maillots ».
///
/// Gère le type (intérieur / extérieur), le nom, la couleur (visuel
/// `shirt-*.png`), l'ajout multiple et la liste des maillots déjà ajoutés.
class JerseyForm extends StatefulWidget {
  const JerseyForm({
    super.key,
    required this.controller,
    this.initialJerseys = const <Jersey>[],
  });

  final JerseyFormController controller;
  final List<Jersey> initialJerseys;

  @override
  State<JerseyForm> createState() => _JerseyFormState();
}

class _JerseyFormState extends State<JerseyForm> {
  final TextEditingController _nom = TextEditingController();
  JerseyColorOption? _color;
  late final List<Jersey> _added;

  @override
  void initState() {
    super.initState();
    _added = <Jersey>[...widget.initialJerseys];
    widget.controller._collect =
        () => <Jersey>[
          ..._added,
          if (_currentJersey() != null) _currentJersey()!,
        ];
  }

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  /// Vrai dès le premier ajout refusé : les champs manquants passent alors en
  /// rouge, comme sur l'écran de complétion de profil.
  bool _submitted = false;

  void _onFieldChanged(String _) {
    if (_submitted) setState(() {});
  }

  Jersey? _currentJersey() {
    if (_nom.text.trim().isEmpty || _color == null) return null;
    return Jersey(name: _nom.text.trim(), color: _color!);
  }

  void _add() {
    final Jersey? jersey = _currentJersey();
    if (jersey == null) {
      setState(() => _submitted = true);
      showAppNotif(
        context,
        title: 'app.jersey-form.maillot-incomplet-titre'.tr(),
        subTitle: 'app.jersey-form.maillot-incomplet-message'.tr(),
        success: false,
      );
      return;
    }
    setState(() {
      _added.add(jersey);
      _nom.clear();
      _color = null;
      // Le formulaire se vide pour l'ajout suivant : sans ça il repartirait rouge.
      _submitted = false;
    });
    showAppNotif(
      context,
      title: 'app.jersey-form.maillot-ajoute-titre'.tr(),
      subTitle: '${jersey.name} · ${jersey.color.label}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_added.isNotEmpty) ...[
          Wrap(
            spacing: formatWidth(8),
            runSpacing: formatHeight(8),
            children: [
              for (int i = 0; i < _added.length; i++)
                _AddedChip(
                  jersey: _added[i],
                  onRemove: () => setState(() => _added.removeAt(i)),
                ),
            ],
          ),
          sh(18),
        ],
        CpLabel('app.jersey-form.nom-label'.tr()),
        sh(8),
        CpTextField(
          controller: _nom,
          hint: 'app.jersey-form.nom-hint'.tr(),
          onChanged: _onFieldChanged,
          error: _submitted && _nom.text.trim().isEmpty,
        ),
        sh(18),
        CpLabel('app.jersey-form.couleur-label'.tr()),
        sh(8),
        CpDropdown<JerseyColorOption>(
          value: _color,
          values: JerseyColorOption.values,
          labelOf: (JerseyColorOption v) => v.label,
          leadingOf: (JerseyColorOption v) => ShirtIcon(asset: v.asset),
          onChanged: (JerseyColorOption v) => setState(() => _color = v),
          error: _submitted && _color == null,
        ),
        sh(20),
        CpButton(
          label: 'app.jersey-form.ajouter'.tr(),
          onTap: _add,
          soft: true,
        ),
      ],
    );
  }
}

/// Puce d'un maillot déjà ajouté (visuel + nom + suppression).
class _AddedChip extends StatelessWidget {
  const _AddedChip({required this.jersey, required this.onRemove});

  final Jersey jersey;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: formatWidth(12),
        vertical: formatHeight(7),
      ),
      decoration: BoxDecoration(
        color: AppColor.background,
        borderRadius: BorderRadius.circular(r(14)),
        border: Border.all(color: AppColor.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShirtIcon(asset: jersey.color.asset, size: 20),
          sw(8),
          Flexible(
            child: Text(
              jersey.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.mediumStyle(13, AppColor.primaryLabels),
            ),
          ),
          sw(8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Iconsax.close_circle,
              size: sp(15),
              color: AppColor.secondaryLabels,
            ),
          ),
        ],
      ),
    );
  }
}

/// Visuel de maillot (image `shirt-*.png`).
class ShirtIcon extends StatelessWidget {
  const ShirtIcon({super.key, required this.asset, this.size = 24});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: formatHeight(size),
      height: formatHeight(size),
      fit: BoxFit.contain,
    );
  }
}
