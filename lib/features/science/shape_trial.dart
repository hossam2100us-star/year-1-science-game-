import 'package:flutter/material.dart';

import 'science_picture.dart';

class ShapeTrial extends StatelessWidget {
  const ShapeTrial({
    super.key,
    required this.material,
    required this.art,
    required this.action,
    required this.revealed,
  });
  final String material, art, action;
  final bool revealed;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 240,
    width: double.infinity,
    child: TweenAnimationBuilder<double>(
      key: ValueKey('$material-$action-$revealed'),
      tween: Tween(begin: 0, end: revealed ? 1 : 0),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 750),
      builder: (context, t, child) => CustomPaint(
        key: ValueKey('shape-result-$material-$action'),
        painter: _ShapePainter(material, action, t),
        child: ['stone', 'metal_spoon'].contains(material)
            ? Center(child: SciencePicture(art, height: 150))
            : null,
      ),
    ),
  );
}

class _ShapePainter extends CustomPainter {
  const _ShapePainter(this.material, this.action, this.t);
  final String material, action;
  final double t;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.translate(s.width / 2, s.height / 2);
    c.scale((s.width / 450).clamp(.4, 1.0));
    final p = Paint()..color = const Color(0xFFD3E1DC);
    c.drawOval(const Rect.fromLTWH(-180, 72, 360, 26), p);
    if (material == 'rubber_band') {
      p
        ..color = const Color(0xFFC89B61)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14;
      c.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 145 + 125 * t,
          height: 108 - 55 * t,
        ),
        p,
      );
    } else if (material == 'paper_straw') {
      p
        ..color = const Color(0xFF719B8C)
        ..strokeWidth = 22
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(-95, 60)
        ..lineTo(0, 0)
        ..lineTo(95 - 70 * t, -60 + 120 * t);
      c.drawPath(path, p);
      p
        ..color = const Color(0xFFEDE3C3)
        ..strokeWidth = 3;
      for (var i = 0; i < 5; i++) {
        final x = -85 + i * 15.0;
        c.drawLine(
          Offset(x, (-x) * .63 - 10),
          Offset(x + 8, (-x) * .63 + 8),
          p,
        );
      }
    } else if (material == 'sponge') {
      final w = 150 + 75 * t, h = 110 - 65 * t;
      p.color = const Color(0xFFE0B65E);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(16),
        ),
        p,
      );
      p.color = const Color(0xFFC89D4E);
      for (var i = 0; i < 4; i++) {
        for (var j = 0; j < 3; j++) {
          c.drawOval(
            Rect.fromCenter(
              center: Offset(-w * .32 + i * w * .21, -h * .28 + j * h * .27),
              width: 12,
              height: 9 - 4 * t,
            ),
            p,
          );
        }
      }
    } else if (material == 'dough') {
      p.color = const Color(0xFFD9BA93);
      if (action == 'Twist') {
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-120, -30, 240, 60),
            const Radius.circular(30),
          ),
          p,
        );
        p
          ..color = const Color(0xFFB4906B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        for (var i = 0; i < 5; i++) {
          final x = -86 + i * 42.0;
          c.drawPath(
            Path()
              ..moveTo(x, -26)
              ..cubicTo(x + 30 * t, -10, x - 30 * t, 10, x, 26),
            p,
          );
        }
      } else {
        c.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: 145 + 115 * t,
            height: 115 - 70 * t,
          ),
          p,
        );
      }
    }
    if (revealing && action == 'Squash') {
      p
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF678B82)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      c.drawLine(const Offset(0, -108), Offset(0, -83 + 18 * t), p);
      c.drawLine(Offset(-10, -96 + 18 * t), Offset(0, -83 + 18 * t), p);
      c.drawLine(Offset(10, -96 + 18 * t), Offset(0, -83 + 18 * t), p);
    }
    c.restore();
  }

  bool get revealing => t > 0;
  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.material != material || old.action != action || old.t != t;
}
