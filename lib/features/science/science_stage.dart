import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/touch_cue.dart';
import 'science_picture.dart';
import 'material_workshop.dart';
import 'force_stage.dart';
import 'sound_stage.dart';
import 'science_world_stage.dart';

class ScienceStage extends StatelessWidget {
  const ScienceStage({
    super.key,
    required this.step,
    required this.selected,
    required this.placements,
    required this.done,
    required this.onItem,
    required this.onPlace,
    this.reviewItems = const {},
    this.onSound,
    this.onSpeak,
    this.onOrder,
    this.onOrderPlacements,
  });
  final LessonStep step;
  final Set<String> selected;
  final Set<String> reviewItems;
  final Map<String, String> placements;
  final bool done;
  final ValueChanged<String> onItem;
  final void Function(String, double)? onSound;
  final ValueChanged<String>? onSpeak;
  final ValueChanged<List<String>>? onOrder;
  final ValueChanged<Map<String, String>>? onOrderPlacements;
  final void Function(String, String) onPlace;
  Color get tint => ['unit_04', 'quiz_02'].contains(step.json['theme'])
      ? const Color(0xFFFFEBCF)
      : ['unit_08', 'unit_09', 'quiz_04'].contains(step.json['theme'])
      ? const Color(0xFFE9E5F4)
      : const Color(0xFFDEEFF5);
  Widget tile(PictureItem p, {bool target = false, bool hover = false}) =>
      Container(
        width: target ? 185 : 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected.contains(p.id) && !target
              ? const Color(0xFFFFE0A0)
              : Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: hover ? const Color(0xFFC08023) : const Color(0xFF9CAFA8),
            width: hover ? 3 : 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!done)
              const Align(alignment: Alignment.topRight, child: TouchCue()),
            if (SciencePicture.has(p.art))
              SciencePicture(p.art, height: target ? 78 : 110),
            Text(
              p.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            if (!target && step.isMapping)
              SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    placements.containsKey(p.id)
                        ? step.label(placements[p.id]!)
                        : '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            if (!target && selected.contains(p.id) && step.isOrder)
              Text(
                '${selected.toList().indexOf(p.id) + 1}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      );
  Widget chart() => Column(
    children: [
      for (final row in step.table)
        Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(row['name'], style: const TextStyle(fontSize: 21)),
              ),
              Expanded(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (row['value'] as int) / 25,
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF698FAE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${row['value']}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ],
          ),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) => step.json['soundScene'] != null
      ? SoundStage(
          key: ValueKey('sound-${step.id}'),
          step: step,
          selected: selected,
          placements: placements,
          done: done,
          reviewItems: reviewItems,
          onItem: onItem,
          onPlace: onPlace,
          onSound: onSound,
          onSpeak: onSpeak,
          onOrder: onOrder,
          onOrderPlacements: onOrderPlacements,
        )
      : step.json['forceScene'] != null
      ? ForceStage(
          step: step,
          selected: selected,
          placements: placements,
          done: done,
          reviewItems: reviewItems,
          onItem: onItem,
          onPlace: onPlace,
          onSpeak: onSpeak,
        )
      : step.json['workshop'] != null
      ? MaterialWorkshop(
          step: step,
          selected: selected,
          placements: placements,
          done: done,
          reviewItems: reviewItems,
          onItem: onItem,
          onPlace: onPlace,
        )
      : ['unit_07', 'unit_08', 'unit_09'].contains(step.json['theme']) ||
            step.json['quizContext'] != null
      ? ScienceWorldStage(
          key: ValueKey('world-${step.id}'),
          step: step,
          selected: selected,
          placements: placements,
          done: done,
          reviewItems: reviewItems,
          onItem: onItem,
          onPlace: onPlace,
          onSpeak: onSpeak,
          onSound: onSound,
          onOrder: onOrder,
          onOrderPlacements: onOrderPlacements,
        )
      : Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              if (step.focus != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SciencePicture(step.focus!, height: 180),
                ),
              if (step.table.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: chart(),
                ),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  for (final p in step.options)
                    Draggable<String>(
                      data: p.id,
                      maxSimultaneousDrags: step.isMapping && !done ? 1 : 0,
                      onDragStarted: () => onItem(p.id),
                      feedback: Material(
                        color: Colors.transparent,
                        child: tile(p),
                      ),
                      child: InkWell(
                        key: ValueKey('science-item-${p.id}'),
                        onTap: done ? null : () => onItem(p.id),
                        borderRadius: BorderRadius.circular(23),
                        child: tile(p),
                      ),
                    ),
                ],
              ),
              if (step.isOrder && selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    selected.map(step.label).join(' → '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              if (step.targets.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.south_rounded, size: 30),
                ),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final p in step.targets)
                      DragTarget<String>(
                        onWillAcceptWithDetails: (d) =>
                            !done && step.options.any((o) => o.id == d.data),
                        onAcceptWithDetails: (d) => onPlace(d.data, p.id),
                        builder: (context, candidates, rejected) => InkWell(
                          key: ValueKey('science-target-${p.id}'),
                          onTap: done || selected.isEmpty
                              ? null
                              : () => onPlace(selected.first, p.id),
                          borderRadius: BorderRadius.circular(23),
                          child: tile(
                            p,
                            target: true,
                            hover: candidates.isNotEmpty,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
}
