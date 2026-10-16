import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Compresse un fichier image.
/// - Retourne les octets compressés (Uint8List).
/// - Garde le ratio et cible au moins [minWidth]x[minHeight].
/// - Par défaut, force JPEG mais choisit PNG/WebP si l’extension le suggère.
/// - Fallback: retourne les octets originaux si la compression échoue
///   ou si elle n'apporte aucun gain.
Future<Uint8List> compressFile(
  File file, {
  int minWidth = 640,
  int minHeight = 480,
  int quality = 75,
}) async {
  // Lire les octets originaux pour fallback
  final originalBytes = await file.readAsBytes();
  if (originalBytes.isEmpty) return originalBytes;

  // Clamp qualité
  quality = quality.clamp(1, 100);

  // Choisir format de sortie selon extension
  final path = file.absolute.path.toLowerCase();
  final isPng = path.endsWith('.png');
  final isWebp = path.endsWith('.webp');

  final format = isPng
      ? CompressFormat.png
      : (isWebp ? CompressFormat.webp : CompressFormat.jpeg);

  try {
    final compressed = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      format: format,
    );

    // Vérifier le résultat
    if (compressed == null || compressed.isEmpty) {
      return originalBytes;
    }

    // Si compression inefficace, garder original
    if (compressed.lengthInBytes >= originalBytes.lengthInBytes) {
      return originalBytes;
    }

    return compressed;
  } catch (e, st) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Compression failed: $e\n$st');
    }
    return originalBytes;
  }
}
