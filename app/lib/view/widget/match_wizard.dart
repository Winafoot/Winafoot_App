import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/custom_back_button.dart';
import 'package:wina/view/widget/whistle_icon.dart';

/// Ossature des écrans de l'assistant « Coup d'envoi » : entête (retour +
/// sifflet + « Coup d'envoi » + logo), fond terrain, grand titre centré,
/// contenu, et CTA bas centré.
class MatchWizardScaffold extends StatelessWidget {
  const MatchWizardScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onBack,
    this.bottomCta,
  });

  /// Grand titre centré de l'étape (ex. « Choix de l'adversaire »).
  final String title;
  final Widget child;
  final VoidCallback? onBack;

  /// CTA bas, centré (ex. bouton « Suivant »).
  final Widget? bottomCta;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: AppBackdrop(
        child: Stack(
          children: <Widget>[
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
                      _WizardHeader(onBack: onBack),
                      cSh(isPhoneLayout ? 6 : 14),
                      Container(height: 1, color: AppColor.divider),
                    ],
                  ),
                ),
                cSh(isPhoneLayout ? 8 : 26),
                Text(
                  title,
                  style: AppThemeStyle.semiBStyle(
                    isPhoneLayout ? cFs(26) : cFs(30),
                    AppColor.primaryLabels,
                  ),
                ),
                // Clavier ouvert, le body est amputé de la hauteur du
                // clavier : le contenu défile au lieu de déborder.
                // `minHeight` conserve la contrainte tendue d'aujourd'hui —
                // l'étape 3 n'a pas de `Center` et compte dessus pour rester
                // alignée en haut.
                Expanded(
                  child: LayoutBuilder(
                    builder:
                        (BuildContext ctx, BoxConstraints c) =>
                            SingleChildScrollView(
                              // Dégage le CTA flottant (Positioned bas), et
                              // seulement clavier ouvert : sinon le rendu au
                              // repos deviendrait tirable.
                              // Inset lu sur la VUE, pas via MediaQuery : les
                              // routes sont poussées sous le `Scaffold(body:
                              // AutoRouter())` du skeleton, qui remet l'inset
                              // du body à zéro. Lu DANS le LayoutBuilder, qui
                              // lui est bien rejoué au redimensionnement.
                              padding: EdgeInsets.only(
                                bottom:
                                    bottomCta != null &&
                                            View.of(ctx).viewInsets.bottom > 0
                                        ? cH(92)
                                        : 0,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: c.maxHeight,
                                ),
                                child: child,
                              ),
                            ),
                  ),
                ),
                if (isPhoneLayout && bottomCta != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 10),
                    child: bottomCta!,
                  ),
              ],
            ),
            if (!isPhoneLayout && bottomCta != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: cH(30),
                child: Center(child: bottomCta!),
              ),
          ],
        ),
      ),
    );
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        CustomBackButton(
          onTap: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        cSw(14),
        Container(
          width: 1,
          height: isPhoneLayout ? 20 : cH(30),
          color: AppColor.divider,
        ),
        cSw(14),
        WhistleIcon(size: cIc(24), color: AppColor.primaryColor),
        cSw(10),
        Text(
          'app.match-wizard.coup-denvoi'.tr(),
          style: AppThemeStyle.semiBStyle(cFs(28), AppColor.primaryLabels),
        ),
        const Spacer(),
        WinaWordmark(size: isPhoneLayout ? 22 : 34),
      ],
    );
  }
}

/// Pastille blanche « Mon équipe » / « Équipe adverse » (icône + libellé),
/// posée au-dessus de l'écusson.
class TeamLabelBadge extends StatelessWidget {
  const TeamLabelBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: cW(14), vertical: cH(8)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(20)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColor.primaryLabels.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Iconsax.people, size: cIc(15), color: AppColor.primaryColor),
          cSw(8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.regularStyle(
                cFs(13),
                AppColor.primaryLabels,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Puce d'information (vert pâle) — poste, division, etc.
class InfoChip extends StatelessWidget {
  const InfoChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: cW(14), vertical: cH(7)),
      decoration: BoxDecoration(
        color: AppColor.chipBackground,
        borderRadius: BorderRadius.circular(cR(18)),
      ),
      child: Text(
        label,
        style: AppThemeStyle.mediumStyle(cFs(13), AppColor.primaryLabels),
      ),
    );
  }
}

