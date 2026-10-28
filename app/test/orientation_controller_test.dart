import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/config/orientation_controller.dart';

/// Sur téléphone, l'orientation ne pivote que lorsqu'elle reste stable : une
/// connexion qui enchaîne portrait → paysage → portrait en quelques centaines
/// de millisecondes ne doit pas faire tourner l'écran à chaque étape.
void main() {
  testWidgets('pas de rotation pour un aller-retour rapide, une seule si stable', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844); // téléphone
    addTearDown(tester.view.reset);

    final List<String> demandes = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          demandes.add((call.arguments as List<dynamic>).join(','));
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    // Démarrage : appliqué tout de suite (paysage hors parcours d'entrée).
    OrientationController.apply();
    expect(demandes, hasLength(1));
    expect(demandes.last, contains('landscape'));

    // Entrée puis sortie du portrait en moins d'une demi-seconde : rien ne bouge.
    OrientationController.enterPortraitScope();
    await tester.pump(const Duration(milliseconds: 200));
    OrientationController.leavePortraitScope();
    await tester.pump(const Duration(seconds: 1));
    expect(demandes, hasLength(1));

    // Portrait qui dure : une seule rotation, une fois le délai passé.
    OrientationController.enterPortraitScope();
    await tester.pump(const Duration(milliseconds: 200));
    expect(demandes, hasLength(1));
    await tester.pump(const Duration(seconds: 1));
    expect(demandes, hasLength(2));
    expect(demandes.last, contains('portrait'));

    OrientationController.leavePortraitScope();
    await tester.pump(const Duration(seconds: 1));
    expect(demandes, hasLength(3));
    expect(demandes.last, contains('landscape'));
  });
}
