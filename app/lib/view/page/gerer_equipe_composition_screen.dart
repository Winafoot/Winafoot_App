import 'dart:async';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/custom_composition.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/providers/composition_providers.dart';
import 'package:wina/view/page/creer_composition_screen.dart';
import 'package:wina/view/page/gerer_equipe_placement_screen.dart';
import 'package:wina/view/widget/empty_state_placeholder.dart';
import 'package:wina/view/widget/formation_pitch.dart';
import 'package:wina/view/widget/gerer_equipe_scaffold.dart';
import 'package:wina/view/widget/match_wizard.dart';

/// Sous-flux « Gérer mon équipe » — choix du schéma tactique.
///
/// Gauche : aperçu « Composition choisie ». Droite : compositions personnalisées
/// (à venir) + compositions standards (selon le nombre de joueurs). « Suivant »
/// désactivé tant qu'aucun schéma n'est choisi.
class GererEquipeCompositionScreen extends ConsumerWidget {
  const GererEquipeCompositionScreen({super.key, this.allowedPlayerIds});

  /// Transmis au placement : restreint les joueurs réattribuables (« Modifier
  /// composition » en cours de match). `null` = tout l'effectif.
  final Set<String>? allowedPlayerIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CompositionDraft draft = ref.watch(compositionDraftProvider);
    final CompositionDraftNotifier notifier = ref.read(
      compositionDraftProvider.notifier,
    );
    final int count = draft.playerCount ?? 11;
    final List<Formation> standards = standardFormations(count);
    final List<CustomComposition> customs = (ref
                .watch(customCompositionsProvider)
                .valueOrNull ??
            const <CustomComposition>[])
        .where((CustomComposition c) => c.playerCount == count)
        .toList(growable: false);

