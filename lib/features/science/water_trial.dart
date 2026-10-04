import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Source-defined water outcomes become visible only after a saved prediction
/// and a test. The cover is a material sample, not a bottle/shirt illustration.
class WaterTrial extends StatelessWidget {
  const WaterTrial({
    super.key,
    required this.material,
    required this.umbrella,
    required this.revealed,
    required this.leaks,
  });
  final String material;
  final bool umbrella, revealed, leaks;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 310,
    width: double.infinity,
    child: TweenAnimationBuilder<double>(
      key: ValueKey('$material-$revealed'),
      tween: Tween(begin: 0, end: revealed ? 1 : 0),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 1400),
      builder: (_, progress, _) => CustomPaint(
        key: const ValueKey('material-water-trial'),
        painter: _WaterPainter(material, umbrella, leaks, progress),
      ),
    ),
  );
}

class _WaterPainter extends CustomPainter {
  const _WaterPainter(this.material, this.umbrella, this.leaks, this.progress);
  final String material;
  final bool umbrella, leaks;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, 0);
    final scale = math.min(1.0, size.width / 330);
    canvas.scale(scale, 1);
    final p = Paint();
    p.color = const Color(0xFFCEE5DF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-155, 265, 310, 18),
        const Radius.circular(9),
      ),
      p,
    );
    final sample = material.contains('foil')
        ? const Color(0xFFBCC5CD)
        : material.contains('plastic')
        ? const Color(0xFF79C6C7)
        : material.contains('cloth')
        ? const Color(0xFFEAB8A6)
        : const Color(0xFFFFF5D9);
    Path cover;
    if (umbrella) {
      cover = Path()
        ..moveTo(-130, 130)
        ..quadraticBezierTo(0, -35, 130, 130)
        ..quadraticBezierTo(92, 106, 65, 134)
        ..quadraticBezierTo(32, 108, 0, 132)
        ..quadraticBezierTo(-32, 108, -65, 134)
        ..quadraticBezierTo(-96, 106, -130, 130)
        ..close();
      p
        ..color = const Color(0xFF866E56)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7;
      canvas.drawPath(
        Path()
          ..moveTo(0, 122)
          ..lineTo(0, 235)
          ..quadraticBezierTo(0, 266, 26, 246),
        p,
      );
    } else {
      p
        ..color = const Color(0xFFFEFDF7)
        ..style = PaintingStyle.fill;
      final cup = Path()
        ..moveTo(-92, 122)
        ..lineTo(-76, 260)
        ..quadraticBezierTo(0, 280, 76, 260)
        ..lineTo(92, 122)
        ..close();
      canvas.drawPath(cup, p);
      canvas.save();
      canvas.clipPath(cup);
      if (leaks && progress > 0) {
        p.color = const Color(0xFF73BEE0);
        canvas.drawRect(
          Rect.fromLTWH(-100, 267 - 85 * progress, 200, 90 * progress),
          p,
        );
      }
      canvas.restore();
      p
        ..color = const Color(0xFF6E8C95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawPath(cup, p);
      cover = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-105, 110, 210, 18),
            const Radius.circular(7),
          ),
        );
    }
    p
      ..style = PaintingStyle.fill
      ..color = sample;
    canvas.drawPath(cover, p);
    canvas.save();
    canvas.clipPath(cover);
    p
      ..color = const Color(0x55796A58)
      ..strokeWidth = 1;
    for (double x = -140; x < 150; x += 14) {
      canvas.drawLine(Offset(x, 15), Offset(x + 25, 142), p);
      if (material.contains('cloth')) {
        canvas.drawLine(Offset(-140, x + 140), Offset(140, x + 140), p);
      }
    }
    canvas.restore();
    p
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF708B8B)
      ..strokeWidth = 2;
    canvas.drawPath(cover, p);
    if (progress > 0) {
      p
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF499CC7);
      for (var i = 0; i < 9; i++) {
        final x = -100.0 + i * 25;
        final y = 18 + ((progress * 100 + i * 13) % 75);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 5, height: 12),
          p,
        );
      }
      if (leaks) {
        for (var i = 0; i < 5; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(
                -52.0 + i * 26,
                147 + ((progress * 100 + i * 17) % 70),
              ),
              width: 5,
              height: 13,
            ),
            p,
          );
        }
        if (umbrella) {
          canvas.drawOval(
            Rect.fromCenter(
              center: const Offset(0, 269),
              width: 160 * progress,
              height: 17,
            ),
            p,
          );
        }
      } else if (umbrella) {
        for (final x in [-135.0, 135.0]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(x, 160 + progress * 65),
              width: 7,
              height: 17,
            ),
            p,
          );
        }
      } else {
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(0, 110),
            width: 125 * progress,
            height: 9,
          ),
          p,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WaterPainter old) =>
      old.progress != progress ||
      old.material != material ||
      old.umbrella != umbrella ||
      old.leaks != leaks;
}
