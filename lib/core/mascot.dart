import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';

enum OwlMood { idle, happy, thinking, cheering }

class ScientistOwl extends StatefulWidget {
  const ScientistOwl({
    super.key,
    this.gender = ChildGender.boy,
    this.mood = OwlMood.idle,
    this.size = 180,
  });
  final ChildGender gender;
  final OwlMood mood;
  final double size;
  @override
  State<ScientistOwl> createState() => _ScientistOwlState();
}

class _ScientistOwlState extends State<ScientistOwl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
    } else {
      _animation.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.gender == ChildGender.girl
        ? 'Zizi, your girl scientist guide'
        : 'Zizo, your boy scientist guide',
    image: true,
    child: AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -5 * _animation.value),
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: OwlPainter(widget.gender, widget.mood, _animation.value),
        ),
      ),
    ),
  );
}

class OwlPainter extends CustomPainter {
  OwlPainter(this.gender, this.mood, this.t);
  final ChildGender gender;
  final OwlMood mood;
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);
    final p = Paint()..color = const Color(0x1C174F7F);
    canvas.drawOval(const Rect.fromLTWH(41, 181, 119, 12), p);
    void oval(Rect rect, Color c) {
      canvas.drawOval(
        rect,
        p
          ..color = c
          ..style = PaintingStyle.fill,
      );
    }

    void circle(Offset center, double radius, Color c) {
      canvas.drawCircle(
        center,
        radius,
        p
          ..color = c
          ..style = PaintingStyle.fill,
      );
    }

    const brown = Color(0xFFC88A52),
        dark = Color(0xFF774F36),
        white = Color(0xFFFFF3D9);
    final accent = gender == ChildGender.girl
        ? const Color(0xFF794D91)
        : const Color(0xFF2170B5);
    oval(const Rect.fromLTWH(54, 161, 34, 24), const Color(0xFFE8A130));
    oval(const Rect.fromLTWH(112, 161, 34, 24), const Color(0xFFE8A130));
    oval(const Rect.fromLTWH(41, 71, 119, 107), brown);
    final left = Path()
      ..moveTo(55, 100)
      ..quadraticBezierTo(10, mood == OwlMood.cheering ? 48 : 137, 30, 153)
      ..quadraticBezierTo(57, 154, 70, 120);
    canvas.drawPath(left, p..color = brown);
    final right = Path()
      ..moveTo(145, 100)
      ..quadraticBezierTo(190, mood == OwlMood.cheering ? 48 : 137, 170, 153)
      ..quadraticBezierTo(143, 154, 130, 120);
    canvas.drawPath(right, p);
    final coat = Path()
      ..moveTo(62, 98)
      ..lineTo(137, 98)
      ..lineTo(151, 168)
      ..quadraticBezierTo(100, 189, 49, 168)
      ..close();
    canvas.drawPath(coat, p..color = Colors.white);
    canvas.drawPath(
      Path()
        ..moveTo(68, 100)
        ..lineTo(98, 133)
        ..lineTo(81, 144)
        ..lineTo(56, 110),
      p..color = const Color(0xFFD9E8EC),
    );
    canvas.drawPath(
      Path()
        ..moveTo(132, 100)
        ..lineTo(103, 133)
        ..lineTo(119, 144)
        ..lineTo(143, 110),
      p,
    );
    canvas.drawLine(
      const Offset(100, 132),
      const Offset(100, 173),
      p
        ..color = const Color(0xFFACCAD2)
        ..strokeWidth = 2,
    );
    circle(const Offset(109, 149), 2.5, accent);
    circle(const Offset(109, 161), 2.5, accent);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(120, 141, 19, 20),
        const Radius.circular(4),
      ),
      p..color = accent,
    );
    final head = Path()
      ..moveTo(45, 63)
      ..lineTo(38, 16)
      ..quadraticBezierTo(66, 19, 76, 32)
      ..quadraticBezierTo(104, 20, 126, 32)
      ..quadraticBezierTo(143, 17, 161, 19)
      ..lineTo(157, 67)
      ..quadraticBezierTo(165, 119, 101, 127)
      ..quadraticBezierTo(34, 120, 45, 63)
      ..close();
    canvas.drawPath(head, p..color = brown);
    oval(const Rect.fromLTWH(47, 41, 57, 70), white);
    oval(const Rect.fromLTWH(96, 41, 57, 70), white);
    for (final x in [76.0, 125.0]) {
      circle(Offset(x, 76), 27, accent);
      circle(Offset(x, 76), 22, Colors.white);
      if (mood == OwlMood.happy || mood == OwlMood.cheering) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(x, 80), width: 22, height: 20),
          math.pi,
          math.pi,
          false,
          p
            ..color = dark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
      } else {
        circle(Offset(x + (mood == OwlMood.thinking ? 4 : 0), 77), 9, dark);
        circle(Offset(x + 3, 73), 3, Colors.white);
      }
    }
    canvas.drawLine(
      const Offset(101, 74),
      const Offset(99, 74),
      p
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    final beak = Path()
      ..moveTo(91, 99)
      ..lineTo(110, 99)
      ..lineTo(100, 111)
      ..close();
    canvas.drawPath(
      beak,
      p
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFE8A130),
    );
    oval(const Rect.fromLTWH(56, 98, 16, 7), const Color(0xFFEDA88C));
    oval(const Rect.fromLTWH(132, 98, 16, 7), const Color(0xFFEDA88C));
    if (gender == ChildGender.girl) {
      for (var i = 0; i < 5; i++) {
        circle(
          Offset(143 + 8 * math.cos(i * 1.26), 32 + 8 * math.sin(i * 1.26)),
          5,
          accent,
        );
      }
      circle(const Offset(143, 32), 4, const Color(0xFFF9D46B));
    } else {
      final bow = Path()
        ..moveTo(99, 126)
        ..lineTo(85, 118)
        ..lineTo(85, 134)
        ..close()
        ..moveTo(102, 126)
        ..lineTo(116, 118)
        ..lineTo(116, 134)
        ..close();
      canvas.drawPath(bow, p..color = accent);
      circle(const Offset(100, 126), 4, accent);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OwlPainter old) =>
      old.gender != gender || old.mood != mood || old.t != t;
}

