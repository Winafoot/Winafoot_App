import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/bottom_bar/bottom_bar_item.dart';

final navigationProvider = NotifierProvider<NavigationPath, String>(NavigationPath.new);

class NavigationPath extends Notifier<String> {
  @override
  String build() => "home";

  void setPath(String newPath) => state = newPath;
}

class BottomBarWidget extends ConsumerWidget {
  final List<BottomBarItem> items;
  final double? height;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const BottomBarWidget({
    super.key,
    required this.items,
    this.height,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: height,
      color: backgroundColor ?? Colors.white,
      padding: padding ??
          pwh(8, 40).add(
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom)),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          for (final item in items) ...[
            InkWell(
              onTap: () {
                if (item.updateProvider)
                  ref.read(navigationProvider.notifier).setPath(item.tag);
                item.onTap?.call();
              },
              child: Padding(
                padding: pwh(12, 15),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      item.icon,
                      if (item.label != null) ...[
                        sh(2),
                        Text(item.label!,
                            style:
                                DefaultAppStyle.darkBlue(10, FontWeight.w500)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (item != items.last) const Spacer(),
          ],
        ],
      ),
    );
  }
}
