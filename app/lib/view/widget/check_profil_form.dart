import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/orientation_controller.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/live_match.dart';
import 'package:wina/providers/home_tab_provider.dart';
import 'package:wina/providers/live_match_providers.dart';
import 'package:wina/routes/app_router.gr.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/confirm_dialog.dart';
import 'package:wina/view/widget/custom_back_button.dart';

/// Logo « wina » (w vert + ina sombre). Cliquable par défaut : il ramène à
/// l'accueil. Deux réserves : `tappable: false` sur les entêtes qui barrent
/// volontairement la sortie (écran « Finalisez votre profil »), et un match en
/// cours neutralise le raccourci de lui-même (cf. `_goHome`).
class WinaWordmark extends ConsumerWidget {
  const WinaWordmark({super.key, this.size = 125, this.tappable = true});

  final double size;
  final bool tappable;

  /// Retour à l'accueil à travers les trois navigators imbriqués : `popUntil`
  /// dépile les écrans poussés en `MaterialPageRoute` sur le navigator de
  /// `LoggedUserAppCorePage` (dont la première route est `HomeRoute`), puis
  /// `root.navigate` remet la coquille sur l'accueil — indispensable depuis
  /// Paramètres, qui vit dans le routeur propre à `ProfileParentPage`.
  void _goHome(BuildContext context, WidgetRef ref) {
    // Un match en cours n'est abandonné proprement — état en mémoire vidé ET
    // document Firestore marqué — que par « Quitter le match ». Un retour
    // accueil depuis une entête le laisserait orphelin : entête de match, mais
    // aussi « Modifier composition », qui rouvre le sous-flux « Gérer mon
    // équipe » par-dessus le direct. Garde posée ici, donc valable pour les
    // douze entêtes qui portent le logo.
    final LiveMatch? live = ref.read(liveMatchProvider);
    if (live != null && (live.isLive || live.isPaused)) {
      // Pas de sortie silencieuse : un logo qui ne répond à rien se lit comme
      // un bug (et le direct peut rester ouvert derrière un retour système,
      // rendant alors le logo inerte partout). Même confirmation que le bouton
      // « Quitter le match » de l'écran de direct.
      showDialog<void>(
        context: context,
        barrierColor: AppColor.scrim,
        builder:
            (BuildContext ctx) => AppConfirmDialog(
              title: 'app.match-live.titre-quitter'.tr(),
              message: 'app.match-live.message-quitter'.tr(),
              primaryLabel: 'app.match-live.reprendre-match'.tr(),
              onPrimary: () => Navigator.of(ctx).pop(),
              secondaryLabel: 'app.match-live.quitter-quand-meme'.tr(),
              onSecondary: () {
                Navigator.of(ctx).pop();
                abandonLiveMatch(ref);
                _navigateHome(context, ref);
              },
            ),
      );
      return;
    }
    _navigateHome(context, ref);
  }

  void _navigateHome(BuildContext context, WidgetRef ref) {
    // L'accueil est un IndexedStack à 4 onglets : sans cette remise à zéro, le
    // logo des onglets IA / Statistiques / Test équipe ne ferait rien (on y est
    // déjà sur la première route et sur `HomeRoute`).
    ref.read(homeTabProvider.notifier).state = 0;
    final StackRouter router = AutoRouter.of(context).root;
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    router.navigate(
      const LoggedUserAppCoreRoute(children: <PageRouteInfo>[HomeRoute()]),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget logo = SvgPicture.asset(
      "assets/svg/logo_inline.svg",
      width: sp(125),
    );
    if (!tappable) return logo;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _goHome(context, ref),
      child: logo,
    );
    // return Text.rich(
    //   TextSpan(
    //     children: [
    //       TextSpan(
    //         text: 'w',
    //         style: AppThemeStyle.regularStyle(size, AppColor.primaryColor),
    //       ),
    //       TextSpan(
    //         text: 'ina',
    //         style: AppThemeStyle.regularStyle(size, AppColor.primaryLabels),
    //       ),
    //     ],
    //   ),
    // );
  }
}

/// Hauteur du clavier à l'écran, lue sur la vue elle-même.
///
/// Un `Scaffold` qui se redimensionne pour le clavier retire cette hauteur du `MediaQuery` de son corps :
/// `MediaQuery.viewInsetsOf` y vaut alors 0 et ne permet pas de retrouver la hauteur d'écran complète.
double keyboardInset(BuildContext context) {
  final view = View.of(context);
  return view.viewInsets.bottom / view.devicePixelRatio;
}

