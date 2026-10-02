import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/touch_cue.dart';
import 'force_picture.dart';
import 'force_object.dart';

/// Scene positions and movement demonstrations never consult the answer key.
class ForceStage extends StatefulWidget {
  const ForceStage({
    super.key,
    required this.step,
    required this.selected,
    required this.placements,
    required this.done,
    required this.onItem,
    required this.onPlace,
    this.reviewItems = const {},
  });
  final LessonStep step;
  final Set<String> selected, reviewItems;
  final Map<String, String> placements;
  final bool done;
  final ValueChanged<String> onItem;
  final void Function(String, String) onPlace;
  @override
  State<ForceStage> createState() => _ForceStageState();
}

class _ForceStageState extends State<ForceStage> {
  int pulse = 0;
  String? movingItem;
  LessonStep get step => widget.step;
  Map get ui => step.json['forceScene'];
  void choose(String id) {
    if (widget.done) return;
    setState(() {
      pulse++;
      movingItem = id;
    });
    widget.onItem(id);
  }

  Widget cue(String id) => widget.reviewItems.contains(id)
      ? Semantics(
          key: ValueKey('review-item-$id'),
          label: step.json['correctionUi']['review'],
          child: const Icon(
            Icons.help_outline_rounded,
            color: Color(0xFF93631F),
            size: 30,
          ),
        )
      : const TouchCue();
  Widget object(PictureItem item, {double size = 85, bool label = true}) {
    final motion = step.json['motions']?[item.id] as String?;
    final art = switch (item.art) {
      'push' || 'pull' || 'away_from_you' || 'towards_you' => 'trolley',
      _ => item.art,
    };
    return Draggable<String>(
      data: item.id,
      maxSimultaneousDrags: ui['mode'] == 'tank' && !widget.done ? 1 : 0,
      onDragStarted: () => choose(item.id),
      feedback: Material(
        color: Colors.transparent,
        child: ForcePicture(art, height: 90),
      ),
      child: InkWell(
        key: ValueKey('science-item-${item.id}'),
        onTap: widget.done ? null : () => choose(item.id),
        borderRadius: BorderRadius.circular(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: size + 40,
              width: size + 55,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (item.art == 'tank_question')
                    const Icon(
                      Icons.water_rounded,
                      size: 72,
                      color: Color(0xFF6B9DAC),
                    )
                  else if (['switch', 'zip'].contains(art))
                    ForceObject(art, size: size)
                  else
                    MovementSprite(
                      key: ValueKey(
                        '${item.id}-${movingItem == item.id ? pulse : 0}',
                      ),
                      art: art,
                      motion: motion,
                      active: movingItem == item.id && motion != null,
                      size: size,
                    ),
                  if (!widget.done)
                    Positioned(right: 2, bottom: 2, child: cue(item.id)),
                ],
              ),
            ),
            if (label)
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (step.isMapping)
              SizedBox(
                height: 52,
                child: Text(
                  widget.placements.containsKey(item.id)
                      ? step.label(widget.placements[item.id]!)
                      : '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget board() => LayoutBuilder(
    builder: (context, box) {
      final mode = ui['mode'];
      final count = step.options.length;
      final columns = count > 6
          ? 4
          : count > 2
          ? 3
          : 2;
      final rows = (count / columns).ceil();
      final cell = box.maxWidth / columns;
      final size = (cell * .48).clamp(60.0, 118.0);
      final height = rows * 210.0;
      const movement = [
        Offset(.02, .07),
        Offset(.28, .71),
        Offset(.52, .92),
        Offset(.82, .78),
        Offset(.02, .8),
        Offset(.62, 0),
        Offset(.29, .03),
        Offset(.84, .07),
      ];
      const animals = [
        Offset(.02, .76),
        Offset(.48, .87),
        Offset(.82, .7),
        Offset(.8, 0),
        Offset(.27, .02),
      ];
      final locations = mode == 'movement'
          ? movement
          : mode == 'animals'
          ? animals
          : null;
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: height,
          width: box.maxWidth,
          child: CustomPaint(
            painter: _ForceBackdrop(mode),
            child: Stack(
              children: [
                for (var i = 0; i < count; i++)
                  Positioned(
                    left: locations == null
                        ? (i % columns) * cell
                        : locations[i].dx * (box.maxWidth - cell),
                    top: locations == null
                        ? (i ~/ columns) * 210.0 + 10
                        : locations[i].dy * (height - 185),
                    width: cell,
                    child: Center(
                      child: object(
                        step.options[i],
                        size: size,
                        label:
                            mode == 'direction' ||
                            (mode == 'movement' &&
                                widget.selected.lastOrNull ==
                                    step.options[i].id),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
  Widget tankTarget(PictureItem target) => DragTarget<String>(
    onWillAcceptWithDetails: (d) =>
        !widget.done && step.options.any((p) => p.id == d.data),
    onAcceptWithDetails: (d) => widget.onPlace(d.data, target.id),
    builder: (context, candidates, rejected) => InkWell(
      key: ValueKey('science-target-${target.id}'),
      onTap: widget.done || widget.selected.isEmpty
          ? null
          : () => widget.onPlace(widget.selected.first, target.id),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 135),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: target.id == 'float'
              ? const Color(0xFFB6DBDF)
              : const Color(0xFF7DAEBF),
          border: Border.all(
            color: candidates.isEmpty
                ? const Color(0xFF6195A4)
                : const Color(0xFF345F69),
            width: 3,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  target.label,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                if (!widget.done) const TouchCue(),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children: [
                for (final p in step.options.where(
                  (p) => widget.placements[p.id] == target.id,
                ))
                  ForcePicture(p.art, height: 55),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  Widget targets() => Wrap(
    alignment: WrapAlignment.center,
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final p in step.targets)
        SizedBox(
          width: 180,
          child: FilledButton.tonal(
            key: ValueKey('science-target-${p.id}'),
            onPressed: widget.done || widget.selected.isEmpty
                ? null
                : () => widget.onPlace(widget.selected.first, p.id),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
              textStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 22),
            ),
            child: Text(p.label, textAlign: TextAlign.center),
          ),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final mode = ui['mode'];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            ui['instruction'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        if (mode == 'direction')
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 36),
                Text(ui['you']),
              ],
            ),
          ),
        if (mode == 'boat') ...[
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEFEF),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Center(child: ForcePicture('sailboat', height: 180)),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            children: [
              for (final p in step.options)
                SizedBox(
                  width: 180,
                  child: FilledButton.tonal(
                    key: ValueKey('science-item-${p.id}'),
                    onPressed: widget.done ? null : () => choose(p.id),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Text(p.label, style: const TextStyle(fontSize: 22)),
                          if (!widget.done) cue(p.id),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ] else if (mode == 'tank') ...[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              for (final p in step.options)
                SizedBox(width: 140, child: object(p, size: 72)),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                for (final id in ['float', 'sink'])
                  tankTarget(step.targets.firstWhere((p) => p.id == id)),
              ],
            ),
          ),
        ] else
          board(),
        if (step.isMapping && mode != 'tank') ...[
          SizedBox(
            height: 72,
            child: Center(
              child: Text(
                widget.selected.isEmpty
                    ? ''
                    : step.label(widget.selected.first),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          targets(),
        ],
        if (step.isMapping)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${ui['progress']}: ${widget.placements.length} / ${step.options.length}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
      ],
    );
  }
}

class MovementSprite extends StatelessWidget {
  const MovementSprite({
    super.key,
    required this.art,
    required this.motion,
    required this.active,
    required this.size,
  });
  final String art;
  final String? motion;
  final bool active;
  final double size;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: active ? 1 : 0),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 2400),
    builder: (context, value, _) {
      // Reduced motion shows the neutral pose; animation never hints an answer.
      final t = active && !MediaQuery.disableAnimationsOf(context)
          ? value
          : 0.0;
      final travel = Curves.easeInOutSine.transform(t);
      final phase = t * math.pi * 6;
      final hop = math.sin(t * math.pi * 3).abs();
      final offset = switch (motion) {
        'push' => Offset(36 * travel, 0),
        'pull' => Offset(-36 * travel, 0),
        'hop' => Offset(30 * travel, -27 * hop),
        'fly' => Offset(34 * travel, -12 * math.sin(t * math.pi)),
        'swim' => Offset(30 * travel, 3 * math.sin(phase)),
        'crawl' || 'slither' || 'roll' => Offset(30 * travel, 0),
        _ => Offset.zero,
      };
      return Transform.translate(
        offset: offset,
        child: ForcePicture(art, height: size, phase: phase),
      );
    },
  );
}

class _ForceBackdrop extends CustomPainter {
  const _ForceBackdrop(this.mode);
  final String mode;
  @override
  void paint(Canvas c, Size s) {
    final outside = ['movement', 'animals'].contains(mode);
    final p = Paint()
      ..color = outside ? const Color(0xFFE2EFEA) : const Color(0xFFF3E7D4);
    c.drawRect(Offset.zero & s, p);
    p.color = outside ? const Color(0xFFCADFC7) : const Color(0xFFD3BD9F);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, s.height * .62, s.width, s.height * .38),
        const Radius.circular(20),
      ),
      p,
    );
    p
      ..color = const Color(0xFFEDE3BB)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(0, s.height * .7)
        ..quadraticBezierTo(
          s.width * .5,
          s.height * .95,
          s.width,
          s.height * .72,
        ),
      p,
    );
    if (outside) {
      p
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFABCED1);
      c.drawOval(
        Rect.fromLTWH(
          s.width * .36,
          s.height * .62,
          s.width * .26,
          s.height * .27,
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_ForceBackdrop old) => old.mode != mode;
}
