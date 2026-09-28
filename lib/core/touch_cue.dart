import 'package:flutter/material.dart';

/// A neutral affordance; never derives its appearance from the correct answer.
class TouchCue extends StatelessWidget {
  const TouchCue({super.key, this.size = 32});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF4),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF356D75), width: 2),
      ),
      child: Icon(
        Icons.touch_app_rounded,
        size: size * .48,
        color: const Color(0xFF254957),
      ),
    ),
  );
}

class SceneTouchLinks extends CustomPainter {
  const SceneTouchLinks(this.points);
  final List<(Offset, Offset)> points;
  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = const Color(0xFF356D75)
      ..strokeWidth = 2;
    for (final (button, anchor) in points) {
      canvas.drawLine(
        button,
        anchor,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 5,
      );
      canvas.drawLine(button, anchor, ink);
      canvas.drawCircle(anchor, 6, Paint()..color = Colors.white);
      canvas.drawCircle(anchor, 4, ink);
    }
  }

  @override
  bool shouldRepaint(SceneTouchLinks oldDelegate) => true;
}
