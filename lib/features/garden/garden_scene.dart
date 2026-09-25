import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

const gardenInk = Color(0xFF25463E);
const gardenAsset = 'assets/images/garden-v2.png';

/// Bounds in the final original illustration; these are also the portrait crops.
const gardenBounds = <String, Rect>{
  'tree': Rect.fromLTWH(.015, .025, .225, .72),
  'cloud': Rect.fromLTWH(.46, .033, .23, .25),
  'car': Rect.fromLTWH(.609, .355, .24, .274),
  'chair': Rect.fromLTWH(.795, .557, .19, .382),
  'plant': Rect.fromLTWH(.213, .558, .14, .341),
  'cat': Rect.fromLTWH(.43, .542, .15, .366),
  'bird': Rect.fromLTWH(.253, .161, .083, .134),
};
Rect gardenCanvas(Size s) {
  final scale = math.min(s.width / 2, s.height);
  return Rect.fromCenter(
    center: Offset(s.width / 2, s.height / 2),
    width: scale * 2,
    height: scale,
  );
}

Map<String, Rect> gardenRects(
  Size s, {
  bool touch = false,
  Map<String, Rect> bounds = gardenBounds,
}) {
  final canvas = gardenCanvas(s);
  return bounds.map((id, r) {
    var rect = Rect.fromLTWH(
      canvas.left + r.left * canvas.width,
      canvas.top + r.top * canvas.height,
      r.width * canvas.width,
      r.height * canvas.height,
    );
    if (touch)
      rect = Rect.fromCenter(
        center: rect.center,
        width: math.max(64, rect.width),
        height: math.max(64, rect.height),
      );
    return MapEntry(id, rect);
  });
}

class GardenScene extends FlameGame {
  GardenScene({
    required this.onReady,
    this.asset = 'garden-v2.png',
    this.bounds = gardenBounds,
    this.guide = 'cat',
    this.difficulty = 1,
  });
  final String asset, guide;
  final int difficulty;
  final Map<String, Rect> bounds;
  Set<String> explained = {};
  final VoidCallback onReady;
  ui.Image? artwork;
  Set<String> found = {};
  bool tutorial = true, reducedMotion = false;
  double time = 0, celebration = 0;
  @override
  Future<void> onLoad() async {
    artwork = await images.load(asset);
    onReady();
  }

  @override
  Color backgroundColor() => const Color(0xFFF0F5DC);
  @override
  void update(double dt) {
    super.update(dt);
    if (!reducedMotion) time += dt;
    celebration = math.max(0, celebration - dt);
  }

