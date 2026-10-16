import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/coach_profile.dart';
import 'package:wina/view/page/statistiques_matchs_screen.dart';

/// Le numéro du terrain « Statistiques matchs » restait en blanc en dur : sur
/// les maillots clairs (jaune, vert clair, orange, rose, gris, blanc) il était
/// illisible, et contredisait le roster de la même page, qui passe par
/// `numberColorForJerseyAsset`.
///
/// Échoue si le marqueur redécide l'encre lui-même au lieu de suivre le
/// maillot réellement peint (maillot d'équipe, ou noir quand sélectionné).
void main() {
  Future<Color?> numberInk(
    WidgetTester tester, {
    required String jerseyAsset,
    bool selected = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerMarker(
            size: 40,
            selected: selected,
            jerseyAsset: jerseyAsset,
            number: 10,
            name: 'Joueur 1',
            isCaptain: false,
            onTap: () {},
          ),
        ),
      ),
    );
    return tester.widget<Text>(find.text('10')).style?.color;
  }

  testWidgets('le numéro suit le maillot de l\'équipe, comme le roster', (
    WidgetTester tester,
  ) async {
    for (final JerseyColorOption o in JerseyColorOption.values) {
      expect(
        await numberInk(tester, jerseyAsset: o.asset),
        numberColorForJerseyAsset(o.asset),
        reason: 'encre du numéro sur ${o.name}',
      );
    }
    // Cas concret du défaut : équipe en jaune, chiffre sombre et non blanc.
    expect(
      await numberInk(tester, jerseyAsset: JerseyColorOption.jaune.asset),
      AppColor.primaryLabels,
    );
  });

  testWidgets('joueur sélectionné : maillot noir, numéro blanc', (
    WidgetTester tester,
  ) async {
    expect(
      await numberInk(
        tester,
        jerseyAsset: JerseyColorOption.jaune.asset,
        selected: true,
      ),
      AppColor.textLight,
    );
  });
}
