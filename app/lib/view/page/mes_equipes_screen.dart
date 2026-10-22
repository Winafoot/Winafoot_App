import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wina/billing/access_info.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/data/linked_team_repository.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/models/formation.dart';
import 'package:wina/models/player.dart';
import 'package:wina/providers/billing_providers.dart';
import 'package:wina/providers/coach_providers.dart';
import 'package:wina/providers/home_tab_provider.dart';
import 'package:wina/providers/player_providers.dart';
import 'package:wina/services/register_validation.dart';
import 'package:wina/view/page/creer_equipe_liee_screen.dart';
import 'package:wina/view/widget/app_background.dart';
import 'package:wina/view/widget/app_notif.dart';
import 'package:wina/view/widget/check_profil_form.dart';
import 'package:wina/view/widget/custom_back_button.dart';
import 'package:wina/view/widget/label_pill.dart';
import 'package:wina/view/widget/team_crest.dart';

/// Réinitialise le mot de passe d'une équipe liée (injectable pour les tests).
typedef ResetLinkedTeamPasswordFn = Future<void> Function({required String uid, required String password});

/// Écran « Mes équipes » : équipes supplémentaires de l'abonnement, réinitialisation de leur mot de passe
/// et ajout d'une équipe tant qu'il reste des places.
class MesEquipesScreen extends ConsumerWidget {
  const MesEquipesScreen({super.key, this.onResetPassword = LinkedTeamRepository.resetPassword});

  final ResetLinkedTeamPasswordFn onResetPassword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<LinkedTeam> teams = ref.watch(linkedTeamsProvider).valueOrNull ?? const <LinkedTeam>[];
    final AccessInfo? info = ref.watch(accessInfoProvider).valueOrNull;
    final bool canAdd = info != null && missingTeams(info, linkedCount: teams.length, now: DateTime.now()) > 0;
    final CoachProfile? profile = ref.watch(coachProfileProvider).valueOrNull;
    final List<Player>? roster = ref.watch(playersStreamProvider).valueOrNull;

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
                  Row(
                    children: <Widget>[
                      CustomBackButton(onTap: () => Navigator.of(context).maybePop()),
                      sw(14),
                      Icon(Iconsax.people, size: sp(26), color: AppColor.primaryColor),
                      sw(10),
                      Expanded(
                        child: Text(
                          'app.teams.my-title'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppThemeStyle.semiBStyle(28, AppColor.primaryLabels),
                        ),
                      ),
                      const WinaWordmark(size: 34),
                    ],
                  ),
                  sh(12),
                  Container(height: 1, color: AppColor.headerRule),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: formatWidth(960)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              sh(24),
                              _TeamsGrid(
                                cards: <Widget>[
                                  _MainTeamCard(profile: profile, playerCount: roster?.length),
                                  for (final LinkedTeam team in teams)
                                    _LinkedTeamCard(team: team, onReset: () => _askNewPassword(context, team)),
                                ],
                              ),
                              if (teams.isEmpty)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: formatHeight(30)),
                                  child: Text(
                                    'app.teams.my-empty'.tr(),
                                    textAlign: TextAlign.center,
                                    style: AppThemeStyle.regularStyle(16, AppColor.secondaryLabels),
                                  ),
                                ),
                              if (canAdd) ...<Widget>[
                                sh(12),
                                CpButton(
                                  label: 'app.teams.add'.tr(),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(builder: (_) => const CreerEquipeLieeScreen()),
                                  ),
                                ),
                              ],
                              sh(24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _askNewPassword(BuildContext context, LinkedTeam team) async {
    final bool done =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext _) => _ResetPasswordDialog(team: team, onReset: onResetPassword),
        ) ??
        false;
    if (done && context.mounted) showAppNotif(context, title: 'app.teams.reset-done'.tr());
  }
}

/// Grille de cartes d'équipes : deux colonnes dès que la place le permet (tablette), une seule sinon.
class _TeamsGrid extends StatelessWidget {
  const _TeamsGrid({required this.cards});

  final List<Widget> cards;

  static const double _gap = 16;
  static const double _twoColumnsMinWidth = 600;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double gap = formatWidth(_gap);
        final bool twoColumns = constraints.maxWidth >= _twoColumnsMinWidth;
        final double cardWidth = twoColumns ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[for (final Widget card in cards) SizedBox(width: cardWidth, child: card)],
        );
      },
    );
  }
}

