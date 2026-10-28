import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/phone_scale.dart';
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
      // Le clavier ne sert qu'au dialogue d'enregistrement : sans cela, la page derrière se redimensionne
      // à chaque ouverture du clavier (l'aperçu du terrain « zoome »).
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const AppBackground(),
            Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isPhoneLayout ? 16 : cW(40),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      cSh(isPhoneLayout ? 8 : 18),
                      PageHeader(
                        icon: Iconsax.people,
                        title:
                            _isEditing
                                ? 'app.creer-composition.titre-modifier'.tr()
                                : 'app.creer-composition.titre-creer'.tr(),
                        onBack: () => context.pop(),
                      ),
                      cSh(isPhoneLayout ? 6 : 14),
                      Container(height: 1, color: AppColor.divider),
                      cSh(isPhoneLayout ? 8 : 20),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isPhoneLayout ? 16 : cW(40),
                      0,
                      isPhoneLayout ? 16 : cW(40),
                      isPhoneLayout ? 8 : cH(20),
                    ),
                    child:
                        isPhoneLayout
                            // Téléphone : terrain à gauche (hauteur d'écran),
                            // nom / consigne / bouton à droite, sans défiler
                            // (le défilement gênerait le glisser des maillots).
                            ? _BuilderPreview(
                              name: widget.existing?.name,
                              slots: _slots,
                              onMove: _moveSlot,
                              phoneCta: _CreatePill(
                                saving: _saving,
                                label:
                                    _isEditing
                                        ? 'app.creer-composition.cta-modifier'
                                            .tr()
                                        : 'app.creer-composition.cta-creer'
                                            .tr(),
                                onTap: _openSaveModal,
                              ),
                            )
                            : Center(
                              child: SingleChildScrollView(
                                child: SizedBox(
                                  width: cW(330),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      _CreatePill(
                                        saving: _saving,
                                        label:
                                            _isEditing
                                                ? 'app.creer-composition.cta-modifier'
                                                    .tr()
                                                : 'app.creer-composition.cta-creer'
                                                    .tr(),
                                        onTap: _openSaveModal,
                                      ),
                                      cSh(12),
                                      _BuilderPreview(
                                        name: widget.existing?.name,
                                        slots: _slots,
                                        onMove: _moveSlot,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
    this.phoneCta,
  });

  /// Bouton de validation affiché à droite du terrain sur téléphone.
  final Widget? phoneCta;

  /// Nom de la composition en cours d'édition (`null` en création → « Aucun nom »).
  final String? name;
  final List<FormationSlot> slots;
  final void Function(int index, double nx, double ny) onMove;

  @override
  Widget build(BuildContext context) {
    final bool hasName = name != null && name!.trim().isNotEmpty;
    if (isPhoneLayout) return _phoneCard(hasName);
    return Container(
      padding: EdgeInsets.all(cW(12)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(18)),
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
                          ? AppThemeStyle.semiBStyle(
                            cFs(15),
                            AppColor.primaryLabels,
                          )
                          : AppThemeStyle.regularStyle(
                            cFs(15),
                            AppColor.secondaryLabels,
                          ),
                ),
              ),
              cSw(8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: cW(12),
                  vertical: cH(5),
                ),
                decoration: BoxDecoration(
                  color: AppColor.chipBackground,
                  borderRadius: BorderRadius.circular(cR(12)),
                ),
                child: Text(
                  'app.creer-composition.personnalise'.tr(),
                  style: AppThemeStyle.semiBStyle(
                    cFs(12),
                    AppColor.primaryLabels,
                  ),
                ),
              ),
            ],
          ),
          cSh(12),
          _BuilderPitch(slots: slots, onMove: onMove),
          cSh(10),
          Text(
            'app.creer-composition.consigne'.tr(),
            textAlign: TextAlign.center,
            style: AppThemeStyle.regularStyle(
              cFs(12),
              AppColor.secondaryLabels,
            ),
          ),
        ],
      ),
    );
  }
}

