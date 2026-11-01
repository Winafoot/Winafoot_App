import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/coach_profile_repository.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/app_loader.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/confirm_dialog.dart';
import 'package:wina/view/widget/jersey_form.dart';
import 'package:wina/view/widget/player_form.dart';

/// Page « Modifier les maillots » : gère les maillots de l'équipe
/// (`users/{uid}/jerseys`). Les maillots enregistrés peuvent être modifiés ou
/// supprimés un par un ; « Enregistrer » ajoute les maillots saisis en dessous.
///
/// Accessible depuis le sélecteur de maillots de « Mon équipe ».
class GererMaillotsScreen extends ConsumerStatefulWidget {
  const GererMaillotsScreen({super.key});

  @override
  ConsumerState<GererMaillotsScreen> createState() =>
      _GererMaillotsScreenState();
}

class _GererMaillotsScreenState extends ConsumerState<GererMaillotsScreen> {
  final JerseyFormController _jerseys = JerseyFormController();

  /// Écriture en cours : bloque les actions et affiche le chargement.
  bool _busy = false;

  /// Exécute une écriture : état d'attente, notification de succès, ou la
  /// vraie erreur en cas d'échec. Retourne `true` si l'écriture a abouti.
  Future<bool> _run(
    Future<void> Function() action, {
    required String title,
    required String subTitle,
  }) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showAppNotif(context, title: title, subTitle: subTitle);
      return true;
    } catch (e) {
      if (mounted) {
        showAppNotif(
          context,
          title: 'app.gerer-maillots.echec'.tr(),
          subTitle: '$e',
          success: false,
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// « Enregistrer » : ajoute les maillots saisis dans le formulaire.
  Future<void> _save() async {
    final List<Jersey> added = _jerseys.collect();
    if (added.isEmpty) {
      showAppNotif(
        context,
        title: 'app.gerer-maillots.aucun-maillot-titre'.tr(),
        subTitle: 'app.gerer-maillots.aucun-maillot-message'.tr(),
        success: false,
      );
      return;
    }
    final bool ok = await _run(
      () => CoachProfileRepository.addJerseys(added),
      title: 'app.gerer-maillots.enregistres-titre'.tr(),
      subTitle: 'app.gerer-maillots.enregistres-message'.tr(),
    );
    if (!ok || !mounted) return;
    Navigator.of(context).maybePop();
  }

  Future<void> _edit(int index, Jersey jersey) async {
    if (_busy) return;
    final Jersey? edited = await showDialog<Jersey>(
      context: context,
      barrierColor: AppColor.scrim,
      builder: (_) => _JerseyEditDialog(jersey: jersey),
    );
    if (edited == null || !mounted) return;
    await _run(
      () => CoachProfileRepository.updateJersey(index, edited),
      title: 'app.gerer-maillots.modifie-titre'.tr(),
      subTitle: '${edited.name} · ${edited.color.label}',
    );
  }

  Future<void> _delete(int index, Jersey jersey) async {
    if (_busy) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColor.scrim,
      builder:
          (BuildContext ctx) => AppConfirmDialog(
            title: 'app.gerer-maillots.supprimer-titre'.tr(),
            message: 'app.gerer-maillots.supprimer-message'.tr(
              args: <String>[jersey.name],
            ),
            primaryLabel: 'app.gerer-maillots.conserver'.tr(),
            onPrimary: () => Navigator.of(ctx).pop(false),
            secondaryLabel: 'app.gerer-maillots.supprimer-definitivement'.tr(),
            secondaryAccent: AppColor.destructive,
            onSecondary: () => Navigator.of(ctx).pop(true),
          ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      () => CoachProfileRepository.deleteJersey(index),
      title: 'app.gerer-maillots.supprime-titre'.tr(),
      subTitle: 'app.gerer-maillots.supprime-message'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Jersey>> jerseysAsync = ref.watch(jerseysProvider);
    return PlayerFormScaffold(
      title: 'app.gerer-maillots.titre'.tr(),
      form: jerseysAsync.when(
        data:
            (List<Jersey> jerseys) => _MaillotsCard(
              controller: _jerseys,
              jerseys: jerseys,
              busy: _busy,
              onSave: _save,
              onEdit: _edit,
              onDelete: _delete,
            ),
        loading: () => AppLoader(padding: EdgeInsets.all(cW(40))),
        error:
            (Object e, _) => Padding(
              padding: EdgeInsets.all(cW(40)),
              child: Text(
                '${'app.gerer-maillots.erreur-chargement'.tr()}\n$e',
                textAlign: TextAlign.center,
                style: AppThemeStyle.mediumStyle(
                  cFs(15),
                  AppColor.secondaryLabels,
                ),
              ),
            ),
      ),
    );
  }
}

class _MaillotsCard extends StatelessWidget {
  const _MaillotsCard({
    required this.controller,
    required this.jerseys,
    required this.busy,
    required this.onSave,
    required this.onEdit,
    required this.onDelete,
  });

  final JerseyFormController controller;

  /// Maillots déjà enregistrés (ordre de `users/{uid}/jerseys`).
  final List<Jersey> jerseys;
  final bool busy;
  final VoidCallback onSave;
  final void Function(int index, Jersey jersey) onEdit;
  final void Function(int index, Jersey jersey) onDelete;

  Widget _card(Widget child) {
    return Container(
      padding:
          isPhoneLayout
              ? const EdgeInsets.all(12)
              : EdgeInsets.symmetric(horizontal: cW(28), vertical: cH(28)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(16)),
      ),
      child: child,
    );
  }

  Widget _savedList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CpLabel('app.gerer-maillots.section-enregistres'.tr()),
        cSh(8),
        for (int i = 0; i < jerseys.length; i++) ...[
          if (i > 0) cSh(8),
          _JerseyRow(
            jersey: jerseys[i],
            onEdit: () => onEdit(i, jerseys[i]),
            onDelete: () => onDelete(i, jerseys[i]),
          ),
        ],
      ],
    );
  }

  Widget _addForm() {
    final bool phone = isPhoneLayout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JerseyForm(controller: controller),
        SizedBox(height: phone ? 8 : cH(18)),
        if (!phone) ...[Container(height: 1, color: AppColor.divider), cSh(18)],
        busy
            ? AppLoader(padding: EdgeInsets.symmetric(vertical: cH(12)))
            : CpButton(label: 'utils.save'.tr(), onTap: onSave),
        if (!phone) ...[cSh(14), const CpRequiredNote()],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Téléphone : maillots enregistrés à gauche, ajout à droite, côte à côte
    // (une seule carte verticale obligeait à défiler longuement).
    if (isPhoneLayout) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (jerseys.isNotEmpty) ...[
              Expanded(child: _card(_savedList())),
              const SizedBox(width: 12),
            ],
            Expanded(child: _card(_addForm())),
          ],
        ),
      );
    }
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
          if (jerseys.isNotEmpty) ...[
            CpLabel('app.gerer-maillots.section-enregistres'.tr()),
            cSh(8),
            for (int i = 0; i < jerseys.length; i++) ...[
              if (i > 0) cSh(8),
              _JerseyRow(
                jersey: jerseys[i],
                onEdit: () => onEdit(i, jerseys[i]),
                onDelete: () => onDelete(i, jerseys[i]),
              ),
            ],
            cSh(18),
            Container(height: 1, color: AppColor.divider),
            cSh(18),
          ],
          JerseyForm(controller: controller),
          cSh(18),
          Container(height: 1, color: AppColor.divider),
          cSh(18),
          busy
              ? AppLoader(padding: EdgeInsets.symmetric(vertical: cH(12)))
              : CpButton(label: 'utils.save'.tr(), onTap: onSave),
          cSh(14),
          const CpRequiredNote(),
        ],
      ),
    );
  }
}