  @override
  void render(Canvas c) {
    super.render(c);
    final s = size.toSize(), area = gardenCanvas(s), p = Paint();
    if (artwork == null) return;
    c.drawImageRect(
      artwork!,
      Rect.fromLTWH(
        0,
        0,
        artwork!.width.toDouble(),
        artwork!.height.toDouble(),
      ),
      area,
      p..filterQuality = FilterQuality.medium,
    );
    final rects = gardenRects(s, bounds: bounds);
    for (final id in found) {
      final at = rects[id]!.topRight + const Offset(-8, 12);
      c.drawCircle(at, 18, p..color = const Color(0xFFFFF8E7));
      _icon(
        c,
        explained.contains(id) ? Icons.menu_book_rounded : Icons.star_rounded,
        at - const Offset(14, 14),
        28,
        const Color(0xFFAA781B),
      );
    }
    if (tutorial &&
        difficulty < 3 &&
        (difficulty == 1 || found.isEmpty) &&
        found.length < bounds.length) {
      final target = !found.contains(guide)
          ? guide
          : bounds.keys.firstWhere((id) => !found.contains(id));
      final cat = rects[target]!;
      final at =
          cat.center +
          Offset(cat.width * .23, cat.height * .10 + math.sin(time * 3) * 6);
      c.drawCircle(
        cat.center,
        math.min(cat.width, cat.height) * .56 + (math.sin(time * 3) + 1) * 3,
        p
          ..color = const Color(0xFFFFF8E7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      p.style = PaintingStyle.fill;
      c.drawCircle(
        at + const Offset(24, 24),
        27,
        p..color = gardenInk.withValues(alpha: .8),
      );
      _icon(c, Icons.touch_app_rounded, at, 48, Colors.white);
    }
    if (celebration > 0 && !reducedMotion) {
      for (var i = 0; i < 20; i++) {
        final angle = i * math.pi / 10, distance = (1.2 - celebration) * 160;
        c.drawCircle(
          Offset(
            s.width * .5 + math.cos(angle) * distance,
            s.height * .55 + math.sin(angle) * distance,
          ),
          4,
          p
            ..color = [
              const Color(0xFFF0C35F),
              const Color(0xFF5E9F81),
              const Color(0xFF9382C0),
            ][i % 3],
        );
      }
    }
  }
}

void _icon(Canvas c, IconData icon, Offset at, double size, Color color) {
  final t = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: icon.fontFamily,
        fontSize: size,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  t.paint(c, at);
}

class GardenPortrait extends StatelessWidget {
  const GardenPortrait({
    super.key,
    required this.id,
    required this.image,
    this.size = 120,
    this.bounds = gardenBounds,
  });
  final String id;
  final ui.Image? image;
  final double size;
  final Map<String, Rect> bounds;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: CustomPaint(
      size: Size.square(size),
      painter: _Portrait(id, image, bounds),
    ),
  );
}

class _Portrait extends CustomPainter {
  _Portrait(this.id, this.image, this.bounds);
  final Map<String, Rect> bounds;
  final String id;
  final ui.Image? image;
  @override
  void paint(Canvas c, Size s) {
    if (image == null) return;
    final b = bounds[id]!;
    final src = Rect.fromLTWH(
      b.left * image!.width,
      b.top * image!.height,
      b.width * image!.width,
      b.height * image!.height,
    );
    final fit = applyBoxFit(BoxFit.contain, src.size, s);
    final dest = Alignment.center.inscribe(fit.destination, Offset.zero & s);
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(22)),
      Paint()..color = const Color(0xFFF0F5DC),
    );
    c.drawImageRect(
      image!,
      src,
      dest,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_Portrait old) => old.id != id || old.image != image;
}

class BasketPicture extends CustomPainter {
  BasketPicture(this.alive, {this.highlight = false});
  final bool alive, highlight;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    final body = Rect.fromLTWH(4, s.height * .38, s.width - 8, s.height * .57);
    c.drawArc(
      Rect.fromLTWH(s.width * .18, 2, s.width * .64, s.height * .80),
      math.pi,
      math.pi,
      false,
      p
        ..color = (alive ? const Color(0xFF4F9175) : const Color(0xFF648CAE))
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(12)),
      p
        ..style = PaintingStyle.fill
        ..color = (alive ? const Color(0xFFBFDCCA) : const Color(0xFFCDDFEC)),
    );
    for (var y = body.top + 10; y < body.bottom; y += 14)
      c.drawLine(
        Offset(body.left + 4, y),
        Offset(body.right - 4, y),
        p
          ..color = Colors.white.withValues(alpha: .4)
          ..strokeWidth = 2,
      );
    final badge = Rect.fromCenter(
      center: body.center,
      width: s.height * .44,
      height: s.height * .44,
    );
    c.drawCircle(
      badge.center,
      badge.width * .65,
      p..color = const Color(0xFFFFF8EC),
    );
    _icon(
      c,
      alive ? Icons.spa_rounded : Icons.toys_rounded,
      badge.topLeft,
      badge.width,
      alive ? const Color(0xFF468C66) : const Color(0xFF537C9D),
    );
    if (highlight)
      _icon(
        c,
        Icons.star_rounded,
        Offset(s.width - 25, 0),
        30,
        const Color(0xFFAF7A18),
      );
  }

  @override
  bool shouldRepaint(BasketPicture old) =>
      old.alive != alive || old.highlight != highlight;
}
