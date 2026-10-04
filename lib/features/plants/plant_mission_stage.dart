import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/touch_cue.dart';
import '../biology/illustrated_art.dart';
import 'plant_lab_game.dart';
import 'plant_lab_stage.dart';
import 'plant_workshop.dart';

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
    if (step.kind == 'tap-choice' &&
        step.options.length == 4 &&
        step.options.every((p) => plantPartRegions.containsKey(p.id))) {
      return PlantLabStage(
        step: step,
        selected: selected,
        touched: const {},
        placements: placements,
        done: done,
        assembled: const {},
        onItem: onItem,
        onPlace: onPlace,
      );
    }
    if (step.isMapping && step.options.length > 8) {
      return _FoodCollection(
        key: ValueKey(step.id),
        step: step,
        selected: selected,
        placements: placements,
        done: done,
        onItem: onItem,
        onPlace: onPlace,
      );
    }
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
          image: AssetImage('assets/images/greenhouse-v1.webp'),
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
                                PlantMissionPicture(id: target.art, height: 48),
                                if (!done) const TouchCue(),
                                Text(
                                  target.label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                  height: 48,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        for (final item in step.options.where(
                                          (o) => placements[o.id] == target.id,
                                        ))
                                          Text(
                                            item.label,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
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
        width: step.options.length > 8 ? 154 : 190,
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
              ? 65
              : 140,
        ),
        if (!done) const TouchCue(),
        Text(
          item.label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
        ),
        if (step.isMapping)
          SizedBox(
            height: 24,
            child: placements.containsKey(item.id)
                ? const Icon(Icons.inventory_2_outlined)
                : null,
          ),
      ],
    ),
  );
}

/// Sort one food on the same workbench instead of displaying thirteen cards.
/// All mappings remain in the lesson's original state and scoring engine.
class _FoodCollection extends StatefulWidget {
  const _FoodCollection({
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
  State<_FoodCollection> createState() => _FoodCollectionState();
}

class _FoodCollectionState extends State<_FoodCollection> {
  late int index;
  PictureItem get food => widget.step.options[index];
  @override
  void initState() {
    super.initState();
    final selected = widget.step.options.indexWhere(
      (p) => widget.selected.contains(p.id),
    );
    final missing = widget.step.options.indexWhere(
      (p) => !widget.placements.containsKey(p.id),
    );
    index = selected >= 0
        ? selected
        : missing >= 0
        ? missing
        : 0;
  }

  void move(int next) {
    setState(() => index = next);
    if (!widget.done) widget.onItem(food.id);
  }

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      color: const Color(0xFFE6F0D7),
      image: const DecorationImage(
        image: AssetImage('assets/images/greenhouse-v1.webp'),
        fit: BoxFit.cover,
        opacity: .15,
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('plant-collection-previous'),
              tooltip: 'Previous food',
              onPressed: index == 0 ? null : () => move(index - 1),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                'Food ${index + 1} / ${widget.step.options.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 8),
        Draggable<String>(
          data: food.id,
          maxSimultaneousDrags: widget.done ? 0 : 1,
          feedback: Material(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 150,
              child: PlantMissionPicture(id: food.art, height: 100),
            ),
          ),
          child: Material(
            color: const Color(0xFFFFFCF4),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              key: ValueKey('mission-item-${food.id}'),
              borderRadius: BorderRadius.circular(22),
              onTap: widget.done ? null : () => widget.onItem(food.id),
              child: SizedBox(
                width: 250,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      PlantMissionPicture(id: food.art, height: 170),
                      Text(
                        food.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Text(
            'Which part do we eat? Choose a basket.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final target in widget.step.targets)
              DragTarget<String>(
                onWillAcceptWithDetails: (details) =>
                    !widget.done && details.data == food.id,
                onAcceptWithDetails: (details) =>
                    widget.onPlace(details.data, target.id),
                builder: (context, hover, rejected) => Material(
                  color:
                      hover.isNotEmpty ||
                          widget.placements[food.id] == target.id
                      ? const Color(0xFFE0ECE5)
                      : const Color(0xFFFFFCF4),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    key: ValueKey('mission-target-${target.id}'),
                    borderRadius: BorderRadius.circular(20),
                    onTap: widget.done
                        ? null
                        : () => widget.onPlace(food.id, target.id),
                    child: SizedBox(
                      width: 130,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            PlantMissionPicture(id: target.art, height: 64),
                            Text(
                              target.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22),
                            ),
                            if (widget.placements[food.id] == target.id)
                              const Icon(
                                Icons.radio_button_checked,
                                color: Color(0xFF356D75),
                              )
                            else if (!widget.done)
                              const TouchCue(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (index + 1 < widget.step.options.length)
          FilledButton.icon(
            key: const ValueKey('plant-collection-next'),
            onPressed: !widget.placements.containsKey(food.id) && !widget.done
                ? null
                : () => move(index + 1),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Next food'),
          )
        else if (widget.placements.containsKey(food.id))
          const Text(
            'Check your food collection below.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
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
    if (const ['toys', 'paper', 'wind', 'dry_and_drooping'].contains(id)) {
      final illustration = illustrationFor(id);
      return SizedBox(
        height: height,
        width: double.infinity,
        child: illustration == null
            ? CustomPaint(painter: WorkshopArt(id))
            : IllustratedArt(
                asset: illustration.asset,
                crop: illustration.crop,
              ),
      );
    }
    String asset = 'plant-foods-v1.webp';
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
      asset = 'plant-lab-v1.webp';
      crop = plantPartRegions[plantPartId(id)]!;
    } else if (id.startsWith('bean_')) {
      asset = 'bean-stages-v1.webp';
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
      asset = 'light-plants-v1.webp';
      final pale = [
        'pale_yellow',
        'pale_and_floppy',
        'thin_floppy_stem',
        'not_healthy',
      ].contains(id);
      crop = Rect.fromLTWH(pale ? 2 / 3 : 1 / 3, 0, 1 / 3, 1);
    } else if (['plant', 'holds_the_plant_up'].contains(id)) {
      asset = 'plant-lab-v1.webp';
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
