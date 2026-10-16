// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';

/// {@category Research}
enum ResearchType {
  typeahead,
  classic,
}

/// {@category Widget}
/// {@category Research}
///
/// Permet d'afficher une page de recherche avec la SearchBar
/// en autofocus.
/// Vous avez la possibilité d'afficher votre propre SearchBar
/// via le paramètre [searchBarBuilder]. Sinon, vous avez
/// deux types à disposition:
///
/// - [ResearchType.classic] : SearchBar classique avec texte
/// simple
/// - [ResearchType.typeahead] : SearchBar avec suggestions
/// (vous devrez obligatoirement fournir les paramètres
/// [typeaheadSuggestionsCallback] et [typeaheaditemBuilder]).
///
/// Si vous utilisez l'un des deux types de SearchBar, vous
/// pouvez fournir un callback via le paramètre
/// [onSearchCallback] qui sera appelé à chaque fois que
/// l'utilisateur tape dans la SearchBar.
/// De plus, un icône de suppression sera affiché à droite
/// de la SearchBar si le texte n'est pas vide.
///
/// Vous pouvez utiliser un système de filtre en supplément,
/// uniquement si le paramètre [showFilterButton] est à true.
/// Vous pourrez alors utiliser votre propre PopUp de filtre
/// via le paramètre [onTapFilterButton].
/// Celui-ci retourne une liste de [FilterModel] qui sera
/// affichée dans la SearchBar (en dessous).
///
/// Si votre recherche possède déjà des filtres ou des items
/// a affichés, vous pouvez les fournir via les paramètres
/// [initialFilter] et [initialItems].
///
/// **/!| Attention**, vous devez fournir **obligatoirement**
/// fournir le paramètre [itemBuilder] qui permet de construire
/// chaque item de la liste.
///
/// **/!| Attention**, ce [Widget] n'est pas une page, vous
/// devrez obligatoirement la mettre dans un parent pour
/// qu'elle s'affiche correctement.
///
/// Si vous souhaitez intéragir avec la SearchBar, vous
/// pouvez utiliser les fonctions fournis via un [GlobalKey].
///
/// - [ResearchWidgetState.updateFilters] : Permet de mettre
/// à jour les filtres affichés dans la SearchBar.
/// - [ResearchWidgetState.updateItems] : Permet de mettre
/// à jour les items affichés dans la liste.
/// - [ResearchWidgetState.updateSearch] : Permet de mettre
/// à jour le texte de la SearchBar.
/// - [ResearchWidgetState.textEditingController] : Permet
/// d'accéder au [TextEditingController] de la SearchBar.
///
/// Exemple d'utilisation:
///
/// ```Dart
/// class ResearchExamplePage extends StatefulHookConsumerWidget {
///   const ResearchExamplePage({super.key});
///
///   @override
///   ConsumerState<ConsumerStatefulWidget> createState() => _ResearchExamplePageState();
/// }
///
/// class _ResearchExamplePageState extends ConsumerState<ResearchExamplePage> {
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       crossAxisAlignment: CrossAxisAlignment.start,
///       children: [
///         SizedBox(height: MediaQuery.of(context).padding.top + formatHeight(12)),
///         TitleHeader(title: "Research Example Page", onTapBack: () => AutoRouter.of(context).pop()),
///         SizedBox(height: formatHeight(15)),
///         Expanded(
///           child: ResearchWidget<String, String>(
///             onSearchCallback: (val) async {
///               if (val == null) {
///                 return ["AAAA", "BBB", "CCC", "AAABBB", "CCCDDD"];
///               }
///               return ["AAAA", "BBB", "CCC", "AAABBB", "CCCDDD"].where((element) => element.contains(val)).toList();
///             },
///             initialFilter: const [
///               FilterModel(tag: "hmmm", value: "hmmm"),
///               FilterModel(tag: "BBBB", value: "AAAA"),
///             ],
///             itemBuilder: (_, __, ___) => Padding(
///               padding: pwh(10, 10),
///               child: Container(
///                 width: double.infinity,
///                 height: formatHeight(100),
///                 color: Colors.red,
///                 child: Center(child: Text(___)),
///               ),
///             ),
///           ),
///         ),
///       ],
///     );
///   }
/// }
/// ```
///
/// Vous pouvez également utiliser le thème [KosmosRechercheThemeData]
/// pour personnaliser le thème de la SearchBar.
/// Par défaut, le thème est [kDefaultKosmosRechercheTheme]. Vous
/// pouvez éagelement utiliser un thème personnalisé en fournissant
/// le paramètre [theme] ou [themeName]. (par défaut "kosmos_research")
class ResearchWidget<T, U> extends StatefulHookConsumerWidget {
  /// Search
  final Widget? suffixFilterWidget;
  final bool showFilterButton;
  final ResearchType researchType;
  final Widget Function(BuildContext context, TextEditingController? controller,
      List<T> items)? searchBarBuilder;
  final List<T>? initialItems;
  final String? searchBarHint;
  final Widget? prefixIcon;
  final FutureOr<List<T>?> Function(String?)? onSearchCallback;
  final bool showFilter;
  final bool? autofocus;
  final List<FilterModel>? initialFilter;
  final Widget Function(FilterModel)? filterBuilder;
  final void Function(List<FilterModel>)? onFilterChanged;
  final FutureOr<List<FilterModel>> Function(BuildContext)? onTapFilterButton;
  final Widget Function(BuildContext, WidgetRef ref, List<T> items)?
      childBuilder;

