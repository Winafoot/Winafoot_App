import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:wina/config/theme.dart';
import 'package:wina/models/coach_profile.dart';

void main() {
  group('jerseyAssetFor', () {
    test('titulaire : la couleur portée par l\'équipe', () {
      expect(
        jerseyAssetFor(isSub: false, own: JerseyColorOption.blanc),
        JerseyColorOption.blanc.asset,
      );
    });

    test('remplaçant : bleu, quelle que soit la couleur portée', () {
      expect(
        jerseyAssetFor(isSub: true, own: JerseyColorOption.blanc),
        JerseyColorOption.bleu.asset,
      );
    });

    test('remplaçant d\'une équipe en bleu : replié sur le bleu clair', () {
      expect(
        jerseyAssetFor(isSub: true, own: JerseyColorOption.bleu),
        JerseyColorOption.bleuClair.asset,
      );
    });

    test('sans maillot choisi : les deux rôles restent distincts', () {
      expect(
        jerseyAssetFor(isSub: false, own: null),
        isNot(jerseyAssetFor(isSub: true, own: null)),
      );
    });
  });

  group('numberColorForJerseyAsset', () {
    test('maillot blanc : encre sombre', () {
      expect(
        numberColorForJerseyAsset(JerseyColorOption.blanc.asset),
        AppColor.primaryLabels,
      );
    });

    test('maillot noir ou asset sans option : chiffre blanc', () {
      expect(
        numberColorForJerseyAsset(JerseyColorOption.noir.asset),
        AppColor.textLight,
      );
      expect(
        numberColorForJerseyAsset('assets/images/shirt-empty.png'),
        AppColor.textLight,
      );
    });

    test('maillots clairs : chiffre sombre', () {
      for (final JerseyColorOption o in <JerseyColorOption>[
        JerseyColorOption.jaune,
        JerseyColorOption.vertClair,
        JerseyColorOption.bleuClair,
      ]) {
        expect(numberColorForJerseyAsset(o.asset), AppColor.primaryLabels);
      }
    });

    // Garde-fou des appelants (placement, numéros, match live, statistiques —
    // roster et terrain —, tableau de stats) : quelle que soit la palette,
    // l'encre est lisible.
    test('chaque maillot : encre lisible (>= 4:1) et la plus contrastée', () {
      for (final JerseyColorOption o in JerseyColorOption.values) {
        final Color ink = numberColorForJerseyAsset(o.asset);
        final Color other =
            ink == AppColor.textLight
                ? AppColor.primaryLabels
                : AppColor.textLight;
        expect(
          _contrast(ink, o.color),
          greaterThanOrEqualTo(4),
          reason: 'numéro illisible sur ${o.name}',
        );
        expect(
          _contrast(ink, o.color),
          greaterThanOrEqualTo(_contrast(other, o.color)),
          reason: 'meilleure encre pour ${o.name}',
        );
      }
    });
  });
}

/// Rapport de contraste WCAG (1 à 21).
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance(), lb = b.computeLuminance();
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}
