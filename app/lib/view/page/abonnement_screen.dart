import 'dart:async';
import 'dart:math' as math;

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:skeleton/controller/user_controller.dart';
import 'package:skeleton/skeleton.dart';
import 'package:wina/billing/billing_service.dart';
import 'package:wina/billing/offers.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/providers/billing_providers.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/app_loader.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/team_crest.dart';

/// Délai au-delà duquel on prévient l'utilisateur que l'activation est plus longue que prévu.
const Duration _kActivationDelay = Duration(seconds: 60);

/// Écran « Abonnement » (maquettes tablette) : choix de la formule (1, 2 ou 3 équipes), puis abonnement
/// annuel ou mensuel. Mur obligatoire : pas de bouton retour. L'écran ne navigue pas après l'achat, la
/// garde d'accès le remplace dès que `users/{uid}.access` devient actif.
class AbonnementScreen extends ConsumerStatefulWidget {
  const AbonnementScreen({super.key});

  @override
  ConsumerState<AbonnementScreen> createState() => _AbonnementScreenState();
}

class _AbonnementScreenState extends ConsumerState<AbonnementScreen> {
  int _teams = 1;
  bool _busy = false;
  bool _activating = false;
  bool _activatingLate = false;
  Timer? _lateTimer;

  @override
  void dispose() {
    _lateTimer?.cancel();
    super.dispose();
  }

  /// Affiche le voile « Activation… » et arme le minuteur du message « plus long que prévu ».
  void _startActivating() {
    _lateTimer?.cancel();
    setState(() {
      _activating = true;
      _activatingLate = false;
    });
    _lateTimer = Timer(_kActivationDelay, () {
      if (mounted) setState(() => _activatingLate = true);
    });
  }

  void _notifyError(String message) {
    showAppNotif(
      context,
      title: 'utils.error'.tr(),
      subTitle: message,
      success: false,
    );
  }

  Future<void> _buy(String productId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final PurchaseResult result = await ref
          .read(billingServiceProvider)
          .purchase(productId);
      if (!mounted) return;
      if (result == PurchaseResult.cancelled) {
        setState(() => _busy = false);
        return;
      }
      _startActivating();
    } on BillingException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _notifyError(e.message);
    } on BillingUnavailable {
      if (!mounted) return;
      setState(() => _busy = false);
      _notifyError('app.subscription.unavailable'.tr());
    } catch (_) {
      // Panne inattendue du SDK : l'écran ne doit pas rester bloqué en « occupé ».
      if (!mounted) return;
      setState(() => _busy = false);
      _notifyError('utils.error-default'.tr());
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bool found = await ref.read(billingServiceProvider).restore();
      if (!mounted) return;
      if (found) {
        _startActivating();
      } else {
        setState(() => _busy = false);
        showAppNotif(context, title: 'app.subscription.restore-none'.tr());
      }
    } on BillingException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _notifyError(e.message);
    } on BillingUnavailable {
      if (!mounted) return;
      setState(() => _busy = false);
      _notifyError('app.subscription.unavailable'.tr());
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _notifyError('utils.error-default'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Map<int, TeamsOffer>> offers = ref.watch(offersProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const AppBackground(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: formatWidth(40)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  sh(16),
                  const _Header(),
                  sh(12),
                  Container(height: 1, color: AppColor.headerRule),
                  // Pas de défilement : le contenu est réduit pour tenir dans la hauteur disponible
                  // (jamais agrandi), sur un écran bas comme sur une tablette.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints box) {
                        final double width = math.min(
                          box.maxWidth,
                          formatWidth(880),
                        );
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: width,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                sh(18),
                                Text(
                                  'app.subscription.choose'.tr(),
                                  textAlign: TextAlign.center,
                                  style: AppThemeStyle.boldStyle(
                                    32,
                                    AppColor.primaryLabels,
                                  ),
                                ),
                                sh(22),
                                _TeamSelector(
                                  selected: _teams,
                                  onSelect:
                                      (int n) => setState(() => _teams = n),
                                ),
                                sh(28),
                                offers.when(
                                  data:
                                      (Map<int, TeamsOffer> byTeams) =>
                                          _buildCards(byTeams[_teams]),
                                  loading:
                                      () => Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: formatHeight(60),
                                        ),
                                        child: const AppLoader(),
                                      ),
                                  error:
                                      (Object _, StackTrace _) => _Unavailable(
                                        onRetry:
                                            () =>
                                                ref.invalidate(offersProvider),
                                      ),
                                ),
                                sh(14),
                                _Footer(onRestore: _restore),
                                sh(8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed:
                                        () => UserController.logoutUser(
                                          context,
                                          ref,
                                        ),
                                    child: Text(
                                      'app.subscription.logout'.tr(),
                                      style: AppThemeStyle.regularStyle(
                                        14,
                                        AppColor.secondaryLabels,
                                      ).copyWith(
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                sh(12),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_activating) _ActivatingOverlay(late: _activatingLate),
          ],
        ),
      ),
    );
  }

  /// Les deux cartes de la formule choisie ; une carte dont l'offre manque n'est pas affichée.
  Widget _buildCards(TeamsOffer? offer) {
    if (offer == null || (offer.yearly == null && offer.monthly == null)) {
      return _Unavailable(onRetry: () => ref.invalidate(offersProvider));
    }
    final List<Widget> cards = <Widget>[
      if (offer.yearly != null)
        Expanded(
          child: _YearlyCard(
            offer: offer,
            busy: _busy,
            onSubscribe: () => _buy(offer.yearly!.productId),
          ),
        ),
      if (offer.yearly != null && offer.monthly != null) sw(28),
      if (offer.monthly != null)
        Expanded(
          child: _MonthlyCard(
            offer: offer,
            busy: _busy,
            onSubscribe: () => _buy(offer.monthly!.productId),
          ),
        ),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cards,
      ),
    );
  }
}

