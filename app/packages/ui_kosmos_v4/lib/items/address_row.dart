import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:ui_kosmos_v4/items/theme/item_theme.dart';

/// {@category Widget}
/// {@category Item}
///
/// Permet d'afficher une adresse avec un bouton pour l'ouvrir dans
/// une application de navigation.
///
/// **Attention**: Pour utiliser cette fonctionnalité, il faut ajouter
/// la dépendance suivante dans le pubspec.yaml:
///
/// ```yaml
/// dependencies:
///   map_launcher:
/// ```
///
/// Et ajouter les permissions suivantes dans le Info.plist:
///
/// ```xml
/// <key>LSApplicationQueriesSchemes</key>
/// <array>
/// 	<string>comgooglemaps</string>
/// 	<string>waze</string>
/// 	<string>iosamap</string>
/// </array>
/// ```
///
/// Exemple:
///
/// ![address_row](../../images/item/address_row.png)
///
/// ```dart
/// AddressRow(
///   address: "1 rue de la paix",
///   location: GeoPoint(48.8566, 2.3522),
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [ItemThemeData] : "item".
class AddressRow extends ConsumerStatefulWidget {
  final String address;
  final String? title;
  final GeoPoint location;

  final Widget? suffix;

  /// Theme
  final ItemThemeData? theme;
  final String? themeName;

  const AddressRow({
    super.key,
    this.title,
    required this.address,
    required this.location,
    this.suffix,
    this.theme,
    this.themeName,
  });

  @override
  ConsumerState<AddressRow> createState() => _AddressRowState();
}

class _AddressRowState extends ConsumerState<AddressRow> {
  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
      widget.theme,
      widget.themeName ?? "item",
      () => kDefaultItemTheme,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title ?? "item.address".tr(),
                  style: themeData.titleStyle),
              Text(widget.address, style: themeData.contentStyle),
            ],
          ),
        ),
        sw(6),
        if (widget.suffix != null)
          widget.suffix!
        else
          InkWell(
            onTap: () async {
              final maps = await MapLauncher.installedMaps;
              if (mounted) {
                final r = await _showMapSelector(context, maps);
                if (r == null) return;
                await r.showMarker(
                  coords: Coords(
                      widget.location.latitude, widget.location.longitude),
                  title: widget.address,
                );
              }
            },
            child: Container(
              width: formatWidth(29),
              height: formatWidth(29),
              decoration: themeData.suffixDecoration,
              child: Center(
                child: SvgPicture.asset(
                  "assets/svg/ic_address.svg",
                  package: "ui_kosmos_v4",
                  color: themeData.suffixIconColor,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<AvailableMap?> _showMapSelector(
      BuildContext context, List<AvailableMap> maps) async {
    final rep = await showModalBottomSheet<AvailableMap>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: formatHeight(12) + MediaQuery.of(context).padding.bottom,
            top: formatHeight(12),
            left: formatWidth(29),
            right: formatWidth(29),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: maps
                .map(
                  (e) => Padding(
                    padding: EdgeInsets.only(bottom: formatHeight(4)),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(e),
                      child: Row(
                        children: [
                          Container(
                            width: formatWidth(38),
                            height: formatWidth(38),
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7)),
                            child: _generateMapIcon(e),
                          ),
                          sw(12),
                          Expanded(
                              child: Text(e.mapName,
                                  style: DefaultAppStyle.darkBlue(19))),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    return rep;
  }

  _generateMapIcon(AvailableMap e) {
    printInDebug(e.icon);
    if (e.mapName == "Apple Maps") {
      return Image.asset("assets/images/map_apple.png",
          package: "ui_kosmos_v4", fit: BoxFit.cover);
    } else if (e.mapName == "Waze") {
      return Image.asset("assets/images/map_waze.png",
          package: "ui_kosmos_v4", fit: BoxFit.cover);
    } else if (e.mapName == "Google Map" || e.mapName == "Google Maps") {
      return Image.asset("assets/images/map_google.png",
          package: "ui_kosmos_v4", fit: BoxFit.cover);
    }
  }
}
