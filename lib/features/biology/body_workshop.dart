import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import 'illustrated_art.dart';

/// Separate touch buttons point to anatomical anchors without overlapping.
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
    return const Rect.fromLTWH(.14, 0, .72, .96);
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
  Widget _tray() => NameBatches(
    key: ValueKey('name-batches-${step.id}'),
    options: step.options,
    placements: placements,
    builder: (p) => Draggable<String>(
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
  );
  Widget _scene() => LayoutBuilder(
    builder: (context, box) {
      final height = eye ? 430.0 : 570.0;
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

      final markers = <String, Offset>{};
      const leftParts = {
        'shoulder',
        'arm',
        'elbow',
        'wrist',
        'hand',
        'fingers',
        'eyes',
        'eyebrow',
        'skin',
      };
      for (final left in [true, false]) {
        final column =
            spots.where((p) => leftParts.contains(p.id) == left).toList()
              ..sort((a, b) => point(a.id).dy.compareTo(point(b.id).dy));
        for (var i = 0; i < column.length; i++) {
          // Equal spacing keeps every 64 dp button separate, even at the wrist.
          markers[column[i].id] = Offset(
            left ? 36 : box.maxWidth - 36,
            column.length == 1
                ? height / 2
                : 36 + i * (height - 72) / (column.length - 1),
          );
        }
      }

      final asset = eye
          ? 'five-senses-v2.webp'
          : girl
          ? 'explorer-girl-v2.webp'
          : 'explorer-boy-v2.webp';
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
          child: Stack(
            children: [
              Positioned.fill(
                child: IllustratedArt(asset: asset, crop: crop),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _BodyLeaders([
                      for (final p in spots) (markers[p.id]!, point(p.id)),
                    ]),
                  ),
                ),
              ),
              for (final p in spots)
                Positioned.fromRect(
                  rect: Rect.fromCenter(
                    center: markers[p.id]!,
                    width: 64,
                    height: 64,
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
                      child: Material(
                        color:
                            hover.isNotEmpty ||
                                (!assembling && selected.contains(p.id)) ||
                                placements.containsValue(p.id)
                            ? const Color(0xFFFFD577)
                            : const Color(0xFFFFFCF4),
                        shape: const CircleBorder(
                          side: BorderSide(color: Color(0xFF356D75), width: 2),
                        ),
                        child: InkWell(
                          key: ValueKey('body-spot-${p.id}'),
                          customBorder: const CircleBorder(),
                          onTap: done ? null : () => chooseSpot(p.id),
                          child: Icon(
                            placements.containsValue(p.id)
                                ? Icons.check_rounded
                                : Icons.touch_app_rounded,
                            size: 30,
                            color: const Color(0xFF254957),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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

/// Shows the name labels a few at a time (AUD-018): thirteen labels at once
/// overloaded young children. Every body spot stays visible and active, and
/// placements are stored exactly as before, so objectives and scoring are
/// unchanged. When every name in a batch is placed, the next batch with an
/// unplaced name opens by itself.
class NameBatches extends StatefulWidget {
  const NameBatches({
    super.key,
    required this.options,
    required this.placements,
    required this.builder,
  });
  static const batchSize = 5;
  final List<PictureItem> options;
  final Map<String, String> placements;
  final Widget Function(PictureItem) builder;

  @override
  State<NameBatches> createState() => _NameBatchesState();
}

class _NameBatchesState extends State<NameBatches> {
  late int _page = _firstOpenPage();

  int get _pages => (widget.options.length / NameBatches.batchSize).ceil();

  List<PictureItem> _batch(int page) => widget.options
      .skip(page * NameBatches.batchSize)
      .take(NameBatches.batchSize)
      .toList();

  bool _complete(int page) =>
      _batch(page).every((p) => widget.placements.containsKey(p.id));

  int _firstOpenPage() {
    for (var page = 0; page < _pages; page++) {
      if (!_complete(page)) return page;
    }
    return 0;
  }

  // The lesson keeps one placements map and updates it in place, so the
  // count is remembered here rather than read from the old widget.
  late int _placed = widget.placements.length;

  @override
  void didUpdateWidget(NameBatches oldWidget) {
    super.didUpdateWidget(oldWidget);
    final placed = widget.placements.length;
    if (placed > _placed && _complete(_page)) {
      final next = _firstOpenPage();
      if (!_complete(next)) _page = next;
    }
    _placed = placed;
    if (_page >= _pages) _page = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_pages <= 1) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final p in widget.options) widget.builder(p)],
      );
    }
    final first = _page * NameBatches.batchSize + 1;
    final last = first + _batch(_page).length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final p in _batch(_page)) widget.builder(p)],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton.outlined(
              key: const ValueKey('names-previous'),
              tooltip: 'Previous names',
              iconSize: 30,
              constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
              onPressed: _page == 0 ? null : () => setState(() => _page--),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                '$first–$last / ${widget.options.length}',
                key: const ValueKey('names-range'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            IconButton.outlined(
              key: const ValueKey('names-next'),
              tooltip: 'More names',
              iconSize: 30,
              constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
              onPressed: _page + 1 >= _pages
                  ? null
                  : () => setState(() => _page++),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _BodyLeaders extends CustomPainter {
  const _BodyLeaders(this.points);
  final List<(Offset, Offset)> points;
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFF356D75)
      ..strokeWidth = 2;
    for (final (button, anchor) in points) {
      canvas.drawLine(
        button,
        anchor,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 5,
      );
      canvas.drawLine(button, anchor, line);
      canvas.drawCircle(anchor, 6, Paint()..color = Colors.white);
      canvas.drawCircle(anchor, 4, line);
    }
  }

  @override
  bool shouldRepaint(_BodyLeaders oldDelegate) => true;
}