/// Coquille commune d'une carte d'équipe : écusson, nom, rang, pastilles, effectif, puis un pied de carte.
class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.name,
    required this.teamIndex,
    required this.pills,
    required this.playerCount,
    required this.footer,
  });

  final String name;
  final int teamIndex;

  /// Pastilles catégorie, division, format : celles qui manquent sont déjà écartées.
  final List<String> pills;
  final int? playerCount;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(formatWidth(24)),
      decoration: BoxDecoration(color: AppColor.surface, borderRadius: BorderRadius.circular(r(20))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const TeamCrest(size: 46),
              sw(14),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemeStyle.boldStyle(20, AppColor.primaryLabels),
                ),
              ),
              sw(10),
              LabelPill('app.teams.team-index'.tr(args: <String>['$teamIndex'])),
            ],
          ),
          if (pills.isNotEmpty) ...<Widget>[
            sh(14),
            Wrap(
              spacing: formatWidth(8),
              runSpacing: formatHeight(8),
              children: <Widget>[for (final String p in pills) LabelPill(p)],
            ),
          ],
          if (playerCount != null) ...<Widget>[
            sh(14),
            Row(
              children: <Widget>[
                Icon(Iconsax.people, size: sp(18), color: AppColor.secondaryLabels),
                sw(8),
                Text(
                  playerCount == 1
                      ? 'app.teams.players-one'.tr(args: <String>['$playerCount'])
                      : 'app.teams.players-many'.tr(args: <String>['$playerCount']),
                  style: AppThemeStyle.regularStyle(15, AppColor.secondaryLabels),
                ),
              ],
            ),
          ],
          sh(16),
          Container(height: 1, color: AppColor.divider),
          sh(8),
          footer,
        ],
      ),
    );
  }
}

/// Pastilles d'une équipe : catégorie, division et format (ex. « 11v11 »).
List<String> _pillsFor(TeamCategory? category, TeamDivision? division, PlayerCount? format) => <String>[
  if (category != null) category.label,
  if (division != null) division.label,
  if (format != null) '${format.value}v${format.value}',
];

/// Équipe 1 : le compte connecté lui-même. Le bouton ramène à « Mon équipe ».
class _MainTeamCard extends ConsumerWidget {
  const _MainTeamCard({required this.profile, required this.playerCount});

  final CoachProfile? profile;
  final int? playerCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String name = profile?.teamName?.trim() ?? '';
    return _TeamCard(
      name: name.isEmpty ? 'app.mon-equipe.nom-equipe-defaut'.tr() : name,
      teamIndex: 1,
      pills: _pillsFor(profile?.category, profile?.division, profile?.teamFormat),
      playerCount: playerCount,
      footer: Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () {
            ref.read(homeTabProvider.notifier).state = 0;
            Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
          },
          child: Text('app.teams.view-team'.tr(), style: AppThemeStyle.semiBStyle(15, AppColor.primaryColor)),
        ),
      ),
    );
  }
}

/// Équipe liée : identifiant de connexion et réinitialisation du mot de passe.
class _LinkedTeamCard extends StatelessWidget {
  const _LinkedTeamCard({required this.team, required this.onReset});

  final LinkedTeam team;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return _TeamCard(
      name: team.teamName,
      teamIndex: team.teamIndex,
      pills: _pillsFor(team.category, team.division, team.teamFormat),
      playerCount: team.playerCount,
      footer: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              team.identifier,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeStyle.regularStyle(15, AppColor.secondaryLabels),
            ),
          ),
          sw(12),
          TextButton(
            onPressed: onReset,
            child: Text('app.teams.reset-password'.tr(), style: AppThemeStyle.semiBStyle(15, AppColor.primaryColor)),
          ),
        ],
      ),
    );
  }
}

/// Boîte de dialogue : saisie du nouveau mot de passe d'une équipe. Se ferme sur `true` quand il est enregistré.
class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.team, required this.onReset});

  final LinkedTeam team;
  final ResetLinkedTeamPasswordFn onReset;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final List<String> missing = RegisterValidation.passwordViolations(_password.text);
    if (missing.isNotEmpty) {
      setState(() => _error = 'Il manque : ${missing.join(', ')}.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onReset(uid: widget.team.uid, password: _password.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'utils.error-default'.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColor.surface,
      title: Text(
        'app.teams.reset-title'.tr(args: <String>[widget.team.teamName]),
        style: AppThemeStyle.semiBStyle(18, AppColor.primaryLabels),
      ),
      content: SizedBox(
        width: formatWidth(400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            KeyedSubtree(
              key: const Key('reset-password-field'),
              child: CpTextField(
                controller: _password,
                hint: 'app.teams.password'.tr(),
                obscure: true,
                error: _error != null,
              ),
            ),
            if (_error != null)
              Padding(
                padding: EdgeInsets.only(top: formatHeight(6)),
                child: Text(_error!, style: AppThemeStyle.regularStyle(12, DefaultColor.error)),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text('app.teams.cancel'.tr()),
        ),
        TextButton(
          onPressed: _busy ? null : _save,
          child: Text('app.teams.save'.tr()),
        ),
      ],
    );
  }
}
