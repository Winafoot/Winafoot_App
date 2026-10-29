// Habille les captures brutes (voir capture_test.dart) en visuels de fiche App Store / Google Play :
// fond de marque avec lignes de terrain, accroche à mot clé coloré, pastilles d'arguments et plusieurs écrans
// superposés en éventail. Tailles exactes demandées par les stores.
//
//   flutter test tool/store_screenshots/capture_test.dart
//   flutter test tool/store_screenshots/compose_test.dart
//
// Sortie : build/store_screenshots/visuels_portrait/<store>/<appareil>/<n>_<nom>.png
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Une cible de store : taille exacte en pixels et capture source (téléphone ou tablette).
class _Target {
  const _Target(this.store, this.folder, this.width, this.height, this.source);

  final String store;
  final String folder;
  final int width;
  final int height;
  final String source; // 'phone' | 'tablet'

  bool get wide => width / height > 1.7;
  bool get portrait => height > width;
}

const List<_Target> _targets = <_Target>[
  // App Store : iPhone 6,9" et iPad 13" (paysage, l'app est verrouillée en paysage).
  _Target('apple', 'iphone_6.9', 2868, 1320, 'phone'),
  _Target('apple', 'ipad_13', 2752, 2064, 'tablet'),
  // Google Play : téléphone 16:9, tablettes 7" et 10" (16:10).
  _Target('google', 'telephone', 2560, 1440, 'phone'),
  _Target('google', 'tablette_10', 2560, 1600, 'tablet'),

  // Mêmes visuels en portrait, aux tailles exactes listées pour les fiches (le contenu de l'app reste en
  // paysage : les écrans sont empilés / en éventail).
  _Target('apple', 'iphone_6.9_portrait_1320x2868', 1320, 2868, 'phone'),
  _Target('apple', 'ipad_13_portrait_2064x2752', 2064, 2752, 'tablet'),
  _Target('google', 'telephone_portrait_1080x1920', 1080, 1920, 'phone'),
  _Target('google', 'tablette_7_portrait_1200x1920', 1200, 1920, 'tablet'),
  _Target('google', 'tablette_10_portrait_1600x2560', 1600, 2560, 'tablet'),
];

class _Slide {
  const _Slide(this.file, this.name, this.before, this.accent, this.after, this.subtitle, this.perks);

  final String file;
  final String name;
  final String before;
  final String accent;
  final String after;
  final String subtitle;
  final List<String> perks;
}

const List<_Slide> _slides = <_Slide>[
  _Slide(
    '01_match_direct',
    '1_stats_en_direct',
    'Saisissez les ',
    'stats',
    ' en direct',
    'Chaque action en un seul appui, pendant le match.',
    <String>['En ligne ou hors ligne', 'Remplacements', 'Chrono et score'],
  ),
  _Slide(
    '02_composition',
    '2_composition',
    'Composez votre ',
    'équipe',
    '',
    'Placez vos joueurs et attribuez les numéros en quelques gestes.',
    <String>['Tous les schémas', 'Numéros et brassard', 'Vos compositions'],
  ),
  _Slide(
    '04_statistiques',
    '3_historique',
    'Retrouvez ',
    'tous',
    ' vos matchs',
    'Score, bilans et composition de chaque rencontre.',
    <String>['Historique complet', 'Recherche rapide', 'Résultat en un coup d\'œil'],
  ),
  _Slide(
    '05_bilan_collectif',
    '4_bilans',
    'Des ',
    'bilans',
    ' qui font progresser',
    'Statistiques collectives et individuelles, par mi-temps.',
    <String>['Bilan collectif', 'Bilan par joueur', 'Export PDF'],
  ),
];

const Color _navy = Color(0xFF001F41); // bleu marine
const Color _anis = Color(0xFFA8C03C); // vert anis

