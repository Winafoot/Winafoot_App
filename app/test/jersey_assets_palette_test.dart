import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/coach_profile.dart';

/// Les couleurs des maillots sont CUITES dans les `shirt-*.png` : changer une
/// constante `AppColor.jersey*` sans recolorer le PNG (ou l'inverse) laisse
/// l'écusson et le maillot d'un même match de deux couleurs différentes, sans
/// qu'aucun autre test ne tombe.
///
/// Décodage pixel par pixel : on lit la teinte dominante (le corps du maillot,
/// ~25 000 px opaques sur 192x192) et on la compare à l'option.
class _Shirt {
  const _Shirt(this.body, this.pixels, this.hem);

  /// Couleur opaque la plus fréquente.
  final Color body;

  /// Couleurs des pixels entièrement opaques.
  final List<Color> pixels;

  /// Pixels entièrement opaques de la dernière ligne qui en contient (l'ourlet).
  final List<Color> hem;
}

Future<_Shirt> _decode(WidgetTester tester, String asset) async {
  late _Shirt shirt;
  await tester.runAsync(() async {
    final ui.Codec codec = await ui.instantiateImageCodec(
      File(asset).readAsBytesSync(),
    );
    final ui.Image image = (await codec.getNextFrame()).image;
    final List<int> rgba = (await image.toByteData())!.buffer.asUint8List();
    final List<Color> pixels = <Color>[];
    List<Color> hem = <Color>[];
    int hemRow = -1;
    final Map<int, int> count = <int, int>{};
    for (int i = 0; i < rgba.length; i += 4) {
      if (rgba[i + 3] != 255) continue;
      final Color c = Color.fromARGB(255, rgba[i], rgba[i + 1], rgba[i + 2]);
      pixels.add(c);
      final int row = i ~/ 4 ~/ image.width;
      if (row != hemRow) {
        hemRow = row;
        hem = <Color>[];
      }
      hem.add(c);
      count[c.toARGB32()] = (count[c.toARGB32()] ?? 0) + 1;
    }
    final int top =
        count.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    shirt = _Shirt(Color(top), pixels, hem);
  });
  return shirt;
}

/// Rapport de contraste WCAG (1 à 21).
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance(), lb = b.computeLuminance();
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}

void main() {
  testWidgets('chaque maillot est peint à la teinte de son option', (
    WidgetTester tester,
  ) async {
    for (final JerseyColorOption o in JerseyColorOption.values) {
      // Le blanc est l'exception : son écusson d'équipe est un gris clair
      // (visible sur le fond de l'app) mais le corps du maillot est quasi blanc.
      if (o == JerseyColorOption.blanc) continue;
      final _Shirt s = await _decode(tester, o.asset);
      expect(
        s.body.toARGB32(),
        o.color.toARGB32(),
        reason: '${o.asset} doit être peint en ${o.name}',
      );
    }
  });

  testWidgets('le maillot blanc reste visible sur un fond blanc', (
    WidgetTester tester,
  ) async {
    final _Shirt s = await _decode(tester, JerseyColorOption.blanc.asset);
    const Color paper = Color(0xFFFFFFFF);
    // Corps clair, mais cerné d'un contour franc : sans lui, un maillot #F7F7F7
    // se confond avec le fond blanc des menus déroulants.
    expect(s.body.computeLuminance(), greaterThan(0.85));
    final int outline =
        s.pixels.where((Color c) => _contrast(c, paper) >= 2.5).length;
    expect(outline, greaterThan(1500));
    // La silhouette touche le bas du canevas : l'ourlet doit être cerné lui
    // aussi (sinon le maillot ressemble à un U ouvert sur fond blanc).
    final int hemOutline =
        s.hem.where((Color c) => _contrast(c, paper) >= 2.5).length;
    expect(hemOutline, greaterThan(s.hem.length * 0.9));
  });

  testWidgets('bleu et bleu clair restent nettement distincts à l\'écran', (
    WidgetTester tester,
  ) async {
    // C'est ce couple qui sépare titulaires et remplaçants sur le terrain
    // (`subJerseyAsset`) : les tests de chemins restent verts même si une
    // palette rapproche les deux teintes, d'où cette mesure sur les pixels.
    final Color bleu =
        (await _decode(tester, JerseyColorOption.bleu.asset)).body;
    final Color clair =
        (await _decode(tester, JerseyColorOption.bleuClair.asset)).body;
    expect(_contrast(bleu, clair), greaterThanOrEqualTo(1.8));
  });
}
