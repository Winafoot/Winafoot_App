import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/config/phone_scale.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/composition_repository.dart';
import 'package:wina/data/search/union_search.dart';
import 'package:wina/models/custom_composition.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/composition_providers.dart';
import 'package:wina/providers/search_providers.dart';
import 'package:wina/view/page/creer_composition_screen.dart';
import 'package:wina/view/page/gerer_equipe_composition_screen.dart';
import 'package:wina/view/page/tester_equipe_screen.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/confirm_dialog.dart';
import 'package:wina/view/widget/empty_state_placeholder.dart';
import 'package:wina/view/widget/formation_pitch.dart';
import 'package:wina/view/widget/label_pill.dart';
import 'package:wina/view/widget/match_wizard.dart';
import 'package:wina/view/widget/notification_bell.dart';
import 'package:wina/view/widget/settings_button.dart';

/// Onglet « Test équipe » — « Testez et créez des compositions ».
///
/// Liste filtrable (par recherche, et par nombre de joueurs tant que le club n'a
/// pas de format imposé) des compositions personnalisées du coach (favori /
/// modifier / dupliquer / supprimer) et des compositions standards (dupliquer
/// en perso), plus la création.
///
/// Un club dont le format est fixé (`teamFormat`, cf. [teamFormatProvider]) n'a
/// pas de filtre « Type d'équipe » : ce format s'applique partout.
class TestEquipeScreen extends ConsumerStatefulWidget {
  const TestEquipeScreen({super.key});

  @override
  ConsumerState<TestEquipeScreen> createState() => _TestEquipeScreenState();
}

class _TestEquipeScreenState extends ConsumerState<TestEquipeScreen> {
  /// Choix du filtre « Type d'équipe », pour les comptes sans format de club.
  int _count = 11;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// Identifiants des compositions trouvées par Algolia pour [_query] : ils
  /// s'ajoutent au filtre local, jamais ne le remplacent.
  Set<String> _remoteIds = const <String>{};

  /// Réponse d'Algolia attendue : l'état vide n'est pas affiché avant elle.
  bool _pending = false;
  late final UnionSearch _union = UnionSearch(
    search: (String q) => ref.read(searchServiceProvider).searchCompositions(q),
    onChange: (String query, Set<String> remoteIds) {
      if (!mounted) return;
      setState(() {
        _query = query;
        _remoteIds = remoteIds;
      });
    },
    onPending: (bool pending) {
      if (mounted) setState(() => _pending = pending);
    },
  );

