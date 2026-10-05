import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../content/lesson.dart';
import 'science_art.dart';

class DiscoveryGame extends FlameGame with TapCallbacks, DragCallbacks {
  DiscoveryGame({
    required this.step,
    required this.onItem,
    required this.onPlace,
    required this.girl,
  });
  final LessonStep step;
  final void Function(String) onItem;
  final void Function(String, String) onPlace;
  final bool girl;
  Set<String> selected = {};
  Map<String, String> placements = {};
  bool reveal = false, reducedMotion = false;
  int frame = 0;
  double clock = 0, celebration = 0, wobble = 0;
  String? dragging;
  Offset? dragPoint;
  @override
  Color backgroundColor() => const Color(0xFFE8F5F1);
  Map<String, Rect> get itemRects {
    final result = <String, Rect>{};
    final options = step.options;
    final count = options.length;
    if (count == 0) return result;
    final cols = math.min(
      count,
      count > 6
          ? 4
          : count > 3
          ? 3
          : count,
    );
    final rows = (count / cols).ceil();
    final height = step.targets.isNotEmpty ? size.y - 90 : size.y;
    final cellW = size.x / cols, cellH = height / rows;
    final side = math.max(
      64.0,
      math.min(100.0, math.min(cellW - 12, cellH - 10)),
    );
    for (var i = 0; i < count; i++) {
      result[options[i].id] = Rect.fromLTWH(
        (i % cols + .5) * cellW - side / 2,
        (i ~/ cols + .5) * cellH - side / 2,
        side,
        side,
      );
    }
    if (step.kind == 'label-diagram') {
      return {options.first.id: Rect.fromLTWH(8, size.y * .33, 80, 80)};
    }
    return result;
  }

  Map<String, Rect> get targetRects {
    if (step.targets.isEmpty) return {};
    final result = <String, Rect>{};
    if (step.kind == 'label-diagram') {
      final n = step.targets.length;
      for (var i = 0; i < n; i++) {
        result[step.targets[i].id] = Rect.fromLTWH(
          size.x - 90,
          (size.y - 68 * n) / (n + 1) * (i + 1) + 68 * i,
          76,
          64,
        );
      }
    } else {
      final width = size.x / step.targets.length;
      for (var i = 0; i < step.targets.length; i++) {
        result[step.targets[i].id] = Rect.fromLTWH(
          i * width + 5,
          size.y - 77,
          width - 10,
          70,
        );
      }
    }
    return result;
  }

