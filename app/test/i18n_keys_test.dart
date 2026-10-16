import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Aplatit `{"a": {"b": "x"}}` en `{"a.b"}`.
Set<String> _flatten(Map<String, dynamic> json, [String prefix = '']) {
  final Set<String> out = <String>{};
  json.forEach((String k, dynamic v) {
    final String path = prefix.isEmpty ? k : '$prefix.$k';
    if (v is Map<String, dynamic>) {
      out.addAll(_flatten(v, path));
    } else {
      out.add(path);
    }
  });
  return out;
}

/// Clés référencées dans le code mais volontairement absentes du JSON.
const Set<String> _knownMissing = <String>{};

void main() {
  test('toute clé de traduction citée dans lib/ existe dans fr-FR.json', () {
    final Set<String> known = _flatten(
      json.decode(File('assets/translations/fr-FR.json').readAsStringSync())
          as Map<String, dynamic>,
    );

    // Les littéraux commençant par un bloc racine du JSON — donc aussi ceux
    // passés en argument (`_toast(context, 'utils.error', 'package.…')`), pas
    // seulement le motif `"x".tr()` : c'est cet angle mort qui a laissé passer
    // les clés brutes affichées à l'écran.
    final RegExp keyLiteral = RegExp(
      r'''['"]((?:app|bar|date|package|utils)\.[a-zA-Z0-9_.\-]+)['"]''',
    );
    final Map<String, String> missing = <String, String>{};
    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart') || f.path.endsWith('.g.dart')) {
        continue;
      }
      for (final RegExpMatch m in keyLiteral.allMatches(f.readAsStringSync())) {
        final String key = m.group(1)!;
        if (key.endsWith('.') || known.contains(key) ||
            _knownMissing.contains(key)) {
          continue;
        }
        missing[key] = f.path;
      }
    }

    expect(missing, isEmpty, reason: 'Clés absentes de fr-FR.json : $missing');
  });
}