    return GererEquipeScaffold(
      title: 'app.gerer-equipe-composition.titre'.tr(),
      action: WizardCtaButton(
        label: 'app.gerer-equipe-composition.suivant'.tr(),
        enabled: draft.hasFormation,
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder:
                    (_) => GererEquipePlacementScreen(
                      allowedPlayerIds: allowedPlayerIds,
                    ),
              ),
            ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          formatWidth(40),
          formatHeight(8),
          formatWidth(40),
          0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: formatWidth(370),
              child: _ChosenPreview(formation: draft.formation),
            ),
            sw(24),
            Expanded(
              child: _CompositionsList(
                standards: standards,
                customs: customs,
                selected: draft.formation,
                onSelect: notifier.setFormation,
                onCreate:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CreerCompositionScreen(),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChosenPreview extends StatelessWidget {
  const _ChosenPreview({required this.formation});

  final Formation? formation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(formatWidth(12)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(r(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'app.gerer-equipe-composition.composition-choisie'.tr(),
                style: AppThemeStyle.semiBStyle(14, AppColor.primaryLabels),
              ),
              const Spacer(),
              if (formation != null) _LabelPill(formation!.label),
            ],
          ),
          sh(12),
          Flexible(
            child: FormationPitch(formation: formation, markerFraction: 0.15),
          ),
          if (formation == null) ...[
            sh(10),
            Text(
              'app.gerer-equipe-composition.aide-choix'.tr(),
              textAlign: TextAlign.center,
              style: AppThemeStyle.regularStyle(12, AppColor.secondaryLabels),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompositionsList extends StatefulWidget {
  const _CompositionsList({
    required this.standards,
    required this.customs,
    required this.selected,
    required this.onSelect,
    required this.onCreate,
  });

  final List<Formation> standards;
  final List<CustomComposition> customs;
  final Formation? selected;
  final void Function(Formation formation, {String? name}) onSelect;
  final VoidCallback onCreate;

  @override
  State<_CompositionsList> createState() => _CompositionsListState();
}

class _CompositionsListState extends State<_CompositionsList> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Temporise le filtrage (~300 ms) pour ne pas refiltrer à chaque frappe.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value);
    });
  }

  /// Effacement immédiat : annule la temporisation en attente pour ne pas
  /// réappliquer l'ancienne recherche après coup.
  void _clearSearch() {
    _debounce?.cancel();
    setState(() {
      _controller.clear();
      _query = '';
    });
  }

  Widget _grid(List<Formation> list) {
    return Wrap(
      spacing: formatWidth(14),
      runSpacing: formatHeight(14),
      children: <Widget>[
        for (final Formation f in list)
          _CompoCard(
            formation: f,
            selected: widget.selected == f,
            dimmed: widget.selected != null && widget.selected != f,
            onTap: () => widget.onSelect(f),
          ),
      ],
    );
  }

  Widget _customGrid(List<CustomComposition> list) {
    return Wrap(
      spacing: formatWidth(14),
      runSpacing: formatHeight(14),
      children: <Widget>[
        for (final CustomComposition c in list)
          _CompoCard(
            formation: c.toFormation(),
            name: c.name,
            selected: widget.selected == c.toFormation(),
            dimmed:
                widget.selected != null && widget.selected != c.toFormation(),
            onTap: () => widget.onSelect(c.toFormation(), name: c.name),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String q = _query.trim().toLowerCase();
    final bool searching = q.isNotEmpty;
    final List<Formation> filtered =
        searching
            ? widget.standards
                .where((Formation f) => f.label.toLowerCase().contains(q))
                .toList(growable: false)
            : widget.standards;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: formatHeight(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Align(
            alignment: Alignment.centerRight,
            child: _SearchField(
              controller: _controller,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
          ),
          sh(14),
          if (searching) ...<Widget>[
            Text(
              'app.gerer-equipe-composition.resultats-recherche'.tr(),
              style: AppThemeStyle.semiBStyle(15, AppColor.primaryLabels),
            ),
            sh(10),
            if (filtered.isEmpty)
              EmptyStatePlaceholder(
                title: 'app.gerer-equipe-composition.aucun-resultat'.tr(),
                subtitle:
                    'app.gerer-equipe-composition.aucun-resultat-sous-titre'
                        .tr(),
                titleSize: 18,
                padding: EdgeInsets.symmetric(vertical: formatHeight(40)),
              )
            else
              _grid(filtered),
          ] else ...<Widget>[
            Row(
              children: <Widget>[
                Text(
                  'app.gerer-equipe-composition.mes-compositions'.tr(),
                  style: AppThemeStyle.semiBStyle(15, AppColor.primaryLabels),
                ),
                const Spacer(),
                _CreateCompoButton(onTap: widget.onCreate),
              ],
            ),
            sh(10),
            if (widget.customs.isEmpty)
              Text(
                'app.gerer-equipe-composition.aucune-composition-personnalisee'
                    .tr(),
                style: AppThemeStyle.regularStyle(13, AppColor.secondaryLabels),
              )
            else
              _customGrid(widget.customs),
            sh(18),
            Text(
              'app.gerer-equipe-composition.compositions-standards'.tr(),
              style: AppThemeStyle.semiBStyle(15, AppColor.primaryLabels),
            ),
            sh(10),
            _grid(widget.standards),
          ],
        ],
      ),
    );
  }
}

class _CompoCard extends StatelessWidget {
  const _CompoCard({
    required this.formation,
    required this.selected,
    required this.dimmed,
    required this.onTap,
    this.name,
  });

  final Formation formation;
  final bool selected;

  /// Atténue la carte (30%) lorsqu'une autre composition est sélectionnée.
  final bool dimmed;
  final VoidCallback onTap;

  /// Nom affiché pour une composition personnalisée (`null` pour un standard).
  final String? name;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: dimmed ? 0.3 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: formatWidth(190),
          padding: EdgeInsets.all(formatWidth(8)),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(r(14)),
            border: Border.all(
              color: selected ? AppColor.primaryColor : AppColor.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _LabelPill(formation.label),
                  if (name != null) ...<Widget>[
                    sw(6),
                    Expanded(
                      child: Text(
                        name!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppThemeStyle.mediumStyle(
                          12,
                          AppColor.primaryLabels,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (selected) ...<Widget>[
                    sw(4),
                    Icon(
                      Iconsax.tick_circle,
                      size: sp(18),
                      color: AppColor.primaryColor,
                    ),
                  ],
                ],
              ),
              sh(8),
              FormationPitch(formation: formation, markerFraction: 0.19),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelPill extends StatelessWidget {
  const _LabelPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: formatWidth(12),
        vertical: formatHeight(5),
      ),
      decoration: BoxDecoration(
        color: AppColor.chipBackground,
        borderRadius: BorderRadius.circular(r(12)),
      ),
      child: Text(
        label,
        style: AppThemeStyle.semiBStyle(12, AppColor.primaryLabels),
      ),
    );
  }
}

/// Bouton « + Créer une composition » (entête de la section personnalisées).
class _CreateCompoButton extends StatelessWidget {
  const _CreateCompoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.chipBackground,
      borderRadius: BorderRadius.circular(r(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r(12)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: formatWidth(14),
            vertical: formatHeight(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Iconsax.add_copy,
                size: sp(16),
                color: AppColor.primaryColor,
              ),
              sw(6),
              Text(
                'app.gerer-equipe-composition.creer-composition'.tr(),
                style: AppThemeStyle.semiBStyle(13, AppColor.primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Insère un tiret entre chaque chiffre, façon libellé de schéma :
/// « 433 » → « 4-3-3 », « 4411 » → « 4-4-1-1 ». Idempotent.
String dashifyFormationQuery(String input) {
  final String digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.split('').join('-');
}

/// Formate une saisie de schéma en libellé au fil de la frappe : l'utilisateur
/// tape « 433 », le champ affiche « 4-3-3 ». Indispensable partout où un pavé
/// numérique est imposé — il ne permet pas de taper le tiret.
class FormationSearchFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = dashifyFormationQuery(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Champ de recherche des compositions (filtre par libellé, ex. « 4-4 »).
///
/// Pas d'autofocus : la barre est affichée en permanence dans l'étape du
/// tunnel, un focus automatique ferait remonter le clavier à chaque arrivée
/// sur l'écran alors que le coach vient d'abord choisir une carte.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: formatWidth(260),
      padding: EdgeInsets.symmetric(horizontal: formatWidth(14)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(r(12)),
        border: Border.all(color: AppColor.divider),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Iconsax.search_normal_1_copy,
            size: sp(16),
            color: AppColor.secondaryLabels,
          ),
          sw(8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              // Valider la recherche referme le clavier.
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              inputFormatters: <TextInputFormatter>[FormationSearchFormatter()],
              style: AppThemeStyle.regularStyle(13, AppColor.primaryLabels),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'app.recherche.compositions-hint'.tr(),
                hintStyle: AppThemeStyle.regularStyle(
                  13,
                  AppColor.secondaryLabels,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            InkResponse(
              onTap: onClear,
              radius: sp(18),
              child: Icon(
                Iconsax.close_circle,
                size: sp(16),
                color: AppColor.secondaryLabels,
              ),
            ),
        ],
      ),
    );
  }
}

// L'état vide « Aucun résultat » utilise [EmptyStatePlaceholder].
