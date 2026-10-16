import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
import 'package:provider/provider.dart';

/// {@category Widget}
/// {@category Research}
///
/// Permet d'afficher un bouton de recherche.
/// L'ui est celui d'un [FormClassicField] mais
/// le champ de recherche est vide et lorsque
/// l'utilisateur clique dessus, il est redirigé
/// vers la page de recherche (ou la route fourni
/// en paramètre [route]).
///
class ResearchButton extends ConsumerWidget {
  final String? hint;
  final String? heroTag;
  final Widget? prefixIcon;
  final String? route;
  final PageRouteInfo? searchPageInfo;

  /// Theme
  final String? themeName;
  final FormFieldThemeData? theme;
  final InputDecoration? decoration;

  const ResearchButton(
      {super.key,
      this.hint,
      this.prefixIcon,
      this.route,
      this.searchPageInfo,

      /// Theme
      this.themeName,
      this.theme,
      this.decoration,
      this.heroTag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FormFieldThemeData themeData = loadThemeData(
      theme,
      themeName ?? "form_field",
      () => const FormFieldThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    InputDecoration decoration = (this.decoration ??
            themeData.inputDecoration ??
            kDefaultInputDecoration)
        .copyWith(
      hintText: hint ?? "package.research.hint".tr(),
    );
    decoration = decoration.copyWith(
      prefixIcon: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ignore: deprecated_member_use
          prefixIcon ??
              SvgPicture.asset("assets/svg/ic_search.svg",
                  package: "ui_kosmos_v4", color: decoration.prefixIconColor),
        ],
      ),
    );

    return InkWell(
      onTap: () {
        if (searchPageInfo == null) {
          AutoRouter.of(context).pushNamed(route ?? "app/research");
        } else {
          context.pushRoute(searchPageInfo!);
        }
      },
      child: Hero(
          tag: heroTag ?? "research_button",
          child: FormClassicField(
            maxLines: 1,
            isRequired: false,
            isEnabled: false,
            inputDecoration: decoration.copyWith(
              hintMaxLines: 1,
            ),
          )),
    );
  }
}
