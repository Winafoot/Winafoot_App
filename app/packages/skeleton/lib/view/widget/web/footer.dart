import 'package:flutter/material.dart';
import 'package:skeleton/skeleton.dart';
import 'package:url_launcher/url_launcher.dart';

class WebFooter extends StatefulHookConsumerWidget {
  const WebFooter({super.key});

  @override
  ConsumerState<WebFooter> createState() => _WebFooterState();
}

class _WebFooterState extends ConsumerState<WebFooter> {
  late final SkeletonAppConfig? config = getAppModel()
      .getDependenciesFromName<SkeletonAppConfig>("skeleton_app_config");

  @override
  Widget build(BuildContext context) {
    final SkeletonWebThemeData themeData = loadThemeData(
      null,
      "skeleton_footer",
      () => kDefaultSkeletonWebThemeData,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    final List<Link> items = config?.bottomBarItem ?? [];

    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: BoxConstraints(minHeight: formatHeight(70)),
      decoration: themeData.footerDecoration,
      child: Wrap(
        direction: Axis.horizontal,
        alignment: WrapAlignment.spaceEvenly,
        spacing: themeData.footerItemSpacing ?? formatWidth(50),
        runAlignment: WrapAlignment.center,
        runSpacing: formatHeight(20),
        children: [
          for (final item in items) ...[
            InkWell(
              onTap: item.onTap == null
                  ? () => launchUrl(Uri.parse(item.url))
                  : () => item.onTap?.call(context, ref),
              child:
                  Text(item.title.call(ref), style: themeData.footerItemStyle),
            ),
            // if (item != items.last)
            //   SizedBox(width: themeData.footerItemSpacing ?? formatWidth(50)),
          ],
        ],
      ),
    );
  }
}
