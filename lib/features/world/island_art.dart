import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Original vector islands. No external illustrations or book artwork.
class IslandArt extends CustomPainter {
  IslandArt(this.kind, this.color);
  final int kind;
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 320, s.height / 150);
    final p = Paint();
    void oval(double x, double y, double w, double h, Color color) {
      c.drawOval(
        Rect.fromLTWH(x, y, w, h),
        p
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    void line(Offset a, Offset b, Color color, double width) {
      c.drawLine(
        a,
        b,
        p
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    oval(18, 100, 284, 42, const Color(0xFFDDEDF0));
    oval(42, 84, 236, 48, color.withValues(alpha: .25));
    oval(46, 76, 228, 42, color.withValues(alpha: .4));
    if (kind == 0) {
      for (final x in [96.0, 211.0]) {
        line(Offset(x, 93), Offset(x, 40), const Color(0xFF997044), 8);
        oval(x - 27, 20, 54, 55, color);
        oval(x - 35, 35, 70, 40, color);
      }
      oval(147, 78, 34, 28, const Color(0xFFDAA16D));
      oval(157, 62, 15, 24, const Color(0xFFDAA16D));
      oval(157, 58, 11, 12, const Color(0xFFDAA16D));
      c.drawCircle(
        const Offset(166, 76),
        2,
        p..color = const Color(0xFF223D50),
      );
      for (final x in [74.0, 134.0, 244.0]) {
        line(Offset(x, 98), Offset(x, 84), color, 3);
        c.drawCircle(Offset(x, 82), 5, p..color = const Color(0xFFF7CE67));
      }
    } else if (kind == 1) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(78, 55, 64, 53),
          const Radius.circular(8),
        ),
        p..color = color,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(145, 69, 68, 44),
          const Radius.circular(8),
        ),
        p..color = const Color(0xFFEACCA0),
      );
      oval(185, 34, 58, 58, const Color(0xFF6FA6BA));
      line(
        const Offset(87, 67),
        const Offset(123, 67),
        Colors.white.withValues(alpha: .5),
        4,
      );
      c.drawPath(
        Path()
          ..moveTo(134, 56)
          ..lineTo(160, 17)
          ..lineTo(186, 56)
          ..close(),
        p..color = const Color(0xFFB47BBA),
      );
    } else if (kind == 2) {
      final boat = Path()
        ..moveTo(92, 91)
        ..lineTo(221, 91)
        ..lineTo(202, 111)
        ..lineTo(115, 111)
        ..close();
      c.drawPath(boat, p..color = const Color(0xFF986744));
      line(
        const Offset(154, 88),
        const Offset(154, 18),
        const Color(0xFF986744),
        5,
      );
      c.drawPath(
        Path()
          ..moveTo(148, 23)
          ..lineTo(108, 83)
          ..lineTo(148, 83)
          ..close(),
        p..color = color,
      );
      c.drawPath(
        Path()
          ..moveTo(161, 35)
          ..lineTo(204, 83)
          ..lineTo(161, 83)
          ..close(),
        p..color = const Color(0xFFF4C464),
      );
      for (var i = 0; i < 3; i++)
        line(
          Offset(220.0, 35 + i * 14),
          Offset(258.0, 35 + i * 14),
          color.withValues(alpha: .5),
          3,
        );
    } else {
      oval(116, 28, 78, 78, color);
      oval(133, 41, 20, 14, const Color(0xFFA8BA8A));
      oval(162, 63, 20, 29, const Color(0xFFA8BA8A));
      c.save();
      c.translate(157, 68);
      c.rotate(-.35);
      c.drawOval(
        const Rect.fromLTWH(-65, -13, 130, 26),
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = const Color(0xFFEBC86D),
      );
      c.restore();
      for (var i = 0; i < 6; i++) {
        final x = 60 + i * 39.0, y = 20 + math.sin(i * 2) * 13;
        line(Offset(x - 4, y), Offset(x + 4, y), color, 2);
        line(Offset(x, y - 4), Offset(x, y + 4), color, 2);
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant IslandArt old) =>
      old.kind != kind || old.color != color;
}
