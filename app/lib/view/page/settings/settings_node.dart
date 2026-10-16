import 'package:wina/config/theme.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class SettingsNode {
  final Widget? icon;

  /// Optional builder to render a leading icon/avatar that reacts to selection state.
  /// If provided, it takes precedence over [icon].
  final Widget Function(bool isSelected)? leadingBuilder;

  /// Optional builder to render a trailing widget (e.g., switch) reacting to selection state.
  final Widget Function(bool isSelected)? trailingBuilder;

  /// Titre unique obligatoire (clé logique du node)
  final String title;

  /// Sous-texte affiché dans la liste (colonne gauche / panes liste)
  final String? subtitle;

  /// Callback si node terminal (sans children/contentBuilder)
  final void Function()? onTap;

  /// Sous-items (ouvrent un pane de type liste)
  final List<SettingsNode> children;

  /// Contenu custom (ouvre un pane custom, pas une liste)
  final WidgetBuilder? contentBuilder;

  /// Titre affiché en tête du pane de droite (si null → on utilise [title])
  final String? paneTitle;

  SettingsNode({
    this.icon,
    this.leadingBuilder,
    this.trailingBuilder,
    required this.title,
    this.subtitle,
    this.onTap,
    this.children = const [],
    this.contentBuilder,
    this.paneTitle,
  }) : assert(
         !(children.isNotEmpty && contentBuilder != null),
         'Un node ne peut pas avoir à la fois des children et un contentBuilder.',
       );

  bool get hasChildren => children.isNotEmpty;
  bool get hasCustomContent => contentBuilder != null;
}

class SettingsItem {
  final String title; // Titre de section (colonne gauche)
  final List<SettingsNode> children;

  SettingsItem({required this.title, required this.children});
}

class SettingsView extends StatefulWidget {
  final List<SettingsItem> items;
  final WidgetBuilder? leftHeaderBuilder;
  const SettingsView({super.key, required this.items, this.leftHeaderBuilder});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  _LeftSelection? _leftSelected;
  final Map<int, int> _paneSelectedIndex = {};
  final List<_Pane> _panes = [];

  @override
  void initState() {
    super.initState();
    _validateUniqueNodeTitles();
  }

  void _validateUniqueNodeTitles() {
    final seen = <String>{};
    void visitNode(SettingsNode n) {
      assert(
        seen.add(n.title),
        'Titre de node en double détecté: "${n.title}". '
        'Chaque node doit avoir un titre unique.',
      );
      for (final c in n.children) {
        visitNode(c);
      }
    }

    for (final item in widget.items) {
      for (final n in item.children) {
        visitNode(n);
      }
    }
  }

  void _openFromLeft({
    required int itemGroupIndex,
    required int childIndex,
    required SettingsNode node,
  }) {
    setState(() {
      _leftSelected = _LeftSelection(group: itemGroupIndex, index: childIndex);
      _panes.clear();
      _paneSelectedIndex.clear();

      if (node.hasChildren) {
        _panes.add(
          _Pane.list(title: node.paneTitle ?? node.title, nodes: node.children),
        );
      } else if (node.hasCustomContent) {
        _panes.add(
          _Pane.custom(
            title: node.paneTitle ?? node.title,
            builder: node.contentBuilder!,
          ),
        );
      } else {
        node.onTap?.call();
      }
    });
  }

  void _openFromPane({
    required int paneLevel,
    required int nodeIndex,
    required SettingsNode node,
  }) {
    setState(() {
      _paneSelectedIndex[paneLevel] = nodeIndex;

      if (_panes.length > paneLevel + 1) {
        _panes.removeRange(paneLevel + 1, _panes.length);
        _paneSelectedIndex.removeWhere((lvl, _) => lvl > paneLevel);
      }

      if (node.hasChildren) {
        _panes.add(
          _Pane.list(title: node.paneTitle ?? node.title, nodes: node.children),
        );
      } else if (node.hasCustomContent) {
        _panes.add(
          _Pane.custom(
            title: node.paneTitle ?? node.title,
            builder: node.contentBuilder!,
          ),
        );
      } else {
        node.onTap?.call();
      }
    });
  }

  bool _isLeftSelected(int g, int i) =>
      _leftSelected?.group == g && _leftSelected?.index == i;

  bool _isPaneSelected(int level, int i) => _paneSelectedIndex[level] == i;

  Widget? _leadingFor(SettingsNode node, bool isSelected) {
    if (node.leadingBuilder != null) {
      return node.leadingBuilder!(isSelected);
    }
    if (node.icon != null) {
      // Fallback: wrap provided icon widget into a circle with consistent sizing
      return CircleAvatar(
        radius: r(17),
        backgroundColor: Colors.transparent,
        child: node.icon!,
      );
    }
    return null;
  }

  List<Widget> _leadingWidgets(SettingsNode node, bool isSelected) {
    final w = _leadingFor(node, isSelected);
    // Sans icône de gauche, le texte se collerait au filet de la pilule : on
    // rend l'inset que l'avatar assure ailleurs, au même espacement.
    if (w == null) return [SizedBox(width: formatWidth(12))];
    return [w, SizedBox(width: formatWidth(12))];
  }

  Widget? _trailingFor(SettingsNode node, bool isSelected) {
    if (node.trailingBuilder != null) {
      return node.trailingBuilder!(isSelected);
    }
    // Chevron sur les cellules navigables uniquement : une cellule purement
    // informative (ni children, ni contenu, ni onTap) n'en porte pas (Figma).
    if (node.hasChildren || node.hasCustomContent || node.onTap != null) {
      return Icon(
        Iconsax.arrow_right_3_copy,
        size: sp(16),
        color: AppColor.chevron,
      );
    }
    return null;
  }

