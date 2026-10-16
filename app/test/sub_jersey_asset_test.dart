import 'package:flutter_test/flutter_test.dart';
import 'package:wina/models/coach_profile.dart';

void main() {
  test('le maillot des remplaçants diffère toujours de celui des titulaires', () {
    for (final JerseyColorOption own in JerseyColorOption.values) {
      expect(
        subJerseyAsset(own.asset),
        isNot(own.asset),
        reason: 'équipe en ${own.name}',
      );
    }
  });

  test('équipe en bleu : les remplaçants basculent sur le bleu clair', () {
    expect(
      subJerseyAsset(JerseyColorOption.bleu.asset),
      JerseyColorOption.bleuClair.asset,
    );
  });

  test('jerseyAssetFor délègue la même règle', () {
    for (final JerseyColorOption own in JerseyColorOption.values) {
      expect(
        jerseyAssetFor(isSub: true, own: own),
        subJerseyAsset(own.asset),
      );
      expect(jerseyAssetFor(isSub: false, own: own), own.asset);
    }
  });
}