  /// Typeahead
  final FutureOr<List<U>?> Function(String)? typeaheadSuggestionsCallback;
  final ListTile Function(BuildContext, U)? typeaheaditemBuilder;

  /// Item Builder
  final Widget Function(BuildContext context, WidgetRef ref, T item)
      itemBuilder;
  final Widget Function(BuildContext context, WidgetRef ref)? noItemBuilder;
  final String? heroTag;

  /// Theme
  final String? themeName;
  final KosmosRechercheThemeData? theme;

  const ResearchWidget({
    /// Search
    this.suffixFilterWidget,
    this.heroTag,
    this.showFilterButton = true,
    this.researchType = ResearchType.classic,
    this.searchBarBuilder,
    this.initialItems,
    this.searchBarHint,
    this.autofocus,
    this.prefixIcon,
    this.onSearchCallback,
    this.typeaheadSuggestionsCallback,
    this.typeaheaditemBuilder,
    this.showFilter = true,
    this.initialFilter,
    this.filterBuilder,
    this.onFilterChanged,
    this.childBuilder,
    this.onTapFilterButton,

    /// Item Builder
    required this.itemBuilder,
    this.noItemBuilder,

    /// Theme
    this.themeName,
    this.theme,
    super.key,
  }) : assert(
          researchType == ResearchType.typeahead
              ? typeaheadSuggestionsCallback != null &&
                  typeaheaditemBuilder != null
              : true,
          "If research type is [ResearchType.typeahead], you must provide [typeaheadSuggestionsCallback] and [typeaheaditemBuilder]",
        );

  @override
  ConsumerState<ResearchWidget<T, U>> createState() =>
      ResearchWidgetState<T, U>();
}

class ResearchWidgetState<T, U> extends ConsumerState<ResearchWidget<T, U>> {
  late final TextEditingController textController = TextEditingController();
  List<T> items = [];
  List<FilterModel> filters = [];

