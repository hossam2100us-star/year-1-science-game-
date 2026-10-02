import 'package:flutter/material.dart';

/// Whole-object illustrations: no labels, answer markers or automatic zoom.
class MaterialContext extends StatelessWidget {
  const MaterialContext(this.scene, {super.key});
  final String scene;
  @override
  Widget build(BuildContext context) => SizedBox(
    key: ValueKey('material-context-$scene'),
    height: scene == 'pencil' ? 210 : 260,
    width: double.infinity,
    child: CustomPaint(painter: _ContextPainter(scene)),
  );
}

class _ContextPainter extends CustomPainter {
  const _ContextPainter(this.scene);
  final String scene;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.translate(size.width / 2, size.height / 2);
    final scale = (size.width / 620).clamp(.4, 1.0);
    c.scale(scale);
    final p = Paint();
    void box(Rect r, Color color, [double radius = 12]) {
      p
        ..color = color
        ..style = PaintingStyle.fill;
      c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)), p);
    }

    if (scene == 'pencil') {
      // A plain unpainted pencil, with no eraser/metal ring to confuse the task.
      box(
        const Rect.fromLTWH(-285, -82, 570, 164),
        const Color(0xFFFFFCF4),
        24,
      );
      c.save();
      c.rotate(-.12);
      box(const Rect.fromLTWH(-220, -25, 360, 50), const Color(0xFFCCA66F), 4);
      box(const Rect.fromLTWH(-220, -6, 360, 12), const Color(0xFFE7C897), 1);
      p.color = const Color(0xFFEBD4AA);
      c.drawPath(
        Path()
          ..moveTo(140, -25)
          ..lineTo(212, 0)
          ..lineTo(140, 25)
          ..close(),
        p,
      );
      p.color = const Color(0xFF435058);
      c.drawPath(
        Path()
          ..moveTo(193, -7)
          ..lineTo(215, 0)
          ..lineTo(193, 7)
          ..close(),
        p,
      );
      // An enlarged cross-section alongside the complete pencil.
      p.color = const Color(0xFFDFC08C);
      c.drawCircle(const Offset(-255, 0), 29, p);
      p.color = const Color(0xFF435058);
      c.drawCircle(const Offset(-255, 0), 8, p);
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      c.drawPath(
        Path()
          ..moveTo(215, 2)
          ..quadraticBezierTo(255, 12, 238, 38)
          ..quadraticBezierTo(204, 57, 244, 60),
        p,
      );
      c.restore();
    } else {
      box(
        const Rect.fromLTWH(-285, -124, 570, 248),
        const Color(0xFFF1E5D2),
        24,
      );
      box(
        const Rect.fromLTWH(-172, -110, 344, 204),
        const Color(0xFFADCED1),
        8,
      );
      p.color = const Color(0xFFEFD99A);
      c.drawCircle(const Offset(95, -62), 23, p);
      p.color = const Color(0xFF84AB83);
      c.drawOval(const Rect.fromLTWH(-167, 15, 334, 105), p);
      box(const Rect.fromLTWH(-114, -32, 10, 106), const Color(0xFFAB8159), 2);
      p.color = const Color(0xFF689581);
      c.drawCircle(const Offset(-107, -29), 39, p);
      p.color = const Color(0xFF95B195);
      c.drawCircle(const Offset(-78, -44), 28, p);
      p
        ..color = const Color(0xFF698597)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      c.drawPath(
        Path()
          ..moveTo(27, -59)
          ..quadraticBezierTo(35, -68, 44, -57)
          ..quadraticBezierTo(50, -66, 60, -60),
        p,
      );
      box(const Rect.fromLTWH(-180, -116, 360, 10), const Color(0xFFB18C63), 3);
      box(const Rect.fromLTWH(-180, 88, 360, 12), const Color(0xFFB18C63), 3);
      for (final x in [-180.0, -5.0, 170.0]) {
        box(Rect.fromLTWH(x, -110, 10, 206), const Color(0xFFFCF7E8), 2);
      }
      box(const Rect.fromLTWH(-175, -14, 350, 9), const Color(0xFFFCF7E8), 2);
      p
        ..color = const Color(0x5579A6B4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      c.drawLine(const Offset(75, 15), const Offset(106, 50), p);
      c.drawLine(const Offset(85, 15), const Offset(116, 50), p);
      box(const Rect.fromLTWH(-195, 100, 390, 14), const Color(0xFFC5A16F), 4);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_ContextPainter old) => old.scene != scene;
}
