import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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
        loading: () => AppLoader(padding: EdgeInsets.all(formatWidth(40))),
        error:
            (Object e, _) => Padding(
              padding: EdgeInsets.all(formatWidth(40)),
              child: Text(
                '${'app.gerer-maillots.erreur-chargement'.tr()}\n$e',
                textAlign: TextAlign.center,
                style: AppThemeStyle.mediumStyle(15, AppColor.secondaryLabels),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: formatWidth(430),
      padding: EdgeInsets.symmetric(
        horizontal: formatWidth(28),
        vertical: formatHeight(28),
      ),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(r(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (jerseys.isNotEmpty) ...[
            CpLabel('app.gerer-maillots.section-enregistres'.tr()),
            sh(8),
            for (int i = 0; i < jerseys.length; i++) ...[
              if (i > 0) sh(8),
              _JerseyRow(
                jersey: jerseys[i],
                onEdit: () => onEdit(i, jerseys[i]),
                onDelete: () => onDelete(i, jerseys[i]),
              ),
            ],
            sh(18),
            Container(height: 1, color: AppColor.divider),
            sh(18),
          ],
          JerseyForm(controller: controller),
          sh(18),
          Container(height: 1, color: AppColor.divider),
          sh(18),
          busy
              ? AppLoader(
                padding: EdgeInsets.symmetric(vertical: formatHeight(12)),
              )
              : CpButton(label: 'utils.save'.tr(), onTap: onSave),
          sh(14),
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
      padding: EdgeInsets.symmetric(
        horizontal: formatWidth(14),
        vertical: formatHeight(10),
      ),
      decoration: BoxDecoration(
        color: AppColor.background,
        borderRadius: BorderRadius.circular(r(12)),
        border: Border.all(color: AppColor.divider),
      ),
      child: Row(
        children: [
          ShirtIcon(asset: jersey.color.asset, size: 24),
          sw(10),
          Expanded(
            child: Text(
              jersey.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.mediumStyle(14, AppColor.primaryLabels),
            ),
          ),
          sw(8),
          Text(
            jersey.color.label,
            style: AppThemeStyle.regularStyle(12, AppColor.secondaryLabels),
          ),
          sw(12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onEdit,
            child: Icon(
              Iconsax.edit_2,
              size: sp(18),
              color: AppColor.primaryLabels,
            ),
          ),
          sw(12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDelete,
            child: Icon(
              Iconsax.trash,
              size: sp(18),
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
      insetPadding: EdgeInsets.symmetric(horizontal: formatWidth(40)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r(20))),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: formatWidth(430)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: formatWidth(28),
            vertical: formatHeight(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'app.gerer-maillots.modifier-titre'.tr(),
                textAlign: TextAlign.center,
                style: AppThemeStyle.semiBStyle(18, AppColor.primaryLabels),
              ),
              sh(20),
              CpLabel('app.gerer-maillots.champ-nom'.tr()),
              sh(8),
              CpTextField(
                controller: _nom,
                hint: 'app.gerer-maillots.champ-nom-hint'.tr(),
                onChanged: (_) {
                  if (_submitted) setState(() {});
                },
                error: _submitted && _nom.text.trim().isEmpty,
              ),
              sh(18),
              CpLabel('app.gerer-maillots.champ-couleur'.tr()),
              sh(8),
              CpDropdown<JerseyColorOption>(
                value: _color,
                values: JerseyColorOption.values,
                labelOf: (JerseyColorOption v) => v.label,
                leadingOf: (JerseyColorOption v) => ShirtIcon(asset: v.asset),
                onChanged: (JerseyColorOption v) => setState(() => _color = v),
              ),
              sh(24),
              CpButton(label: 'utils.save'.tr(), onTap: _submit),
              sh(12),
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