  @override
  void initState() {
    if (widget.initialItems != null) {
      items = List.from(widget.initialItems!);
    }

    if (widget.initialFilter != null) {
      filters = List.from(widget.initialFilter!);
    }
    super.initState();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  void onFilterClick() async {
    if (widget.onTapFilterButton != null) {
      filters = await widget.onTapFilterButton!(context);
    }
    setState(() {});
  }

  void onSearchChange(String val) async {
    if (widget.onSearchCallback != null) {
      items = await widget.onSearchCallback!(val) ?? [];
      setState(() {});
    }
  }

  void clear() {
    textController.clear();
    items = widget.initialItems ?? [];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final KosmosRechercheThemeData themeData = loadThemeData(
      widget.theme,
      widget.themeName ?? "kosmos_research",
      () => kDefaultKosmosRechercheTheme,
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    printDebug(items.isEmpty);

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Search Row
        Padding(
          padding: EdgeInsets.only(
            left: themeData.horizontalPadding ?? formatWidth(27.5),
            right: (themeData.horizontalPadding ?? formatWidth(27.5)) -
                formatWidth(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(child: _buildSearchBar(context, themeData)),
              if (widget.showFilterButton) ...[
                widget.suffixFilterWidget ??
                    InkWell(
                      onTap: onFilterClick,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: formatWidth(9)),
                        child: SvgPicture.asset("assets/svg/ic_filter.svg",
                            package: "ui_kosmos_v4",
                            color: themeData.suffixIconColor),
                      ),
                    ),
              ]
            ],
          ),
        ),

        if (widget.showFilter && (filters.isNotEmpty)) ...[
          sh(12),
          SizedBox(
            width: double.infinity,
            height: themeData.filterHeight,
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                  horizontal: themeData.horizontalPadding ?? formatWidth(27.5)),
              physics: const BouncingScrollPhysics(),
              children: [
                ...filters.map((e) => Padding(
                      padding: EdgeInsets.only(right: formatWidth(7)),
                      child: widget.filterBuilder?.call(e) ?? _buildFilter(e),
                    )),
              ],
            ),
          ),
          sh(8),
        ],

        /// Items
        Expanded(
          child: items.isEmpty
              ? widget.noItemBuilder?.call(context, ref) ??
                  _buildNoItem(context, themeData)
              : widget.childBuilder?.call(context, ref, items) ??
                  ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                        top: formatHeight(6),
                        bottom: MediaQuery.of(context).padding.bottom +
                            formatHeight(12)),
                    children: [
                      sh(10),
                      ...items
                          .map((e) => Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      themeData.itemsHorizontalPadding ??
                                          themeData.horizontalPadding ??
                                          formatWidth(27.5),
                                ),
                                child: widget.itemBuilder(context, ref, e),
                              ))
                          .toList(),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildNoItem(
    BuildContext context,
    KosmosRechercheThemeData themeData,
  ) {
    return Center(
      child: Padding(
        padding: pw(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: formatWidth(42),
              height: formatWidth(42),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r(42)),
                color: themeData.noItemBackgroundIconColor ??
                    DefaultColor.darkBlue,
              ),
              child: Center(
                child: SvgPicture.asset(
                  "assets/svg/ic_search.svg",
                  package: "ui_kosmos_v4",
                  color: themeData.noItemIconColor ?? DefaultColor.white,
                ),
              ),
            ),
            sh(12),
            Text("package.research.no-item-title".tr(),
                style: themeData.noItemTilteTexStyle,
                textAlign: TextAlign.center),
            sh(4),
            Text("package.research.no-item-content".tr(),
                style: themeData.noItemContentTexStyle,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(
      BuildContext context, KosmosRechercheThemeData themeData) {
    if (widget.searchBarBuilder != null) {
      return widget.searchBarBuilder!.call(context, textController, items);
    }

    final FormFieldThemeData fieldThemeData = loadThemeData(
      null,
      "form_field",
      () => const FormFieldThemeData(),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    InputDecoration decoration = (themeData.searchBarDecoration ??
            fieldThemeData.inputDecoration ??
            kDefaultInputDecoration)
        .copyWith(
      hintText: widget.searchBarHint ?? "package.research.hint".tr(),
    );

    decoration = decoration.copyWith(
      prefixIcon: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.prefixIcon ??
              SvgPicture.asset("assets/svg/ic_search.svg",
                  package: "ui_kosmos_v4", color: decoration.prefixIconColor),
        ],
      ),
      suffix: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          InkWell(
            onTap: clear,
            child: SvgPicture.asset("assets/svg/ic_close.svg",
                package: "ui_kosmos_v4", color: decoration.suffixIconColor),
          ),
        ],
      ),
    );

    /// If search is [ResearchType.classic].
    if (widget.researchType == ResearchType.classic) {
      return Hero(
        tag: widget.heroTag ?? "research_button",
        child: FormClassicField(
            maxLines: 1,
            controller: textController,
            themeName: themeData.searchBarThemeName,
            inputDecoration: decoration,
            autoFocus: widget.autofocus ?? true,
            isRequired: false,
            onChanged: onSearchChange),
      );
    }

    /// If search is [ResearchType.typeahead].
    if (widget.researchType == ResearchType.typeahead) {
      return Hero(
        tag: widget.heroTag ?? "research_button",
        child: FormTypeAheadField<U>(
          controller: textController,
          maxLines: 1,
          themeName: themeData.searchBarThemeName,
          inputDecoration: decoration,
          autofocus: widget.autofocus ?? true,
          isRequired: false,
          suggestionsCallback: widget.typeaheadSuggestionsCallback!,
          itemBuilder: widget.typeaheaditemBuilder!,
          onChanged: onSearchChange,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFilter(FilterModel e) {
    return Container(
      padding: EdgeInsets.only(
          top: formatHeight(9),
          bottom: formatHeight(9),
          left: formatWidth(12),
          right: formatWidth(3)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r(8)),
        border: Border.all(color: DefaultColor.lightGrey, width: .5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                    text: e.tag,
                    style: DefaultAppStyle.darkSteel(10, FontWeight.w500)),
                TextSpan(
                    text: " : ",
                    style: DefaultAppStyle.darkSteel(10, FontWeight.w500)),
                TextSpan(
                    text: e.value,
                    style: DefaultAppStyle.darkSteel(10, FontWeight.w500)),
              ],
            ),
          ),
          sw(5),
          InkWell(
            onTap: () {
              filters.remove(e);
              widget.onFilterChanged?.call(filters);
              setState(() {});
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: formatWidth(5)),
              child: Icon(Icons.close_rounded,
                  size: formatWidth(10), color: DefaultColor.darkGrey),
            ),
          ),
        ],
      ),
    );
  }

  /// Utils Function ///
  void updateFilters(List<FilterModel> filter) =>
      setState(() => filters = filter);

  void updateItems(List<T> items) => setState(() => this.items = items);

  void updateSearch(String search) =>
      setState(() => textController.text = search);

  TextEditingController get textEditingController => textController;
}
