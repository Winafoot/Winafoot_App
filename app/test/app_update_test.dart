import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wina/config/app_update.dart';
import 'package:wina/config/maintenance_gate.dart';

void main() {
  group('isUpdateRequired', () {
    test('build inférieur au minimum : mise à jour exigée', () {
      expect(AppUpdate.isUpdateRequired(currentBuild: 4, minBuild: 5), isTrue);
    });

    test('build égal ou supérieur : aucun blocage', () {
      expect(AppUpdate.isUpdateRequired(currentBuild: 5, minBuild: 5), isFalse);
      expect(AppUpdate.isUpdateRequired(currentBuild: 6, minBuild: 5), isFalse);
    });

    test('valeur inconnue : aucun blocage', () {
      expect(
        AppUpdate.isUpdateRequired(currentBuild: null, minBuild: 5),
        isFalse,
      );
      expect(
        AppUpdate.isUpdateRequired(currentBuild: 4, minBuild: null),
        isFalse,
      );
    });
  });

  group('minBuildFor', () {
    test('lit la valeur de la plateforme', () {
      final Map<String, dynamic> metadata = <String, dynamic>{
        'minBuild': <String, dynamic>{'android': 12, 'ios': 7},
      };
      expect(AppUpdate.minBuildFor(metadata, 'android'), 12);
      expect(AppUpdate.minBuildFor(metadata, 'ios'), 7);
    });

    test('accepte un nombre décimal ou une chaîne numérique', () {
      expect(
        AppUpdate.minBuildFor(<String, dynamic>{
          'minBuild': <String, dynamic>{'ios': 7.0},
        }, 'ios'),
        7,
      );
      expect(
        AppUpdate.minBuildFor(<String, dynamic>{
          'minBuild': <String, dynamic>{'ios': ' 8 '},
        }, 'ios'),
        8,
      );
    });

    test('champ absent, mal formé ou plateforme absente : null', () {
      expect(AppUpdate.minBuildFor(null, 'ios'), isNull);
      expect(AppUpdate.minBuildFor(<String, dynamic>{}, 'ios'), isNull);
      expect(
        AppUpdate.minBuildFor(<String, dynamic>{'minBuild': 12}, 'ios'),
        isNull,
      );
      expect(
        AppUpdate.minBuildFor(<String, dynamic>{
          'minBuild': <String, dynamic>{'android': 12},
        }, 'ios'),
        isNull,
      );
      expect(
        AppUpdate.minBuildFor(<String, dynamic>{
          'minBuild': <String, dynamic>{'ios': 'douze'},
        }, 'ios'),
        isNull,
      );
      expect(
        AppUpdate.minBuildFor(<String, dynamic>{
          'minBuild': <String, dynamic>{'ios': 7},
        }, null),
        isNull,
      );
    });
  });

  group('storeUrlFor', () {
    test('lit le lien de la plateforme', () {
      final Map<String, dynamic> metadata = <String, dynamic>{
        'storeUrl': <String, dynamic>{
          'android': 'https://play.google.com/store/apps/details?id=x',
          'ios': ' https://apps.apple.com/app/id1 ',
        },
      };
      expect(
        AppUpdate.storeUrlFor(metadata, 'android'),
        'https://play.google.com/store/apps/details?id=x',
      );
      expect(
        AppUpdate.storeUrlFor(metadata, 'ios'),
        'https://apps.apple.com/app/id1',
      );
    });

    test('absent, vide ou mal formé : null', () {
      expect(AppUpdate.storeUrlFor(<String, dynamic>{}, 'ios'), isNull);
      expect(
        AppUpdate.storeUrlFor(<String, dynamic>{
          'storeUrl': <String, dynamic>{'ios': ''},
        }, 'ios'),
        isNull,
      );
      expect(
        AppUpdate.storeUrlFor(<String, dynamic>{
          'storeUrl': <String, dynamic>{'ios': 3},
        }, 'ios'),
        isNull,
      );
    });
  });

  test('platformKey : android, ios, sinon null', () {
    expect(AppUpdate.platformKey(TargetPlatform.android), 'android');
    expect(AppUpdate.platformKey(TargetPlatform.iOS), 'ios');
    expect(AppUpdate.platformKey(TargetPlatform.macOS), isNull);
  });

  group('MaintenanceGate.resolve', () {
    const Map<String, dynamic> minBuild10 = <String, dynamic>{
      'minBuild': <String, dynamic>{'android': 10, 'ios': 10},
    };

    test('champs absents : application ouverte', () {
      expect(
        MaintenanceGate.resolve(
          <String, dynamic>{},
          currentBuild: 1,
          platformKey: 'ios',
        ),
        GateState.open,
      );
      expect(
        MaintenanceGate.resolve(null, currentBuild: 1, platformKey: 'ios'),
        GateState.open,
      );
    });

    test('build trop ancien : mise à jour exigée', () {
      expect(
        MaintenanceGate.resolve(
          minBuild10,
          currentBuild: 9,
          platformKey: 'android',
        ),
        GateState.updateRequired,
      );
    });

    test('build à jour : application ouverte', () {
      expect(
        MaintenanceGate.resolve(
          minBuild10,
          currentBuild: 10,
          platformKey: 'ios',
        ),
        GateState.open,
      );
    });

    test('la maintenance prime sur la mise à jour', () {
      expect(
        MaintenanceGate.resolve(
          <String, dynamic>{...minBuild10, 'maintenance': true},
          currentBuild: 9,
          platformKey: 'ios',
        ),
        GateState.maintenance,
      );
    });
  });
}
