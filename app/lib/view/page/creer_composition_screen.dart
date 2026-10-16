import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/composition_repository.dart';
import 'package:wina/models/custom_composition.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/providers/composition_providers.dart';
import 'package:wina/view/page/gerer_equipe_composition_screen.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/formation_pitch.dart';
import 'package:wina/view/widget/page_header.dart';

/// Maillot « vide » (gabarit) glissable sur le terrain du constructeur.
const String _kBuilderJersey = 'assets/images/shirt-empty.png';

/// Valeurs saisies dans la popup d'enregistrement.
typedef _CompositionMeta = ({String name, String formation});

/// Constructeur de composition personnalisée — création ou modification.
///
/// Gauche : aperçu « terrain » où le coach déplace librement chaque maillot.
/// Droite : action d'enregistrement → popup (nom + libellé de schéma) →
/// persistée dans `users/{uid}/compositions`.
///
/// - [existing] non nul → mode **modification** (terrain pré-rempli, titre et
///   bouton adaptés, mise à jour du document).
/// - [playerCount] force le nombre de joueurs (depuis l'onglet « Test équipe »).
///   Sinon on retombe sur le brouillon de l'assistant, puis 11.
class CreerCompositionScreen extends ConsumerStatefulWidget {
  const CreerCompositionScreen({super.key, this.existing, this.playerCount});

  final CustomComposition? existing;
  final int? playerCount;

  @override
  ConsumerState<CreerCompositionScreen> createState() =>
      _CreerCompositionScreenState();
}

class _CreerCompositionScreenState
    extends ConsumerState<CreerCompositionScreen> {
  late final int _playerCount;
  late List<FormationSlot> _slots;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final CustomComposition? existing = widget.existing;
    if (existing != null) {
      _playerCount = existing.playerCount;
      _slots = List<FormationSlot>.from(existing.slots);
    } else {
      _playerCount =
          widget.playerCount ??
          ref.read(compositionDraftProvider).playerCount ??
          11;
      // Point de départ : le premier schéma standard du bon nombre de joueurs,
      // que le coach repositionne ensuite à sa guise.
      _slots = List<FormationSlot>.from(
        standardFormations(_playerCount).first.slots,
      );
    }
  }

  /// Déplace le maillot [index] vers les coordonnées normalisées ([nx], [ny]),
  /// en gardant le maillot sur le terrain (marge anti-débordement).
  void _moveSlot(int index, double nx, double ny) {
    const double margin = 0.07;
    final FormationSlot s = _slots[index];
    setState(() {
      _slots[index] = FormationSlot(
        role: s.role,
        x: nx.clamp(margin, 1 - margin),
        y: ny.clamp(margin, 1 - margin),
      );
    });
  }

  Future<void> _openSaveModal() async {
    final CustomComposition? existing = widget.existing;
    final _CompositionMeta? meta = await showDialog<_CompositionMeta>(
      context: context,
      barrierColor: AppColor.scrim,
      builder:
          (_) => _SaveDialog(
            initialName: existing?.name ?? '',
            initialFormation: existing?.formationLabel ?? '',
            isEditing: _isEditing,
          ),
    );
    if (meta == null) return;
    setState(() => _saving = true);
    try {
      if (existing != null) {
        await CompositionRepository.updateComposition(
          existing.copyWith(
            name: meta.name,
            formationLabel: meta.formation,
            slots: _slots,
          ),
        );
      } else {
        await CompositionRepository.addComposition(
          CustomComposition(
            name: meta.name,
            playerCount: _playerCount,
            formationLabel: meta.formation,
            slots: _slots,
          ),
        );
      }
      AnalyticsController.logEvent(
        'composition_saved',
        parameters: <String, Object>{'player_count': _playerCount},
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppNotif(
        context,
        title: 'app.creer-composition.echec-titre'.tr(),
        subTitle: 'app.creer-composition.echec-message'.tr(),
        success: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const AppBackground(),
            Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: formatWidth(40)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      sh(18),
                      PageHeader(
                        icon: Iconsax.people,
                        title:
                            _isEditing
                                ? 'app.creer-composition.titre-modifier'.tr()
                                : 'app.creer-composition.titre-creer'.tr(),
                        onBack: () => context.pop(),
                      ),
                      sh(14),
                      Container(height: 1, color: AppColor.divider),
                      sh(20),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      formatWidth(40),
                      0,
                      formatWidth(40),
                      formatHeight(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: formatWidth(330),
                          child: _BuilderPreview(
                            name: widget.existing?.name,
                            slots: _slots,
                            onMove: _moveSlot,
                          ),
                        ),
                        sw(24),
                        Expanded(
                          child: _Actions(
                            saving: _saving,
                            label:
                                _isEditing
                                    ? 'app.creer-composition.cta-modifier'.tr()
                                    : 'app.creer-composition.cta-creer'.tr(),
                            onCreate: _openSaveModal,
                          ),
                        ),
                      ],
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

/// Entête du sous-flux (rond retour + icône équipe + titre + wordmark).
/// Carte d'aperçu : nom (ou « Aucun nom ») + badge « Personnalisé » + terrain
/// avec les maillots déplaçables.
class _BuilderPreview extends StatelessWidget {
  const _BuilderPreview({
    required this.name,
    required this.slots,
    required this.onMove,
  });

  /// Nom de la composition en cours d'édition (`null` en création → « Aucun nom »).
  final String? name;
  final List<FormationSlot> slots;
  final void Function(int index, double nx, double ny) onMove;

  @override
  Widget build(BuildContext context) {
    final bool hasName = name != null && name!.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.all(formatWidth(12)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(r(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  hasName
                      ? name!.trim()
                      : 'app.creer-composition.aucun-nom'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      hasName
                          ? AppThemeStyle.semiBStyle(15, AppColor.primaryLabels)
                          : AppThemeStyle.regularStyle(
                            15,
                            AppColor.secondaryLabels,
                          ),
                ),
              ),
              sw(8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: formatWidth(12),
                  vertical: formatHeight(5),
                ),
                decoration: BoxDecoration(
                  color: AppColor.chipBackground,
                  borderRadius: BorderRadius.circular(r(12)),
                ),
                child: Text(
                  'app.creer-composition.personnalise'.tr(),
                  style: AppThemeStyle.semiBStyle(12, AppColor.primaryLabels),
                ),
              ),
            ],
          ),
          sh(12),
          _BuilderPitch(slots: slots, onMove: onMove),
          sh(10),
          Text(
            'app.creer-composition.consigne'.tr(),
            textAlign: TextAlign.center,
            style: AppThemeStyle.regularStyle(12, AppColor.secondaryLabels),
          ),
        ],
      ),
    );
  }
}

