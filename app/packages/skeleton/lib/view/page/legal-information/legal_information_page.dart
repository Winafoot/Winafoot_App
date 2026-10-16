import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:skeleton/skeleton.dart';

class LegalInformationPage extends ConsumerStatefulWidget {
  final String info;

  const LegalInformationPage(
      {super.key, @PathParam("info") required this.info});

  @override
  ConsumerState<LegalInformationPage> createState() =>
      _LegalInformationPageState();
}

class _LegalInformationPageState extends ConsumerState<LegalInformationPage> {
  late final Future<AppMetadataConfig?> _future =
      AppMetadataController.getMetadataConfig();

  String? _extractContent(AppMetadataConfig? config) {
    if (config == null) return null;
    if (widget.info == "about") return config.about;
    if (widget.info == "privacy-policy") return config.confidentialityPolicy;
    if (widget.info == "cgvu") return config.cgvu;
    if (widget.info == "legal-notice") return config.legalNotice;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
      null,
      "kosmos-settings",
      () => kDefaultSettingsTheme,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    final themeAuth = loadThemeData<AuthTemplateThemeData>(
      null,
      "authentication_theme",
      () => const AuthTemplateThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    return Scaffold(
      backgroundColor: themeAuth.popupBackgroundColor ??
          Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (themeAuth.legalPageBackground != null)
            Positioned.fill(child: themeAuth.legalPageBackground!(context)),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sh(12),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ButtonBack(
                        onTap: () => AutoRouter.of(context).canPop()
                            ? AutoRouter.of(context).pop()
                            : AutoRouter.of(context).navigateBack(),
                        color: themeData?.actionIconColor,
                        padding:
                            EdgeInsets.symmetric(horizontal: formatWidth(27.5)),
                      ),
                      sw(12),
                      Expanded(
                        child: Center(
                          child: Text(
                              "package.settings.node.link.${widget.info}".tr(),
                              style: themeData?.sectionTitleStyle,
                              textAlign: TextAlign.center),
                        ),
                      ),
                      sw(12),
                      Opacity(
                        opacity: 0,
                        child: ButtonBack(
                          onTap: () {},
                          padding: EdgeInsets.symmetric(
                              horizontal: formatWidth(27.5)),
                        ),
                      ),
                    ],
                  ),
                  sh(25),
                  Expanded(
                    child: FutureBuilder<AppMetadataConfig?>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final content = _extractContent(snapshot.data);
                        if (content == null) {
                          return Center(child: Text("utils.loading".tr()));
                        }
                        return SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                                    horizontal: formatWidth(29))
                                .copyWith(bottom: formatHeight(20)),
                            physics: const BouncingScrollPhysics(),
                            primary: true,
                            child: HtmlWidget(
                              content,
                              textStyle: themeAuth.htmlTextStyle,
                            ),
                          );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