  List<Widget> _trailingWidgets(SettingsNode node, bool isSelected) {
    final w = _trailingFor(node, isSelected);
    if (w == null) return [];
    return [SizedBox(width: formatWidth(12)), w];
  }

  /// Cellule de réglages (Figma) : pilule de 60 px, fond transparent sur la
  /// carte blanche, filet 0.5 px au repos et bordure verte de 2 px une fois
  /// sélectionnée — le texte reste sombre dans les deux états.
  Widget _cell({
    required SettingsNode node,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(r(30)),
      child: Container(
        width: double.infinity,
        height: formatHeight(60),
        padding: EdgeInsets.symmetric(horizontal: formatWidth(12)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r(30)),
          border: Border.all(
            color: isSelected ? AppColor.primaryColor : AppColor.cellBorder,
            width: isSelected ? 2 : .5,
          ),
        ),
        child: Row(
          children: [
            ..._leadingWidgets(node, isSelected),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeStyle.mediumStyle(
                      13,
                      AppColor.primaryLabels,
                    ),
                  ),
                  if (node.subtitle != null)
                    Text(
                      node.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemeStyle.regularStyle(
                        11,
                        AppColor.primaryLabels.withValues(alpha: .65),
                      ),
                    ),
                ],
              ),
            ),
            ..._trailingWidgets(node, isSelected),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === Colonne gauche ===
        SizedBox(
          width: formatWidth(366),
          child: SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.only(bottom: formatHeight(16)),
              padding: EdgeInsets.all(formatWidth(21.5)),
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(r(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.leftHeaderBuilder != null) ...[
                    widget.leftHeaderBuilder!(context),
                    Divider(
                      thickness: .4,
                      color: DefaultColor.darkBlue.withValues(alpha: .17),
                    ),
                    sh(12),
                  ],
                  for (int i = 0; i < widget.items.length; i++) ...[
                    Text(
                      widget.items[i].title,
                      style: AppThemeStyle.mediumStyle(
                        14,
                        AppColor.primaryLabels,
                      ),
                    ),
                    SizedBox(height: formatHeight(12)),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final child = widget.items[i].children[index];
                        final bool isSelected = _isLeftSelected(i, index);

                        return _cell(
                          node: child,
                          isSelected: isSelected,
                          onTap:
                              () => _openFromLeft(
                                itemGroupIndex: i,
                                childIndex: index,
                                node: child,
                              ),
                        );
                      },
                      separatorBuilder:
                          (context, index) =>
                              SizedBox(height: formatHeight(6.5)),
                      itemCount: widget.items[i].children.length,
                    ),
                    if (i != widget.items.length - 1)
                      SizedBox(height: formatHeight(16)),
                  ],
                ],
              ),
            ),
          ),
        ),

        if (_panes.isNotEmpty) SizedBox(width: formatWidth(11)),

        if (_panes.isNotEmpty)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(_panes.length, (paneLevel) {
                  final pane = _panes[paneLevel];
                  final bool isForm = pane.type == _PaneType.custom;

                  // Chaque pane défile verticalement, comme la colonne de
                  // gauche : le viewport horizontal borne leur hauteur, et
                  // celle-ci se réduit à l'ouverture du clavier.
                  return SingleChildScrollView(
                    child: Container(
                      width: isForm ? formatWidth(377) : formatWidth(345),
                      margin: EdgeInsets.only(
                        right: formatWidth(11),
                        bottom: formatHeight(16),
                      ),
                      padding: EdgeInsets.all(formatWidth(isForm ? 28 : 22)),
                      decoration: BoxDecoration(
                        color: AppColor.surface,
                        borderRadius: BorderRadius.circular(r(12)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pane.title,
                            style: AppThemeStyle.semiBStyle(
                              16,
                              AppColor.primaryLabels,
                            ),
                          ),
                          SizedBox(height: formatHeight(12)),
                          if (pane.type == _PaneType.list)
                            ListView.separated(
                              shrinkWrap: true,
                              primary: false,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final node = pane.nodes![index];
                                final bool isSelected = _isPaneSelected(
                                  paneLevel,
                                  index,
                                );

                                return _cell(
                                  node: node,
                                  isSelected: isSelected,
                                  onTap:
                                      () => _openFromPane(
                                        paneLevel: paneLevel,
                                        nodeIndex: index,
                                        node: node,
                                      ),
                                );
                              },
                              separatorBuilder:
                                  (context, index) =>
                                      SizedBox(height: formatHeight(6.5)),
                              itemCount: pane.nodes!.length,
                            ),
                          if (pane.type == _PaneType.custom)
                            Builder(
                              builder: (context) => pane.builder!(context),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }
}

enum _PaneType { list, custom }

class _Pane {
  final String title;
  final _PaneType type;
  final List<SettingsNode>? nodes;
  final WidgetBuilder? builder;

  _Pane._(this.title, this.type, {this.nodes, this.builder});

  factory _Pane.list({
    required String title,
    required List<SettingsNode> nodes,
  }) => _Pane._(title, _PaneType.list, nodes: nodes);

  factory _Pane.custom({
    required String title,
    required WidgetBuilder builder,
  }) => _Pane._(title, _PaneType.custom, builder: builder);
}

class _LeftSelection {
  final int group;
  final int index;
  const _LeftSelection({required this.group, required this.index});
}