/// En-tête : couronne, titre, wordmark. Pas de bouton retour (mur obligatoire).
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(Iconsax.crown_1, size: sp(33), color: AppColor.primaryColor),
        sw(12),
        Expanded(
          child: Text(
            'app.subscription.title'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemeStyle.semiBStyle(28, AppColor.primaryLabels),
          ),
        ),
        sw(12),
        const WinaWordmark(size: 30, tappable: false),
      ],
    );
  }
}

/// Sélecteur de 3 tuiles : 1, 2 ou 3 équipes. La pastille d'économie dépasse sous la tuile 2.
class _TeamSelector extends StatelessWidget {
  const _TeamSelector({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int n = 1; n <= 3; n++) ...<Widget>[
          if (n > 1) sw(22),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                _TeamTile(
                  teams: n,
                  selected: selected == n,
                  onTap: () => onSelect(n),
                ),
                if (n == 2)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -formatHeight(16),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _Pill(
                          label: 'app.subscription.save-second'.tr(),
                          fontSize: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({
    required this.teams,
    required this.selected,
    required this.onTap,
  });

  final int teams;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color shield = selected ? AppColor.textLight : AppColor.primaryColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: formatWidth(22),
          vertical: formatHeight(18),
        ),
        decoration: BoxDecoration(
          color: selected ? null : AppColor.surface,
          gradient:
              selected
                  ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      AppColor.buttonGradientTop,
                      AppColor.buttonGradientBottom,
                    ],
                  )
                  : null,
          borderRadius: BorderRadius.circular(r(16)),
          // Bordure toujours présente (transparente si non choisie) : sans elle, la
          // tuile choisie serait plus grande de 4 px que les deux autres.
          border: Border.all(
            color: selected ? AppColor.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < teams; i++) ...<Widget>[
              if (i > 0) sw(4),
              TeamCrest(color: shield, size: 18),
            ],
            sw(14),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '$teams',
                          style: AppThemeStyle.semiBStyle(
                            22,
                            selected
                                ? AppColor.textLight
                                : AppColor.primaryLabels,
                          ),
                        ),
                        sw(5),
                        Text(
                          (teams == 1
                                  ? 'app.subscription.team-one'
                                  : 'app.subscription.team-many')
                              .tr(),
                          style: AppThemeStyle.semiBStyle(
                            22,
                            selected
                                ? AppColor.textLight
                                : AppColor.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    sh(2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          (selected
                                  ? 'app.subscription.selected'
                                  : 'app.subscription.pick')
                              .tr(),
                          style: AppThemeStyle.regularStyle(
                            14,
                            selected
                                ? AppColor.textLight
                                : AppColor.primaryLabels,
                          ),
                        ),
                        if (!selected) ...<Widget>[
                          sw(6),
                          Container(
                            width: formatWidth(6),
                            height: formatWidth(6),
                            decoration: const BoxDecoration(
                              color: AppColor.primaryLabels,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastille verte à texte blanc en majuscules (le texte est déjà en majuscules dans les traductions).
class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.fontSize = 13, this.vertical = 7});

  final String label;
  final double fontSize;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: formatWidth(14),
        vertical: formatHeight(vertical),
      ),
      decoration: BoxDecoration(
        color: AppColor.buttonGradientBottom,
        borderRadius: BorderRadius.circular(r(10)),
      ),
      child: Text(
        label,
        style: AppThemeStyle.boldStyle(fontSize, AppColor.textLight),
      ),
    );
  }
}

