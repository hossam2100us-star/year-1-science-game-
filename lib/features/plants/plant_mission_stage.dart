import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import 'plant_lab_game.dart';

/// Illustrated choices keep each label attached to its own picture.
class PlantMissionStage extends StatelessWidget {
  const PlantMissionStage({
    super.key,
    required this.step,
    required this.selected,
    required this.placements,
    required this.done,
    required this.onItem,
    required this.onPlace,
  });
  final LessonStep step;
  final Set<String> selected;
  final Map<String, String> placements;
  final bool done;
  final ValueChanged<String> onItem;
  final void Function(String, String) onPlace;

  @override
  Widget build(BuildContext context) {
    final options = step.isOrder
        ? [
            ...selected.map((id) => step.options.firstWhere((o) => o.id == id)),
            ...step.options.where((o) => !selected.contains(o.id)),
          ]
        : step.options;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/images/greenhouse-v1.png'),
          fit: BoxFit.cover,
          opacity: .35,
        ),
        color: const Color(0xFFE6F0D7),
      ),
      child: Column(
        children: [
          if (step.isOrder && !done)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_forward_rounded, size: 40),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final item in options)
                Draggable<String>(
                  data: item.id,
                  maxSimultaneousDrags: step.isMapping && !done ? 1 : 0,
                  feedback: Material(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(width: 120, child: _tile(item, true)),
                  ),
                  childWhenDragging: Opacity(opacity: .3, child: _option(item)),
                  child: _option(item),
                ),
            ],
          ),
          if (step.targets.isNotEmpty) ...[
            const SizedBox(height: 20),
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
                    builder: (context, candidates, rejected) => Material(
                      color: candidates.isEmpty
                          ? const Color(0xFFFFF8EC)
                          : const Color(0xFFFFE9C7),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        key: ValueKey('mission-target-${target.id}'),
                        borderRadius: BorderRadius.circular(20),
                        onTap: done || selected.isEmpty
                            ? null
                            : () => onPlace(selected.first, target.id),
                        child: SizedBox(
                          width: 150,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                PlantMissionPicture(id: target.art, height: 75),
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
                                  Text(
                                    item.label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                              ],
                            ),
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

  Widget _option(PictureItem item) => Material(
    color: selected.contains(item.id)
        ? const Color(0xFFFFE9C7)
        : const Color(0xFFFFFCF4),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      key: ValueKey('mission-item-${item.id}'),
      borderRadius: BorderRadius.circular(20),
      onTap: done ? null : () => onItem(item.id),
      child: SizedBox(
        width: step.options.length > 8 ? 132 : 190,
        child: _tile(item, false),
      ),
    ),
  );
  Widget _tile(PictureItem item, bool dragging) => Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (step.isOrder && selected.contains(item.id))
          Text(
            '${selected.toList().indexOf(item.id) + 1}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        PlantMissionPicture(
          id: item.art,
          height: dragging
              ? 90
              : step.options.length > 8
              ? 100
              : 140,
        ),
        Text(
          item.label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22),
        ),
        if (placements.containsKey(item.id))
          const Icon(Icons.inventory_2_outlined),
      ],
    ),
  );
}

class PlantMissionPicture extends StatelessWidget {
  const PlantMissionPicture({super.key, required this.id, this.height = 140});
  final String id;
  final double height;
  static const foods = [
    'carrot',
    'radish',
    'celery',
    'sugar_cane',
    'lettuce',
    'mint',
    'parsley',
    'cauliflower',
    'broccoli',
    'beans',
    'rice',
    'lentils',
    'peas',
    'water',
    'light',
    'soil',
  ];
  @override
  Widget build(BuildContext context) {
    String asset = 'plant-foods-v1.png';
    Rect crop = const Rect.fromLTWH(0, 0, 1, 1);
    final food = foods.indexOf(switch (id) {
      'sunlight' || 'catches_sunlight' => 'light',
      'drinks_water' => 'water',
      'makes_seeds' || 'seed' => 'beans',
      _ => id,
    });
    if (food >= 0) {
      crop = Rect.fromLTWH((food % 4) / 4, (food ~/ 4) / 4, .25, .25);
    } else if (plantPartRegions.containsKey(plantPartId(id))) {
      asset = 'plant-lab-v1.png';
      crop = plantPartRegions[plantPartId(id)]!;
    } else if (id.startsWith('bean_')) {
      asset = 'bean-stages-v1.png';
      final frame = ['bean_1', 'bean_4', 'bean_7', 'bean_8'].indexOf(id);
      crop = Rect.fromLTWH(
        frame.isEven ? 0 : .5,
        frame < 2 ? 0 : .47,
        .5,
        frame < 2 ? .47 : .53,
      );
    } else if ([
      'green',
      'healthy',
      'green_and_strong',
      'thick_stem',
      'pale_yellow',
      'pale_and_floppy',
      'thin_floppy_stem',
      'not_healthy',
    ].contains(id)) {
      asset = 'light-plants-v1.png';
      final pale = [
        'pale_yellow',
        'pale_and_floppy',
        'thin_floppy_stem',
        'not_healthy',
      ].contains(id);
      crop = Rect.fromLTWH(pale ? 2 / 3 : 1 / 3, 0, 1 / 3, 1);
    } else if (['plant', 'holds_the_plant_up'].contains(id)) {
      asset = 'plant-lab-v1.png';
    } else {
      // Text-only alternatives remain explicit; never attach an unrelated image.
      return const SizedBox(height: 12);
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: FutureBuilder<ui.Image>(
        future: Flame.images.load(asset),
        builder: (context, snapshot) => snapshot.hasData
            ? CustomPaint(painter: _PlantCrop(snapshot.data!, crop))
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _PlantCrop extends CustomPainter {
  const _PlantCrop(this.image, this.crop);
  final ui.Image image;
  final Rect crop;
  @override
  void paint(Canvas c, Size s) {
    final source = Rect.fromLTWH(
      crop.left * image.width,
      crop.top * image.height,
      crop.width * image.width,
      crop.height * image.height,
    );
    final fit = applyBoxFit(BoxFit.contain, source.size, s);
    c.drawImageRect(
      image,
      source,
      Alignment.center.inscribe(fit.destination, Offset.zero & s),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_PlantCrop old) => old.image != image || old.crop != crop;
}
