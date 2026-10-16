import 'dart:math' as math;

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/game_match.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/match_providers.dart';
import 'package:wina/view/page/coup_denvoi_step3_screen.dart';
import 'package:wina/view/widget/jersey_form.dart';
import 'package:wina/view/widget/match_wizard.dart';

/// Assistant « Coup d'envoi » — étape 2 : choix des maillots.
///
/// Gauche : sélection du maillot porté par l'équipe (parmi les maillots du
/// coach). Droite : couleur du maillot adverse. « Suivant » désactivé tant que
/// les deux ne sont pas choisis.
class CoupDEnvoiStep2Screen extends ConsumerWidget {
  const CoupDEnvoiStep2Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GameMatch draft = ref.watch(matchDraftProvider);
    final MatchDraftNotifier notifier = ref.read(matchDraftProvider.notifier);
    final List<Jersey> jerseys =
        ref.watch(jerseysProvider).valueOrNull ?? const <Jersey>[];

    return MatchWizardScaffold(
      title: 'app.coup-denvoi-step2.titre'.tr(),
      onBack: () => Navigator.of(context).maybePop(),
      bottomCta: WizardCtaButton(
        label: 'app.coup-denvoi-step2.suivant'.tr(),
        enabled: draft.isJerseyValid,
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: kCoupDEnvoiHubRoute),
                builder: (_) => const CoupDEnvoiStep3Screen(),
              ),
            ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: formatWidth(40),
            vertical: formatHeight(80),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _ownColumn(draft, notifier, jerseys)),
              Padding(
                padding: EdgeInsets.only(
                  top: formatHeight(200),
                  left: formatWidth(24),
                  right: formatWidth(24),
                ),
                child: const VsBadge(),
              ),
              Expanded(child: _opponentColumn(draft, notifier)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ownColumn(
    GameMatch draft,
    MatchDraftNotifier notifier,
    List<Jersey> jerseys,
  ) {
    return Column(
      children: <Widget>[
        TeamLabelBadge('app.coup-denvoi-step2.mon-equipe'.tr()),
        sh(20),
        if (jerseys.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: formatHeight(30)),
            child: Text(
              'app.coup-denvoi-step2.aucun-maillot'.tr(),
              textAlign: TextAlign.center,
              style: AppThemeStyle.regularStyle(13, AppColor.secondaryLabels),
            ),
          )
        else
          _JerseyCarousel(
            jerseys: jerseys,
            selectedIndex: _selectedIndex(draft, jerseys),
            onSelect: (int i) => notifier.setOwnJersey(jerseys[i]),
          ),
      ],
    );
  }

  /// Index du maillot actuellement porté dans [jerseys] (-1 si aucun).
  int _selectedIndex(GameMatch draft, List<Jersey> jerseys) {
    final Jersey? sel = draft.ownJersey;
    if (sel == null) return -1;
    for (int i = 0; i < jerseys.length; i++) {
      if (jerseys[i].name == sel.name && jerseys[i].color == sel.color) {
        return i;
      }
    }
    return -1;
  }

  Widget _opponentColumn(GameMatch draft, MatchDraftNotifier notifier) {
    final JerseyColorOption color =
        draft.opponent.jerseyColor ?? JerseyColorOption.blanc;
    final String name =
        draft.opponent.name.isEmpty
            ? 'app.coup-denvoi-step2.equipe-adverse'.tr()
            : draft.opponent.name;
    return Column(
      children: <Widget>[
        TeamLabelBadge(name),
        sh(20),
        ShirtIcon(asset: color.asset, size: 168),
        sh(16),
        Text(
          'app.coup-denvoi-step2.maillot-adverse'.tr(),
          style: AppThemeStyle.semiBStyle(17, AppColor.primaryLabels),
        ),
        sh(8),
        Text(
          'app.coup-denvoi-step2.choisir-couleur'.tr(),
          textAlign: TextAlign.center,
          style: AppThemeStyle.regularStyle(13, AppColor.secondaryLabels),
        ),
        sh(14),
        SizedBox(
          width: formatWidth(320),
          child: LabeledPillDropdown<JerseyColorOption>(
            label: 'app.coup-denvoi-step2.couleur-maillot'.tr(),
            value: draft.opponent.jerseyColor,
            values: JerseyColorOption.values,
            labelOf: (JerseyColorOption c) => c.label,
            leadingOf: (JerseyColorOption c) => ShirtIcon(asset: c.asset),
            onChanged: notifier.setOpponentJerseyColor,
          ),
        ),
      ],
    );
  }
}

