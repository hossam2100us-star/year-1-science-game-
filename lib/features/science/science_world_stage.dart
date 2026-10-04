import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/touch_cue.dart';
import 'science_picture.dart';

/// Story settings and one-at-a-time discoveries. This presentation reads only
/// the learner's saved choices; the answer values remain in the question engine.
class ScienceWorldStage extends StatefulWidget {
  const ScienceWorldStage({
    super.key,
    required this.step,
    required this.selected,
    required this.placements,
    required this.done,
    required this.onItem,
    required this.onPlace,
    this.reviewItems = const {},
    this.onSpeak,
    this.onSound,
    this.onOrder,
    this.onOrderPlacements,
  });
  final LessonStep step;
  final Set<String> selected, reviewItems;
  final Map<String, String> placements;
  final bool done;
  final ValueChanged<String> onItem;
  final void Function(String, String) onPlace;
  final ValueChanged<String>? onSpeak;
  final void Function(String, double)? onSound;
  final ValueChanged<List<String>>? onOrder;
  final ValueChanged<Map<String, String>>? onOrderPlacements;

  @override
  State<ScienceWorldStage> createState() => _ScienceWorldStageState();
}

class _ScienceWorldStageState extends State<ScienceWorldStage> {
  int index = 0;
  LessonStep get step => widget.step;
  bool get discovering => step.kind == 'explore';
  bool get guided => discovering || step.isMapping;
  PictureItem get current => step.options[index];
  List<PictureItem> get choiceOrder {
    final order = step.json['choiceOrder'];
    final byId = {for (final item in step.options) item.id: item};
    if (order is! List ||
        order.length != byId.length ||
        order.toSet().length != byId.length ||
        order.any((id) => !byId.containsKey(id))) {
      return step.options;
    }
    return [for (final id in order) byId[id]!];
  }

  String? get focus => step.json['quizContext'] is Map
      ? step.json['quizContext']['art'] as String?
      : step.focus;
  String get setting =>
      step.json['quizContext']?['setting'] as String? ??
      (step.id.startsWith('unit_07')
          ? 'electric'
          : step.id.startsWith('unit_08')
          ? 'earth'
          : 'space');
  int get row => ['workshop', 'electric', 'sound', 'rain'].contains(setting)
      ? 0
      : setting == 'space'
      ? 2
      : 1;
  String get discoveryInstruction => step.id.startsWith('unit_07')
      ? 'Touch the hand. Listen to this safety rule.'
      : step.id.startsWith('unit_09')
      ? 'Touch the hand. Explore this space model.'
      : 'Touch the hand. Explore this water place.';
  String get nextLabel => !discovering
      ? 'Next discovery'
      : step.id.startsWith('unit_07')
      ? 'Next rule'
      : step.id.startsWith('unit_09')
      ? 'Next model'
      : 'Next place';

  @override
  void initState() {
    super.initState();
    resume();
  }

  void resume() {
    if (!guided || step.options.isEmpty) {
      index = 0;
      return;
    }
    final revisit = step.options.indexWhere(
      (item) => widget.reviewItems.contains(item.id),
    );
    final pending = step.options.indexWhere(
      (item) => discovering
          ? !widget.selected.contains(item.id)
          : !widget.placements.containsKey(item.id),
    );
    index = revisit >= 0 ? revisit : (pending >= 0 ? pending : 0);
  }

  @override
  void didUpdateWidget(ScienceWorldStage old) {
    super.didUpdateWidget(old);
    if (old.step.id != step.id ||
        old.reviewItems.length != widget.reviewItems.length ||
        old.reviewItems.any((id) => !widget.reviewItems.contains(id))) {
      resume();
    }
  }

  void move(int next) {
    if (next < 0 || next >= step.options.length) return;
    setState(() => index = next);
    // Navigation is speech only: it never selects or places an answer.
    widget.onSpeak?.call(current.label);
  }

  String get discoverySpeech =>
      step.json['senseDescriptions']?[current.id] as String? ?? current.label;
  void discover() {
    if (!widget.done && !widget.selected.contains(current.id)) {
      widget.onItem(current.id);
    } else {
      widget.onSpeak?.call(discoverySpeech);
    }
  }