/// Terrain portrait où chaque maillot peut être déplacé librement.
class _BuilderPitch extends StatelessWidget {
  const _BuilderPitch({required this.slots, required this.onMove});

  final List<FormationSlot> slots;
  final void Function(int index, double nx, double ny) onMove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(r(14)),
      child: AspectRatio(
        aspectRatio: 1668 / 2388,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;
            final double m = w * 0.155;
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Image.asset(kPitchPortraitAsset, fit: BoxFit.cover),
                ),
                for (int i = 0; i < slots.length; i++)
                  Positioned(
                    left: slots[i].x * w - m / 2,
                    top: slots[i].y * h - m / 2,
                    width: m,
                    height: m,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate:
                          (DragUpdateDetails d) => onMove(
                            i,
                            slots[i].x + d.delta.dx / w,
                            slots[i].y + d.delta.dy / h,
                          ),
                      child: Image.asset(_kBuilderJersey, fit: BoxFit.contain),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Colonne d'actions à droite du terrain.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.saving,
    required this.label,
    required this.onCreate,
  });

  final bool saving;
  final String label;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'app.creer-composition.actions'.tr(),
          style: AppThemeStyle.semiBStyle(16, AppColor.primaryLabels),
        ),
        sh(14),
        _CreatePill(saving: saving, label: label, onTap: onCreate),
      ],
    );
  }
}

/// Pilule verte d'enregistrement (création ou modification).
class _CreatePill extends StatelessWidget {
  const _CreatePill({
    required this.saving,
    required this.label,
    required this.onTap,
  });

