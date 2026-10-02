import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Original illustrated creatures, with articulated parts drawn in scene space.
/// Texture is clipped to each silhouette and never paints an image background.
class ForceCreature {
  ForceCreature(this.c, this.phase);
  final Canvas c;
  final double phase;
  double get wave => math.sin(phase);
  static const outline = Color(0xFF60534C);
  static const skin = Color(0xFFF4C7A1);
  static const brown = Color(0xFFB88559);
  static const blue = Color(0xFF6EA7C3);
  static const white = Color(0xFFFFF4DC);

  void stroke(Path path, Color color, [double width = 1]) => c.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );

  void painted(
    Path path,
    Color color, {
    bool texture = true,
    double edge = .65,
  }) {
    final bounds = path.getBounds();
    c.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.45, -.6),
          radius: 1.25,
          colors: [
            Color.lerp(color, white, .24)!,
            color,
            Color.lerp(color, outline, .22)!,
          ],
          stops: const [0, .55, 1],
        ).createShader(bounds),
    );
    if (texture) {
      c.save();
      c.clipPath(path);
      // Fixed grain, so it cannot shimmer between frames.
      final paint = Paint()..color = white.withValues(alpha: .12);
      for (var i = 0; i < 95; i++) {
        final x = bounds.left + ((i * 47) % 97) / 97 * bounds.width;
        final y = bounds.top + ((i * 31) % 89) / 89 * bounds.height;
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: .6 + (i % 3) * .3,
            height: .5,
          ),
          paint,
        );
      }
      c.restore();
    }
    if (edge > 0) stroke(path, Color.lerp(color, outline, .4)!, edge);
  }

  void oval(
    double x,
    double y,
    double w,
    double h,
    Color color, {
    double edge = .5,
  }) => painted(Path()..addOval(Rect.fromLTWH(x, y, w, h)), color, edge: edge);

  void eye(double x, double y, {double radius = 3.5}) {
    oval(
      x - radius - 1,
      y - radius - 1,
      (radius + 1) * 2,
      (radius + 1) * 2,
      white,
      edge: .5,
    );
    oval(
      x - radius + .6,
      y - radius,
      radius * 1.8,
      radius * 2,
      const Color(0xFF5F4938),
      edge: 0,
    );
    oval(
      x - radius * .5,
      y - radius * .8,
      radius * .65,
      radius * .65,
      Colors.white,
      edge: 0,
    );
  }

  void limb(List<Offset> joints, Color color, double width) {
    final p = Path()..moveTo(joints.first.dx, joints.first.dy);
    for (final point in joints.skip(1)) {
      p.lineTo(point.dx, point.dy);
    }
    stroke(p, Color.lerp(color, outline, .2)!, width + 1);
    stroke(p, color, width);
    final highlight = Path()..moveTo(joints.first.dx - 1, joints.first.dy - 1);
    for (final point in joints.skip(1)) {
      highlight.lineTo(point.dx - 1, point.dy - 1);
    }
    stroke(highlight, Color.lerp(color, white, .2)!, width * .35);
  }

  void fish() {
    c.save();
    c.translate(29, 54);
    c.rotate(wave * .22);
    final tail = Path()
      ..moveTo(10, 0)
      ..cubicTo(-3, -10, -8, -22, -23, -27)
      ..quadraticBezierTo(-15, -7, -20, 0)
      ..quadraticBezierTo(-14, 10, -24, 26)
      ..cubicTo(-6, 23, -3, 9, 10, 0)
      ..close();
    painted(tail, const Color(0xFFED9554));
    for (var i = -3; i <= 3; i++)
      stroke(
        Path()
          ..moveTo(7, 0)
          ..quadraticBezierTo(-5, i * 4, -20, i * 7),
        white.withValues(alpha: .45),
        .8,
      );
    c.restore();
    painted(
      Path()
        ..moveTo(40, 36)
        ..quadraticBezierTo(40, 17, 50, 14)
        ..quadraticBezierTo(60, 9, 77, 33)
        ..close(),
      const Color(0xFFE9A54D),
    );
    for (var i = 0; i < 5; i++)
      stroke(
        Path()
          ..moveTo(44 + i * 5.0, 32)
          ..lineTo(48 + i * 4.0, 17.0 + i),
        white.withValues(alpha: .45),
        .7,
      );
    oval(27, 29, 79, 49, const Color(0xFFF7AF51));
    c.save();
    c.clipPath(Path()..addOval(const Rect.fromLTWH(30, 30, 73, 46)));
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 6; col++) {
        final x = 35 + col * 8.0 + (row.isOdd ? 4 : 0), y = 39 + row * 8.0;
        stroke(
          Path()
            ..moveTo(x, y)
            ..quadraticBezierTo(x + 7, y + 4, x, y + 8),
          const Color(0xFFCB8339).withValues(alpha: .36),
          .65,
        );
      }
    }
    c.restore();
    painted(
      Path()
        ..moveTo(65, 55)
        ..quadraticBezierTo(45, 62 + wave * 4, 53, 79 + wave * 3)
        ..quadraticBezierTo(72, 73, 73, 56)
        ..close(),
      const Color(0xFFEC9348),
    );
    stroke(
      Path()
        ..moveTo(65, 58)
        ..lineTo(57, 73 + wave * 3),
      white.withValues(alpha: .55),
    );
    stroke(
      Path()
        ..moveTo(82, 37)
        ..quadraticBezierTo(75, 55, 83, 65),
      const Color(0xFFCA843D),
      .8,
    );
    eye(94, 44, radius: 4.5);
    stroke(
      Path()
        ..moveTo(103, 56)
        ..quadraticBezierTo(108, 58, 110, 55),
      outline,
      1,
    );
  }

  double snakeY(double x) => 61 + math.sin(x / 15 - phase) * 10;
  void snake() {
    for (var x = 8.0; x < 98; x += 1.4) {
      final y = snakeY(x), next = snakeY(x + 2);
      final radius = (2 + (x / 98) * 7).clamp(2.0, 9.0);
      stroke(
        Path()
          ..moveTo(x, y)
          ..lineTo(x + 2, next),
        const Color(0xFF527746),
        radius * 2 + 1,
      );
      stroke(
        Path()
          ..moveTo(x, y - 1.5)
          ..lineTo(x + 2, next - 1.5),
        const Color(0xFF8AB967),
        radius * 1.6,
      );
      stroke(
        Path()
          ..moveTo(x, y + radius * .5)
          ..lineTo(x + 2, next + radius * .5),
        const Color(0xFFD7D493),
        radius * .4,
      );
    }
    for (var x = 23.0; x < 90; x += 7) {
      final y = snakeY(x);
      painted(
        Path()
          ..moveTo(x, y - 6)
          ..lineTo(x + 3, y - 3)
          ..lineTo(x, y)
          ..lineTo(x - 3, y - 3)
          ..close(),
        const Color(0xFF688F4F),
        edge: .25,
      );
    }
    final y = snakeY(96);
    painted(
      Path()
        ..moveTo(91, y - 9)
        ..cubicTo(94, y - 19, 113, y - 15, 115, y - 5)
        ..cubicTo(119, y + 5, 103, y + 9, 91, y + 5)
        ..close(),
      const Color(0xFF98BD74),
    );
    oval(100, y + 2, 14, 6, const Color(0xFFDDE1A3), edge: 0);
    eye(109, y - 7, radius: 3.4);
    stroke(
      Path()
        ..moveTo(107, y + 3)
        ..quadraticBezierTo(114, y + 5, 117, y + 1),
      outline,
      .8,
    );
    stroke(
      Path()
        ..moveTo(116, y + 2)
        ..lineTo(122, y + 3)
        ..lineTo(124, y),
      const Color(0xFFCE7D7A),
      .8,
    );
    stroke(
      Path()
        ..moveTo(122, y + 3)
        ..lineTo(124, y + 5),
      const Color(0xFFCE7D7A),
      .8,
    );
  }

  void bird() {
    painted(
      Path()
        ..moveTo(44, 54)
        ..quadraticBezierTo(21, 52, 12, 43)
        ..lineTo(21, 60)
        ..lineTo(13, 62)
        ..quadraticBezierTo(31, 71, 52, 64)
        ..close(),
      const Color(0xFF557EA2),
    );
    for (var i = 0; i < 3; i++)
      stroke(
        Path()
          ..moveTo(43, 59 + i * 2.0)
          ..lineTo(20 + i * 3.0, 49 + i * 6.0),
        const Color(0xFFAAC8D4),
        .7,
      );
    oval(35, 34, 61, 41, const Color(0xFF7CACBB));
    painted(
      Path()
        ..moveTo(72, 43)
        ..quadraticBezierTo(52, 55, 48, 66)
        ..quadraticBezierTo(68, 86, 89, 63)
        ..quadraticBezierTo(98, 55, 93, 43)
        ..close(),
      const Color(0xFFE6AD73),
    );
    c.save();
    c.translate(61, 49);
    c.rotate(-.35 - wave * .85);
    // Individual overlapping tapered flight feathers.
    for (var i = 0; i < 5; i++) {
      final reach = 29 - i * 3.0;
      painted(
        Path()
          ..moveTo(-2, -2)
          ..quadraticBezierTo(
            -reach - 6,
            -29 + i * 3.0,
            -reach - 5,
            -25 + i * 4.0,
          )
          ..quadraticBezierTo(-reach - 2, -4 + i * 2.0, -6, 9.0 - i)
          ..close(),
        Color.lerp(const Color(0xFF447894), const Color(0xFF8AB6C7), i / 7)!,
        edge: .7,
      );
    }
    oval(-21, -12, 25, 19, const Color(0xFF79AABA), edge: .3);
    c.restore();
    oval(77, 24, 30, 32, const Color(0xFF87B9C9));
    oval(90, 42, 13, 9, const Color(0xFFF1C497), edge: 0);
    eye(99, 34, radius: 3.7);
    painted(
      Path()
        ..moveTo(106, 38)
        ..quadraticBezierTo(111, 38, 117, 43)
        ..lineTo(106, 45)
        ..close(),
      const Color(0xFFDCA05D),
    );
    stroke(
      Path()
        ..moveTo(108, 42)
        ..lineTo(115, 43),
      outline,
      .65,
    );
    for (var i = 0; i < 3; i++)
      stroke(
        Path()
          ..moveTo(85 + i * 3.0, 26)
          ..lineTo(83 + i * 3.0, 21.0 + i),
        const Color(0xFF679CB1),
        .8,
      );
    limb(
      [const Offset(67, 73), const Offset(63, 79), const Offset(70, 79)],
      const Color(0xFFA38964),
      1.4,
    );
  }

  void kangaroo() {
    final bend = wave * 5;
    painted(
      Path()
        ..moveTo(56, 60)
        ..cubicTo(41, 78, 19, 88, 7, 83)
        ..cubicTo(27, 80, 40, 62, 49, 48)
        ..close(),
      brown,
    );
    limb(
      [
        const Offset(60, 60),
        Offset(79, 71 - bend),
        const Offset(70, 86),
        const Offset(96, 89),
      ],
      const Color(0xFF9C714F),
      7,
    );
    oval(42, 40, 36, 43, brown);
    oval(59, 39, 20, 38, const Color(0xFFE9CCA3), edge: .25);
    oval(39, 57, 27, 24, const Color(0xFFC09366));
    limb(
      [
        const Offset(53, 71),
        Offset(70, 74 - bend),
        const Offset(60, 88),
        const Offset(89, 89),
      ],
      brown,
      7,
    );
    oval(59, 85, 35, 7, brown);
    for (var i = 0; i < 3; i++)
      stroke(
        Path()
          ..moveTo(85 + i * 3.0, 86)
          ..lineTo(87 + i * 3.0, 90),
        outline,
        .55,
      );
    painted(
      Path()
        ..moveTo(61, 49)
        ..cubicTo(66, 29, 68, 21, 78, 22)
        ..quadraticBezierTo(88, 30, 78, 53)
        ..close(),
      brown,
    );
    limb(
      [const Offset(71, 43), Offset(79, 53 + bend), Offset(85, 58 + bend)],
      brown,
      4.5,
    );
    oval(80, 55 + bend, 10, 5, brown);
    c.save();
    c.translate(74, 23);
    c.rotate(-.16);
    oval(-5, -21, 9, 27, brown);
    oval(-2, -17, 3, 18, const Color(0xFFE8B79B), edge: 0);
    c.restore();
    c.save();
    c.translate(85, 23);
    c.rotate(.16);
    oval(-4, -21, 8, 25, const Color(0xFFA77653));
    oval(-2, -17, 3, 17, const Color(0xFFD5A991), edge: 0);
    c.restore();
    painted(
      Path()
        ..moveTo(72, 22)
        ..cubicTo(78, 15, 90, 18, 95, 25)
        ..quadraticBezierTo(105, 28, 106, 33)
        ..quadraticBezierTo(95, 43, 79, 38)
        ..quadraticBezierTo(70, 32, 72, 22)
        ..close(),
      const Color(0xFFC79A6E),
    );
    oval(87, 30, 17, 9, const Color(0xFFE0BF98), edge: .3);
    eye(88, 25, radius: 3.3);
    oval(101, 29, 7, 5, const Color(0xFF665649), edge: 0);
    stroke(
      Path()
        ..moveTo(98, 34)
        ..quadraticBezierTo(98, 37, 91, 37),
      outline,
      .7,
    );
    // Fur tufts follow the back and cheeks rather than a uniform dotted fill.
    for (var i = 0; i < 5; i++)
      stroke(
        Path()
          ..moveTo(45 + i % 2 * 2.0, 46 + i * 4.0)
          ..lineTo(43 + i % 2 * 2.0, 49 + i * 4.0),
        const Color(0xFFE1BA89),
        .8,
      );
    stroke(
      Path()
        ..moveTo(65, 63)
        ..quadraticBezierTo(73, 66, 77, 61),
      const Color(0xFFBC9A70),
      .7,
    );
  }

  void baby() {
    final back = -wave * 6, front = wave * 6;
    limb(
      [const Offset(38, 56), Offset(24 + back, 73), Offset(37 + back, 83)],
      const Color(0xFF668DAD),
      12,
    );
    oval(32 + back, 80, 14, 7, skin);
    limb(
      [const Offset(81, 51), Offset(87 + front, 70), Offset(100 + front, 79)],
      const Color(0xFFD6A17F),
      7,
    );
    oval(94 + front, 76, 15, 6, const Color(0xFFD6A17F));
    painted(
      Path()
        ..moveTo(31, 43)
        ..cubicTo(38, 30, 68, 33, 79, 39)
        ..quadraticBezierTo(94, 48, 79, 66)
        ..quadraticBezierTo(59, 72, 34, 65)
        ..quadraticBezierTo(23, 59, 31, 43)
        ..close(),
      blue,
    );
    stroke(
      Path()
        ..moveTo(39, 42)
        ..quadraticBezierTo(56, 37, 72, 42),
      const Color(0xFFC5E0E7),
      1.8,
    );
    limb(
      [const Offset(47, 61), Offset(36 + front, 77), Offset(50 + front, 86)],
      blue,
      12,
    );
    oval(45 + front, 82, 17, 8, skin);
    oval(38 + front, 65, 15, 17, blue);
    oval(67, 42, 18, 19, blue);
    limb(
      [const Offset(76, 55), Offset(70 + back, 73), Offset(85 + back, 84)],
      skin,
      8,
    );
    oval(78 + back, 80, 18, 7, skin);
    for (var i = 0; i < 3; i++)
      stroke(
        Path()
          ..moveTo(87 + back + i * 2.0, 81)
          ..lineTo(88 + back + i * 2.0, 85),
        const Color(0xFFCA9C7C),
        .5,
      );
    oval(78, 33, 15, 18, skin);
    painted(
      Path()
        ..moveTo(77, 14)
        ..cubicTo(92, 6, 107, 14, 109, 28)
        ..quadraticBezierTo(111, 34, 114, 36)
        ..quadraticBezierTo(111, 38, 109, 38)
        ..cubicTo(109, 51, 91, 53, 80, 43)
        ..quadraticBezierTo(70, 34, 77, 14)
        ..close(),
      skin,
    );
    oval(75, 29, 9, 12, skin);
    stroke(
      Path()
        ..moveTo(78, 32)
        ..quadraticBezierTo(83, 32, 79, 38),
      const Color(0xFFC68B70),
      .7,
    );
    painted(
      Path()
        ..moveTo(76, 30)
        ..cubicTo(66, 12, 88, 3, 103, 12)
        ..quadraticBezierTo(111, 16, 108, 23)
        ..quadraticBezierTo(103, 16, 96, 18)
        ..quadraticBezierTo(101, 11, 90, 16)
        ..quadraticBezierTo(83, 17, 83, 30)
        ..close(),
      const Color(0xFFA5734D),
    );
    for (var i = 0; i < 5; i++)
      stroke(
        Path()
          ..moveTo(76 + i * 4.0, 20)
          ..quadraticBezierTo(77 + i * 4.0, 11, 87 + i * 2.0, 13),
        const Color(0xFFD1A26F),
        .8,
      );
    eye(103, 29, radius: 3.8);
    stroke(
      Path()
        ..moveTo(98, 22)
        ..quadraticBezierTo(102, 20, 106, 22),
      const Color(0xFF966849),
      .7,
    );
    oval(99, 36, 9, 6, const Color(0xFFEBAC93), edge: 0);
    painted(
      Path()
        ..moveTo(99, 42)
        ..quadraticBezierTo(104, 44, 109, 40)
        ..quadraticBezierTo(106, 49, 101, 46)
        ..close(),
      const Color(0xFFA56458),
      edge: .3,
    );
    stroke(
      Path()
        ..moveTo(101, 42)
        ..lineTo(106, 42),
      white,
      1.2,
    );
    for (final p in [
      const Offset(41, 48),
      const Offset(56, 54),
      const Offset(65, 44),
    ]) {
      oval(p.dx, p.dy, 4, 4, const Color(0xFFE6DAB4), edge: 0);
      oval(p.dx - 1, p.dy - 1, 1.4, 1.4, const Color(0xFFE6DAB4), edge: 0);
      oval(p.dx + 3, p.dy - 1, 1.4, 1.4, const Color(0xFFE6DAB4), edge: 0);
    }
    stroke(
      Path()
        ..moveTo(50, 59)
        ..quadraticBezierTo(60, 64, 67, 59),
      const Color(0xFF5B93AB),
      .6,
    );
  }

  void draw(String art) {
    switch (art) {
      case 'fish':
        fish();
      case 'snake':
        snake();
      case 'bird':
        bird();
      case 'kangaroo':
        kangaroo();
      case 'baby':
        baby();
    }
  }
}
