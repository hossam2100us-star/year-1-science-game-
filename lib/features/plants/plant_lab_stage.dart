import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/touch_cue.dart';
import 'plant_lab_game.dart';
import 'plant_workshop.dart';

/// The painting, touch targets and drag destinations share normalized geometry.
class PlantLabStage extends StatefulWidget {
  const PlantLabStage({
    super.key,
    required this.step,
    required this.selected,
    required this.touched,
    required this.placements,
    required this.done,
    required this.onItem,
    required this.onPlace,
    required this.assembled,
  });
  final LessonStep step;
  final Set<String> selected, touched, assembled;
  final Map<String, String> placements;
  final bool done;
  final ValueChanged<String> onItem;
  final void Function(String, String) onPlace;
  @override
  State<PlantLabStage> createState() => _PlantLabStageState();
}

class _PlantLabStageState extends State<PlantLabStage> {
  late final PlantLabGame game;
  bool get story => widget.step.kind == 'story';
  bool get puzzle => widget.step.kind == 'label-diagram';
  bool get freeBuild => widget.step.kind == 'free-plant';
  String? get active => story
      ? widget.step.focus
      : widget.selected.isEmpty
      ? null
      : plantPartId(widget.selected.last);
  @override
  void initState() {
    super.initState();
    game = PlantLabGame();
    _sync();
  }

  void _sync() {
    game.activePart = active;
    game.assembling = puzzle || freeBuild;
    game.discovered = freeBuild
        ? widget.touched
        : {...widget.assembled, if (widget.done) ...widget.placements.values};
  }

  @override
  void didUpdateWidget(PlantLabStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
    if (!oldWidget.done && widget.done && widget.placements.isNotEmpty) {
      game.animatePart(widget.placements.values.first);
    }
  }

  void choosePart(String part) {
    part = plantPartId(part);
    if (widget.done) return;
    if (puzzle) {
      final item = widget.step.options.single.id;
      widget.onPlace(item, part);
    } else {
      final item = widget.step.options
          .where((o) => plantPartId(o.id) == plantPartId(part))
          .firstOrNull;
      if (item == null) return;
      widget.onItem(item.id);
      game.animatePart(part);
    }
  }

  @override
  void dispose() {
    game.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (freeBuild) {
      return PlantWorkshop(
        step: widget.step,
        placed: {...widget.touched},
        onPlace: widget.onItem,
      );
    }
    game.reducedMotion = MediaQuery.disableAnimationsOf(context);
    final step = widget.step;
    final shownParts = puzzle
        ? plantPartRegions.keys.toList()
        : step.options
              .map((o) => plantPartId(o.id))
              .where(plantPartRegions.containsKey)
              .toList();
    return Column(
      children: [
        if (puzzle)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Draggable<String>(
              data: step.options.single.id,
              feedback: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(20),
                child: _PartTile(
                  id: step.options.single.id,
                  label: step.options.single.label,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: .35,
                child: _PartTile(
                  id: step.options.single.id,
                  label: step.options.single.label,
                ),
              ),
              child: Semantics(
                label: step.options.single.label,
                button: true,
                child: InkWell(
                  key: const ValueKey('plant-piece'),
                  onTap: widget.done
                      ? null
                      : () => widget.onItem(step.options.single.id),
                  borderRadius: BorderRadius.circular(20),
                  child: _PartTile(
                    id: step.options.single.id,
                    label: step.options.single.label,
                  ),
                ),
              ),
            ),
          ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                (MediaQuery.sizeOf(context).height * .70).clamp(260.0, 520.0) *
                1.5,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: LayoutBuilder(
                builder: (context, box) {
                  final size = Size(box.maxWidth, box.maxHeight);
                  Offset marker(String id) {
                    final point = switch (id) {
                      'flower' => const Offset(.12, .20),
                      'leaf' => const Offset(.88, .25),
                      'stem' => const Offset(.88, .65),
                      _ => const Offset(.12, .80),
                    };
                    return Offset(
                      point.dx * size.width,
                      point.dy * size.height,
                    );
                  }

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ExcludeSemantics(
                          child: GameWidget<PlantLabGame>(game: game),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: SceneTouchLinks([
                              for (final part in shownParts)
                                (
                                  marker(part),
                                  plantPartRect(part, size).center,
                                ),
                            ]),
                          ),
                        ),
                      ),
                      for (final part in shownParts)
                        Positioned.fromRect(
                          rect: Rect.fromCenter(
                            center: marker(part),
                            width: 64,
                            height: 64,
                          ),
                          child: DragTarget<String>(
                            onWillAcceptWithDetails: (d) =>
                                puzzle && !widget.done,
                            onAcceptWithDetails: (d) =>
                                widget.onPlace(d.data, plantPartId(part)),
                            builder: (context, candidate, rejected) => Material(
                              color: candidate.isEmpty
                                  ? Colors.transparent
                                  : const Color(0x55FFF29A),
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                key: ValueKey('plant-part-$part'),
                                onTap: widget.done
                                    ? null
                                    : () => choosePart(part),
                                borderRadius: BorderRadius.circular(18),
                                child: Semantics(
                                  button: true,
                                  label:
                                      step.targets
                                          .where(
                                            (t) => t.id == plantPartId(part),
                                          )
                                          .firstOrNull
                                          ?.label ??
                                      step.options
                                          .where(
                                            (o) =>
                                                plantPartId(o.id) ==
                                                plantPartId(part),
                                          )
                                          .firstOrNull
                                          ?.label ??
                                      part,
                                  child:
                                      step.kind == 'explore' &&
                                          widget.touched.any(
                                            (id) =>
                                                plantPartId(id) ==
                                                plantPartId(part),
                                          )
                                      ? const SizedBox(
                                          width: 64,
                                          height: 64,
                                          child: Icon(
                                            Icons.check_circle_outline,
                                            size: 44,
                                            color: Color(0xFF437A69),
                                          ),
                                        )
                                      : const TouchCue(size: 64),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        if (step.kind == 'explore' && active != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _PartTile(
              id: active!,
              enlarged: true,
              label: step.options.firstWhere((o) => o.id == active).label,
            ),
          ),
      ],
    );
  }
}

class _PartTile extends StatelessWidget {
  const _PartTile({
    required this.id,
    required this.label,
    this.enlarged = false,
  });
  final String id, label;
  final bool enlarged;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 130),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF6E9253), width: 2),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: enlarged ? 240 : 110,
          height: enlarged ? 160 : 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LayoutBuilder(
              builder: (context, box) {
                final region = plantPartRegions[plantPartId(id)]!;
                final scale = (box.maxWidth / (region.width * 1.5)).clamp(
                  0.0,
                  box.maxHeight / region.height,
                );
                final width = scale * 1.5, height = scale;
                return Center(
                  child: SizedBox(
                    width: region.width * width,
                    height: region.height * height,
                    child: ClipRect(
                      child: Stack(
                        children: [
                          Positioned(
                            left: -region.left * width,
                            top: -region.top * height,
                            width: width,
                            height: height,
                            child: Image.asset(
                              plantLabAsset,
                              fit: BoxFit.fill,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
