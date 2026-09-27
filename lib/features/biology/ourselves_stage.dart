import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import 'biology_art.dart';
import 'body_workshop.dart';

class OurselvesStage extends StatelessWidget {
  const OurselvesStage({
    super.key,
    required this.step,
    required this.selected,
    required this.placements,
    required this.done,
    required this.girl,
    required this.onItem,
    required this.onPlace,
  });
  final LessonStep step;
  final Set<String> selected;
  final Map<String, String> placements;
  final bool done, girl;
  final ValueChanged<String> onItem;
  final void Function(String, String) onPlace;
  bool get body => step.json['activityView'] == 'body';
  @override
  Widget build(BuildContext context) {
    if (step.json['activityView'] == 'sense-story') return _senseStory(context);
    if (step.json['activityView'] == 'park') return _park(context);
    if (body)
      return BodyWorkshop(
        step: step,
        selected: selected,
        placements: placements,
        done: done,
        girl: girl,
        onItem: onItem,
        onPlace: onPlace,
      );
    if (step.kind == 'free-measure') return const SizedBox.shrink();
    if (step.table.isNotEmpty)
      return Column(
        children: [
          if (step.isMapping)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Wrap(
                spacing: 16,
                runSpacing: 10,
                children: [
                  for (final item in step.options)
                    Draggable<String>(
                      data: item.id,
                      maxSimultaneousDrags: done ? 0 : 1,
                      feedback: Material(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(item.label),
                        ),
                      ),
                      child: _option(context, item),
                    ),
                ],
              ),
            ),
          _marbles(context),
        ],
      );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2E8),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          if (step.focus != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5DF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: BiologyPicture(
                  art: step.focus!,
                  height: 210,
                  girl: girl,
                ),
              ),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final item in step.options)
                Draggable<String>(
                  data: item.id,
                  maxSimultaneousDrags: step.isMapping && !done ? 1 : 0,
                  feedback: Material(
                    color: Colors.transparent,
                    child: SizedBox(width: 150, child: _tile(item)),
                  ),
                  childWhenDragging: Opacity(
                    opacity: .35,
                    child: _option(context, item),
                  ),
                  child: _option(context, item),
                ),
            ],
          ),
          if (step.targets.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.south_rounded,
                size: 32,
                color: Color(0xFF52776D),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final target in step.targets)
                  DragTarget<String>(
                    onWillAcceptWithDetails: (d) =>
                        !done && step.options.any((o) => o.id == d.data),
                    onAcceptWithDetails: (d) => onPlace(d.data, target.id),
                    builder: (context, candidate, rejected) => Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('biology-target-${target.id}'),
                        onTap: done || selected.isEmpty
                            ? null
                            : () => onPlace(selected.first, target.id),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 160,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: candidate.isEmpty
                                ? Colors.white
                                : const Color(0xFFFFE4AA),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFF78A68D),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              BiologyPicture(
                                art: target.art,
                                height: 80,
                                girl: girl,
                              ),
                              Text(
                                target.label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              for (final item in step.options.where(
                                (o) => placements[o.id] == target.id,
                              ))
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Color(0xFF34624D),
                                    ),
                                  ),
                                ),
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
    );
  }

  Widget _senseStory(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 16,
    alignment: WrapAlignment.center,
    children: [
      for (final item in step.options)
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('biology-item-${item.id}'),
            onTap: () => onItem(item.id),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 190,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEE),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected.contains(item.id)
                      ? const Color(0xFF65A382)
                      : const Color(0xFFE1DCC9),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  BiologyPicture(art: item.art, height: 170, girl: girl),
                  const SizedBox(height: 10),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    step.json['senseDescriptions'][item.id],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22),
                  ),
                  if (selected.contains(item.id))
                    const Icon(
                      Icons.volume_up_rounded,
                      color: Color(0xFF56856A),
                    ),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  Widget _park(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final side = (box.maxWidth / 3).clamp(110.0, 220.0);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDFEFF5), Color(0xFFECF3D7), Color(0xFFBAD59C)],
          ),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 24,
          alignment: WrapAlignment.spaceEvenly,
          children: [
            for (final item in step.options)
              InkWell(
                key: ValueKey('biology-item-${item.id}'),
                onTap: done ? null : () => onItem(item.id),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: side,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: selected.contains(item.id)
                        ? const Color(0xAAFFF0AA)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected.contains(item.id)
                          ? const Color(0xFFAF813B)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Column(
                    children: [
                      BiologyPicture(art: item.art, height: 150, girl: girl),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (selected.contains(item.id))
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF44785A),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  Widget _option(BuildContext context, PictureItem item) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: ValueKey('biology-item-${item.id}'),
      onTap: done ? null : () => onItem(item.id),
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width < 500 ? 140 : 174,
        child: _tile(item),
      ),
    ),
  );
  Widget _tile(PictureItem item) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: selected.contains(item.id)
          ? const Color(0xFFFFE5A9)
          : Colors.white,
      border: Border.all(
        color: selected.contains(item.id)
            ? const Color(0xFFA87527)
            : const Color(0xFFD3DFCD),
        width: 2,
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BiologyPicture(art: item.art, height: 115, girl: girl),
        Text(
          item.label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        if (selected.contains(item.id))
          const Icon(Icons.check_circle_rounded, color: Color(0xFF427B57)),
      ],
    ),
  );
  Widget _marbles(BuildContext context) => Wrap(
    spacing: 18,
    runSpacing: 18,
    alignment: WrapAlignment.center,
    children: [
      for (final row in step.table)
        DragTarget<String>(
          onWillAcceptWithDetails: (d) =>
              step.isMapping &&
              !done &&
              step.options.any((o) => o.id == d.data),
          onAcceptWithDetails: (d) =>
              onPlace(d.data, row['name'].toString().toLowerCase()),
          builder: (context, hover, rejected) => Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey(
                'biology-item-${row['name'].toString().toLowerCase()}',
              ),
              onTap: done
                  ? null
                  : () {
                      final id = row['name'].toString().toLowerCase();
                      if (step.isMapping) {
                        if (selected.isNotEmpty) onPlace(selected.first, id);
                      } else {
                        onItem(id);
                      }
                    },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 240,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: selected.contains(row['name'].toString().toLowerCase())
                      ? const Color(0xFFFFE6AD)
                      : const Color(0xFFECF4EA),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF83A796), width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      row['name'],
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < row['value']; i++)
                          Container(
                            key: ValueKey('marble-${row['name']}-$i'),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: const Alignment(-.4, -.5),
                                colors: [
                                  Colors.white,
                                  [
                                    const Color(0xFF62AACA),
                                    const Color(0xFFE5AD58),
                                    const Color(0xFF8CAF70),
                                  ][i % 3],
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22745F44),
                                  offset: Offset(0, 3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${row['value']}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    for (final p in step.options.where(
                      (o) =>
                          placements[o.id] ==
                          row['name'].toString().toLowerCase(),
                    ))
                      Text(
                        p.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