  @override
  void dispose() {
    _union.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Effacement immédiat : annule la temporisation en attente pour ne pas
  /// réappliquer l'ancienne recherche après coup.
  void _clearSearch() {
    // Seule sortie de clavier de l'écran : le pavé numérique iOS n'a pas de
    // touche retour, `onSubmitted` y est inerte.
    FocusScope.of(context).unfocus();
    _searchController.clear();
    _union.clear();
  }

  bool _matches(String name, String label) =>
      matchesCompositionQuery(_query, name, label);

  void _err(String message) => showAppNotif(
    context,
    title: 'app.test-equipe.erreur-titre'.tr(),
    subTitle: message,
    success: false,
  );

  void _create(int count) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CreerCompositionScreen(playerCount: count),
    ),
  );

  void _edit(CustomComposition c) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CreerCompositionScreen(existing: c),
    ),
  );

  void _test(CustomComposition c) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => TesterEquipeScreen(composition: c)),
  );

  /// Teste un schéma standard en l'enveloppant dans une composition éphémère
  /// (non persistée) le temps de l'essai.
  void _testStandard(Formation f) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder:
          (_) => TesterEquipeScreen(
            composition: CustomComposition(
              name: f.label,
              playerCount: f.playerCount,
              formationLabel: f.label,
              slots: f.slots,
            ),
          ),
    ),
  );

  Future<void> _duplicate(CustomComposition c) async {
    try {
      await CompositionRepository.addComposition(
        CustomComposition(
          name: 'app.test-equipe.nom-copie'.tr(args: <String>[c.name]),
          playerCount: c.playerCount,
          formationLabel: c.formationLabel,
          slots: c.slots,
        ),
      );
    } catch (_) {
      if (mounted) _err('app.test-equipe.erreur-duplication'.tr());
    }
  }

  Future<void> _duplicateStandard(Formation f) async {
    try {
      await CompositionRepository.addComposition(
        CustomComposition(
          name: f.label,
          playerCount: f.playerCount,
          formationLabel: f.label,
          slots: f.slots,
        ),
      );
    } catch (_) {
      if (mounted) _err('app.test-equipe.erreur-creation'.tr());
    }
  }

  Future<void> _toggleFavorite(CustomComposition c) async {
    final String? id = c.id;
    if (id == null) return;
    try {
      await CompositionRepository.setFavorite(id, !c.isFavorite);
    } catch (_) {
      if (mounted) _err('app.test-equipe.erreur-action'.tr());
    }
  }

  void _confirmDelete(CustomComposition c) {
    showDialog<void>(
      context: context,
      barrierColor: AppColor.scrim,
      builder:
          (BuildContext ctx) => AppConfirmDialog(
            title: 'app.test-equipe.supprimer-titre'.tr(),
            message: 'app.test-equipe.supprimer-message'.tr(),
            primaryLabel: 'app.test-equipe.supprimer-conserver'.tr(),
            onPrimary: () => Navigator.of(ctx).pop(),
            secondaryLabel: 'app.test-equipe.supprimer-confirmer'.tr(),
            secondaryAccent: AppColor.destructive,
            onSecondary: () {
              Navigator.of(ctx).pop();
              _delete(c);
            },
          ),
    );
  }

  Future<void> _delete(CustomComposition c) async {
    final String? id = c.id;
    if (id == null) return;
    try {
      await CompositionRepository.deleteComposition(id);
    } catch (_) {
      if (mounted) _err('app.test-equipe.erreur-suppression'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final PlayerCount? clubFormat = ref.watch(teamFormatProvider);
    final int count = clubFormat?.value ?? _count;
    // Filtre local UNION identifiants Algolia (fautes de frappe, accents) : le
    // local s'affiche tout de suite, Algolia ne fait qu'ajouter.
    final List<CustomComposition> customs = unionVisible<CustomComposition>(
        items:
            (ref.watch(customCompositionsProvider).valueOrNull ??
                    const <CustomComposition>[])
                .where((CustomComposition c) => c.playerCount == count)
                .toList(),
        matchesLocally:
            (CustomComposition c) => _matches(c.name, c.formationLabel),
        idOf: (CustomComposition c) => c.id,
        remoteIds: _remoteIds,
      )
      // Favorites en tête (tri stable : conserve l'ordre createdAt du flux).
      ..sort(
        (CustomComposition a, CustomComposition b) =>
            (b.isFavorite ? 1 : 0) - (a.isFavorite ? 1 : 0),
      );
    final List<Formation> standards = standardFormations(
      count,
    ).where((Formation f) => _matches('', f.label)).toList(growable: false);

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isPhoneLayout ? 16 : cW(40),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              cSh(isPhoneLayout ? 8 : 18),
              _header(),
              cSh(isPhoneLayout ? 6 : 14),
              VerticalDivider(),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isPhoneLayout ? 16 : cW(40),
              isPhoneLayout ? 8 : cH(16),
              isPhoneLayout ? 16 : cW(40),
              cH(kBottomNavClearance),
            ),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // Largeur des cartes calculée pour remplir la ligne : 5 colonnes
                // séparées par [gap], occupant toute la largeur disponible.
                // Téléphone : 3 cartes horizontales (aperçu + actions) par ligne
                // plutôt que 5 cartes hautes.
                final int cols = isPhoneLayout ? 3 : 5;
                final double gap = cW(14);
                final double cardW =
                    (constraints.maxWidth - gap * (cols - 1)) / cols;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'app.test-equipe.titre'.tr(),
                            style: AppThemeStyle.semiBStyle(
                              cFs(28),
                              AppColor.primaryLabels,
                            ),
                          ),
                        ),
                        cSw(16),
                        _CreateButton(onTap: () => _create(count)),
                      ],
                    ),
                    cSh(20),
                    _headingWithFilter(
                      'app.test-equipe.section-personnalisees'.tr(),
                      showCountFilter: clubFormat == null,
                    ),
                    cSh(12),
                    // Recherche sans aucune correspondance (ni perso ni
                    // standard) : un seul état vide plutôt que deux sections
                    // vides.
                    if (customs.isEmpty && standards.isEmpty && _pending)
                      const SizedBox.shrink()
                    else if (customs.isEmpty && standards.isEmpty)
                      EmptyStatePlaceholder(
                        title: 'app.test-equipe.aucun-resultat-titre'.tr(),
                        subtitle:
                            'app.test-equipe.aucun-resultat-sous-titre'.tr(),
                        titleSize: 18,
                        padding: EdgeInsets.symmetric(vertical: cH(40)),
                      )
                    else ...<Widget>[
                      if (customs.isEmpty && _pending)
                        const SizedBox.shrink()
                      else if (customs.isEmpty)
                        Text(
                          _query.trim().isEmpty
                              ? 'app.test-equipe.aucune-composition'.tr()
                              : 'app.test-equipe.aucun-resultat-recherche'.tr(),
                          style: AppThemeStyle.regularStyle(
                            cFs(13),
                            AppColor.secondaryLabels,
                          ),
                        )
                      else
                        Wrap(
                          spacing: gap,
                          runSpacing: cH(14),
                          children: <Widget>[
                            for (final CustomComposition c in customs)
                              _CustomCard(
                                width: cardW,
                                composition: c,
                                onTest: () => _test(c),
                                onEdit: () => _edit(c),
                                onDuplicate: () => _duplicate(c),
                                onDelete: () => _confirmDelete(c),
                                onToggleFavorite: () => _toggleFavorite(c),
                              ),
                          ],
                        ),
                      cSh(26),
                      Text(
                        'app.test-equipe.section-standards'.tr(),
                        style: AppThemeStyle.semiBStyle(
                          cFs(16),
                          AppColor.primaryLabels,
                        ),
                      ),
                      cSh(12),
                      if (standards.isEmpty)
                        Text(
                          'app.test-equipe.aucun-resultat-recherche'.tr(),
                          style: AppThemeStyle.regularStyle(
                            cFs(13),
                            AppColor.secondaryLabels,
                          ),
                        )
                      else
                        Wrap(
                          spacing: gap,
                          runSpacing: cH(14),
                          children: <Widget>[
                            for (final Formation f in standards)
                              _StandardCard(
                                width: cardW,
                                formation: f,
                                onTest: () => _testStandard(f),
                                onDuplicate: () => _duplicateStandard(f),
                              ),
                          ],
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return Row(
      children: <Widget>[
        Icon(Iconsax.people, size: cIc(26), color: AppColor.primaryColor),
        cSw(10),
        Text(
          'app.test-equipe.entete'.tr(),
          style: AppThemeStyle.semiBStyle(cFs(28), AppColor.primaryLabels),
        ),
        const Spacer(),
        const NotificationBell(),
        cSw(16),
        const SettingsButton(),
        cSw(18),
        const WinaWordmark(size: 34),
      ],
    );
  }

  /// Titre de section aligné à gauche + filtres (type d'équipe, recherche)
  /// alignés à droite sur la même ligne (design 1:19314). Le type d'équipe
  /// disparaît quand le club a un format imposé ([showCountFilter] faux).
  Widget _headingWithFilter(String heading, {required bool showCountFilter}) {
    return Row(
      children: <Widget>[
        Text(
          heading,
          style: AppThemeStyle.semiBStyle(cFs(16), AppColor.primaryLabels),
        ),
        const Spacer(),
        if (showCountFilter) ...<Widget>[
          SizedBox(
            // 230 dp ne tenait plus le contenu (~237) depuis que
            // `LabeledPillDropdown` garantit 12 dp entre libellé et valeur :
            // « Type d'équipe » s'ellipsait en « Type d'équi… ».
            width: cW(250),
            child: LabeledPillDropdown<int>(
              label: 'app.test-equipe.type-equipe'.tr(),
              value: _count,
              values: const <int>[11, 8, 5],
              labelOf:
                  (int n) => 'app.test-equipe.compo-a'.tr(args: <String>['$n']),
              onChanged: (int n) => setState(() => _count = n),
            ),
          ),
          cSw(14),
        ],
        _SearchField(
          controller: _searchController,
          onChanged: _union.input,
          onClear: _clearSearch,
        ),
      ],
    );
  }
}