/// Carte blanche commune aux deux formules.
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.child, this.highlighted = false, this.badge});

  final Widget child;
  final bool highlighted;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(
            formatWidth(28),
            formatHeight(26),
            formatWidth(28),
            formatHeight(26),
          ),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(r(24)),
            // Bordure toujours présente : les deux cartes gardent le même cadre
            // intérieur, donc titres, prix et coches sont à la même hauteur.
            border: Border.all(
              color: highlighted ? AppColor.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: child,
        ),
        if (badge != null)
          Positioned(
            top: -formatHeight(18),
            left: formatWidth(28),
            child: badge!,
          ),
      ],
    );
  }
}

/// Prix en gros caractères suivi de son unité (« / an », « / mois »). Le prix rétrécit au lieu de déborder.
class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.price,
    required this.unit,
    required this.color,
  });

  final String price;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(price, style: AppThemeStyle.boldStyle(48, color)),
          ),
        ),
        sw(8),
        Text(
          unit,
          style: AppThemeStyle.regularStyle(18, AppColor.secondaryLabels),
        ),
      ],
    );
  }
}

/// Ligne à coche ; coche pleine (annuel) ou cerclée (mensuel).
class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.text, required this.filled});

  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: formatHeight(14)),
      child: Row(
        children: <Widget>[
          Container(
            width: formatWidth(24),
            height: formatWidth(24),
            decoration: BoxDecoration(
              color: filled ? AppColor.buttonGradientBottom : null,
              shape: BoxShape.circle,
              border:
                  filled
                      ? null
                      : Border.all(
                        color: AppColor.buttonGradientBottom,
                        width: 2,
                      ),
            ),
            child: Icon(
              Icons.check,
              size: sp(15),
              color:
                  filled ? AppColor.textLight : AppColor.buttonGradientBottom,
            ),
          ),
          sw(12),
          Expanded(
            child: Text(
              text,
              style: AppThemeStyle.regularStyle(16, AppColor.primaryLabels),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton pilule : plein (dégradé vert) ou bordé vert, avec pastille flèche.
class _PlanButton extends StatelessWidget {
  const _PlanButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg =
        filled ? AppColor.textLight : AppColor.buttonGradientBottom;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1,
        child: Container(
          height: formatHeight(58),
          padding: EdgeInsets.symmetric(horizontal: formatWidth(16)),
          decoration: BoxDecoration(
            color: filled ? null : AppColor.surface,
            gradient:
                filled
                    ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColor.buttonGradientTop,
                        AppColor.buttonGradientBottom,
                      ],
                    )
                    : null,
            borderRadius: BorderRadius.circular(r(29)),
            border:
                filled
                    ? null
                    : Border.all(color: AppColor.primaryColor, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: AppThemeStyle.semiBStyle(18, fg)),
                ),
              ),
              sw(10),
              Container(
                width: formatWidth(22),
                height: formatWidth(22),
                decoration: BoxDecoration(
                  color: filled ? AppColor.textLight : fg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right,
                  size: sp(16),
                  color:
                      filled
                          ? AppColor.buttonGradientBottom
                          : AppColor.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearlyCard extends StatelessWidget {
  const _YearlyCard({
    required this.offer,
    required this.busy,
    required this.onSubscribe,
  });

  final TeamsOffer offer;
  final bool busy;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final PlanOffer yearly = offer.yearly!;
    final String? fullPrice =
        offer.yearlyFullPrice == null
            ? null
            : formatMoney(offer.yearlyFullPrice!, yearly.currencyCode);
    final String perMonth = formatMoney(
      offer.yearlyPerMonth!,
      yearly.currencyCode,
    );
    return _PlanCard(
      highlighted: true,
      badge: _Pill(label: 'app.subscription.save-yearly'.tr()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          sh(8),
          Text(
            'app.subscription.yearly-title'.tr(),
            style: AppThemeStyle.semiBStyle(24, AppColor.primaryLabels),
          ),
          sh(18),
          _PriceRow(
            price: yearly.priceString,
            unit: 'app.subscription.per-year'.tr(),
            color: AppColor.rosterName,
          ),
          sh(10),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                if (fullPrice != null)
                  TextSpan(
                    text: fullPrice,
                    style: AppThemeStyle.regularStyle(
                      15,
                      AppColor.destructive,
                    ).copyWith(decoration: TextDecoration.lineThrough),
                  ),
                TextSpan(
                  text:
                      '${fullPrice != null ? ' · ' : ''}${'app.subscription.per-month-equiv'.tr(args: <String>[perMonth])}',
                  style: AppThemeStyle.regularStyle(
                    15,
                    AppColor.secondaryLabels,
                  ),
                ),
              ],
            ),
          ),
          sh(16),
          Container(height: 1, color: AppColor.divider),
          sh(20),
          _CheckLine(text: 'app.subscription.yearly-1'.tr(), filled: true),
          _CheckLine(text: 'app.subscription.yearly-2'.tr(), filled: true),
          _CheckLine(
            text:
                offer.teams == 1
                    ? 'app.subscription.yearly-3-one'.tr()
                    : 'app.subscription.yearly-3-many'.tr(
                      args: <String>['${offer.teams}'],
                    ),
            filled: true,
          ),
          const Spacer(),
          sh(10),
          _PlanButton(
            label: 'app.subscription.subscribe-year'.tr(),
            filled: true,
            onTap: busy ? null : onSubscribe,
          ),
        ],
      ),
    );
  }
}

