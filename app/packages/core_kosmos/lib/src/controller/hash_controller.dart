import 'package:core_kosmos/core_kosmos.dart';
import 'package:encrypt/encrypt.dart';

/// Chiffrement symétrique de valeurs, utilisé par les convertisseurs
/// `*_hash_converter`.
abstract class KosmosHashController {
  static String? encrypt(String plainText, [String? salt]) {
    final s = salt ?? GetIt.instance.get<AppMetadataConfig>().appHash;

    if (s == null || s.length != 32) {
      printExcept("Salt must be 32 characters long");
      return null;
    }
    final key = Key.fromUtf8(s);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    Encrypted.fromBase64(encrypted.base64);
    return encrypted.base64;
  }

  static decrypt(String encrypted, [String? salt]) {
    final s = salt ?? GetIt.instance.get<AppMetadataConfig>().appHash;
    if (s == null || s.length != 32) {
      printExcept("Salt must be 32 characters long");
      return null;
    }
    final key = Key.fromUtf8(s);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    final decrypted = encrypter.decrypt(Encrypted.from64(encrypted), iv: iv);
    return decrypted;
  }
}