Future<ui.Image> _load(String path) async {
  final Uint8List bytes = File(path).readAsBytesSync();
  final ui.Codec codec = await ui.instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

// ── Décor ───────────────────────────────────────────────────────────────────

void _background(Canvas canvas, double w, double h) {
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w, h),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(w, h),
        <Color>[_navy, const Color(0xFF00305F)],
      ),
  );
  // Bande de pelouse en diagonale, à peine visible.
  canvas.drawPath(
    Path()
      ..moveTo(w * 0.55, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w * 0.25, h)
      ..close(),
    Paint()..color = _anis.withValues(alpha: 0.07),
  );
  // Marquage de terrain en filigrane.
  final Paint line =
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.005;
  final double r = math.min(h * 0.46, w * 0.6);
  canvas.drawCircle(Offset(w * 0.72, h * 0.55), r, line);
  canvas.drawLine(Offset(w * 0.72, -h * 0.1), Offset(w * 0.72, h * 1.1), line);
  // Halo anis derrière l'appareil.
  canvas.drawCircle(
    Offset(w * 0.72, h * 0.58),
    h * 0.6,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.72, h * 0.58),
        h * 0.6,
        <Color>[_anis.withValues(alpha: 0.20), _anis.withValues(alpha: 0)],
      ),
  );
}

// ── Texte ───────────────────────────────────────────────────────────────────

TextPainter _rich(List<TextSpan> spans, double maxWidth, {TextAlign align = TextAlign.left}) {
  return TextPainter(
    text: TextSpan(children: spans),
    textAlign: align,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);
}

TextSpan _span(String t, double size, FontWeight weight, Color color, {double height = 1.12, double spacing = 0}) =>
    TextSpan(
      text: t,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: spacing,
      ),
    );

