import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:skeleton/skeleton.dart';
import 'package:skeleton/view/widget/web/footer.dart';

class AuthParent extends ConsumerStatefulWidget {
  final Widget child;
  final dynamic Function(BuildContext context)? onBack;
  final bool showBackButton;
  final Size? logoSize;
  final ScrollController? scrollController;
  final Widget? backgroundPage;
  final Widget Function(BuildContext context)? appBarActionWidget;
  final bool? hideLogo;

  const AuthParent({
    super.key,
    required this.child,
    this.onBack,
    this.showBackButton = true,
    this.logoSize,
    this.scrollController,
    this.backgroundPage,
    this.appBarActionWidget,
    this.hideLogo,
  });

  @override
  ConsumerState<AuthParent> createState() => _AuthParentState();
}

class _AuthParentState extends ConsumerState<AuthParent> {
  late ThemeData? lightTheme;
  late ThemeData? darkTheme;
  late final config = getAppModel()
      .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");
  

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() {
    if (GetIt.instance.isRegistered<AppTheme>()) {
      lightTheme = GetIt.instance<AppTheme>().themeData;
      darkTheme = GetIt.instance<AppTheme>().themeDataDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return getResponsiveValue<Widget>(
      context,
      defaultValue: _buildWeb(context),
      phone: _buildPhone(context),
    );
  }

  Widget _buildPhone(BuildContext context) {
    final btd = loadThemeData(
      null,
      "back_button",
      () => const KosmosButtonThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    final size = (((widget.logoSize?.height ?? 0)) >
            (((btd?.iconSize ?? formatWidth(26)) +
                ((btd?.padding ?? EdgeInsets.zero) as EdgeInsets).top)))
        ? widget.logoSize?.height ?? 0
        : (((btd?.iconSize ?? formatWidth(26)) +
            (((btd?.padding ?? EdgeInsets.zero) as EdgeInsets).top) +
            ((btd?.padding ?? EdgeInsets.zero) as EdgeInsets).bottom));

    return Container(
      width: double.infinity,
      height: double.infinity,
      color:
      ref.watch(isDarkModeProvider).isDarkMode ? darkTheme?.scaffoldBackgroundColor?? Theme.of(context).scaffoldBackgroundColor : lightTheme?.scaffoldBackgroundColor ??  Theme.of(context).scaffoldBackgroundColor,
      
      child: Stack(
        children: [
          if (widget.backgroundPage != null)
            Positioned.fill(child: widget.backgroundPage!),
          Positioned.fill(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              physics: const BouncingScrollPhysics(),
              // primary: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      height: MediaQuery.of(context).padding.top +
                          formatHeight(20)),
                  SizedBox(
                    height: size + formatHeight(10),
                    child: Stack(
                      children: [
                        SizedBox(
                            width: double.infinity,
                            height: size + formatHeight(10)),
                        if (widget.showBackButton)
                          Positioned(
                              top: 0,
                              bottom: 0,
                              child: ButtonBack(
                                  onTap: () => widget.onBack?.call(context),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: formatWidth(27.5)))),
                        if (widget.hideLogo != true &&
                            (config?.authentificationConfig.showLogoOnPage ??
                                true) &&
                            config?.logoPath != null)
                          Positioned(
                              child: Center(
                                  child: _createImageLogo(
                                      config!.logoPath, config!.logoFormat))),
                        if (widget.appBarActionWidget != null)
                          widget.appBarActionWidget!(context),
                      ],
                    ),
                  ),
                  sh(38),
                  widget.child,
                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom +
                          formatHeight(12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    final SkeletonWebThemeData themeData = loadThemeData(
      null,
      "skeleton_footer",
      () => kDefaultSkeletonWebThemeData,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    return Container(
      width: double.infinity,
      height: double.infinity,
      // `backgroundPage` n'etait rendu que par `_buildPhone` (l.86) : toute
      // application qui n'atteint jamais cette branche — verrouillee en
      // paysage, ou sur un gabarit tablette au-dessus de la balise PHONE —
      // se voyait offrir un crochet de theme structurellement inoperant.
      // Il est ici rendu SOUS le contenu, en premier enfant d'un Stack pose
      // directement sous le Container racine : le poser dans le Stack interne
      // le rognerait, celui-ci etant enferme dans un SingleChildScrollView
      // dimensionne au contenu. Garde par un test de nullite : sans crochet
      // fourni, le rendu est identique a l'existant.
      color:
       ref.watch(isDarkModeProvider).isDarkMode ? darkTheme?.scaffoldBackgroundColor?? Theme.of(context).scaffoldBackgroundColor : lightTheme?.scaffoldBackgroundColor ??  Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.backgroundPage != null)
            Positioned.fill(child: widget.backgroundPage!),
          Positioned.fill(
            child:
     
     kIsWeb ?
       Stack(
        children: [
          Positioned.fill(
              child:
                  Container(color: Theme.of(context).scaffoldBackgroundColor)),
          // if ((config?.authentificationConfig.showLogoOnPage ?? true) &&
          //     config?.logoPath != null)
          //   Positioned(
          //     top: MediaQuery.of(context).padding.top + formatHeight(21),
          //     left: formatWidth(45),
          //     child: _createImageLogo(config!.logoPath, config!.logoFormat),
          //   ),
          if (config?.bottomBarItem?.isNotEmpty ?? false) ...[
            const Positioned(
              bottom: 0,
              child: WebFooter(),
            ),
          ],
          Center(
            child: Padding(
              padding:
                  EdgeInsets.only(bottom: themeData.height ?? formatHeight(70)),
              child: widget.child,
            ),
          ),
        ],
      ) : 
      
       Center(
        child: SingleChildScrollView(
          child: Stack(
            alignment: Alignment.center,
            children: [
              
              // if ((config?.authentificationConfig.showLogoOnPage ?? true) &&
              //     config?.logoPath != null)
              //   Positioned(
              //     top: MediaQuery.of(context).padding.top + formatHeight(21),
              //     left: formatWidth(45),
              //     child: _createImageLogo(config!.logoPath, config!.logoFormat),
              //   ),
              if (config?.bottomBarItem?.isNotEmpty ?? false) ...[
                const Positioned(
                  bottom: 0,
                  child: WebFooter(),
                ),
              ],
          
              
              Center(
                child: Padding(
                          padding:
                              EdgeInsets.only(bottom: themeData.height ?? formatHeight(70)),
                          child: widget.child,
                          ),
              )
            ],
          ),
        ),
      ),
          ),
        ],
      ),
    );
  }

  Widget _createImageLogo(String path, LogoFormat format) {
    if (format == LogoFormat.svg) {
      return SvgPicture.asset(path,
          width: widget.logoSize?.width, height: widget.logoSize?.height);
    } else {
      return Image.asset(path,
          width: widget.logoSize?.width, height: widget.logoSize?.height);
    }
  }
}
