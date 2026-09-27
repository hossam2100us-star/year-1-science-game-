import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../content/lesson.dart';

/// An empty workbench: only placed pieces are painted, never a hidden full plant.
class PlantWorkshop extends StatefulWidget {
  const PlantWorkshop({
    super.key,
    required this.step,
    required this.placed,
    required this.onPlace,
  });
  final LessonStep step;
  final Set<String> placed;
  final ValueChanged<String> onPlace;
  @override
  State<PlantWorkshop> createState() => _PlantWorkshopState();
}

class _PlantWorkshopState extends State<PlantWorkshop>
    with SingleTickerProviderStateMixin {
  String? picked;
  String? animatedPart;
  bool retry = false;
  bool get challenge => widget.step.json['buildChallenge'] == true;
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  void attempt(String item, String slot) {
    if (widget.placed.contains(slot)) return;
    if (item != slot) {
      setState(() => retry = true);
      return;
    }
    place(item);
  }

  static const regions = {
    'flower': Rect.fromLTWH(.32, .01, .36, .29),
    'leaf': Rect.fromLTWH(.13, .30, .74, .23),
    'stem': Rect.fromLTWH(.40, .53, .20, .20),
    'roots': Rect.fromLTWH(.22, .76, .56, .23),
  };
  void place(String id) {
    if (widget.placed.contains(id)) return;
    widget.onPlace(id);
    setState(() {
      picked = null;
      retry = false;
      animatedPart = id;
    });
    if (!MediaQuery.disableAnimationsOf(context)) motion.forward(from: 0);
  }

  Widget tile(PictureItem item) => Container(
    width: 112,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: picked == item.id ? const Color(0xFFFFE4A0) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF72965F), width: 2),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 65,
          width: 90,
          child: CustomPaint(painter: WorkshopArt(item.id)),
        ),
        Text(item.label, style: const TextStyle(fontSize: 22)),
        if (widget.placed.contains(item.id)) const Icon(Icons.check_circle),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          for (final item in widget.step.options)
            Draggable<String>(
              data: item.id,
              maxSimultaneousDrags: widget.placed.contains(item.id) ? 0 : 1,
              feedback: Material(color: Colors.transparent, child: tile(item)),
              childWhenDragging: Opacity(opacity: .35, child: tile(item)),
              child: InkWell(
                key: ValueKey('workshop-piece-${item.id}'),
                onTap: widget.placed.contains(item.id)
                    ? null
                    : () => setState(() => picked = item.id),
                child: tile(item),
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (retry)
        Semantics(
          liveRegion: true,
          child: Text(widget.step.json['retryText'] ?? ''),
        ),
      if (challenge && widget.placed.length == 4)
        Text(
          widget.step.json['completionText'],
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: AspectRatio(
          aspectRatio: 1.4,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: motion,
                    builder: (_, _) => CustomPaint(
                      painter: WorkshopCanvas(
                        widget.placed,
                        pot: challenge,
                        active: animatedPart,
                        progress: motion.value,
                      ),
                    ),
                  ),
                ),
                for (final entry in regions.entries)
                  Positioned.fromRect(
                    rect: Rect.fromLTWH(
                      entry.value.left * box.maxWidth,
                      entry.value.top * box.maxHeight,
                      entry.value.width * box.maxWidth,
                      entry.value.height * box.maxHeight,
                    ),
                    child: DragTarget<String>(
                      onWillAcceptWithDetails: (d) =>
                          (challenge || d.data == entry.key) &&
                          !widget.placed.contains(entry.key),
                      onAcceptWithDetails: (d) => attempt(d.data, entry.key),
                      builder: (context, candidates, rejected) => InkWell(
                        key: ValueKey('workshop-slot-${entry.key}'),
                        onTap:
                            picked != null && (challenge || picked == entry.key)
                            ? () => attempt(picked!, entry.key)
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                candidates.isNotEmpty ||
                                    (!challenge && picked == entry.key)
                                ? const Color(0x44FFD870)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            border: widget.placed.contains(entry.key)
                                ? null
                                : Border.all(
                                    color: const Color(0x88709065),
                                    width: 2,
                                  ),
                          ),
                          child: widget.placed.contains(entry.key) || challenge
                              ? null
                              : Center(
                                  child: Text(
                                    widget.step.label(entry.key),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Color(0xFF385936),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class WorkshopCanvas extends CustomPainter {
  const WorkshopCanvas(
    this.placed, {
    this.pot = false,
    this.active,
    this.progress = 0,
  });
  final Set<String> placed;
  final bool pot;
  final String? active;
  final double progress;
  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(24)),
      Paint()..color = const Color(0xFFE9F5EE),
    );
    c.save();
    c.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(24)),
    );
    c.drawRect(
      Rect.fromLTWH(0, s.height * .74, s.width, s.height * .26),
      Paint()..color = const Color(0xFFC49363),
    );
    c.restore();
    if (pot) {
      final rim = Paint()
        ..color = const Color(0xFFB9643C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10;
      c.drawPath(
        Path()
          ..moveTo(s.width * .18, s.height * .74)
          ..lineTo(s.width * .25, s.height * .99)
          ..lineTo(s.width * .75, s.height * .99)
          ..lineTo(s.width * .82, s.height * .74),
        rim,
      );
      c.drawLine(
        Offset(s.width * .17, s.height * .74),
        Offset(s.width * .83, s.height * .74),
        rim,
      );
    }
    void part(String id, Rect rect) {
      if (!placed.contains(id)) return;
      c.save();
      c.translate(rect.left * s.width, rect.top * s.height);
      WorkshopArt(id)
          .paint(c, Size(rect.width * s.width, rect.height * s.height));
      c.restore();
    }

    part('roots', const Rect.fromLTWH(.25, .72, .5, .27));
    part('stem', const Rect.fromLTWH(.42, .22, .16, .54));
    part('leaf', const Rect.fromLTWH(.20, .30, .60, .23));
    part('flower', const Rect.fromLTWH(.32, .01, .36, .29));
    if (pot && active != null && progress > 0 && progress < 1) {
      final t = (progress * 2) % 1;
      final paint = Paint()..color = const Color(0xFF39A9E8);
      for (var i = 0; i < 5; i++) {
        final phase = (t + i / 5) % 1;
        final point = switch (active) {
          'roots' => Offset(
            s.width * (.25 + phase * .25),
            s.height * (.94 - phase * .18),
          ),
          'stem' => Offset(s.width * .5, s.height * (.73 - phase * .40)),
          'leaf' => Offset(
            s.width * (.12 + phase * .23),
            s.height * (.10 + phase * .27),
          ),
          _ => Offset(
            s.width * (.5 + (i - 2) * .035),
            s.height * (.16 + phase * .10),
          ),
        };
        paint.color = active == 'leaf'
            ? const Color(0xFFFFC842)
            : active == 'flower'
            ? const Color(0xFF89572D)
            : const Color(0xFF39A9E8);
        c.drawCircle(point, active == 'flower' ? 4 : 6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(WorkshopCanvas old) => true;
}

/// Original vector illustrations sized for children's picture cards.
class WorkshopArt extends CustomPainter {
  const WorkshopArt(this.id);
  final String id;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    final scale = math.min(s.width / 180, s.height / 140);
    c.translate((s.width - 180 * scale) / 2, (s.height - 140 * scale) / 2);
    c.scale(scale);
    void oval(Rect r, Color color) => c.drawOval(r, Paint()..color = color);
    void line(List<Offset> points, Color color, double width) {
      final p = Path()..moveTo(points.first.dx, points.first.dy);
      for (final pt in points.skip(1)) {
        p.lineTo(pt.dx, pt.dy);
      }
      c.drawPath(
        p,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    void box(Rect r, Color color) => c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(7)),
      Paint()..color = color,
    );
    const green = Color(0xFF419C52);
    if (id == 'toys') {
      box(const Rect.fromLTWH(18, 68, 94, 39), const Color(0xFFE96F55));
      box(const Rect.fromLTWH(38, 42, 53, 39), const Color(0xFFF4B64E));
      box(const Rect.fromLTWH(48, 49, 31, 23), const Color(0xFFA8DCEC));
      for (final x in [37.0, 93.0]) {
        oval(
          Rect.fromCircle(center: Offset(x, 110), radius: 15),
          const Color(0xFF34516D),
        );
        oval(Rect.fromCircle(center: Offset(x, 110), radius: 6), Colors.white);
      }
      oval(const Rect.fromLTWH(117, 67, 48, 48), const Color(0xFF6DB998));
      line(
        [const Offset(121, 79), const Offset(158, 102)],
        const Color(0xFFFFE19B),
        8,
      );
    } else if (id == 'paper') {
      box(const Rect.fromLTWH(38, 27, 102, 105), const Color(0xFF9FB9CA));
      box(const Rect.fromLTWH(30, 16, 102, 105), const Color(0xFFE0ECF5));
      box(const Rect.fromLTWH(22, 5, 102, 105), Colors.white);
      for (var y = 37.0; y < 94; y += 18) {
        line([Offset(38, y), Offset(107, y)], const Color(0xFF96BBD2), 3);
      }
      c.drawPath(
        Path()
          ..moveTo(98, 5)
          ..lineTo(124, 31)
          ..lineTo(98, 31)
          ..close(),
        Paint()..color = const Color(0xFFB6D4E7),
      );
    } else if (id == 'wind') {
      for (var i = 0; i < 3; i++) {
        final y = 35.0 + i * 35;
        c.drawPath(
          Path()
            ..moveTo(17, y)
            ..lineTo(122 - i * 12, y)
            ..cubicTo(169, y, 157, y - 33, 136, y - 18),
          Paint()
            ..color = const Color(0xFF68A9C1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..strokeCap = StrokeCap.round,
        );
      }
    } else if (id == 'dry_and_drooping') {
      box(const Rect.fromLTWH(63, 98, 61, 33), const Color(0xFFCE8958));
      line(
        [
          const Offset(94, 101),
          const Offset(90, 49),
          const Offset(113, 40),
          const Offset(130, 59),
        ],
        const Color(0xFF927340),
        7,
      );
      oval(const Rect.fromLTWH(120, 52, 19, 36), const Color(0xFFAC8343));
      line(
        [const Offset(91, 67), const Offset(65, 66), const Offset(54, 85)],
        const Color(0xFF927340),
        5,
      );
      oval(const Rect.fromLTWH(46, 79, 19, 33), const Color(0xFFAA7844));
      line(
        [const Offset(90, 84), const Offset(108, 85), const Offset(116, 97)],
        const Color(0xFF927340),
        4,
      );
    } else if (id == 'stem') {
      // Stretch to join the assembled flower, leaves and roots.
      c.restore();
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s.width * .40, 0, s.width * .20, s.height),
          const Radius.circular(10),
        ),
        Paint()..color = green,
      );
      return;
    } else if (id == 'roots') {
      line(
        [const Offset(90, 0), const Offset(90, 61), const Offset(76, 126)],
        const Color(0xFF956038),
        8,
      );
      for (final sign in [-1, 1]) {
        line(
          [
            const Offset(90, 32),
            Offset(90 + sign * 30, 66),
            Offset(90 + sign * 58, 103),
          ],
          const Color(0xFF956038),
          6,
        );
        line(
          [
            Offset(90 + sign * 30, 66),
            Offset(90 + sign * 49, 68),
            Offset(90 + sign * 71, 85),
          ],
          const Color(0xFF956038),
          4,
        );
      }
    } else if (id == 'leaf') {
      for (final sign in [-1, 1]) {
        final p = Path()
          ..moveTo(90, 114)
          ..quadraticBezierTo(90 + sign * 88, 99, 90 + sign * 73, 24)
          ..quadraticBezierTo(90 + sign * 8, 29, 90, 114);
        c.drawPath(
          p,
          Paint()..color = sign == -1 ? green : const Color(0xFF6BB958),
        );
        line(
          [const Offset(90, 114), Offset(90 + sign * 54, 48)],
          const Color(0xFFD3EAA1),
          3,
        );
      }
    } else if (id == 'flower') {
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        oval(
          Rect.fromCircle(
            center: Offset(90 + math.cos(a) * 34, 68 + math.sin(a) * 34),
            radius: 23,
          ),
          const Color(0xFFF39B96),
        );
      }
      oval(
        Rect.fromCircle(center: const Offset(90, 68), radius: 24),
        const Color(0xFFFFD265),
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(WorkshopArt old) => old.id != id;
}
