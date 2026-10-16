import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';

import 'theme/form_field_theme.dart';

/// {@category Widget}
/// {@subCategory Form, Input}
///
/// Item de formulaire avec un titre / action et suffix.
/// Widget permettant d'ajouter un un [fieldName] et/ou une [fieldAction] à un champ de formulaire.
/// Vous pouvez aussi ajouter un [fieldSuffix] à votre champ, sous la forme d'un widget.
///
/// Exemple:
///
/// ![form_field_item](../../images/field/field_item.png)
///
/// ```dart
/// FormFieldItem(
///   fieldName: "Nom du champ, sur plusieurs mots",
///   fieldAction: "Clique ici!",
///   fieldActionOnTap: () => printDebug("Pass"),
///   fieldSuffix: const Text("Suffix child"), // permet d'ajouter un suffix widget au champ.
///   child: Container(
///     width: double.infinity,
///     height: 20,
///     color: Colors.pinkAccent.shade200,
///   ),
/// ),
/// ```
///
/// Vous pouvez créer votre propre theme, ou définir celui par défaut via le [FormFieldThemeData] : "form_field".
///
class FormFieldItem extends ConsumerStatefulWidget {
  final Widget child;

  final String? fieldName;
  final String? fieldAction;
  final Widget? fieldSuffix;
  final VoidCallback? fieldActionOnTap;
  final bool isError;
  final bool showErrorTitle;

  /// Theme
  final String? themeName;
  final FormFieldThemeData? theme;

  const FormFieldItem({
    Key? key,
    required this.child,
    this.fieldName,
    this.fieldAction,
    this.fieldActionOnTap,
    this.fieldSuffix,
    this.theme,
    this.themeName,
    this.isError = false,
    this.showErrorTitle = true,
  })  : assert(fieldAction != null ? fieldActionOnTap != null : true,
            "You must provide a onTap callback for the fieldAction"),
        super(key: key);

  @override
  ConsumerState<FormFieldItem> createState() => _FormFieldItemState();
}

class _FormFieldItemState extends ConsumerState<FormFieldItem> {
  bool _actionIsHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeData = loadThemeData(
      widget.theme,
      widget.themeName ?? "form_field",
      () => const FormFieldThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.fieldName != null || widget.fieldAction != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (widget.fieldName != null) ...[
                Expanded(
                  child: Text(
                    widget.fieldName!,
                    style: widget.isError
                        ? themeData.fieldNameErrorStyle ??
                            DefaultAppStyle.error(12)
                        : themeData.fieldNameStyle ??
                            DefaultAppStyle.darkBlue(12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (widget.fieldAction != null) sw(4),
              ],
              if (widget.fieldAction != null)
                InkWell(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  onTap: widget.fieldActionOnTap,
                  onHover: (val) => val != _actionIsHovered
                      ? setState(() => _actionIsHovered = val)
                      : null,
                  child: Text(
                    widget.fieldAction!,
                    style: _actionIsHovered
                        ? themeData.fieldActionHoverStyle ??
                            themeData.fieldActionStyle ??
                            DefaultAppStyle.darkBlue(12)
                                .copyWith(decoration: TextDecoration.underline)
                        : themeData.fieldActionStyle ??
                            DefaultAppStyle.darkBlue(12),
                  ),
                ),
            ],
          ),
          sh(6),
        ],
        widget.child,
        if (widget.fieldSuffix != null) ...[
          sh(6),
          widget.fieldSuffix!,
        ],
      ],
    );
  }
}