  final bool saving;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double badge = sp(22);
    return Material(
      color: AppColor.primaryColor,
      borderRadius: BorderRadius.circular(r(28)),
      child: InkWell(
        onTap: saving ? null : onTap,
        borderRadius: BorderRadius.circular(r(28)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: formatWidth(24),
            vertical: formatHeight(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: AppThemeStyle.semiBStyle(15, AppColor.textLight),
              ),
              sw(10),
              SizedBox(
                width: badge,
                height: badge,
                child:
                    saving
                        ? Padding(
                          padding: EdgeInsets.all(sp(4)),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColor.textLight,
                            ),
                          ),
                        )
                        : Container(
                          decoration: const BoxDecoration(
                            color: AppColor.textLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Iconsax.arrow_circle_right,
                            size: sp(13),
                            color: AppColor.primaryColor,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Popup « Créer la composition personnalisée » : nom + libellé de schéma.
/// Renvoie un [_CompositionMeta] via `Navigator.pop` quand les deux champs
/// obligatoires sont remplis.
class _SaveDialog extends StatefulWidget {
  const _SaveDialog({
    required this.initialName,
    required this.initialFormation,
    required this.isEditing,
  });

  final String initialName;
  final String initialFormation;
  final bool isEditing;

  @override
  State<_SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<_SaveDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialName,
  );
  late final TextEditingController _formationController = TextEditingController(
    text: widget.initialFormation,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _formationController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _formationController.text.trim().isNotEmpty;

  void _submit() {
    if (!_isValid) return;
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      formation: _formationController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColor.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r(20))),
      insetPadding: EdgeInsets.symmetric(
        horizontal: formatWidth(360),
        vertical: formatHeight(120),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          formatWidth(28),
          formatHeight(16),
          formatWidth(28),
          formatHeight(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: InkResponse(
                onTap: () => Navigator.of(context).pop(),
                radius: sp(20),
                child: Icon(
                  Iconsax.close_circle,
                  size: sp(20),
                  color: AppColor.secondaryLabels,
                ),
              ),
            ),
            Center(
              child: Text(
                widget.isEditing
                    ? 'app.creer-composition.dialogue-titre-modifier'.tr()
                    : 'app.creer-composition.cta-creer'.tr(),
                style: AppThemeStyle.semiBStyle(18, AppColor.primaryLabels),
              ),
            ),
            sh(20),
            _FieldLabel('app.creer-composition.champ-nom'.tr()),
            sh(8),
            _DialogField(
              controller: _nameController,
              hint: 'app.creer-composition.champ-nom-hint'.tr(),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            sh(16),
            _FieldLabel('app.creer-composition.champ-formation'.tr()),
            sh(8),
            _DialogField(
              controller: _formationController,
              hint: 'app.creer-composition.champ-formation-hint'.tr(),
              // Un schéma ne contient que des chiffres : pavé numérique, et le
              // formateur remet les tirets que ce clavier ne permet pas de
              // taper (« 442 » → « 4-4-2 »), la valeur étant persistée telle
              // quelle. Rien de tout ça sur le champ « Nom », texte libre.
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[FormationSearchFormatter()],
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            sh(22),
            // Motif « CTA grisé » assumé : ce dialogue n'affiche jamais de
            // bannière, donc pas d'état rouge par champ.
            _SaveButton(enabled: _isValid, onTap: _submit),
            sh(12),
            Center(
              child: Text(
                'app.creer-composition.champs-obligatoires'.tr(),
                style: AppThemeStyle.regularStyle(12, AppColor.secondaryLabels),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppThemeStyle.mediumStyle(13, AppColor.primaryLabels),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: formatWidth(16)),
      decoration: BoxDecoration(
        color: AppColor.background,
        borderRadius: BorderRadius.circular(r(14)),
        border: Border.all(color: AppColor.divider),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textInputAction: TextInputAction.done,
        style: AppThemeStyle.regularStyle(14, AppColor.primaryLabels),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: formatHeight(14)),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppThemeStyle.regularStyle(14, AppColor.secondaryLabels),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          enabled
              ? AppColor.primaryColor
              : AppColor.primaryColor.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(r(14)),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(r(14)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: formatHeight(15)),
          child: Center(
            child: Text(
              'utils.save'.tr(),
              style: AppThemeStyle.semiBStyle(15, AppColor.textLight),
            ),
          ),
        ),
      ),
    );
  }
}
