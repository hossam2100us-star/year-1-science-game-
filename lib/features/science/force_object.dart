import 'package:flutter/material.dart';

/// Small physical objects for actions that previously had abstract UI icons.
class ForceObject extends StatelessWidget {
  const ForceObject(this.art, {super.key, required this.size});
  final String art;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _ObjectPainter(art)),
  );
}

class _ObjectPainter extends CustomPainter {
  const _ObjectPainter(this.art);
  final String art;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 100, s.height / 100);
    final p = Paint();
    void box(Rect r, Color color, double radius) {
      p
        ..color = color
        ..style = PaintingStyle.fill;
      c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)), p);
    }

    if (art == 'switch') {
      box(const Rect.fromLTWH(20, 5, 60, 90), const Color(0xFFC6BCAF), 8);
      box(const Rect.fromLTWH(23, 5, 54, 86), const Color(0xFFFFFAE9), 7);
      box(const Rect.fromLTWH(34, 24, 32, 53), const Color(0xFF819897), 4);
      box(const Rect.fromLTWH(37, 25, 26, 39), const Color(0xFFDBE5DC), 3);
      p.color = const Color(0xFF9CA5A0);
      c.drawCircle(const Offset(50, 14), 2, p);
      c.drawCircle(const Offset(50, 84), 2, p);
    } else {
      box(const Rect.fromLTWH(13, 1, 74, 98), const Color(0xFF86A7BB), 12);
      box(const Rect.fromLTWH(43, 5, 14, 91), const Color(0xFF435F72), 2);
      for (var y = 10.0; y < 94; y += 8) {
        box(Rect.fromLTWH(39, y, 10, 5), const Color(0xFFD7C6A0), 1);
        box(Rect.fromLTWH(51, y + 3, 10, 5), const Color(0xFFE6D6B5), 1);
      }
      box(const Rect.fromLTWH(39, 23, 22, 19), const Color(0xFFB19668), 4);
      box(const Rect.fromLTWH(44, 28, 12, 30), const Color(0xFFE3CCA0), 4);
      box(const Rect.fromLTWH(47, 41, 6, 11), const Color(0xFF526E80), 2);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_ObjectPainter old) => old.art != art;
}
