import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stockage sécurisé simulé en mémoire.
class _MemoryCredentialStore implements LocalCredentialStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  late _MemoryCredentialStore store;

  setUp(() {
    store = _MemoryCredentialStore();
    LocalAuthController.credentialStore = store;
  });

  group('rememberCredentials', () {
    test('biométrie non activée : rien n\'est enregistré', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await LocalAuthController.rememberCredentials(
        'coach@example.com',
        'secret-1',
      );

      expect(store.values, isEmpty);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isNot(contains('data')));
      expect(prefs.getKeys(), isNot(contains('email')));
    });

    test(
      'biométrie non activée : des identifiants restants sont effacés',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        store.values[LocalAuthController.emailKey] = 'ancien@example.com';
        store.values[LocalAuthController.passwordKey] = 'ancien';

        await LocalAuthController.rememberCredentials(
          'coach@example.com',
          'secret-1',
        );

        expect(store.values, isEmpty);
      },
    );

    test(
      'biométrie activée : identifiants dans le stockage sécurisé seulement',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          LocalAuthController.biometricsFlagKey: true,
        });

        await LocalAuthController.rememberCredentials(
          'coach@example.com',
          'secret-1',
        );

        expect(store.values, <String, String>{
          LocalAuthController.emailKey: 'coach@example.com',
          LocalAuthController.passwordKey: 'secret-1',
        });
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getKeys(), <String>{
          LocalAuthController.biometricsFlagKey,
        });
      },
    );
  });

  group('getLoginData', () {
    test('rend les identifiants quand la biométrie est activée', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalAuthController.biometricsFlagKey: true,
      });
      await LocalAuthController.rememberCredentials(
        'coach@example.com',
        'secret-1',
      );

      final data = await LocalAuthController.getLoginData();

      expect(data?.value1, 'coach@example.com');
      expect(data?.value2, 'secret-1');
    });

    test(
      'null quand la biométrie est désactivée, même si des identifiants restent',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          LocalAuthController.biometricsFlagKey: false,
        });
        store.values[LocalAuthController.emailKey] = 'coach@example.com';
        store.values[LocalAuthController.passwordKey] = 'secret-1';

        expect(await LocalAuthController.getLoginData(), isNull);
      },
    );

    test('null quand rien n\'est enregistré', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalAuthController.biometricsFlagKey: true,
      });

      expect(await LocalAuthController.getLoginData(), isNull);
    });
  });

  group('purgeStoredCredentials', () {
    test(
      'retire les valeurs SharedPreferences des versions précédentes',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'data': 'valeur-chiffree',
          'email': 'coach@example.com',
          'isDarkMode': false,
        });

        await LocalAuthController.purgeStoredCredentials();

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getKeys(), <String>{'isDarkMode'});
      },
    );

    test('biométrie non activée : vide aussi le stockage sécurisé', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      store.values[LocalAuthController.emailKey] = 'coach@example.com';
      store.values[LocalAuthController.passwordKey] = 'secret-1';

      await LocalAuthController.purgeStoredCredentials();

      expect(store.values, isEmpty);
    });

    test(
      'biométrie activée : garde les identifiants du stockage sécurisé',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          LocalAuthController.biometricsFlagKey: true,
          'data': 'valeur-chiffree',
        });
        store.values[LocalAuthController.emailKey] = 'coach@example.com';
        store.values[LocalAuthController.passwordKey] = 'secret-1';

        await LocalAuthController.purgeStoredCredentials();

        expect(store.values.length, 2);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getKeys(), <String>{
          LocalAuthController.biometricsFlagKey,
        });
      },
    );
  });

  test('forgetCredentials efface tout, biométrie activée ou non', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LocalAuthController.biometricsFlagKey: true,
      'data': 'valeur-chiffree',
      'email': 'coach@example.com',
    });
    store.values[LocalAuthController.emailKey] = 'coach@example.com';
    store.values[LocalAuthController.passwordKey] = 'secret-1';

    await LocalAuthController.forgetCredentials();

    expect(store.values, isEmpty);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), <String>{LocalAuthController.biometricsFlagKey});
  });

  test('clearCredentials vide le stockage sécurisé', () async {
    store.values[LocalAuthController.emailKey] = 'coach@example.com';
    store.values[LocalAuthController.passwordKey] = 'secret-1';

    await LocalAuthController.clearCredentials();

    expect(store.values, isEmpty);
  });

  test(
    'un stockage sécurisé en erreur ne fait pas échouer la connexion',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalAuthController.biometricsFlagKey: true,
      });
      LocalAuthController.credentialStore = _FailingCredentialStore();

      await expectLater(
        LocalAuthController.rememberCredentials(
          'coach@example.com',
          'secret-1',
        ),
        completes,
      );
      expect(await LocalAuthController.getLoginData(), isNull);
      await expectLater(
        LocalAuthController.purgeStoredCredentials(),
        completes,
      );
      await expectLater(LocalAuthController.forgetCredentials(), completes);
    },
  );
}

class _FailingCredentialStore implements LocalCredentialStore {
  @override
  Future<String?> read(String key) async =>
      throw StateError('stockage indisponible');

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('stockage indisponible');

  @override
  Future<void> delete(String key) async =>
      throw StateError('stockage indisponible');
}