/// Carte d'une composition personnalisée : nom + schéma + favori + aperçu +
/// actions (Tester / Modifier / Dupliquer / Supprimer).
class _CustomCard extends StatelessWidget {
  const _CustomCard({
    required this.width,
    required this.composition,
    required this.onTest,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  final double width;
  final CustomComposition composition;
  final VoidCallback onTest;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    if (isPhoneLayout) return _phoneCard();
    return Container(
      width: width,
      padding: EdgeInsets.all(cW(10)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(16)),
        border: Border.all(color: AppColor.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  composition.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemeStyle.mediumStyle(
                    cFs(12),
                    AppColor.primaryLabels,
                  ),
                ),
              ),
              cSw(6),
              LabelPill(composition.formationLabel, horizontalPadding: 10),
              cSw(6),
              InkResponse(
                onTap: onToggleFavorite,
                radius: cIc(20),
                child: Icon(
                  composition.isFavorite ? Iconsax.heart : Iconsax.heart_copy,
                  size: cIc(20),
                  color:
                      composition.isFavorite
                          ? AppColor.destructive
                          : AppColor.secondaryLabels,
                ),
              ),
            ],
          ),
          cSh(8),
          FormationPitch(
            formation: composition.toFormation(),
            markerFraction: 0.16,
          ),
          cSh(10),
          _CardButton(
            label: 'app.test-equipe.action-tester'.tr(),
            onTap: onTest,
          ),
          cSh(8),
          _CardButton(label: 'utils.modify'.tr(), onTap: onEdit),
          cSh(8),
          _CardButton(
            label: 'app.test-equipe.action-dupliquer'.tr(),
            onTap: onDuplicate,
          ),
          cSh(8),
          _CardButton(
            label: 'app.test-equipe.action-supprimer'.tr(),
            accent: AppColor.destructive,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Carte d'une composition standard : schéma + aperçu + « Dupliquer » (crée une
/// composition personnalisée modifiable à partir du modèle).
class _StandardCard extends StatelessWidget {
  const _StandardCard({
    required this.width,
    required this.formation,
    required this.onTest,
    required this.onDuplicate,
  });

  final double width;
  final Formation formation;
  final VoidCallback onTest;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    if (isPhoneLayout) return _phoneCard();
    return Container(
      width: width,
      padding: EdgeInsets.all(cW(10)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(16)),
        border: Border.all(color: AppColor.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              LabelPill(formation.label, horizontalPadding: 10),
              const Spacer(),
            ],
          ),
          cSh(8),
          FormationPitch(formation: formation, markerFraction: 0.16),
          cSh(10),
          _CardButton(
            label: 'app.test-equipe.action-creer-depuis-modele'.tr(),
            onTap: onDuplicate,
          ),
          cSh(8),
          _CardButton(
            label: 'app.test-equipe.action-tester'.tr(),
            onTap: onTest,
          ),
        ],
      ),
    );
  }
}

