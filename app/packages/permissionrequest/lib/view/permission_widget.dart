import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permissionrequest/permissons_package.dart';
import 'package:ui_kosmos_v4/button/back_button.dart';
import 'package:ui_kosmos_v4/button/button.dart';

/// {@category Widget}
/// {@category Permission}
///
/// Permet d'afficher les permissions.
/// Cette page permet d'afficher votre propre liste de
/// permissions. Via le paramètre [permissions] ou via
/// la configuration [config].
///
/// Exemple:
///
/// ```Dart
/// PermissionWidget(
///   permissions: <PageController>[...],
///   pageController: _pageController,
///   themeData: null,
///   themeName: "permission",
///   config: PermissionConfig(),
/// )
/// ```
///
/// Vous pouvez aussi fournir votre theme via le paramètre
/// [themeData] ou alors directement le récupérer via la key
/// donnée en [themeName].
/// Par défaut, le Widget cherchera un thème via la key
/// "permission".
///
class PermissionWidget extends ConsumerStatefulWidget {
  final PageController? pageController;
  final List<PermissionDataModel> permissions;
  final String? appLogoAsset;

  /// Theme and Config
  final PermissionThemeData? themeData;
  final PermissionConfig? config;
  final String? themeName;

  const PermissionWidget({
    super.key,
    this.pageController,
    required this.permissions,
    this.themeData,
    this.config,
    this.appLogoAsset,
    this.themeName,
  });

  @override
  ConsumerState<PermissionWidget> createState() => _PermissionWidgetState();
}

class _PermissionWidgetState extends ConsumerState<PermissionWidget> {

  late final PermissionConfig? config = widget.config ??
      (getAppModel().dependencies.packages["permission-kosmos"]
          as PermissionConfig?);

  late final PageController _pageController =
      widget.pageController ?? PageController();

  int _actualPage = 0;

  @override
  void initState() {
    _pageController.addListener(() {
      if (!_pageController.hasClients) return;
      setState(() => _actualPage = _pageController.page!.round());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final PermissionThemeData themeData = loadThemeData(widget.themeData,
      widget.themeName ?? "permission", () => kDefaultPermissionTheme,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
      );
    return Stack(
      children: [
        if (config?.backgroundChild != null) config!.backgroundChild!(context),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: themeData.backgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sh(12),
                  Stack(
                    children: [
                      const SizedBox(width: double.infinity),
                      if (widget.appLogoAsset != null)
                        Positioned(
                          child: Center(
                              child: Image.asset(widget.appLogoAsset!,
                                  width: themeData.logoSize?.width,
                                  height: themeData.logoSize?.height)),
                        )
                      else
                        Positioned(child: sh(40)),
                      if (config?.showBackButton ?? true)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Flex(
                            direction: Axis.vertical,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Opacity(
                                      opacity: _actualPage == 0 ? 0 : 1,
                                      child: ButtonBack(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: formatWidth(27.5)),
                                        themeName:
                                            themeData.backButtonThemeName,
                                        onTap: () => _actualPage == 0
                                            ? () {}
                                            : _pageController.previousPage(
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                curve: Curves.easeInOut),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (config?.showSkipButton ?? true)
                        Positioned(
                          top: 0,
                          right: 0,
                          bottom: 0,
                          child: Flex(
                            direction: Axis.vertical,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        if (config?.onSkipButtonPressed !=
                                            null) {
                                          config?.onSkipButtonPressed
                                              ?.call(_pageController, context);
                                        } else {
                                          await PermissionController
                                              .setPermissionAsComplete();
                                          AutoRouter.of(context)
                                              .replaceNamed("/");
                                        }
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: formatWidth(29)),
                                        child: Text(
                                            "package.permission.skip".tr(),
                                            style: themeData.skipButtonStyle),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                    ],
                  ),
                  sh(12),

                  /// Build Permission
                  Expanded(
                    child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: widget.permissions
                            .map((e) => _buildPermission(context, e, themeData))
                            .toList()),
                  ),

                  /// Build Action button
                  sh(39),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: formatWidth(29)),
                    child: widget.permissions[_actualPage].actionButton?.call(
                            context,
                            ref,
                            _pageController,
                            _actualPage == widget.permissions.length - 1) ??
                        Button(
                          text: widget.permissions[_actualPage].buttonText
                                  ?.call() ??
                              "no-value",
                          width: double.infinity,
                          height: formatHeight(54),
                          onTap: () async => await widget
                              .permissions[_actualPage].onActionButtonPressed
                              ?.call(
                            context,
                            ref,
                            _pageController,
                            _actualPage == widget.permissions.length - 1,
                          ),
                        ),
                  ),
                  sh(24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermission(BuildContext context, PermissionDataModel data,
      PermissionThemeData themeData) {
    final title = data.title?.call();
    final description = data.description?.call();
    final Widget child = data.child ??
        (data.imagePath != null
            ? Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                    child: SizedBox(
                        width: themeData.childSize?.width,
                        height: themeData.childSize?.height,
                        child: Image.asset(
                          data.imagePath!,
                          fit: BoxFit.contain,
                        ))),
              )
            : (data.svgPath != null
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                        width: themeData.childSize?.width,
                        height: themeData.childSize?.height,
                        child: SvgPicture.asset(
                          data.svgPath!,
                          fit: BoxFit.contain,
                        )),
                  )
                : const SizedBox()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: child),
        sh(29),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: formatHeight(240)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: formatWidth(29)),
                    child: Text(title,
                        style: themeData.titleStyle,
                        textAlign: TextAlign.center),
                  ),
                ),
                sh(9),
              ] else if (data.titleWidget != null) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: formatWidth(29)),
                  child: data.titleWidget!.call(context),
                ),
                sh(9),
              ],
              if (description != null) ...[
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: formatWidth(29)),
                    child: Text(description,
                        style: themeData.descriptionStyle,
                        textAlign: TextAlign.center),
                  ),
                ),
              ] else if (data.descriptionWidget != null) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: formatWidth(29)),
                  child: data.descriptionWidget!.call(context),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