/// Ligne d'un maillot enregistré : visuel, nom, couleur, puis modification et
/// suppression.
class _JerseyRow extends StatelessWidget {
  const _JerseyRow({
    required this.jersey,
    required this.onEdit,
    required this.onDelete,
  });

  final Jersey jersey;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          isPhoneLayout
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
              : EdgeInsets.symmetric(horizontal: cW(14), vertical: cH(10)),
      decoration: BoxDecoration(
        color: AppColor.background,
        borderRadius: BorderRadius.circular(cR(12)),
        border: Border.all(color: AppColor.divider),
      ),
      child: Row(
        children: [
          ShirtIcon(asset: jersey.color.asset, size: isPhoneLayout ? 34 : 24),
          cSw(10),
          Expanded(
            child: Text(
              jersey.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.mediumStyle(cFs(14), AppColor.primaryLabels),
            ),
          ),
          cSw(8),
          Text(
            jersey.color.label,
            style: AppThemeStyle.regularStyle(
              cFs(12),
              AppColor.secondaryLabels,
            ),
          ),
          cSw(12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onEdit,
            child: Icon(
              Iconsax.edit_2,
              size: cIc(18),
              color: AppColor.primaryLabels,
            ),
          ),
          cSw(12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDelete,
            child: Icon(
              Iconsax.trash,
              size: cIc(18),
              color: AppColor.destructive,
            ),
          ),
        ],
      ),
    );
  }
}

