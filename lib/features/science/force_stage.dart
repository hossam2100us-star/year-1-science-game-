import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/touch_cue.dart';
import 'force_picture.dart';
import 'force_object.dart';
import 'force_trolley_scene.dart';
import 'force_discovery.dart';
import 'force_motion.dart';
export 'force_motion.dart';

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
    this.onSpeak,
  });
  final LessonStep step;
  final Set<String> selected, reviewItems;
  final Map<String, String> placements;
  final bool done;
  final ValueChanged<String> onItem;
  final ValueChanged<String>? onSpeak;
  final void Function(String, String) onPlace;
  @override
  State<ForceStage> createState() => _ForceStageState();
}

class _ForceStageState extends State<ForceStage> {
  int pulse = 0;
  String? movingItem;
  String? focused;
  LessonStep get step => widget.step;
  Map<dynamic, dynamic> get ui => step.json['forceScene'];
  @override
  void didUpdateWidget(covariant ForceStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.id != widget.step.id) {
      movingItem = null;
      focused = null;
      pulse = 0;
    }
  }

  void choose(String id) {
    if (widget.done) return;
    setState(() {
      pulse++;
      movingItem = id;
      focused = id;
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
              clipBehavior: Clip.hardEdge,
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

  Widget board({List<PictureItem>? items}) => LayoutBuilder(
    builder: (context, box) {
      final mode = ui['mode'];
      final pictures = items ?? step.options;
      final count = pictures.length;
      final available = box.maxWidth - 24;
      final columns = available < 270
          ? 1
          : available < 540
          ? 2
          : count > 6
          ? 4
          : count > 2
          ? 3
          : 2;
      final cell = (available - (columns - 1) * 12) / columns;
      // The old fixed three-column scene let pictures and hitboxes overlap on
      // phones. Give every object its own flowing cell, including larger text.
      final size = (cell - 55).clamp(44.0, 118.0);
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: CustomPaint(
          painter: _ForceBackdrop(mode),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 20,
              children: [
                for (final picture in pictures)
                  SizedBox(
                    width: cell,
                    child: Center(
                      child: object(picture, size: size, label: false),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
  Widget trolley(PictureItem item, {bool label = true}) => InkWell(
    key: ValueKey('science-item-${item.id}'),
    onTap: widget.done ? null : () => choose(item.id),
    borderRadius: BorderRadius.circular(24),
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2EFEA),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ForceTrolleyScene(
            key: ValueKey(
              'trolley-${item.id}-${movingItem == item.id ? pulse : 0}',
            ),
            motion: step.json['motions'][item.id],
            active: movingItem == item.id,
            you: ui['you'],
            showAction: !step.assessed,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (label)
                Flexible(
                  child: Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (!widget.done) ...[const SizedBox(width: 12), cue(item.id)],
            ],
          ),
          if (step.isMapping)
            SizedBox(
              height: 52,
              child: Text(
                widget.placements.containsKey(item.id)
                    ? step.label(widget.placements[item.id]!)
                    : '',
                style: const TextStyle(fontSize: 18),
              ),
            ),
        ],
      ),
    ),
  );
  Widget trolleyBoard() => LayoutBuilder(
    builder: (context, box) => Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final item in step.options.where(
          (p) =>
              step.json['motions']?[p.id] == 'push' ||
              step.json['motions']?[p.id] == 'pull',
        ))
          SizedBox(
            width: box.maxWidth >= 720 ? (box.maxWidth - 16) / 2 : box.maxWidth,
            child: trolley(item),
          ),
      ],
    ),
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
  Widget targets({String? item}) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final p in step.targets)
        SizedBox(
          width: 180,
          child: FilledButton.tonal(
            key: ValueKey('science-target-${p.id}'),
            onPressed: widget.done || (item == null && widget.selected.isEmpty)
                ? null
                : () => widget.onPlace(item ?? widget.selected.first, p.id),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
              textStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 22),
            ),
            child: Text(p.label, textAlign: TextAlign.center),
          ),
        ),
    ],
  );

  Widget discoveries() {
    final id = focused ?? widget.selected.firstOrNull ?? step.options.first.id;
    final index = step.options.indexWhere((item) => item.id == id);
    final question = step.options[index];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E7D4),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < step.options.length; i++)
                OutlinedButton(
                  key: ValueKey('science-item-${step.options[i].id}'),
                  onPressed: () => widget.done
                      ? setState(() => focused = step.options[i].id)
                      : choose(step.options[i].id),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 52),
                    backgroundColor: id == step.options[i].id
                        ? const Color(0xFFDCE8E7)
                        : const Color(0xFFFAF3E6),
                  ),
                  child: Text(
                    '${i + 1}${widget.reviewItems.contains(step.options[i].id)
                        ? ' ?'
                        : widget.placements.containsKey(step.options[i].id)
                        ? ' ✓'
                        : ''}',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${ui['mission']} ${index + 1} / ${step.options.length}',
            style: const TextStyle(fontSize: 19),
          ),
          const SizedBox(height: 14),
          if (question.art == 'tank_question')
            const Icon(Icons.water_rounded, size: 100, color: Color(0xFF6B9DAC))
          else
            ForcePicture(
              question.art == 'push' ? 'trolley' : question.art,
              height: 150,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              ui['missions']?[id] ?? question.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          if (widget.placements.containsKey(id))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${ui['yourAnswer']}: ${step.label(widget.placements[id]!)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19),
              ),
            ),
          targets(item: id),
          if (index < step.options.length - 1) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              key: const ValueKey('force-next-mission'),
              onPressed: () => widget.done
                  ? setState(() => focused = step.options[index + 1].id)
                  : choose(step.options[index + 1].id),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                ui['nextMission'],
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = ui['mode'];
    return Column(
      children: [
        if (mode != 'movement')
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              ui['instruction'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        if (mode == 'movement')
          ForceDiscovery(
            key: ValueKey(step.id),
            step: step,
            seen: widget.selected,
            onItem: widget.onItem,
            onSpeak: widget.onSpeak,
          )
        else if (mode == 'direction')
          trolleyBoard()
        else if (mode == 'discoveries')
          discoveries()
        else if (mode == 'boat') ...[
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
        if (step.isMapping && mode != 'tank' && mode != 'discoveries') ...[
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