class _MonthlyCard extends StatelessWidget {
  const _MonthlyCard({
    required this.offer,
    required this.busy,
    required this.onSubscribe,
  });

  final TeamsOffer offer;
  final bool busy;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final PlanOffer monthly = offer.monthly!;
    return _PlanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          sh(8),
          // « Sans engagement » sur le côté du titre : l'en-tête garde la hauteur de la carte annuelle,
          // les deux prix sont donc sur la même ligne.
          Row(
            children: <Widget>[
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'app.subscription.monthly-title'.tr(),
                    style: AppThemeStyle.semiBStyle(24, AppColor.primaryLabels),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: formatWidth(14),
                  vertical: formatHeight(6),
                ),
                decoration: BoxDecoration(
                  color: AppColor.background,
                  borderRadius: BorderRadius.circular(r(14)),
                ),
                child: Text(
                  'app.subscription.no-commitment'.tr(),
                  style: AppThemeStyle.mediumStyle(13, AppColor.grey5A6574),
                ),
              ),
            ],
          ),
          sh(18),
          _PriceRow(
            price: monthly.priceString,
            unit: 'app.subscription.per-month'.tr(),
            color: AppColor.primaryLabels,
          ),
          sh(10),
          Text(
            offer.teams == 1
                ? 'app.subscription.for-one-team'.tr()
                : 'app.subscription.per-team'.tr(
                  args: <String>[
                    formatMoney(offer.monthlyPerTeam!, monthly.currencyCode),
                  ],
                ),
            style: AppThemeStyle.regularStyle(15, AppColor.secondaryLabels),
          ),
          sh(16),
          Container(height: 1, color: AppColor.divider),
          sh(20),
          _CheckLine(text: 'app.subscription.monthly-1'.tr(), filled: false),
          _CheckLine(text: 'app.subscription.monthly-2'.tr(), filled: false),
          _CheckLine(text: 'app.subscription.monthly-3'.tr(), filled: false),
          const Spacer(),
          sh(10),
          _PlanButton(
            label: 'app.subscription.subscribe-month'.tr(),
            filled: false,
            onTap: busy ? null : onSubscribe,
          ),
        ],
      ),
    );
  }
}