/// Badge « VS » central (vert).
class VsBadge extends StatelessWidget {
  const VsBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'app.match-wizard.vs'.tr(),
      style: AppThemeStyle.boldStyle(cFs(30), AppColor.primaryColor),
    );
  }
}

/// Pilule « libellé … valeur ⌄ » (vert pâle) — sélecteur compact utilisé pour
/// la catégorie / division de l'adversaire.
class LabeledPillDropdown<T> extends StatelessWidget {
  const LabeledPillDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
    this.leadingOf,
  });

  final String label;
  final T? value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  /// Visuel optionnel devant chaque option (ex. vignette de maillot), sur le
  /// modèle de `CpDropdown.leadingOf`.
  final Widget Function(T)? leadingOf;

  /// `MainAxisSize.min` est indispensable ici, contrairement à `CpDropdown` :
  /// ce dropdown n'est PAS `isExpanded`, il se dimensionne sur la largeur
  /// intrinsèque de ses items — une `Row` non bornée réclamerait la largeur max.
  Widget _item(T v) {
    if (leadingOf == null) return Text(labelOf(v));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[leadingOf!(v), cSw(10), Text(labelOf(v))],
    );
  }

  /// Ligne « libellé … valeur » affichée dans le bouton fermé.
  Widget _closedRow(Widget valueWidget) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemeStyle.regularStyle(
              cFs(14),
              AppColor.secondaryLabels,
            ),
          ),
        ),
        cSw(12),
        valueWidget,
      ],
    );
  }

  /// Le `DropdownButton` est `isExpanded` : toute la pilule est cliquable,
  /// pas seulement la valeur et le chevron.
  @override
  Widget build(BuildContext context) {
    return Container(
      // Téléphone : le bouton « dense » est fin, on garde une zone tactile de
      // ~36 dp (toute la pilule reste cliquable).
      padding: EdgeInsets.only(
        left: cW(18),
        right: cW(10),
        top: isPhoneLayout ? 8 : 0,
        bottom: isPhoneLayout ? 8 : 0,
      ),
      decoration: BoxDecoration(
        color: AppColor.chipBackground,
        borderRadius: BorderRadius.circular(cR(14)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          // Hauteur 48 imposée par défaut : trop haut pour un téléphone paysage.
          isDense: isPhoneLayout,
          itemHeight: isPhoneLayout ? null : kMinInteractiveDimension,
          borderRadius: BorderRadius.circular(cR(12)),
          hint: _closedRow(
            Text(
              'utils.choose'.tr(),
              style: AppThemeStyle.regularStyle(
                cFs(14),
                AppColor.secondaryLabels,
              ),
            ),
          ),
          selectedItemBuilder:
              (BuildContext context) => <Widget>[
                for (final T v in values) _closedRow(_item(v)),
              ],
          icon: Icon(
            Iconsax.arrow_down_1_copy,
            size: cIc(20),
            color: AppColor.primaryLabels,
          ),
          style: AppThemeStyle.regularStyle(cFs(14), AppColor.primaryLabels),
          dropdownColor: AppColor.surface,
          items: <DropdownMenuItem<T>>[
            for (final T v in values)
              DropdownMenuItem<T>(value: v, child: _item(v)),
          ],
          onChanged: (T? v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// Bouton « Suivant » / « Démarrer le match » de l'assistant (pilule verte
/// avec pastille fléchée). Grisé + non cliquable quand [enabled] est faux.
class WizardCtaButton extends StatelessWidget {
  const WizardCtaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final double badge = cIc(22);
    final Color bg =
        enabled
            ? AppColor.primaryColor
            : AppColor.primaryColor.withValues(alpha: 0.4);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(cR(28)),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(cR(28)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: cW(28), vertical: cH(15)),
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
                child: Icon(
                  Iconsax.arrow_circle_right,
                  size: cIc(13),
                  color: AppColor.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
