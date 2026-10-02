import 'package:flutter/material.dart';

import 'force_object.dart';
import 'force_creature.dart';
import 'science_picture.dart';

/// Illustrated cutouts with transparent silhouettes and articulated movement.
/// Phase articulates limbs, wings and tails independently of scene travel.
class ForcePicture extends StatelessWidget {
  const ForcePicture(this.art, {super.key, this.height = 115, this.phase = 0});
  final String art;
  final double height, phase;
  static const subjects = {
    'trolley',
    'ball',
    'fish',
    'snake',
    'bird',
    'kangaroo',
    'baby',
    'doorbell',
    'drawer',
    'swing',
    'sailboat',
    'cork',
    'balloon',
    'nail',
    'plastic_pot',
    'stone',
    'glass_marble',
    'orange',
    'peeled_orange',
    'fridge',
  };
  @override
  Widget build(BuildContext context) {
    if (art == 'switch' || art == 'zip') return ForceObject(art, size: height);
    if (!subjects.contains(art)) return SciencePicture(art, height: height);
    return SizedBox(
      width: height * 1.25,
      height: height,
      child: CustomPaint(painter: ForceIllustrator(art, phase)),
    );
  }
}

class ForceIllustrator extends CustomPainter {
  const ForceIllustrator(this.art, this.phase);
  final String art;
  final double phase;
  static const ink = Color(0xFF425968);
  static const cream = Color(0xFFFFF1D1);
  @override
  void paint(Canvas canvas, Size size) {
    final c = canvas;
    c.save();
    c.scale(size.width / 125, size.height / 100);
    if (const {'fish', 'snake', 'bird', 'kangaroo', 'baby'}.contains(art)) {
      ForceCreature(c, phase).draw(art);
      c.restore();
      return;
    }
    Paint surface(Color color, Rect bounds) {
      if (color.a < 1) return Paint()..color = color;
      return Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.5, -.65),
          radius: 1.35,
          colors: [
            Color.lerp(color, cream, .28)!,
            color,
            Color.lerp(color, ink, .23)!,
          ],
          stops: const [0, .5, 1],
        ).createShader(bounds);
    }

    void oval(double x, double y, double w, double h, Color color) {
      final bounds = Rect.fromLTWH(x, y, w, h);
      c.drawOval(bounds, surface(color, bounds));
    }

    void line(List<Offset> points, Color color, double width) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      c.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    void shape(Path path, Color color, {Color edge = ink, double width = .85}) {
      c.drawPath(path, surface(color, path.getBounds()));
      c.drawPath(
        path,
        Paint()
          ..color = Color.lerp(color, edge, .5)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeJoin = StrokeJoin.round,
      );
    }

    void box(
      double x,
      double y,
      double w,
      double h,
      Color color, [
      double r = 5,
    ]) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(r),
      );
      c.drawRRect(rect, surface(color, rect.outerRect));
      c.drawRRect(
        rect,
        Paint()
          ..color = ink.withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .75,
      );
    }

    void wheel(double x, double y) {
      oval(x - 9, y - 9, 18, 18, ink);
      oval(x - 6, y - 6, 12, 12, const Color(0xFFB7C7CD));
      c.save();
      c.translate(x, y);
      c.rotate(phase);
      line([const Offset(-5, 0), const Offset(5, 0)], ink, 2);
      line([const Offset(0, -5), const Offset(0, 5)], ink, 2);
      c.restore();
      oval(x - 2, y - 2, 4, 4, cream);
    }

    switch (art) {
      case 'ball':
        c.save();
        c.translate(62.5, 52);
        c.rotate(phase);
        final ball = Rect.fromCircle(center: Offset.zero, radius: 32);
        c.drawCircle(
          Offset.zero,
          32,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-.4, -.5),
              colors: [Color(0xFFFFDC82), Color(0xFFF1A24D)],
            ).createShader(ball),
        );
        c.save();
        c.clipPath(Path()..addOval(ball));
        shape(
          Path()
            ..moveTo(-12, -34)
            ..quadraticBezierTo(26, 0, -12, 34)
            ..lineTo(8, 34)
            ..quadraticBezierTo(44, 0, 8, -34)
            ..close(),
          const Color(0xFF75B7C1),
          edge: const Color(0xFF75B7C1),
        );
        c.restore();
        oval(-19, -22, 15, 9, Colors.white.withValues(alpha: .55));
        c.restore();
      case 'trolley':
        wheel(42, 83);
        wheel(96, 83);
        line(
          [
            const Offset(14, 18),
            const Offset(26, 18),
            const Offset(40, 71),
            const Offset(103, 71),
          ],
          ink,
          4,
        );
        shape(
          Path()
            ..moveTo(31, 29)
            ..lineTo(114, 29)
            ..lineTo(105, 61)
            ..lineTo(39, 61)
            ..close(),
          const Color(0xFFBDDEDE),
        );
        for (var x = 45.0; x < 108; x += 12) {
          line([Offset(x, 31), Offset(x - 2, 59)], const Color(0xFF789DA5), 2);
        }
        line(
          [const Offset(36, 44), const Offset(109, 44)],
          const Color(0xFF789DA5),
          2,
        );
        line(
          [const Offset(11, 17), const Offset(26, 17)],
          const Color(0xFFE48A70),
          7,
        );
        line(
          [
            const Offset(31, 29),
            const Offset(49, 21),
            const Offset(119, 21),
            const Offset(114, 29),
          ],
          const Color(0xFF7D969F),
          2,
        );
        line(
          [const Offset(39, 62), const Offset(106, 62)],
          const Color(0xFFC8D9D9),
          1.5,
        );
      case 'doorbell':
        box(37, 9, 51, 83, const Color(0xFFB8C9C4), 12);
        box(42, 13, 41, 74, const Color(0xFFE8EADD), 9);
        oval(46, 34, 33, 33, const Color(0xFFC37765));
        oval(48, 33, 29, 29, const Color(0xFFF1A28A));
        oval(52, 36, 13, 6, const Color(0xFFFFCEB6));
        oval(60, 20, 4, 4, ink);
        oval(60, 77, 4, 4, ink);
      case 'drawer':
        box(15, 21, 95, 65, const Color(0xFFB99069));
        box(22, 28, 81, 44, const Color(0xFF765C48));
        shape(
          Path()
            ..moveTo(23, 44)
            ..lineTo(98, 44)
            ..lineTo(109, 70)
            ..lineTo(12, 70)
            ..close(),
          const Color(0xFFE2B787),
        );
        box(12, 63, 97, 28, const Color(0xFFC99B70), 3);
        box(51, 72, 22, 7, const Color(0xFF82614A), 3);
        for (var y = 68.0; y < 89; y += 5) {
          c.drawPath(
            Path()
              ..moveTo(18, y)
              ..cubicTo(41, y - 2, 70, y + 2, 102, y),
            Paint()
              ..color = const Color(0xFF966D49).withValues(alpha: .28)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .7,
          );
        }
      case 'swing':
        line(
          [const Offset(12, 91), const Offset(32, 12), const Offset(48, 91)],
          const Color(0xFFB18A62),
          6,
        );
        line(
          [const Offset(78, 91), const Offset(94, 12), const Offset(113, 91)],
          const Color(0xFFB18A62),
          6,
        );
        line(
          [const Offset(29, 13), const Offset(97, 13)],
          const Color(0xFF668F83),
          7,
        );
        line(
          [const Offset(46, 15), const Offset(46, 70)],
          const Color(0xFF9E805D),
          2.5,
        );
        line(
          [const Offset(80, 15), const Offset(80, 70)],
          const Color(0xFF9E805D),
          2.5,
        );
        box(39, 69, 48, 8, const Color(0xFFBF9365), 3);
      case 'sailboat':
        line(
          [const Offset(63, 10), const Offset(63, 75)],
          const Color(0xFFAC825D),
          3,
        );
        shape(
          Path()
            ..moveTo(58, 15)
            ..lineTo(58, 62)
            ..lineTo(21, 62)
            ..close(),
          cream,
        );
        shape(
          Path()
            ..moveTo(69, 25)
            ..lineTo(98, 62)
            ..lineTo(69, 62)
            ..close(),
          const Color(0xFFF0B891),
        );
        shape(
          Path()
            ..moveTo(14, 73)
            ..lineTo(112, 73)
            ..quadraticBezierTo(99, 92, 85, 92)
            ..lineTo(38, 92)
            ..quadraticBezierTo(24, 88, 14, 73),
          const Color(0xFF6599AF),
        );
        line([const Offset(24, 80), const Offset(104, 80)], cream, 3);
        shape(
          Path()
            ..moveTo(64, 10)
            ..lineTo(83, 14)
            ..lineTo(64, 20)
            ..close(),
          const Color(0xFFE4967D),
        );
      case 'balloon':
        c.drawPath(
          Path()
            ..moveTo(65, 72)
            ..cubicTo(46, 84, 81, 84, 61, 98),
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        c.drawOval(
          const Rect.fromLTWH(35, 5, 59, 67),
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-.35, -.5),
              colors: [Color(0xFFFFC5AE), Color(0xFFE48680)],
            ).createShader(const Rect.fromLTWH(35, 5, 59, 67)),
        );
        shape(
          Path()
            ..moveTo(63, 68)
            ..lineTo(58, 75)
            ..lineTo(69, 75)
            ..close(),
          const Color(0xFFE48680),
        );
        oval(45, 16, 12, 23, Colors.white.withValues(alpha: .5));
      case 'nail':
        c.save();
        c.translate(62, 50);
        c.rotate(.6);
        shape(
          Path()
            ..moveTo(-4, -34)
            ..lineTo(4, -34)
            ..lineTo(3, 28)
            ..lineTo(0, 42)
            ..lineTo(-4, 28)
            ..close(),
          const Color(0xFFACBEC4),
        );
        box(-15, -38, 30, 7, const Color(0xFFD8E2E2), 3);
        c.restore();
      case 'cork':
        box(37, 26, 51, 58, const Color(0xFFC79D67), 8);
        oval(37, 18, 51, 23, const Color(0xFFE2C28E));
        for (final point in [
          const Offset(46, 48),
          const Offset(67, 55),
          const Offset(54, 73),
          const Offset(77, 68),
          const Offset(56, 29),
          const Offset(75, 27),
        ]) {
          oval(point.dx, point.dy, 4, 3, const Color(0xFF9C744A));
        }
      case 'plastic_pot':
        shape(
          Path()
            ..moveTo(28, 32)
            ..lineTo(98, 32)
            ..lineTo(88, 87)
            ..lineTo(39, 87)
            ..close(),
          const Color(0xFF82B5AD),
        );
        oval(25, 22, 76, 23, const Color(0xFFADCFC1));
        oval(33, 26, 60, 13, const Color(0xFF548B82));
        line(
          [const Offset(41, 47), const Offset(47, 77)],
          const Color(0xFFC2E0D1),
          4,
        );
      case 'stone':
        shape(
          Path()
            ..moveTo(17, 75)
            ..lineTo(27, 48)
            ..lineTo(53, 27)
            ..lineTo(88, 33)
            ..lineTo(111, 64)
            ..lineTo(99, 84)
            ..lineTo(43, 90)
            ..close(),
          const Color(0xFF91A29D),
        );
        shape(
          Path()
            ..moveTo(27, 48)
            ..lineTo(53, 27)
            ..lineTo(88, 33)
            ..lineTo(66, 62)
            ..close(),
          const Color(0xFFBAC5BA),
          edge: const Color(0xFFBAC5BA),
        );
        line(
          [const Offset(66, 62), const Offset(95, 72)],
          const Color(0xFF6C8381),
          2,
        );
      case 'glass_marble':
        c.drawCircle(
          const Offset(63, 51),
          30,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-.4, -.4),
              colors: [Color(0xFFE2F4EB), Color(0xFF75ABBB)],
            ).createShader(const Rect.fromLTWH(33, 21, 60, 60)),
        );
        c.save();
        c.clipPath(Path()..addOval(const Rect.fromLTWH(33, 21, 60, 60)));
        shape(
          Path()
            ..moveTo(40, 23)
            ..cubicTo(102, 33, 23, 62, 88, 78)
            ..cubicTo(35, 52, 103, 48, 40, 23),
          const Color(0xFFDCB98B),
          edge: const Color(0xFFDCB98B),
        );
        c.restore();
        oval(45, 30, 13, 8, Colors.white.withValues(alpha: .8));
      case 'orange':
      case 'peeled_orange':
        c.drawCircle(
          const Offset(63, 56),
          33,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-.4, -.4),
              colors: [Color(0xFFFFD388), Color(0xFFE7994D)],
            ).createShader(const Rect.fromLTWH(30, 23, 66, 66)),
        );
        if (art == 'orange') {
          shape(
            Path()
              ..moveTo(63, 25)
              ..quadraticBezierTo(75, 0, 95, 13)
              ..quadraticBezierTo(85, 29, 63, 25),
            const Color(0xFF7EAA70),
          );
          for (var x = 42.0; x < 87; x += 11) {
            oval(x, 49 + (x % 7), 2, 3, const Color(0xFFE9A559));
          }
        } else {
          // A whole peeled fruit with curved segment membranes, not a slice.
          for (final bend in [-34.0, -17.0, 0.0, 17.0, 34.0]) {
            c.drawPath(
              Path()
                ..moveTo(63, 24)
                ..cubicTo(63 + bend, 32, 63 + bend, 79, 63, 88),
              Paint()
                ..color = cream
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2,
            );
          }
          oval(57, 23, 12, 7, cream);
        }
      case 'fridge':
        box(33, 5, 59, 89, const Color(0xFFBDDBD9), 8);
        box(37, 9, 51, 28, const Color(0xFFE7EEDC), 5);
        box(37, 40, 51, 49, const Color(0xFFE7EEDC), 5);
        line([const Offset(45, 20), const Offset(45, 29)], ink, 3);
        line([const Offset(45, 49), const Offset(45, 62)], ink, 3);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(ForceIllustrator old) =>
      old.art != art || old.phase != phase;
}