/// Pied de page : essai gratuit, restauration, mentions légales et liens CGU / confidentialité.
class _Footer extends StatelessWidget {
  const _Footer({required this.onRestore});

  final VoidCallback onRestore;

  TextStyle get _link => AppThemeStyle.regularStyle(
    12,
    AppColor.primaryLabels,
  ).copyWith(decoration: TextDecoration.underline);

  @override
  Widget build(BuildContext context) {
    final TextStyle trial = AppThemeStyle.regularStyle(
      14,
      AppColor.primaryLabels,
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: formatWidth(24),
        vertical: formatHeight(14),
      ),
      decoration: BoxDecoration(
        color: AppColor.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(r(16)),
      ),
      child: Column(
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text('app.subscription.trial-line'.tr(), style: trial),
              Text(' · ', style: trial),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRestore,
                child: Text('app.subscription.restore'.tr(), style: trial),
              ),
            ],
          ),
          sh(6),
          Text(
            'app.subscription.legal'.tr(),
            textAlign: TextAlign.center,
            style: AppThemeStyle.regularStyle(11, AppColor.secondaryLabels),
          ),
          sh(4),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Même chemin que « link-cgvu » dans settings.config.dart.
                onTap:
                    () => AutoRouter.of(
                      context,
                    ).pushNamed('legal-information/cgvu'),
                child: Text('app.subscription.terms'.tr(), style: _link),
              ),
              Text(
                ' · ',
                style: AppThemeStyle.regularStyle(12, AppColor.secondaryLabels),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Même chemin que « link-policy » dans settings.config.dart.
                onTap:
                    () => AutoRouter.of(
                      context,
                    ).pushNamed('legal-information/privacy-policy'),
                child: Text('app.subscription.privacy'.tr(), style: _link),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Achats indisponibles (clés absentes ou échec du chargement des offres) : message et bouton Réessayer.
class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: formatHeight(40)),
      child: Column(
        children: <Widget>[
          Text(
            'app.subscription.unavailable'.tr(),
            textAlign: TextAlign.center,
            style: AppThemeStyle.semiBStyle(18, AppColor.primaryLabels),
          ),
          sh(20),
          SizedBox(
            width: formatWidth(260),
            child: _PlanButton(
              label: 'app.subscription.retry'.tr(),
              filled: true,
              onTap: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}

/// Voile blanc translucide pendant l'activation de l'abonnement ; il bloque les appuis en dessous.
class _ActivatingOverlay extends StatelessWidget {
  const _ActivatingOverlay({required this.late});

  final bool late;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: ColoredBox(
          color: AppColor.surface.withValues(alpha: 0.9),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: formatWidth(80)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const AppLoader(),
                  sh(20),
                  Text(
                    (late
                            ? 'app.subscription.activating-late'
                            : 'app.subscription.activating')
                        .tr(),
                    textAlign: TextAlign.center,
                    style: AppThemeStyle.semiBStyle(18, AppColor.primaryLabels),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