// Cartes téléphone : aperçu du schéma à gauche, infos et actions (icônes) à
// droite. Hauteur fixe ~ celle de l'aperçu, au lieu d'une carte haute à quatre
// boutons pleine largeur.
const double _kPhonePitchW = 76;

Widget _phoneShell(double width, Widget pitch, Widget side) {
  return Container(
    width: width,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColor.divider),
    ),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(width: _kPhonePitchW, child: Center(child: pitch)),
          const SizedBox(width: 8),
          Expanded(child: side),
        ],
      ),
    ),
  );
}

/// Petit bouton icône (zone tactile 34x30) avec info-bulle.
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 34,
          height: 30,
          child: Icon(icon, size: 18, color: color ?? AppColor.primaryLabels),
        ),
      ),
    );
  }
}

extension on _CustomCard {
  Widget _phoneCard() {
    return _phoneShell(
      width,
      FormationPitch(
        formation: composition.toFormation(),
        markerFraction: 0.16,
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  composition.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemeStyle.mediumStyle(
                    cFs(13),
                    AppColor.primaryLabels,
                  ),
                ),
              ),
              InkResponse(
                onTap: onToggleFavorite,
                radius: 18,
                child: Icon(
                  composition.isFavorite ? Iconsax.heart : Iconsax.heart_copy,
                  size: 18,
                  color:
                      composition.isFavorite
                          ? AppColor.destructive
                          : AppColor.secondaryLabels,
                ),
              ),
            ],
          ),
          LabelPill(composition.formationLabel, horizontalPadding: 10),
          Row(
            children: <Widget>[
              _IconAction(
                icon: Iconsax.play,
                tooltip: 'app.test-equipe.action-tester'.tr(),
                onTap: onTest,
                color: AppColor.primaryColor,
              ),
              _IconAction(
                icon: Iconsax.edit_2,
                tooltip: 'utils.modify'.tr(),
                onTap: onEdit,
              ),
              _IconAction(
                icon: Iconsax.copy,
                tooltip: 'app.test-equipe.action-dupliquer'.tr(),
                onTap: onDuplicate,
              ),
              _IconAction(
                icon: Iconsax.trash,
                tooltip: 'app.test-equipe.action-supprimer'.tr(),
                onTap: onDelete,
                color: AppColor.destructive,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on _StandardCard {
  Widget _phoneCard() {
    return _phoneShell(
      width,
      FormationPitch(formation: formation, markerFraction: 0.16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          LabelPill(formation.label, horizontalPadding: 10),
          Row(
            children: <Widget>[
              _IconAction(
                icon: Iconsax.play,
                tooltip: 'app.test-equipe.action-tester'.tr(),
                onTap: onTest,
                color: AppColor.primaryColor,
              ),
              _IconAction(
                icon: Iconsax.copy,
                tooltip: 'app.test-equipe.action-creer-depuis-modele'.tr(),
                onTap: onDuplicate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bouton d'action d'une carte : pilule bordée + petite flèche.
class _CardButton extends StatelessWidget {
  const _CardButton({required this.label, required this.onTap, this.accent});

  final String label;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Color fg = accent ?? AppColor.primaryLabels;
    final double badge = cIc(16);
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(cR(999)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cR(999)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cR(999)),
            border: Border.all(color: AppColor.divider),
          ),
          padding: EdgeInsets.symmetric(horizontal: cW(10), vertical: cH(9)),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemeStyle.semiBStyle(cFs(12), fg),
                ),
              ),
              cSw(8),
              SizedBox(
                width: badge,
                height: badge,
                child: Icon(
                  Iconsax.arrow_circle_right,
                  size: badge * 0.72,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastille du libellé de schéma (ex. « 4-4-1-1 »).

/// Vrai si [query] correspond au nom ou au libellé de schéma.
///
/// La saisie au pavé numérique ne permet pas de taper le tiret des libellés
/// (« 4-3-3 ») : « 433 » est donc aussi comparé sous sa forme tiretée.
bool matchesCompositionQuery(String query, String name, String label) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (name.toLowerCase().contains(q) || label.toLowerCase().contains(q)) {
    return true;
  }
  final String dashed = dashifyFormationQuery(q);
  return dashed.isNotEmpty && label.contains(dashed);
}

/// Champ de recherche (par nom ou schéma).
///
/// Pas d'autofocus : la barre est affichée en permanence dans l'entête de
/// l'onglet, un focus automatique ferait remonter le clavier à chaque bascule
/// sur « Test équipe » et masquerait les cartes.
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
      width: cW(240),
      padding: EdgeInsets.symmetric(horizontal: cW(14)),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(cR(999)),
        border: Border.all(color: AppColor.divider),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Iconsax.search_normal_1_copy,
            size: cIc(16),
            color: AppColor.secondaryLabels,
          ),
          cSw(8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              // Le coach cherche d'abord un schéma : clavier chiffres d'emblée.
              keyboardType: TextInputType.number,
              // Valider la recherche referme le clavier.
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              style: AppThemeStyle.regularStyle(
                cFs(13),
                AppColor.primaryLabels,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'app.recherche.test-equipe-hint'.tr(),
                hintStyle: AppThemeStyle.regularStyle(
                  cFs(13),
                  AppColor.secondaryLabels,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            InkResponse(
              onTap: onClear,
              radius: cIc(18),
              child: Icon(
                Iconsax.close_circle,
                size: cIc(16),
                color: AppColor.secondaryLabels,
              ),
            ),
        ],
      ),
    );
  }
}

/// Bouton « + Créer une composition » (vert plein).
class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double badge = cIc(20);
    return Material(
      color: AppColor.primaryColor,
      borderRadius: BorderRadius.circular(cR(999)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cR(999)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: cW(20), vertical: cH(11)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'app.test-equipe.creer-composition'.tr(),
                style: AppThemeStyle.semiBStyle(cFs(14), AppColor.textLight),
              ),
              cSw(10),
              SizedBox(
                width: badge,
                height: badge,
                child: Icon(
                  Iconsax.arrow_circle_right,
                  size: badge * 0.72,
                  color: AppColor.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