class ChildAvatar extends StatelessWidget {
  const ChildAvatar({super.key, required this.profile, this.size = 72});
  final ChildProfile profile;
  final double size;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox.square(
      dimension: size,
      child: profile.photo != null
          ? Image.memory(
              profile.photo!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
                  CustomPaint(painter: AnimalPainter(profile.avatar)),
            )
          : CustomPaint(painter: AnimalPainter(profile.avatar)),
    ),
  );
}

class AnimalPainter extends CustomPainter {
  AnimalPainter(this.kind);
  final int kind;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 100, s.height / 100);
    final p = Paint()
      ..color = [
        const Color(0xFFFFE7BF),
        const Color(0xFFDCF0E3),
        const Color(0xFFEAE0F4),
      ][kind];
    c.drawCircle(const Offset(50, 50), 50, p);
    final fur = [
      const Color(0xFFDB8645),
      const Color(0xFFFCF5E9),
      const Color(0xFFAF85C7),
    ][kind];
    p.color = fur;
    if (kind == 1) {
      c.drawOval(const Rect.fromLTWH(24, 6, 19, 52), p);
      c.drawOval(const Rect.fromLTWH(57, 6, 19, 52), p);
    } else {
      c.drawPath(
        Path()
          ..moveTo(17, 52)
          ..lineTo(16, 15)
          ..lineTo(46, 33)
          ..close(),
        p,
      );
      c.drawPath(
        Path()
          ..moveTo(83, 52)
          ..lineTo(84, 15)
          ..lineTo(54, 33)
          ..close(),
        p,
      );
    }
    c.drawOval(const Rect.fromLTWH(15, 28, 70, 59), p);
    p.color = const Color(0xFFFFF9EF);
    c.drawOval(const Rect.fromLTWH(25, 50, 50, 34), p);
    p.color = const Color(0xFF223D50);
    c.drawCircle(const Offset(35, 52), 4, p);
    c.drawCircle(const Offset(65, 52), 4, p);
    c.drawOval(const Rect.fromLTWH(45, 64, 10, 7), p);
    c.drawArc(
      const Rect.fromLTWH(41, 65, 18, 12),
      0,
      math.pi,
      false,
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    c.restore();
  }

  @override
  bool shouldRepaint(covariant AnimalPainter old) => kind != old.kind;
}