/// Maillot d'une carte du carrousel : visuel + nom + puce « Maillot porté »
/// quand il est celui centré (sélectionné). L'estompe des voisins est gérée par
/// le carrousel.
class _SelectableShirt extends StatelessWidget {
  const _SelectableShirt({
    required this.jersey,
    required this.selected,
    required this.onTap,
  });

  final Jersey jersey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ShirtIcon(asset: jersey.color.asset, size: 168),
          sh(10),
          Text(
            jersey.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemeStyle.semiBStyle(15, AppColor.primaryLabels),
          ),
          sh(6),
          if (selected)
            InfoChip('app.coup-denvoi-step2.maillot-porte'.tr())
          else
            SizedBox(height: formatHeight(28)),
        ],
      ),
    );
  }
}

/// Carrousel horizontal des maillots de l'équipe : le maillot centré est le
/// maillot porté (plein), les voisins sont estompés et débordent sur les côtés.
/// Les flèches ‹ › (losange sombre) font défiler d'un maillot à l'autre —
/// pratique quand il y a plus de maillots que l'écran n'en montre.
class _JerseyCarousel extends StatefulWidget {
  const _JerseyCarousel({
    required this.jerseys,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<Jersey> jerseys;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  State<_JerseyCarousel> createState() => _JerseyCarouselState();
}

class _JerseyCarouselState extends State<_JerseyCarousel> {
  late final PageController _controller;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.selectedIndex >= 0 ? widget.selectedIndex : 0;
    _controller = PageController(viewportFraction: 0.33, initialPage: _page);
    // Aucun maillot encore porté : on sélectionne d'emblée celui affiché au
    // centre (comme sur la maquette).
    if (widget.selectedIndex < 0 && widget.jerseys.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onSelect(_page),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    final int next = index.clamp(0, widget.jerseys.length - 1);
    if (next == _page) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int last = widget.jerseys.length - 1;
    return SizedBox(
      height: formatHeight(240),
      child: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _controller,
            itemCount: widget.jerseys.length,
            onPageChanged: (int i) {
              setState(() => _page = i);
              widget.onSelect(i);
            },
            itemBuilder: (BuildContext context, int i) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  double page = _page.toDouble();
                  if (_controller.hasClients &&
                      _controller.position.haveDimensions) {
                    page = _controller.page ?? page;
                  }
                  final double dist = (page - i).abs().clamp(0.0, 1.0);
                  final double opacity = (1 - dist * 0.6).clamp(0.4, 1.0);
                  // Le maillot centré est plein format, les voisins réduits.
                  final double scale = 1 - dist * 0.32;
                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _SelectableShirt(
                    jersey: widget.jerseys[i],
                    selected: i == _page,
                    onTap: () => _goTo(i),
                  ),
                ),
              );
            },
          ),
          if (widget.jerseys.length > 1) ...<Widget>[
            Align(
              alignment: const Alignment(-1, -0.4),
              child: _CarouselArrow(
                icon: Icons.chevron_left,
                onTap: _page > 0 ? () => _goTo(_page - 1) : null,
              ),
            ),
            Align(
              alignment: const Alignment(1, -0.4),
              child: _CarouselArrow(
                icon: Icons.chevron_right,
                onTap: _page < last ? () => _goTo(_page + 1) : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Flèche losange sombre ‹ / › du carrousel de maillots (grisée en butée).
class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    final double d = sp(38);
    return GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: math.pi / 4,
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            color: enabled ? AppColor.primaryLabels : AppColor.disabled,
            borderRadius: BorderRadius.circular(r(10)),
          ),
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: -math.pi / 4,
            child: Icon(icon, size: sp(22), color: AppColor.textLight),
          ),
        ),
      ),
    );
  }
}