  Widget text(String value, {double size = 20}) => Text(
    value,
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: size, fontWeight: FontWeight.w700),
  );

  Widget cue(String id) => widget.reviewItems.contains(id)
      ? const Icon(
          Icons.help_outline_rounded,
          size: 28,
          color: Color(0xFF826542),
        )
      : const TouchCue();

  Widget environment(Widget child, {double minimumHeight = 180}) => ClipRRect(
    key: const ValueKey('science-world-scene'),
    borderRadius: BorderRadius.circular(26),
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: minimumHeight),
      child: Stack(
        children: [
          Positioned.fill(child: ScienceWorldBackdrop(row: row)),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    ),
  );

  Widget focusScene() => environment(
    Center(
      child: focus != null && SciencePicture.has(focus!)
          ? SciencePicture(focus!, height: 150)
          : const SizedBox(height: 68, width: double.infinity),
    ),
    minimumHeight: focus == null ? 100 : 180,
  );

  Widget navigation() => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('science-world-previous'),
          tooltip: discovering ? 'Previous place' : 'Previous discovery',
          onPressed: index == 0 ? null : () => move(index - 1),
          style: IconButton.styleFrom(minimumSize: const Size(48, 52)),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        Expanded(
          child: TextButton(
            key: const ValueKey('science-world-next'),
            onPressed:
                index == step.options.length - 1 ||
                    (!discovering && !widget.placements.containsKey(current.id))
                ? null
                : () => move(index + 1),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 52),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              backgroundColor: const Color(0xFFE8EEE3),
            ),
            child: text(nextLabel, size: 18),
          ),
        ),
      ],
    ),
  );

  Widget guideHeader() => Row(
    children: [
      Expanded(
        child: Text(
          discovering
              ? 'Discoveries ${widget.selected.intersection(step.options.map((item) => item.id).toSet()).length} / ${step.options.length}'
              : 'Discovery ${index + 1} / ${step.options.length}',
          style: const TextStyle(fontSize: 17),
        ),
      ),
      IconButton(
        key: const ValueKey('science-world-listen'),
        tooltip: 'Listen again',
        onPressed: widget.onSpeak == null
            ? null
            : () => widget.onSpeak!(
                discovering ? discoverySpeech : current.label,
              ),
        icon: const Icon(Icons.volume_up_rounded),
      ),
    ],
  );

  Widget guidedScene() {
    final art = SciencePicture.has(current.art) ? current.art : focus;
    return environment(
      Center(
        child: InkWell(
          key: ValueKey('science-item-${current.id}'),
          borderRadius: BorderRadius.circular(24),
          onTap: discovering
              ? discover
              : widget.done
              ? () => widget.onSpeak?.call(current.label)
              : () => widget.onItem(current.id),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (art != null && SciencePicture.has(art))
                  SciencePicture(art, height: 150),
                const SizedBox(height: 12),
                text(current.label, size: 22),
                const SizedBox(height: 8),
                if (discovering || !widget.done) cue(current.id),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget target(PictureItem item, double width) => DragTarget<String>(
    onWillAcceptWithDetails: (details) =>
        !widget.done && details.data == current.id,
    onAcceptWithDetails: (details) => widget.onPlace(details.data, item.id),
    builder: (context, candidates, rejected) {
      final chosen = widget.placements[current.id] == item.id;
      return SizedBox(
        width: width,
        child: OutlinedButton(
          key: ValueKey('science-target-${item.id}'),
          onPressed: widget.done
              ? null
              : () => widget.onPlace(current.id, item.id),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 64),
            padding: const EdgeInsets.all(12),
            backgroundColor: chosen
                ? const Color(0xFFDDEBE6)
                : const Color(0xFFFBF8EB),
            side: BorderSide(
              color: chosen || candidates.isNotEmpty
                  ? const Color(0xFF477B70)
                  : const Color(0xFFB5BEB1),
              width: chosen || candidates.isNotEmpty ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (SciencePicture.has(item.art))
                SciencePicture(item.art, height: 60),
              text(item.label, size: 18),
            ],
          ),
        ),
      );
    },
  );

  Widget mapping() => Column(
    children: [
      guideHeader(),
      Draggable<String>(
        data: current.id,
        maxSimultaneousDrags: widget.done ? 0 : 1,
        onDragStarted: widget.done ? null : () => widget.onItem(current.id),
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(width: 170, child: text(current.label)),
        ),
        child: guidedScene(),
      ),
      const SizedBox(height: 12),
      text('Choose an answer for this discovery.', size: 18),
      if (widget.placements.containsKey(current.id))
        Padding(
          key: const ValueKey('science-world-saved-choice'),
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Your choice: ${step.label(widget.placements[current.id]!)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, box) => Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (final item in step.targets)
              target(item, box.maxWidth < 520 ? box.maxWidth : 230),
          ],
        ),
      ),
      navigation(),
    ],
  );

  Widget exploration() => Column(
    children: [
      guideHeader(),
      text(discoveryInstruction, size: 18),
      const SizedBox(height: 10),
      guidedScene(),
      navigation(),
    ],
  );

  Widget objectChoice(PictureItem item, double width) {
    final selected = widget.selected.contains(item.id);
    final number = step.isOrder && selected
        ? widget.selected.toList().indexOf(item.id) + 1
        : null;
    return SizedBox(
      width: width,
      child: InkWell(
        key: ValueKey('science-item-${item.id}'),
        onTap: widget.done
            ? () => widget.onSpeak?.call(item.label)
            : () => widget.onItem(item.id),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xCCE0EDE6) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: selected
                ? Border.all(color: const Color(0xFF477B70), width: 2)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (SciencePicture.has(item.art))
                SciencePicture(item.art, height: 70),
              text(item.label, size: 18),
              if (!widget.done) cue(item.id),
              if (number != null) text('$number', size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget choices() => LayoutBuilder(
    builder: (context, box) => environment(
      Wrap(
        spacing: 12,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: [
          for (final item in choiceOrder)
            objectChoice(
              item,
              box.maxWidth < 520 ? (box.maxWidth - 48) / 2 : 165,
            ),
        ],
      ),
    ),
  );

  Widget orderPath() => Padding(
    key: const ValueKey('science-world-order-path'),
    padding: const EdgeInsets.only(top: 12),
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < widget.selected.length; i++)
          OutlinedButton(
            onPressed: widget.done
                ? null
                : () => widget.onItem(widget.selected.elementAt(i)),
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
            child: Text(
              '${i + 1}. ${step.label(widget.selected.elementAt(i))}',
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (discovering && step.options.isNotEmpty) return exploration();
    if (step.isMapping && step.options.isNotEmpty) return mapping();
    return Column(
      children: [
        if (focus != null || step.json['quizContext'] != null) ...[
          focusScene(),
          const SizedBox(height: 12),
        ],
        choices(),
        if (step.isOrder && widget.selected.isNotEmpty) orderPath(),
      ],
    );
  }
}

/// Shared world background; the scene is only a setting, never an answer key.
class ScienceWorldBackdrop extends StatelessWidget {
  const ScienceWorldBackdrop({super.key, required this.row});
  final int row;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _WorldPainter(row));
}

class _WorldPainter extends CustomPainter {
  const _WorldPainter(this.row);
  final int row;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, h),
        row == 0
            ? [const Color(0xFFFFF6DF), const Color(0xFFEBE1C6)]
            : row == 1
            ? [const Color(0xFFE6F1EB), const Color(0xFFEFF1D9)]
            : [const Color(0xFFE5EAF8), const Color(0xFFF1E8F5)],
      );
    canvas.drawRect(Offset.zero & size, paint);
    paint.shader = null;
    if (row == 0) {
      // Empty room: no window, plug or appliance supplies an assessment answer.
      paint.color = const Color(0xFFE6D5B6);
      canvas.drawRect(Rect.fromLTWH(0, h * .73, w, h * .27), paint);
      paint.color = const Color(0xFFCBB991);
      canvas.drawRect(Rect.fromLTWH(0, h * .725, w, 5), paint);
      paint
        ..color = const Color(0x55BCAA89)
        ..strokeWidth = 1.5;
      for (var i = 0; i < 6; i++) {
        canvas.drawLine(
          Offset(w * i / 5, h),
          Offset(w * (.18 + i * .13), h * .74),
          paint,
        );
      }
      paint.color = const Color(0xFFCCB792);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .025, h * .30, w * .13, 8),
          const Radius.circular(4),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .82, h * .17, w * .15, 8),
          const Radius.circular(4),
        ),
        paint,
      );
      paint.color = const Color(0x3DB6B28B);
      canvas.drawOval(Rect.fromLTWH(w * .18, h * .84, w * .64, h * .10), paint);
      paint.color = const Color(0x55C9B88F);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .045, h * .045, w * .11, h * .13),
          const Radius.circular(12),
        ),
        paint,
      );
    } else if (row == 1) {
      paint.color = const Color(0xB5FFFFFF);
      canvas.drawOval(Rect.fromLTWH(w * .02, h * .08, w * .24, h * .06), paint);
      canvas.drawOval(Rect.fromLTWH(w * .74, h * .12, w * .18, h * .05), paint);
      paint.color = const Color(0xFFCFDEC1);
      canvas.drawPath(
        Path()
          ..moveTo(0, h * .70)
          ..quadraticBezierTo(w * .2, h * .50, w * .49, h * .71)
          ..quadraticBezierTo(w * .78, h * .54, w, h * .70)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        paint,
      );
      paint.color = const Color(0xFFAECBC6);
      canvas.drawPath(
        Path()
          ..moveTo(w, h * .81)
          ..quadraticBezierTo(w * .68, h * .78, w * .64, h)
          ..lineTo(w, h)
          ..close(),
        paint,
      );
      paint
        ..color = const Color(0x99EDF7EE)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(
        Path()
          ..moveTo(w * .79, h * .92)
          ..quadraticBezierTo(w * .88, h * .90, w * .97, h * .93),
        paint,
      );
      paint.color = const Color(0xFF9DBA93);
      for (var i = 0; i < 9; i++) {
        final x = w * (.02 + i * .055), y = h * (.87 + (i % 3) * .03);
        canvas.drawPath(
          Path()
            ..moveTo(x, y + 12)
            ..quadraticBezierTo(x - 6, y, x - 4, y - 2)
            ..moveTo(x, y + 12)
            ..quadraticBezierTo(x + 5, y + 2, x + 7, y),
          paint,
        );
      }
      paint.style = PaintingStyle.fill;
    } else {
      // Sparse gentle space wash, with clear centre for the whole model.
      paint.color = const Color(0xB3A9B6D1);
      for (final point in [
        const Offset(.08, .11),
        const Offset(.86, .08),
        const Offset(.12, .36),
        const Offset(.92, .43),
        const Offset(.66, .05),
      ]) {
        final centre = Offset(w * point.dx, h * point.dy);
        canvas.drawCircle(centre, 2.5, paint);
      }
      paint.color = const Color(0xFFD4CEDC);
      canvas.drawPath(
        Path()
          ..moveTo(0, h * .87)
          ..quadraticBezierTo(w * .25, h * .77, w * .51, h * .88)
          ..quadraticBezierTo(w * .72, h * .77, w, h * .85)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        paint,
      );
      paint.color = const Color(0xB3B9B3C7);
      canvas.drawOval(
        Rect.fromLTWH(w * .75, h * .90, w * .15, h * .035),
        paint,
      );
      canvas.drawOval(
        Rect.fromLTWH(w * .07, h * .94, w * .12, h * .025),
        paint,
      );
    }
    // Subtle pigment flecks keep all three settings calm and light.
    paint.color = const Color(0x16A39374);
    for (var i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset(w * ((i * 31 % 101) / 101), h * ((i * 17 % 97) / 97)),
        1.3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WorldPainter old) => old.row != row;
}