/// Pastille d'argument : coche dans un rond citron, puis le libellé. Renvoie sa largeur.
double _pill(Canvas canvas, String label, Offset at, double size) {
  final TextPainter tp = _rich(<TextSpan>[
    _span(label, size, FontWeight.w600, Colors.white),
  ], 4000)..layout();
  final double padX = size * 0.8;
  final double dot = size * 1.15;
  final double hgt = size * 2.5;
  final double wdt = padX + dot + size * 0.6 + tp.width + padX;
  final RRect r = RRect.fromRectAndRadius(
    Rect.fromLTWH(at.dx, at.dy, wdt, hgt),
    Radius.circular(hgt / 2),
  );
  canvas.drawRRect(r, Paint()..color = Colors.white.withValues(alpha: 0.12));
  canvas.drawRRect(
    r,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.08,
  );
  final Offset c = Offset(at.dx + padX + dot / 2, at.dy + hgt / 2);
  canvas.drawCircle(c, dot / 2, Paint()..color = _anis);
  final Path tick =
      Path()
        ..moveTo(c.dx - dot * 0.24, c.dy + dot * 0.01)
        ..lineTo(c.dx - dot * 0.06, c.dy + dot * 0.2)
        ..lineTo(c.dx + dot * 0.27, c.dy - dot * 0.17);
  canvas.drawPath(
    tick,
    Paint()
      ..color = _navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = dot * 0.14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  tp.paint(canvas, Offset(at.dx + padX + dot + size * 0.6, at.dy + (hgt - tp.height) / 2));
  return wdt;
}

// ── Appareils ───────────────────────────────────────────────────────────────

/// Dessine [shot] dans un mockup d'appareil (téléphone ou tablette selon le format de la capture), centré sur
/// [center] et pivoté de [angle] radians : corps métallique, bords noirs, îlot / caméra, boutons latéraux, reflet.
void _device(
  Canvas canvas,
  ui.Image shot, {
  required Offset center,
  required double width,
  required double angle,
  double opacity = 1,
}) {
  final double aspect = shot.width / shot.height;
  final bool phone = aspect > 2;
  final double height = width / aspect;
  // Épaisseurs, proportionnelles à la hauteur de l'écran (l'appareil est en paysage).
  final double metal = height * (phone ? 0.030 : 0.020); // cadre métallique
  final double glass = height * (phone ? 0.020 : 0.052); // bord noir autour de l'écran
  final Rect screen = Rect.fromCenter(center: Offset.zero, width: width, height: height);
  final double screenR = height * (phone ? 0.115 : 0.045);
  final Rect black = screen.inflate(glass);
  final Rect body = black.inflate(metal);
  final RRect rScreen = RRect.fromRectAndRadius(screen, Radius.circular(screenR));
  final RRect rBlack = RRect.fromRectAndRadius(black, Radius.circular(screenR + glass));
  final RRect rBody = RRect.fromRectAndRadius(body, Radius.circular(screenR + glass + metal));

  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);

  // Ombre portée.
  canvas.drawRRect(
    rBody.shift(Offset(0, height * 0.05)),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, height * 0.07),
  );

  // Boutons latéraux (dépassent un peu du corps) : volume en haut, veille en bas.
  final Paint btn = Paint()..color = const Color(0xFF8D96A6);
  final double bt = metal * 0.55;
  void button(double cx, double len, bool top) {
    final double y = top ? body.top - bt * 0.7 : body.bottom - bt * 0.3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, y + bt * 0.5), width: len, height: bt),
        Radius.circular(bt / 2),
      ),
      btn,
    );
  }

  if (phone) {
    button(body.left + body.width * 0.20, body.width * 0.05, true);
    button(body.left + body.width * 0.27, body.width * 0.05, true);
    button(body.right - body.width * 0.18, body.width * 0.09, false);
  }

  // Corps métallique avec léger dégradé.
  canvas.drawRRect(
    rBody,
    Paint()
      ..shader = ui.Gradient.linear(
        body.topLeft,
        body.bottomRight,
        <Color>[const Color(0xFFC9CFDA), const Color(0xFF6C7587), const Color(0xFFB4BBC8)],
        <double>[0, 0.5, 1],
      ),
  );
  canvas.drawRRect(rBlack, Paint()..color = const Color(0xFF05070C));

  // Écran.
  canvas.save();
  canvas.clipRRect(rScreen);
  canvas.drawImageRect(
    shot,
    Rect.fromLTWH(0, 0, shot.width.toDouble(), shot.height.toDouble()),
    screen,
    Paint()..filterQuality = FilterQuality.high,
  );
  // Reflet diagonal discret.
  canvas.drawPath(
    Path()
      ..moveTo(screen.left + screen.width * 0.52, screen.top)
      ..lineTo(screen.left + screen.width * 0.74, screen.top)
      ..lineTo(screen.left + screen.width * 0.40, screen.bottom)
      ..lineTo(screen.left + screen.width * 0.18, screen.bottom)
      ..close(),
    Paint()
      ..shader = ui.Gradient.linear(
        screen.topCenter,
        screen.bottomCenter,
        <Color>[Colors.white.withValues(alpha: 0.07), Colors.white.withValues(alpha: 0)],
      ),
  );
  canvas.restore();

  if (phone) {
    // Îlot dynamique, sur le bord gauche en paysage.
    final Rect island = Rect.fromCenter(
      center: Offset(screen.left + height * 0.008, screen.center.dy),
      width: height * 0.036,
      height: height * 0.17,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(island, Radius.circular(height * 0.03)),
      Paint()..color = const Color(0xFF000000),
    );
    canvas.drawCircle(
      Offset(island.center.dx, island.center.dy - island.height * 0.22),
      height * 0.009,
      Paint()..color = const Color(0xFF1A2236),
    );
  } else {
    // Caméra frontale de la tablette, sur le bord gauche en paysage.
    canvas.drawCircle(
      Offset(screen.left - glass * 0.5, screen.center.dy),
      glass * 0.17,
      Paint()..color = const Color(0xFF1A2236),
    );
  }
  canvas.restore();
}