  String? hit(Offset point, Map<String, Rect> rects, {double tolerance = 0}) {
    final hits =
        rects.entries
            .where((r) => r.value.inflate(tolerance).contains(point))
            .toList()
          ..sort(
            (a, b) => (a.value.center - point).distance.compareTo(
              (b.value.center - point).distance,
            ),
          );
    return hits.firstOrNull?.key;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (reveal) return;
    final point = event.localPosition.toOffset();
    final target = hit(point, targetRects);
    if (target != null && selected.isNotEmpty) {
      onPlace(selected.first, target);
      return;
    }
    final item = hit(point, itemRects);
    if (item != null) onItem(item);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (reveal) return;
    dragPoint = event.localPosition.toOffset();
    dragging = hit(dragPoint!, itemRects);
    if (dragging != null) onItem(dragging!);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (dragPoint != null) dragPoint = dragPoint! + event.localDelta.toOffset();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (dragging != null && dragPoint != null) {
      final target = hit(dragPoint!, targetRects, tolerance: 22);
      if (target != null) onPlace(dragging!, target);
    }
    dragging = null;
    dragPoint = null;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    dragging = null;
    dragPoint = null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!reducedMotion) clock += dt;
    celebration = math.max(0, celebration - dt);
    wobble = math.max(0, wobble - dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final p = Paint();
    final w = size.x, h = size.y;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      p
        ..color = step.scene == 'garden'
            ? const Color(0xFFE6F1F7)
            : const Color(0xFFF1EBDD),
    );
    if (step.scene == 'garden') {
      canvas.drawRect(
        Rect.fromLTWH(0, h * .52, w, h * .48),
        p..color = const Color(0xFFCCE5BC),
      );
      canvas.drawOval(
        Rect.fromLTWH(w * .35, h * .55, w * .5, h * .6),
        p..color = const Color(0xFFEBDCBE),
      );
      canvas.drawCircle(
        Offset(w - 35, 29),
        18,
        p..color = const Color(0xFFF3D88E),
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, h * .72, w, h * .28),
        p..color = const Color(0xFFD9C5A6),
      );
    }
    if (step.kind == 'label-diagram') {
      final rect = Rect.fromLTWH(w * .32, 8, w * .32, h - 20);
      if (step.scene == 'eye') {
        drawPicture(canvas, rect, 'eye');
      } else if (step.scene == 'plant') {
        drawPicture(
          canvas,
          Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * .72),
          'plant',
        );
        drawPicture(
          canvas,
          Rect.fromLTWH(
            rect.left + rect.width * .25,
            rect.top + rect.height * .65,
            rect.width * .5,
            rect.height * .35,
          ),
          'roots',
        );
      } else {
        drawBody(canvas, rect, girl: girl);
      }
      for (final entry in targetRects.entries) {
        final point = step.scene == 'plant'
            ? switch (entry.key) {
                'roots' => const Offset(.5, .88),
                'stem' => const Offset(.5, .47),
                'leaf' => const Offset(.65, .29),
                _ => const Offset(.5, .17),
              }
            : bodyAnchor(entry.key);
        canvas.drawLine(
          entry.value.center,
          Offset(
            rect.left + point.dx * rect.width,
            rect.top + point.dy * rect.height,
          ),
          p
            ..color = const Color(0xFF516E7E)
            ..strokeWidth = 2,
        );
      }
    }
    if (step.focus != null) {
      drawPicture(
        canvas,
        Rect.fromLTWH(w * .43, 4, 70, 70),
        step.focus!,
        girl: girl,
      );
    }
    if (step.kind == 'predict-then-reveal' && frame > 0) {
      if (step.json['experiment'] == 'light') {
        drawPicture(
          canvas,
          Rect.fromLTWH(w * .15, 18, w * .25, h * .68),
          'plant',
        );
        drawPicture(
          canvas,
          Rect.fromLTWH(w * .60, 18, w * .25, h * .68),
          frame >= step.frames.length ? 'pale_and_floppy' : 'plant',
        );
        label(
          canvas,
          step.json['sceneLabels'][0],
          Offset(w * .12, h - 42),
          w * .32,
        );
        label(
          canvas,
          step.json['sceneLabels'][1],
          Offset(w * .56, h - 42),
          w * .35,
        );
      } else {
        drawPicture(
          canvas,
          Rect.fromLTWH(w * .35, 10, w * .3, h - 25),
          step.frames[(frame - 1).clamp(0, step.frames.length - 1)]['art'],
        );
      }
      return;
    }
    for (final entry in itemRects.entries) {
      final item = step.options.firstWhere((o) => o.id == entry.key),
          rect = entry.value;
      final active = selected.contains(item.id);
      if (active) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(18)),
          p
            ..style = PaintingStyle.fill
            ..color = const Color(0xFFEECF79),
        );
      }
      if (placements.containsKey(item.id)) {
        canvas.drawCircle(
          rect.topRight,
          12,
          p..color = const Color(0xFF2170B5),
        );
      }
      final dy = reducedMotion
          ? 0.0
          : math.sin(clock * 2 + step.options.indexOf(item)) *
                (active ? 3 : 1.2);
      final dx = wobble > 0 && !reducedMotion ? math.sin(clock * 28) * 3 : 0.0;
      drawPicture(
        canvas,
        rect.translate(dx, dy),
        item.art,
        motion: clock,
        girl: girl,
      );
      if (step.isOrder && active) {
        label(
          canvas,
          '${selected.toList().indexOf(item.id) + 1}',
          rect.topLeft,
          32,
          background: true,
        );
      }
    }
    for (final entry in targetRects.entries) {
      final index = step.targets.indexWhere((v) => v.id == entry.key);
      canvas.drawRRect(
        RRect.fromRectAndRadius(entry.value, const Radius.circular(16)),
        p..color = Colors.white.withValues(alpha: .95),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(entry.value, const Radius.circular(16)),
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF2170B5),
      );
      p.style = PaintingStyle.fill;
      label(
        canvas,
        step.kind == 'label-diagram' && !reveal
            ? '${index + 1}'
            : step.label(entry.key),
        entry.value.topLeft + const Offset(4, 15),
        entry.value.width - 8,
      );
    }
    if (dragging != null && dragPoint != null) {
      final item = step.options.firstWhere((e) => e.id == dragging);
      drawPicture(
        canvas,
        Rect.fromCenter(center: dragPoint!, width: 88, height: 88),
        item.art,
      );
    }
    if (celebration > 0) {
      for (var i = 0; i < 14; i++) {
        final a = i * math.pi / 7, r = (1.2 - celebration) * 90;
        canvas.drawCircle(
          Offset(w / 2 + r * math.cos(a), h / 2 + r * math.sin(a)),
          4,
          p
            ..color = i.isEven
                ? const Color(0xFFE8B34D)
                : const Color(0xFF3E9B5A),
        );
      }
    }
  }

  void label(
    Canvas c,
    String text,
    Offset at,
    double width, {
    bool background = false,
  }) {
    if (background) {
      c.drawCircle(
        at + const Offset(15, 14),
        16,
        Paint()..color = Colors.white,
      );
    }
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF174F7F),
          fontSize: 22,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: width);
    painter.paint(c, at);
  }
}