/// Popup « Modifier le maillot » : nom et couleur. Rend le maillot modifié via
/// `Navigator.pop` (`null` si annulé).
class _JerseyEditDialog extends StatefulWidget {
  const _JerseyEditDialog({required this.jersey});

  final Jersey jersey;

  @override
  State<_JerseyEditDialog> createState() => _JerseyEditDialogState();
}

class _JerseyEditDialogState extends State<_JerseyEditDialog> {
  late final TextEditingController _nom = TextEditingController(
    text: widget.jersey.name,
  );
  late JerseyColorOption _color = widget.jersey.color;

  /// Vrai dès qu'un enregistrement a échoué : le nom resté vide passe en rouge.
  bool _submitted = false;

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _nom.text.trim();
    if (name.isEmpty) {
      setState(() => _submitted = true);
      showAppNotif(
        context,
        title: 'app.gerer-maillots.incomplet-titre'.tr(),
        subTitle: 'app.gerer-maillots.incomplet-message'.tr(),
        success: false,
      );
      return;
    }
    Navigator.of(context).pop(Jersey(name: name, color: _color));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColor.surface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isPhoneLayout ? 80 : cW(40),
        vertical: isPhoneLayout ? 12 : 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cR(20)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cW(430)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: cW(28), vertical: cH(28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'app.gerer-maillots.modifier-titre'.tr(),
                textAlign: TextAlign.center,
                style: AppThemeStyle.semiBStyle(
                  cFs(18),
                  AppColor.primaryLabels,
                ),
              ),
              cSh(20),
              CpLabel('app.gerer-maillots.champ-nom'.tr()),
              cSh(8),
              CpTextField(
                controller: _nom,
                hint: 'app.gerer-maillots.champ-nom-hint'.tr(),
                onChanged: (_) {
                  if (_submitted) setState(() {});
                },
                error: _submitted && _nom.text.trim().isEmpty,
              ),
              cSh(18),
              CpLabel('app.gerer-maillots.champ-couleur'.tr()),
              cSh(8),
              CpDropdown<JerseyColorOption>(
                value: _color,
                values: JerseyColorOption.values,
                labelOf: (JerseyColorOption v) => v.label,
                leadingOf: (JerseyColorOption v) => ShirtIcon(asset: v.asset),
                onChanged: (JerseyColorOption v) => setState(() => _color = v),
              ),
              cSh(24),
              CpButton(label: 'utils.save'.tr(), onTap: _submit),
              cSh(12),
              CpButton(
                label: 'utils.cancel'.tr(),
                soft: true,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