/// Terrain portrait où chaque maillot peut être déplacé librement.
extension on _BuilderPreview {
  /// Carte téléphone : terrain pleine hauteur + colonne d'infos à droite.
  Widget _phoneCard(bool hasName) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        const double pad = 8;
        final double ph = c.maxHeight - pad * 2;
        return Container(
          padding: const EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: ph * 1668 / 2388,
                height: ph,
                child: _BuilderPitch(slots: slots, onMove: onMove),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      hasName
                          ? name!.trim()
                          : 'app.creer-composition.aucun-nom'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          hasName
                              ? AppThemeStyle.semiBStyle(
                                cFs(15),
                                AppColor.primaryLabels,
                              )
                              : AppThemeStyle.regularStyle(
                                cFs(15),
                                AppColor.secondaryLabels,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: cW(12),
                          vertical: cH(5),
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.chipBackground,
                          borderRadius: BorderRadius.circular(cR(12)),
                        ),
                        child: Text(
                          'app.creer-composition.personnalise'.tr(),
                          style: AppThemeStyle.semiBStyle(
                            cFs(12),
                            AppColor.primaryLabels,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'app.creer-composition.consigne'.tr(),
                      style: AppThemeStyle.regularStyle(
                        cFs(12),
                        AppColor.secondaryLabels,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (phoneCta != null) phoneCta!,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BuilderPitch extends StatelessWidget {
  const _BuilderPitch({required this.slots, required this.onMove});

  final List<FormationSlot> slots;
  final void Function(int index, double nx, double ny) onMove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(cR(14)),
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
    final double badge = cIc(22);
    return Material(
      color: AppColor.primaryColor,
      borderRadius: BorderRadius.circular(cR(28)),
      child: InkWell(
        onTap: saving ? null : onTap,
        borderRadius: BorderRadius.circular(cR(28)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: cW(24), vertical: cH(15)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: AppThemeStyle.semiBStyle(cFs(15), AppColor.textLight),
              ),
              cSw(10),
              SizedBox(
                width: badge,
                height: badge,
                child:
                    saving
                        ? Padding(
                          padding: EdgeInsets.all(cIc(4)),
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
                            size: cIc(13),
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
    // Clavier ouvert : le dialogue prend toute la hauteur restante au lieu de garder ses marges, et défile
    // si son contenu ne tient pas — le bouton « Enregistrer » reste atteignable.
    final bool keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Dialog(
      backgroundColor: AppColor.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cR(20)),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: cW(360),
        vertical: keyboardOpen ? 8 : cH(120),
      ),
      child: GestureDetector(
        // Le pavé numérique du champ « schéma » n'a pas de touche « OK » sur iPhone / iPad : toucher
        // à côté d'un champ ferme le clavier et laisse voir « Enregistrer ».
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(cW(28), cH(16), cW(28), cH(22)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: InkResponse(
                  onTap: () => Navigator.of(context).pop(),
                  radius: cIc(20),
                  child: Icon(
                    Iconsax.close_circle,
                    size: cIc(20),
                    color: AppColor.secondaryLabels,
                  ),
                ),
              ),
              Center(
                child: Text(
                  widget.isEditing
                      ? 'app.creer-composition.dialogue-titre-modifier'.tr()
                      : 'app.creer-composition.cta-creer'.tr(),
                  style: AppThemeStyle.semiBStyle(
                    cFs(18),
                    AppColor.primaryLabels,
                  ),
                ),
              ),
              cSh(20),
              _FieldLabel('app.creer-composition.champ-nom'.tr()),
              cSh(8),
              _DialogField(
                controller: _nameController,
                hint: 'app.creer-composition.champ-nom-hint'.tr(),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
              cSh(16),
              _FieldLabel('app.creer-composition.champ-formation'.tr()),
              cSh(8),
              _DialogField(
                controller: _formationController,
                hint: 'app.creer-composition.champ-formation-hint'.tr(),
                // Un schéma ne contient que des chiffres : pavé numérique, et le
                // formateur remet les tirets que ce clavier ne permet pas de
                // taper (« 442 » → « 4-4-2 »), la valeur étant persistée telle
                // quelle. Rien de tout ça sur le champ « Nom », texte libre.
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FormationSearchFormatter(),
                ],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
              cSh(22),
              // Motif « CTA grisé » assumé : ce dialogue n'affiche jamais de
              // bannière, donc pas d'état rouge par champ.
              _SaveButton(enabled: _isValid, onTap: _submit),
              cSh(12),
              Center(
                child: Text(
                  'app.creer-composition.champs-obligatoires'.tr(),
                  style: AppThemeStyle.regularStyle(
                    cFs(12),
                    AppColor.secondaryLabels,
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppThemeStyle.mediumStyle(cFs(13), AppColor.primaryLabels),
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
      padding: EdgeInsets.symmetric(horizontal: cW(16)),
      decoration: BoxDecoration(
        color: AppColor.background,
        borderRadius: BorderRadius.circular(cR(14)),
        border: Border.all(color: AppColor.divider),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textInputAction: TextInputAction.done,
        style: AppThemeStyle.regularStyle(cFs(14), AppColor.primaryLabels),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: cH(14)),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppThemeStyle.regularStyle(
            cFs(14),
            AppColor.secondaryLabels,
          ),
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
      borderRadius: BorderRadius.circular(cR(14)),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(cR(14)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: cH(15)),
          child: Center(
            child: Text(
              'utils.save'.tr(),
              style: AppThemeStyle.semiBStyle(cFs(15), AppColor.textLight),
            ),
          ),
        ),
      ),
    );
  }
}
