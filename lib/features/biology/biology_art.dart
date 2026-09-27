import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../games/science_art.dart';
import 'body_scene.dart';
import 'illustrated_art.dart';

class BiologyPicture extends StatelessWidget {
  const BiologyPicture({
    super.key,
    required this.art,
    this.height = 130,
    this.girl = false,
  });
  final String art;
  final double height;
  final bool girl;
  @override
  Widget build(BuildContext context) {
    final illustration = illustrationFor(art, girl: girl);
    if (illustration != null)
      return SizedBox(
        height: height,
        width: double.infinity,
        child: IllustratedArt(
          asset: illustration.asset,
          crop: illustration.crop,
        ),
      );
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: BiologyArt(art, girl: girl)),
    );
  }
}

/// Original, explicit illustrations: no unrelated sparkle fallback for unit 3.
class BiologyArt extends CustomPainter {
  const BiologyArt(this.art, {this.girl = false});
  final String art;
  final bool girl;
  static const aliases = {
    'sight': 'eyes',
    'hearing': 'ear',
    'ears': 'ear',
    'smell': 'nose',
    'taste': 'tongue',
    'touch': 'skin',
    'eyelashes': 'eyelash',
    'sweet': 'honey',
    'sweet_honey': 'honey',
    'hear_music': 'music',
    'see_birds': 'bird',
    'smell_flowers': 'flower',
    'soft_cat': 'cat',
    'food': 'apple',
    'sound': 'music',
    'loud': 'music',
    'bright': 'sun',
    'checks_eyes_and_gives_glasses': 'optometrist',
    'looks_after_teeth': 'teeth',
    'cuts_hair': 'hair',
    'traffic_light': 'traffic',
    'grow': 'growing',
  };
  @override
  void paint(Canvas c, Size s) {
    final raw = art.toLowerCase().replaceAll(' ', '_');
    final id = aliases[raw] ?? raw;
    if (explorerAnchors.containsKey(id) &&
        !['eyes', 'nose', 'tongue', 'skin', 'ears'].contains(id)) {
      final a = explorerAnchors[id]!;
      final w = ['arm', 'leg'].contains(id) ? 120.0 : 90.0;
      final source = Rect.fromCenter(
        center: Offset(a.dx * 400, a.dy * 600),
        width: w,
        height: w * 1.2,
      );
      final fit = applyBoxFit(BoxFit.contain, source.size, s);
      final r = Alignment.center.inscribe(fit.destination, Offset.zero & s);
      c.save();
      c.clipRect(r);
      c.translate(r.left, r.top);
      c.scale(r.width / source.width, r.height / source.height);
      c.translate(-source.left, -source.top);
      drawExplorer(c, girl: girl);
      c.restore();
      return;
    }
    if (['eyebrow', 'eyelash', 'eyelid', 'eyes'].contains(id)) {
      final source = id == 'eyes'
          ? const Rect.fromLTWH(70, 50, 450, 300)
          : Rect.fromCenter(
              center: Offset(
                eyeAnchors[id]!.dx * 600,
                eyeAnchors[id]!.dy * 400,
              ),
              width: 220,
              height: 135,
            );
      final fit = applyBoxFit(BoxFit.contain, source.size, s);
      final r = Alignment.center.inscribe(fit.destination, Offset.zero & s);
      c.save();
      c.clipRect(r);
      c.translate(r.left, r.top);
      c.scale(r.width / source.width, r.height / source.height);
      c.translate(-source.left, -source.top);
      drawExplorerEye(c);
      c.restore();
      return;
    }
    c.save();
    final scale = math.min(s.width / 240, s.height / 160);
    c.translate((s.width - 240 * scale) / 2, (s.height - 160 * scale) / 2);
    c.scale(scale);
    const ink = Color(0xFF345269),
        skin = Color(0xFFE7B28A),
        blue = Color(0xFF5B9DB8);
    void oval(Rect r, Color color) => c.drawOval(r, Paint()..color = color);
    void box(Rect r, Color color, [double radius = 12]) => c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      Paint()..color = color,
    );
    void path(Path p, Color color, {double width = 0}) => c.drawPath(
      p,
      Paint()
        ..color = color
        ..style = width > 0 ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    void line(Offset a, Offset b, Color color, double width) => c.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
    if (id == 'ear') {
      oval(const Rect.fromLTWH(76, 10, 84, 137), skin);
      path(
        Path()
          ..moveTo(110, 123)
          ..cubicTo(110, 99, 155, 71, 137, 39)
          ..cubicTo(121, 10, 91, 40, 97, 68),
        const Color(0xFFB97856),
        width: 7,
      );
      path(
        Path()
          ..moveTo(111, 99)
          ..quadraticBezierTo(145, 84, 119, 69),
        const Color(0xFFB97856),
        width: 5,
      );
    } else if (id == 'nose') {
      path(
        Path()
          ..moveTo(102, 14)
          ..quadraticBezierTo(110, 72, 80, 109)
          ..quadraticBezierTo(98, 139, 124, 116)
          ..quadraticBezierTo(154, 135, 160, 108)
          ..quadraticBezierTo(132, 81, 130, 14)
          ..close(),
        skin,
      );
      oval(const Rect.fromLTWH(96, 107, 17, 9), const Color(0xFFAF6E52));
      oval(const Rect.fromLTWH(135, 106, 15, 9), const Color(0xFFAF6E52));
    } else if (id == 'tongue' || id == 'taste_buds') {
      oval(const Rect.fromLTWH(54, 31, 132, 95), const Color(0xFF873E4A));
      box(const Rect.fromLTWH(75, 39, 91, 22), Colors.white, 5);
      oval(const Rect.fromLTWH(85, 69, 72, 82), const Color(0xFFEC929D));
      line(
        const Offset(121, 87),
        const Offset(121, 135),
        const Color(0xFFCD6F80),
        3,
      );
      if (id == 'taste_buds')
        for (var i = 0; i < 12; i++) {
          oval(
            Rect.fromCircle(
              center: Offset(101 + (i % 4) * 13, 93 + (i ~/ 4) * 16),
              radius: 3,
            ),
            const Color(0xFFB75171),
          );
        }
    } else if (id == 'skin') {
      box(const Rect.fromLTWH(76, 64, 84, 78), skin, 22);
      for (var i = 0; i < 4; i++)
        box(Rect.fromLTWH(78 + i * 20, 16 + (i % 3) * 6, 16, 73), skin, 8);
      line(const Offset(77, 101), const Offset(54, 64), skin, 17);
      line(
        const Offset(95, 100),
        const Offset(142, 99),
        const Color(0xFFCE9674),
        2,
      );
    } else if (['three', 'five', 'ten'].contains(id)) {
      final count = id == 'three'
          ? 3
          : id == 'five'
          ? 5
          : 10;
      final text = TextPainter(
        text: TextSpan(
          text: '$count',
          style: const TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 70,
            color: ink,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(c, Offset(120 - text.width / 2, 0));
      for (var i = 0; i < count; i++)
        oval(
          Rect.fromCircle(
            center: Offset(50 + (i % 5) * 35, 105 + (i ~/ 5) * 27),
            radius: 10,
          ),
          blue,
        );
    } else if (id == 'bread') {
      box(const Rect.fromLTWH(37, 80, 166, 59), blue, 18);
      box(const Rect.fromLTWH(58, 47, 123, 49), const Color(0xFF9F6435), 16);
      box(const Rect.fromLTWH(68, 51, 104, 36), const Color(0xFF50382D), 10);
      oval(
        Rect.fromCircle(center: const Offset(180, 109), radius: 9),
        const Color(0xFFE8D9B1),
      );
      for (var i = 0; i < 3; i++)
        path(
          Path()
            ..moveTo(88 + i * 30, 39)
            ..cubicTo(66 + i * 30, 26, 112 + i * 30, 22, 90 + i * 30, 7),
          const Color(0xFF9BABA8),
          width: 5,
        );
    } else if (id == 'lemon') {
      oval(const Rect.fromLTWH(31, 54, 104, 64), const Color(0xFFEBC946));
      oval(const Rect.fromLTWH(116, 34, 91, 92), const Color(0xFFFFDB55));
      oval(const Rect.fromLTWH(125, 43, 73, 74), const Color(0xFFFFF3B7));
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        line(
          const Offset(162, 80),
          Offset(162 + math.cos(a) * 30, 80 + math.sin(a) * 30),
          const Color(0xFFE3BC42),
          3,
        );
      }
    } else if (id == 'mug') {
      c.drawCircle(
        const Offset(166, 87),
        26,
        Paint()
          ..color = blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12,
      );
      box(const Rect.fromLTWH(65, 53, 97, 83), blue, 14);
      oval(const Rect.fromLTWH(65, 44, 97, 25), const Color(0xFFE5EDE3));
      oval(const Rect.fromLTWH(75, 48, 77, 17), const Color(0xFF9F6F40));
      for (var i = 0; i < 3; i++)
        path(
          Path()
            ..moveTo(83 + i * 28, 36)
            ..cubicTo(70 + i * 28, 26, 102 + i * 28, 20, 87 + i * 28, 8),
          const Color(0xFF9CAFAA),
          width: 4,
        );
    } else if (id == 'traffic') {
      box(const Rect.fromLTWH(105, 6, 44, 124), ink, 13);
      line(const Offset(127, 127), const Offset(127, 156), ink, 10);
      for (var i = 0; i < 3; i++)
        oval(
          Rect.fromCircle(center: Offset(127, 29 + i * 39), radius: 14),
          [
            const Color(0xFF86625C),
            const Color(0xFF958762),
            const Color(0xFF72C973),
          ][i],
        );
    } else if (id == 'watermelon') {
      path(
        Path()
          ..moveTo(23, 35)
          ..lineTo(217, 35)
          ..quadraticBezierTo(123, 231, 23, 35),
        const Color(0xFF4D9D60),
      );
      path(
        Path()
          ..moveTo(40, 43)
          ..lineTo(200, 43)
          ..quadraticBezierTo(123, 198, 40, 43),
        const Color(0xFFF8EAB9),
      );
      path(
        Path()
          ..moveTo(49, 48)
          ..lineTo(191, 48)
          ..quadraticBezierTo(123, 176, 49, 48),
        const Color(0xFFEA7B7B),
      );
      for (final p in [
        const Offset(83, 66),
        const Offset(119, 72),
        const Offset(156, 64),
        const Offset(119, 101),
      ])
        oval(Rect.fromCenter(center: p, width: 5, height: 9), ink);
    } else if (id == 'apple') {
      oval(const Rect.fromLTWH(53, 52, 86, 89), const Color(0xFFD86C62));
      oval(const Rect.fromLTWH(111, 52, 76, 89), const Color(0xFFE98171));
      line(
        const Offset(119, 60),
        const Offset(128, 24),
        const Color(0xFF896444),
        7,
      );
      oval(const Rect.fromLTWH(130, 25, 40, 19), const Color(0xFF6EAD69));
    } else if (id == 'honey') {
      box(const Rect.fromLTWH(66, 49, 108, 96), const Color(0xFFE3B850), 18);
      box(const Rect.fromLTWH(60, 36, 120, 23), const Color(0xFF9E855D), 7);
      box(const Rect.fromLTWH(80, 80, 80, 38), const Color(0xFFFFE8A3), 8);
      oval(const Rect.fromLTWH(106, 91, 28, 17), const Color(0xFFF6BA40));
    } else if (id == 'music') {
      box(const Rect.fromLTWH(39, 45, 102, 97), blue, 12);
      oval(Rect.fromCircle(center: const Offset(90, 98), radius: 29), ink);
      oval(
        Rect.fromCircle(center: const Offset(90, 98), radius: 14),
        const Color(0xFF8EC3CF),
      );
      line(const Offset(177, 24), const Offset(177, 82), ink, 6);
      line(const Offset(177, 24), const Offset(209, 18), ink, 6);
      oval(const Rect.fromLTWH(152, 77, 29, 18), const Color(0xFFCC9269));
    } else if (id == 'teeth') {
      path(
        Path()
          ..moveTo(83, 22)
          ..quadraticBezierTo(113, 14, 121, 27)
          ..quadraticBezierTo(158, 9, 175, 39)
          ..quadraticBezierTo(181, 67, 160, 94)
          ..lineTo(149, 142)
          ..quadraticBezierTo(139, 155, 133, 116)
          ..quadraticBezierTo(120, 82, 108, 117)
          ..quadraticBezierTo(102, 157, 90, 142)
          ..lineTo(80, 94)
          ..quadraticBezierTo(45, 38, 83, 22),
        Colors.white,
      );
    } else if (id == 'hair') {
      oval(const Rect.fromLTWH(83, 49, 86, 100), skin);
      path(
        Path()
          ..moveTo(79, 104)
          ..quadraticBezierTo(48, 12, 123, 10)
          ..quadraticBezierTo(194, 13, 178, 108)
          ..lineTo(159, 60)
          ..lineTo(144, 72)
          ..lineTo(127, 50)
          ..lineTo(108, 71)
          ..lineTo(92, 65)
          ..close(),
        const Color(0xFF694933),
      );
    } else if (id == 'dust') {
      for (var i = 0; i < 20; i++)
        oval(
          Rect.fromCircle(
            center: Offset(42 + (i * 41) % 165, 30 + (i * 31) % 104),
            radius: 3 + (i % 4).toDouble(),
          ),
          const Color(0xFFA98D65),
        );
    } else if (id == 'breathe') {
      oval(const Rect.fromLTWH(44, 22, 80, 107), skin);
      oval(const Rect.fromLTWH(105, 70, 24, 20), skin);
      line(const Offset(105, 57), const Offset(110, 57), ink, 4);
      for (var i = 0; i < 3; i++) {
        final y = 68.0 + i * 21;
        line(Offset(203, y), Offset(146, y), blue, 5);
        line(Offset(146, y), Offset(158, y - 8), blue, 5);
      }
    } else if (id == 'made_in_a_factory') {
      path(
        Path()
          ..moveTo(38, 137)
          ..lineTo(38, 58)
          ..lineTo(91, 86)
          ..lineTo(91, 56)
          ..lineTo(145, 85)
          ..lineTo(145, 55)
          ..lineTo(205, 85)
          ..lineTo(205, 137)
          ..close(),
        blue,
      );
      box(const Rect.fromLTWH(48, 20, 21, 58), ink, 3);
      for (var i = 0; i < 4; i++)
        box(
          Rect.fromLTWH(51 + i * 38, 103, 22, 23),
          const Color(0xFFFFDC85),
          3,
        );
    } else if (id == 'spoon') {
      line(
        const Offset(112, 68),
        const Offset(152, 146),
        const Color(0xFF7F9CA6),
        13,
      );
      oval(const Rect.fromLTWH(75, 7, 59, 77), const Color(0xFFA7C1C8));
      oval(const Rect.fromLTWH(85, 17, 38, 52), const Color(0xFFDCE9EA));
    } else if (id == 'table') {
      for (final x in [55.0, 173.0])
        line(Offset(x, 71), Offset(x, 142), const Color(0xFF9C704B), 13);
      box(const Rect.fromLTWH(30, 44, 180, 40), const Color(0xFFC29360), 8);
    } else if (id == 'baby') {
      oval(const Rect.fromLTWH(63, 74, 117, 76), const Color(0xFFF2C879));
      oval(const Rect.fromLTWH(85, 14, 72, 74), skin);
      for (final x in [107.0, 136.0])
        oval(Rect.fromCircle(center: Offset(x, 49), radius: 4), ink);
      path(
        Path()
          ..moveTo(111, 68)
          ..quadraticBezierTo(124, 81, 137, 68),
        ink,
        width: 3,
      );
      line(const Offset(91, 101), const Offset(68, 80), skin, 14);
      line(const Offset(155, 101), const Offset(179, 78), skin, 14);
    } else if (id == 'optometrist') {
      for (final x in [76.0, 162.0]) {
        oval(
          Rect.fromCircle(center: Offset(x, 84), radius: 34),
          const Color(0xFFEAF5EE),
        );
        c.drawCircle(
          Offset(x, 84),
          34,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7,
        );
        oval(Rect.fromCircle(center: Offset(x, 84), radius: 12), blue);
      }
      line(const Offset(110, 80), const Offset(129, 80), ink, 7);
      line(const Offset(43, 75), const Offset(27, 62), ink, 7);
      line(const Offset(195, 75), const Offset(211, 62), ink, 7);
    } else {
      drawPicture(c, const Rect.fromLTWH(40, 0, 160, 160), id, girl: girl);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(BiologyArt old) => old.art != art || old.girl != girl;
}