Future<void> _write(String path, ui.Picture picture, int w, int h) async {
  final ui.Image img = await picture.toImage(w, h);
  final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadFonts);

  testWidgets('visuels des stores', (WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final _Target t in _targets) {
        // Toutes les captures de l'appareil : les autres servent d'éventail derrière l'écran vedette.
        final Map<String, ui.Image> shots = <String, ui.Image>{};
        for (final _Slide s in _slides) {
          final String src = 'build/store_screenshots/raw2/${t.source}_${s.file}.png';
          if (File(src).existsSync()) shots[s.file] = await _load(src);
        }

        for (int i = 0; i < _slides.length; i++) {
          final _Slide s = _slides[i];
          final ui.Image? main = shots[s.file];
          if (main == null) continue;

          final double w = t.width.toDouble();
          final double h = t.height.toDouble();
          final ui.PictureRecorder rec = ui.PictureRecorder();
          final Canvas canvas = Canvas(rec);
          _background(canvas, w, h);

          // ── Bloc texte ────────────────────────────────────────────────────
          final bool por = t.portrait;
          final double left = w * (por ? 0.07 : 0.055);
          final double textW = por ? w * 0.86 : (t.wide ? w * 0.31 : w * 0.62);
          final double titleSize =
              por ? w * 0.064 : (t.wide ? w * 0.031 : w * 0.040);
          final double subSize =
              por ? w * 0.037 : (t.wide ? w * 0.0165 : w * 0.0215);
          double y = h * (por ? 0.045 : (t.wide ? 0.17 : 0.055));

          final TextPainter title = _rich(<TextSpan>[
            _span(s.before.toUpperCase(), titleSize, FontWeight.w700, Colors.white, spacing: titleSize * 0.07),
            _span(s.accent.toUpperCase(), titleSize, FontWeight.w700, _anis, spacing: titleSize * 0.07),
            _span(s.after.toUpperCase(), titleSize, FontWeight.w700, Colors.white, spacing: titleSize * 0.07),
          ], textW);
          title.paint(canvas, Offset(left, y));
          y += title.height + titleSize * 0.22;

          // Soulignement citron sous le titre.
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(left, y, titleSize * 1.6, titleSize * 0.11),
              Radius.circular(titleSize),
            ),
            Paint()..color = _anis,
          );
          y += titleSize * 0.11 + titleSize * 0.42;

          final TextPainter sub = _rich(<TextSpan>[
            _span(s.subtitle, subSize, FontWeight.w400, Colors.white.withValues(alpha: 0.88), height: 1.35),
          ], textW);
          sub.paint(canvas, Offset(left, y));
          y += sub.height + subSize * 1.3;

          // Arguments : une courte liste, un point citron devant chaque ligne.
          final double perkSize = subSize * 0.92;
          double py = y;
          for (final String perk in s.perks) {
            canvas.drawCircle(
              Offset(left + perkSize * 0.35, py + perkSize * 0.72),
              perkSize * 0.2,
              Paint()..color = _anis,
            );
            final TextPainter tp = _rich(<TextSpan>[
              _span(perk, perkSize, FontWeight.w600, Colors.white),
            ], textW)..layout();
            tp.paint(canvas, Offset(left + perkSize * 1.0, py));
            py += perkSize * 1.75;
          }
          final double pillBottom = py;

          // ── Écran vedette (un seul, grand) ──────────────────────────────
          final double mainAspect = main.width / main.height;
          if (por) {
            // Un seul écran, grand, centré dans la place sous le texte.
            final double devW = w * 0.92;
            final double free = h - pillBottom;
            _device(
              canvas,
              main,
              center: Offset(w / 2, pillBottom + free / 2),
              width: devW,
              angle: 0,
            );
            await _write(
              'build/store_screenshots/visuels_portrait/${t.store}/${t.folder}/${s.name}.png',
              rec.endRecording(),
              t.width,
              t.height,
            );
            continue;
          }
          final Rect area = por
              ? Rect.fromLTWH(w * 0.04, pillBottom + h * 0.03, w * 0.92, h * 0.975 - (pillBottom + h * 0.03))
              : (t.wide
                  ? Rect.fromLTWH(w * 0.40, h * 0.07, w * 0.58, h * 0.86)
                  : Rect.fromLTWH(w * 0.04, h * 0.44, w * 0.92, h * 0.54));
          final double mainW = math.min(area.width * 0.98, area.height * mainAspect * 0.98);
          final double mainH = mainW / mainAspect;
          _device(
            canvas,
            main,
            center: Offset(area.center.dx, por ? area.bottom - mainH / 2 : area.center.dy),
            width: mainW,
            angle: por ? 0 : -0.02,
          );

          await _write(
            'build/store_screenshots/visuels_portrait/${t.store}/${t.folder}/${s.name}.png',
            rec.endRecording(),
            t.width,
            t.height,
          );
        }
      }
    });
  });
}
