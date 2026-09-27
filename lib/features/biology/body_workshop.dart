import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import 'illustrated_art.dart';

/// Direct touch and drag over the artwork. No numbered markers cover the picture.
class BodyWorkshop extends StatelessWidget {
  const BodyWorkshop({
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
  bool get eye => step.scene == 'eye';
  bool get assembling => step.kind == 'label-diagram';
  String? get chosen => selected.firstOrNull;
  Map<String, Offset> get anchors =>
      eye ? illustratedEyeAnchors : illustratedBodyAnchors;
  Rect get camera {
    if (eye) return const Rect.fromLTWH(.035, .10, .93, .66);
    final id = chosen;
    if (!assembling || id == null) return const Rect.fromLTWH(.14, 0, .72, .96);
    if (['head', 'chin', 'neck'].contains(id))
      return const Rect.fromLTWH(.28, .045, .44, .25);
    if (['shoulder', 'arm', 'elbow'].contains(id))
      return const Rect.fromLTWH(.20, .27, .29, .23);
    if (['wrist', 'hand', 'fingers'].contains(id))
      return const Rect.fromLTWH(.14, .48, .20, .14);
    return const Rect.fromLTWH(.26, .63, .45, .32);
  }

  List<PictureItem> get spots => (assembling ? step.targets : step.options)
      .where(
        (p) => anchors.containsKey(p.id) && camera.contains(anchors[p.id]!),
      )
      .toList();
  void chooseSpot(String id) {
    if (done) return;
    if (assembling) {
      if (chosen != null) onPlace(chosen!, id);
    } else {
      onItem(id);
    }
  }

  Widget _piece(PictureItem p) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: ValueKey('body-piece-${p.id}'),
      onTap: done ? null : () => onItem(p.id),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64, minWidth: 110),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: chosen == p.id
              ? const Color(0xFFFFE4A1)
              : const Color(0xFFFFFCF4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: chosen == p.id
                ? const Color(0xFFBA8845)
                : const Color(0xFFD8D4BE),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (placements.containsKey(p.id))
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.link, size: 20),
              ),
            Flexible(
              child: Text(
                p.label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _tray() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final p in step.options)
        Draggable<String>(
          data: p.id,
          maxSimultaneousDrags: done ? 0 : 1,
          onDragStarted: () => onItem(p.id),
          feedback: Material(
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(p.label, style: const TextStyle(fontSize: 24)),
            ),
          ),
          childWhenDragging: Opacity(opacity: .4, child: _piece(p)),
          child: _piece(p),
        ),
    ],
  );
  Widget _scene() => LayoutBuilder(
    builder: (context, box) {
      final height = eye
          ? 430.0
          : assembling && chosen != null
          ? 480.0
          : 570.0;
      final frame = eye ? const Size(434.4, 724) : const Size(1024, 1536);
      final source = Rect.fromLTWH(
        camera.left * frame.width,
        camera.top * frame.height,
        camera.width * frame.width,
        camera.height * frame.height,
      );
      final fit = applyBoxFit(
        BoxFit.contain,
        source.size,
        Size(box.maxWidth, height),
      );
      final destination = Alignment.center.inscribe(
        fit.destination,
        Rect.fromLTWH(0, 0, box.maxWidth, height),
      );
      Offset point(String id) {
        final a = anchors[id]!;
        return Offset(
          destination.left +
              (a.dx * frame.width - source.left) *
                  destination.width /
                  source.width,
          destination.top +
              (a.dy * frame.height - source.top) *
                  destination.height /
                  source.height,
        );
      }

      final asset = eye
          ? 'five-senses-v2.png'
          : girl
          ? 'explorer-girl-v2.png'
          : 'explorer-boy-v2.png';
      final crop = eye
          ? Rect.fromLTWH(
              camera.left * .2,
              camera.top,
              camera.width * .2,
              camera.height,
            )
          : camera;
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: height,
          color: const Color(0xFFFFFBEE),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (event) {
              final candidates = [...spots]
                ..sort(
                  (a, b) => (point(a.id) - event.localPosition).distance
                      .compareTo((point(b.id) - event.localPosition).distance),
                );
              if (candidates.isNotEmpty &&
                  (point(candidates.first.id) - event.localPosition).distance <
                      52)
                chooseSpot(candidates.first.id);
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: IllustratedArt(asset: asset, crop: crop),
                ),
                for (final p in spots)
                  Positioned.fromRect(
                    rect: Rect.fromCenter(
                      center: point(p.id),
                      width: 72,
                      height: 72,
                    ),
                    child: DragTarget<String>(
                      onWillAcceptWithDetails: (d) =>
                          assembling &&
                          !done &&
                          step.options.any((o) => o.id == d.data),
                      onAcceptWithDetails: (d) => onPlace(d.data, p.id),
                      builder: (context, hover, rejected) => Semantics(
                        label: p.label,
                        button: true,
                        onTap: () => chooseSpot(p.id),
                        child: Container(
                          key: ValueKey('body-spot-${p.id}'),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: hover.isNotEmpty
                                ? Border.all(
                                    color: const Color(0xFFD7A148),
                                    width: 3,
                                  )
                                : null,
                            color: hover.isNotEmpty
                                ? const Color(0x33FFD25B)
                                : Colors.transparent,
                          ),
                        ),
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
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (assembling)
        LayoutBuilder(
          builder: (context, box) => box.maxWidth >= 760
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 260, child: _tray()),
                    const SizedBox(width: 18),
                    Expanded(child: _scene()),
                  ],
                )
              : Column(
                  children: [_tray(), const SizedBox(height: 14), _scene()],
                ),
        )
      else
        _scene(),
      if (!assembling && selected.isNotEmpty)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            selected.map(step.label).join(' · '),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24),
          ),
        ),
    ],
  );
}