/// Ossature des écrans « Finalisez votre profil » : logo en haut, carte blanche
/// centrée (bouton retour + titre), contenu défilable.
class CheckProfilScaffold extends StatelessWidget {
  const CheckProfilScaffold({
    super.key,
    required this.title,
    required this.children,
    this.onBack,
    this.width,
    this.portraitOnPhone = false,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;

  /// Largeur de la carte ; par défaut celle, étroite, des écrans de complétion de profil.
  final double? width;

  /// Sur téléphone, affiche l'écran en portrait (parcours d'entrée : inscription et
  /// « Finalisez votre profil »). Faux pour les écrans de l'app, qui restent en paysage.
  final bool portraitOnPhone;

  @override
  Widget build(BuildContext context) {
    final Widget scaffold = _buildScaffold(context);
    return portraitOnPhone ? PortraitScope(child: scaffold) : scaffold;
  }

  Widget _buildScaffold(BuildContext context) {
    // Téléphone en portrait : la carte prend la largeur de l'écran, moins une marge.
    final bool narrow = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor: AppColor.background,
      body: AppBackdrop(
        child: Stack(
          children: [
            Column(
              children: [
                cSh(24),
                // `tappable: false` : cet écran est empilé sur le navigator ROOT
                // par le paquet skeleton ; un retour accueil contournerait la
                // complétion de profil obligatoire.
                const WinaWordmark(size: 34, tappable: false),
                Expanded(
                  // Tient sur un écran sans défilement : la carte est réduite si besoin ;
                  // le clavier ouvert fait défiler au lieu de la réduire encore.
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints cons) {
                      // Hauteur SANS le clavier : la carte garde sa taille, c'est le défilement qui laisse
                      // la place au clavier (sinon elle rétrécirait à chaque ouverture).
                      final double fullHeight =
                          cons.maxHeight + keyboardInset(context);
                      final double gutter = narrow ? cW(16) : 0;
                      return SingleChildScrollView(
                        child: SizedBox(
                          width: cons.maxWidth,
                          height: fullHeight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: cH(20),
                                horizontal: gutter,
                              ),
                              child: Container(
                                width:
                                    narrow
                                        ? cons.maxWidth - 2 * gutter
                                        : (width ?? cW(430)),
                                padding: EdgeInsets.symmetric(
                                  horizontal: cW(28),
                                  vertical: cH(28),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColor.surface,
                                  borderRadius: BorderRadius.circular(cR(20)),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        if (onBack != null) ...[
                                          CustomBackButton(onTap: onBack!),
                                          cSw(12),
                                        ],
                                        Flexible(
                                          child: Text(
                                            title,
                                            style: AppThemeStyle.semiBStyle(
                                              cFs(18),
                                              AppColor.primaryLabels,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    cSh(22),
                                    ...children,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

/// Libellé de champ.
class CpLabel extends StatelessWidget {
  const CpLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppThemeStyle.mediumStyle(cFs(13), AppColor.primaryLabels),
    );
  }
}

/// Conteneur de champ (fond blanc, bord fin, arrondi).
///
/// [error] passe la bordure au rouge de la bannière d'erreur (`DefaultColor
/// .error`) : champ obligatoire laissé vide au moment de la validation.
class CpBox extends StatelessWidget {
  const CpBox({super.key, required this.child, this.error = false});

  final Widget child;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: cW(20), vertical: cH(12)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(12)),
        border: Border.all(
          color: error ? DefaultColor.error : AppColor.divider,
          width: error ? 1.5 : 1,
        ),
      ),
      child: child,
    );
  }
}

class CpTextField extends StatelessWidget {
  const CpTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.error = false,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final bool error;

  /// Masque la saisie (mot de passe).
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return CpBox(
      error: error,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        obscureText: obscure,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        autocorrect: !obscure,
        enableSuggestions: !obscure,
        cursorColor: AppColor.primaryColor,
        style: AppThemeStyle.regularStyle(cFs(15), AppColor.primaryLabels),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppThemeStyle.regularStyle(
            cFs(15),
            AppColor.secondaryLabels,
          ),
        ),
      ),
    );
  }
}

/// Liste déroulante facultative (« Choisir » tant que rien n'est sélectionné).
/// [leadingOf] permet d'afficher une pastille (couleur) devant chaque option.
class CpDropdown<T> extends StatelessWidget {
  const CpDropdown({
    super.key,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
    this.leadingOf,
    this.error = false,
  });

  final T? value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final Widget Function(T)? leadingOf;
  final bool error;

  Widget _item(T v) {
    if (leadingOf == null) return Text(labelOf(v));
    return Row(children: [leadingOf!(v), cSw(10), Text(labelOf(v))]);
  }

  @override
  Widget build(BuildContext context) {
    return CpBox(
      error: error,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(cR(12)),
          hint: Text(
            'utils.choose'.tr(),
            style: AppThemeStyle.regularStyle(
              cFs(15),
              AppColor.secondaryLabels,
            ),
          ),
          icon: Icon(
            Iconsax.arrow_down_1_copy,
            size: cIc(22),
            color: AppColor.primaryLabels,
          ),
          style: AppThemeStyle.regularStyle(cFs(15), AppColor.primaryLabels),
          items: [
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

/// Note « *Champs obligatoires » centrée sous les boutons.
class CpRequiredNote extends StatelessWidget {
  const CpRequiredNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'app.check-profil-form.champs-obligatoires'.tr(),
        style: AppThemeStyle.regularStyle(cFs(12), AppColor.secondaryLabels),
      ),
    );
  }
}

/// Bouton plein largeur. [soft] = vert pâle (action secondaire), sinon vert plein.
/// [radius] permet d'ajuster l'arrondi (999 = pilule par défaut ; le formulaire
/// joueur utilise 14).
class CpButton extends StatelessWidget {
  const CpButton({
    super.key,
    required this.label,
    required this.onTap,
    this.soft = false,
    this.radius = 999,
  });

  final String label;
  final VoidCallback onTap;
  final bool soft;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final double badge = cIc(22);
    // `surface` est le blanc des cartes : un bouton soft posé sur une carte
    // (les 5 appelants le sont) devenait invisible, alors que la maquette
    // montre une pilule vert pâle. `background` est cette teinte (#EFF4EF).
    final Color bg = soft ? AppColor.background : AppColor.primaryColor;
    final Color fg = soft ? AppColor.primaryLabels : AppColor.textLight;
    final Color badgeBg = soft ? AppColor.primaryLabels : AppColor.textLight;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(cR(radius)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cR(radius)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: cH(15)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Le libellé rétrécit au lieu de déborder quand le bouton est étroit (deux boutons côte à côte
              // sur téléphone, libellé long).
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppThemeStyle.semiBStyle(cFs(15), fg),
                  ),
                ),
              ),
              cSw(7),
              SizedBox(
                width: badge,
                height: badge,
                child: Icon(
                  Iconsax.arrow_circle_right,
                  size: cIc(13),
                  color: badgeBg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
