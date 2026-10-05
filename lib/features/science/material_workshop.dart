import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/touch_cue.dart';
import 'science_picture.dart';
import 'material_context.dart';

/// A shared physical workspace. Only the learner's selections affect its cues;
/// answer keys stay in the question engine, never in the scene.
class MaterialWorkshop extends StatelessWidget {
  const MaterialWorkshop({
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
  final Set<String> selected;
  final Set<String> reviewItems;
  final Map<String, String> placements;
  final bool done;
  final ValueChanged<String> onItem;
  final void Function(String, String) onPlace;
  Map<dynamic, dynamic> get ui => step.json['workshop'];
  Widget picture(PictureItem item, double size) {
    final examples = (ui['pairedExamples'] as Map?)?[item.id] as List?;
    if (examples != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final art in examples)
            SciencePicture(art as String, height: size * .48),
        ],
      );
    }
    return SciencePicture(item.art, height: size);
  }

  Widget cue(String id) => reviewItems.contains(id)
      ? Semantics(
          key: ValueKey('review-item-$id'),
          label: step.json['correctionUi']['review'],
          child: const SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              Icons.help_outline_rounded,
              color: Color(0xFF93631F),
              size: 30,
            ),
          ),
        )
      : const TouchCue();

  Widget object(PictureItem item, {double size = 94, bool label = true}) {
    final active = selected.contains(item.id);
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: size * 1.3,
              height: size + 16,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFE0EDEA) : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: active
                    ? Border.all(color: const Color(0xFF497B73), width: 2)
                    : null,
              ),
              child: item.art == 'stretch_mission'
                  ? const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.back_hand_outlined,
                            size: 34,
                            color: Color(0xFF6B8E85),
                          ),
                          RotatedBox(
                            quarterTurns: 1,
                            child: Icon(
                              Icons.unfold_more_rounded,
                              size: 32,
                              color: Color(0xFF6B8E85),
                            ),
                          ),
                          Icon(
                            Icons.back_hand_outlined,
                            size: 34,
                            color: Color(0xFF6B8E85),
                          ),
                        ],
                      ),
                    )
                  : picture(item, size),
            ),
            if (!done) Positioned(right: 0, bottom: 0, child: cue(item.id)),
          ],
        ),
        if (label)
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        if (step.isMapping)
          SizedBox(
            height: 48,
            child: Text(
              placements.containsKey(item.id)
                  ? step.label(placements[item.id]!)
                  : '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
      ],
    );
    return Draggable<String>(
      data: item.id,
      maxSimultaneousDrags: (step.isMapping || ui['mode'] == 'pack') && !done
          ? 1
          : 0,
      onDragStarted: step.isMapping ? () => onItem(item.id) : null,
      feedback: Material(color: Colors.transparent, child: picture(item, 110)),
      child: InkWell(
        key: ValueKey('science-item-${item.id}'),
        onTap: done ? null : () => onItem(item.id),
        borderRadius: BorderRadius.circular(20),
        child: body,
      ),
    );
  }

  Widget scene() => LayoutBuilder(
    builder: (context, box) {
      final explore = step.kind == 'explore';
      if (explore) return room(box.maxWidth);
      final illustrated = step.options.every((o) => SciencePicture.has(o.art));
      final objects =
          explore || (step.isMapping && illustrated) || ui['mode'] == 'collect';
      return ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFFF7EDD9)),
          child: CustomPaint(
            painter: const _WorkshopBackdrop(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 32),
              child: Column(
                children: [
                  if (objects)
                    Wrap(
                      spacing: 18,
                      runSpacing: 28,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final item in step.options)
                          SizedBox(
                            width: box.maxWidth < 600 ? 135 : 170,
                            child: object(item),
                          ),
                      ],
                    ),
                  if (!objects) ...[
                    if (ui['focus'] == 'window')
                      const MaterialContext('window')
                    else
                      SciencePicture(ui['focus'] ?? 'spoon', height: 175),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final item in step.options)
                          SizedBox(
                            width: box.maxWidth < 600 ? 215 : 255,
                            child: Material(
                              color: selected.contains(item.id)
                                  ? const Color(0xFFDCECE6)
                                  : const Color(0xFFFFFCF4),
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                key: ValueKey('science-item-${item.id}'),
                                onTap: done ? null : () => onItem(item.id),
                                borderRadius: BorderRadius.circular(18),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Text(
                                        item.label,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (placements.containsKey(item.id))
                                        Text(
                                          step.label(placements[item.id]!),
                                          textAlign: TextAlign.center,
                                        ),
                                      if (!done) cue(item.id),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget room(double width) {
    const locations = <String, Offset>{
      'glass': Offset(.07, .04),
      'fabric': Offset(.78, .04),
      'metal': Offset(.29, .37),
      'plastic': Offset(.48, .34),
      'clay': Offset(.70, .38),
      'wood': Offset(.06, .57),
      'paper': Offset(.48, .66),
    };
    final itemSize = (width * .13).clamp(65.0, 130.0);
    final itemWidth = itemSize * 1.3;
    final narrow = width < 560;
    final narrowLocations = <String, Offset>{
      'glass': const Offset(.02, .02),
      'fabric': const Offset(.98, .02),
      'metal': const Offset(.02, .25),
      'plastic': const Offset(.98, .25),
      'clay': const Offset(.98, .48),
      'wood': const Offset(.02, .48),
      'paper': const Offset(.50, .71),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 500,
        width: width,
        child: CustomPaint(
          painter: const _RoomBackdrop(),
          child: Stack(
            children: [
              for (final item in step.options)
                Positioned(
                  left: narrow
                      ? (width - itemWidth) * narrowLocations[item.id]!.dx
                      : (width * locations[item.id]!.dx).clamp(
                          0.0,
                          width - itemWidth,
                        ),
                  top:
                      500 * (narrow ? narrowLocations : locations)[item.id]!.dy,
                  child: object(item, size: itemSize, label: false),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget drawer(PictureItem target) => DragTarget<String>(
    onWillAcceptWithDetails: (d) =>
        !done && step.options.any((o) => o.id == d.data),
    onAcceptWithDetails: (d) => onPlace(d.data, target.id),
    builder: (context, candidates, rejected) => Semantics(
      button: true,
      child: InkWell(
        key: ValueKey('science-target-${target.id}'),
        onTap: done || selected.isEmpty
            ? null
            : () => onPlace(selected.first, target.id),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE6CCAA),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: candidates.isEmpty
                  ? const Color(0xFFB89369)
                  : const Color(0xFF497B73),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                target.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 42,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF967A60),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final item in step.options.where(
                    (o) => placements[o.id] == target.id,
                  ))
                    picture(item, 44),
                ],
              ),
              if (!done && (selected.isNotEmpty || candidates.isNotEmpty))
                const TouchCue(),
            ],
          ),
        ),
      ),
    ),
  );

  Widget instruction(String text) => Padding(
    padding: const EdgeInsets.all(14),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    ),
  );

  Widget rack() => Wrap(
    alignment: WrapAlignment.center,
    spacing: 18,
    runSpacing: 14,
    children: [
      for (final item in step.options)
        SizedBox(width: 145, child: object(item, size: 88)),
    ],
  );

  Widget pack() => Column(
    children: [
      instruction(ui['instruction']),
      rack(),
      const SizedBox(height: 18),
      DragTarget<String>(
        onWillAcceptWithDetails: (d) =>
            !done && step.options.any((o) => o.id == d.data),
        onAcceptWithDetails: (d) {
          if (!selected.contains(d.data)) onItem(d.data);
        },
        builder: (context, candidates, rejected) => Container(
          key: const ValueKey('material-rain-bag'),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFDDEAE5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: candidates.isEmpty
                  ? const Color(0xFFABC3B9)
                  : const Color(0xFF497B73),
              width: 3,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.backpack_outlined,
                size: 44,
                color: Color(0xFF497B73),
              ),
              instruction(ui['packed']),
              if (selected.isEmpty) instruction(ui['empty']),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 10,
                children: [
                  for (final item in step.options.where(
                    (o) => selected.contains(o.id),
                  ))
                    InkWell(
                      key: ValueKey('unpack-${item.id}'),
                      onTap: done ? null : () => onItem(item.id),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SciencePicture(item.art, height: 62),
                          Text(item.label),
                        ],
                      ),
                    ),
                ],
              ),
              if (selected.isNotEmpty && !done) instruction(ui['remove']),
            ],
          ),
        ),
      ),
    ],
  );

  Widget tray(PictureItem target) => DragTarget<String>(
    onWillAcceptWithDetails: (d) =>
        !done && step.options.any((o) => o.id == d.data),
    onAcceptWithDetails: (d) => onPlace(d.data, target.id),
    builder: (context, candidates, rejected) => InkWell(
      key: ValueKey('science-target-${target.id}'),
      onTap: done || selected.isEmpty
          ? null
          : () => onPlace(selected.first, target.id),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 285,
        constraints: const BoxConstraints(minHeight: 155),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0DDC1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: candidates.isEmpty
                ? const Color(0xFFBFA37D)
                : const Color(0xFF497B73),
            width: 3,
          ),
        ),
        child: Column(
          children: [
            Text(
              target.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final item in step.options.where(
                  (o) => placements[o.id] == target.id,
                ))
                  SizedBox(
                    width: 70,
                    child: SciencePicture(item.art, height: 60),
                  ),
              ],
            ),
            if (!done) const TouchCue(),
          ],
        ),
      ),
    ),
  );

  Widget reasonChoices() => Wrap(
    alignment: WrapAlignment.center,
    spacing: 16,
    runSpacing: 12,
    children: [
      for (final item in step.options)
        SizedBox(
          width: 250,
          child: Material(
            color: selected.contains(item.id)
                ? const Color(0xFFDDEAE5)
                : const Color(0xFFFFFCF4),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              key: ValueKey('science-item-${item.id}'),
              onTap: done ? null : () => onItem(item.id),
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!done) cue(item.id),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget missionRoom() => LayoutBuilder(
    builder: (context, box) {
      // Positions identify objects, never the correct discovery.
      const locations = [
        Offset(.03, .02),
        Offset(.36, .41),
        Offset(.76, .40),
        Offset(.76, .01),
        Offset(.05, .47),
      ];
      final size = (box.maxWidth * .14).clamp(58.0, 110.0);
      final itemWidth = size * 1.35;
      final narrow = box.maxWidth < 560;
      return ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: 420,
          width: box.maxWidth,
          child: CustomPaint(
            painter: const _RoomBackdrop(),
            child: Stack(
              children: [
                for (var i = 0; i < step.options.length; i++)
                  Positioned(
                    left: narrow
                        ? (box.maxWidth - itemWidth) * (i.isEven ? .04 : .96)
                        : (box.maxWidth * locations[i].dx).clamp(
                            0.0,
                            box.maxWidth - itemWidth,
                          ),
                    top: narrow ? 18 + (i ~/ 2) * 132.0 : 420 * locations[i].dy,
                    child: SizedBox(
                      width: size * 1.35,
                      child: object(step.options[i], size: size, label: false),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget mission() {
    final mode = ui['mode'];
    if (mode == 'pack') return pack();
    return Column(
      children: [
        instruction(ui['instruction']),
        if (mode == 'squash') ...[
          rack(),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 16,
            children: step.targets.map(tray).toList(),
          ),
        ],
        if (mode == 'window') ...[
          const MaterialContext('window'),
          reasonChoices(),
        ],
        if (mode == 'pencil') ...[const MaterialContext('pencil'), rack()],
        if (mode == 'missions') ...[
          missionRoom(),
          if (selected.isNotEmpty) instruction(step.label(selected.first)),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final target in step.targets)
                SizedBox(
                  width: 170,
                  child: OutlinedButton(
                    key: ValueKey('science-target-${target.id}'),
                    onPressed: done || selected.isEmpty
                        ? null
                        : () => onPlace(selected.first, target.id),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      textStyle: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 21,
                      ),
                    ),
                    child: Text(target.label, textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if ([
      'pack',
      'squash',
      'window',
      'pencil',
      'missions',
    ].contains(ui['mode'])) {
      return mission();
    }
    final last = selected.isEmpty ? null : selected.last;
    return Column(
      children: [
        scene(),
        if (step.kind == 'explore')
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              last == null
                  ? ui['discover']
                  : step.json['senseDescriptions'][last],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 23),
            ),
          ),
        if (step.isMapping) ...[
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(ui['sort'], textAlign: TextAlign.center),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: step.targets.map(drawer).toList(),
          ),
        ],
        if (ui['mode'] == 'collect' && selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_basket_outlined, size: 36),
                Flexible(
                  child: Text(
                    selected.map(step.label).join(' • '),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RoomBackdrop extends CustomPainter {
  const _RoomBackdrop();
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = const Color(0xFFFFF8E9);
    canvas.drawRect(Offset.zero & s, p);
    p.color = const Color(0xFFDFE9DE);
    canvas.drawRect(Rect.fromLTWH(0, 305, s.width, 195), p);
    p
      ..color = const Color(0xFFB7CDBB)
      ..strokeWidth = 2;
    for (double x = 0; x < s.width; x += 95) {
      canvas.drawLine(Offset(x, 305), Offset(x - 55, 500), p);
    }
    p.color = const Color(0xFFC6A175);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * .26, 320, s.width * .66, 22),
        const Radius.circular(8),
      ),
      p,
    );
    p.color = const Color(0xFFA68158);
    canvas.drawRect(Rect.fromLTWH(s.width * .30, 342, 15, 110), p);
    canvas.drawRect(Rect.fromLTWH(s.width * .86, 342, 15, 110), p);
    p.color = const Color(0xFFBCA283);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * .77, 35, s.width * .18, 10),
        const Radius.circular(5),
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(_RoomBackdrop old) => false;
}

class _WorkshopBackdrop extends CustomPainter {
  const _WorkshopBackdrop();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE8D8BB);
    for (double x = 22; x < size.width; x += 30) {
      for (double y = 15; y < size.height - 38; y += 30) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
    paint.color = const Color(0xFFC9A67D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height - 22, size.width, 22),
        const Radius.circular(6),
      ),
      paint,
    );
    paint.color = const Color(0xFFAF875C);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 8, size.width, 8), paint);
  }

  @override
  bool shouldRepaint(_WorkshopBackdrop oldDelegate) => false;
}
