import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/touch_cue.dart';
import 'science_picture.dart';
import 'science_world_stage.dart';

/// Open exploration and the child's own grouping rule have no answer key.
class EarthCollection extends StatefulWidget {
  const EarthCollection({
    super.key,
    required this.step,
    required this.data,
    required this.onChange,
    required this.onSpeak,
    this.onFeedback,
  });
  final LessonStep step;
  final Map<String, dynamic> data;
  final Future<void> Function(Map<String, dynamic>, bool) onChange;
  final ValueChanged<String> onSpeak;
  final ValueChanged<String>? onFeedback;

  @override
  State<EarthCollection> createState() => _EarthCollectionState();
}

class _EarthCollectionState extends State<EarthCollection> {
  bool busy = false;
  int spot = 0, rock = 0;
  String? discovered;
  String get mode => widget.step.json['lab'];
  List<PictureItem> get options => widget.step.options;
  Set<String> get visited => Set<String>.from(widget.data['visited'] ?? []);
  List<String> get groups =>
      List<String>.from(widget.step.json['labUi']?['groups'] ?? []);
  static const soilSpots = [
    ['small_stones', 'dead_leaf'],
    ['tiny_insect', 'sand'],
    ['worm'],
  ];
  static const spotNames = ['Leaves', 'Sand', 'Below'];
  static const spotStories = [
    'Look beside the fallen leaf. What can you find?',
    'Look closely at this sandy patch.',
    'What is moving under the soil?',
  ];

  @override
  void initState() {
    super.initState();
    resume();
  }

  @override
  void didUpdateWidget(EarthCollection old) {
    super.didUpdateWidget(old);
    if (old.step.id != widget.step.id) {
      discovered = null;
      resume();
    }
  }

  void resume() {
    final nextSpot = soilSpots.indexWhere(
      (ids) => ids.any((id) => !visited.contains(id)),
    );
    spot = nextSpot < 0 ? 0 : nextSpot;
    final nextRock = options.indexWhere(
      (item) => !groups.contains(widget.data[item.id]),
    );
    rock = nextRock < 0 ? 0 : nextRock;
  }

  String groupName(String id) =>
      widget.data['groupLabels']?[id] as String? ?? id;
  void feedback(String value) {
    widget.onFeedback?.call(value);
    widget.onSpeak(value);
  }

  Future<bool> save(Map<String, dynamic> patch) async {
    if (busy) return false;
    setState(() => busy = true);
    final next = {...widget.data, ...patch};
    final seen = Set<String>.from(next['visited'] ?? []);
    final complete = options.every((item) => seen.contains(item.id));
    try {
      await widget.onChange(next, complete);
      return true;
    } catch (_) {
      feedback('Saving needs help. Please try again.');
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> findItem(PictureItem item) async {
    if (busy) return;
    if (!visited.contains(item.id) &&
        !await save({
          'visited': {...visited, item.id}.toList(),
        }))
      return;
    if (!mounted) return;
    setState(() => discovered = item.id);
    feedback(item.label);
  }

  Future<void> placeRock(String id, String group) async {
    if (busy ||
        !groups.contains(group) ||
        !options.any((item) => item.id == id))
      return;
    final item = options.firstWhere((item) => item.id == id);
    final assignments = {...widget.data, id: group};
    if (!await save({
          id: group,
          'visited': {...visited, id}.toList(),
        }) ||
        !mounted)
      return;
    feedback('${item.label} is in ${groupName(group)}. Your rule is welcome.');
    final next = options.indexWhere(
      (item) => !groups.contains(assignments[item.id]),
    );
    if (next >= 0) setState(() => rock = next);
  }

  Widget caption(String value, {double size = 20}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w700),
    ),
  );

  Widget scene(Widget child, {double height = 285, bool beach = false}) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Stack(
            children: [
              const Positioned.fill(child: ScienceWorldBackdrop(row: 1)),
              Positioned.fill(
                child: CustomPaint(painter: _CollectionGround(beach: beach)),
              ),
              Positioned.fill(child: child),
            ],
          ),
        ),
      );

  Widget picture(PictureItem item, double height) => item.id == 'small_stones'
      ? EarthRockPicture(index: 0, height: height)
      : item.id == 'plastic_bag'
      ? SizedBox(
          width: height * 1.25,
          height: height,
          child: const CustomPaint(painter: _BagPainter()),
        )
      : SciencePicture(item.art, height: height);

  Widget specimen(PictureItem item, {bool litter = false}) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('lab-find-${item.id}'),
        onTap: busy ? null : () => findItem(item),
        borderRadius: BorderRadius.circular(18),
        child: Semantics(
          label: item.label,
          button: true,
          child: SizedBox(
            width: 84,
            height: litter ? 90 : 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                picture(item, 66),
                if (!visited.contains(item.id))
                  const Positioned(right: 0, bottom: 0, child: TouchCue()),
              ],
            ),
          ),
        ),
      ),
    );
    if (litter) {
      return Draggable<String>(
        data: item.id,
        maxSimultaneousDrags: busy ? 0 : 1,
        feedback: Material(color: Colors.transparent, child: picture(item, 80)),
        childWhenDragging: Opacity(opacity: .25, child: child),
        child: child,
      );
    }
    return DragTarget<String>(
      key: ValueKey('soil-lens-target-${item.id}'),
      onWillAcceptWithDetails: (details) => !busy && details.data == 'lens',
      onAcceptWithDetails: (_) => findItem(item),
      builder: (context, candidates, rejected) => child,
    );
  }

  Widget soil() {
    final items = options
        .where((item) => soilSpots[spot].contains(item.id))
        .toList();
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < soilSpots.length; i++)
              OutlinedButton(
                key: ValueKey('lab-soil-spot-$i'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: busy
                    ? null
                    : () {
                        setState(() {
                          spot = i;
                          discovered = null;
                        });
                        feedback(spotStories[i]);
                      },
                child: Text(spotNames[i], textAlign: TextAlign.center),
              ),
          ],
        ),
        caption(spotStories[spot]),
        scene(
          LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                for (var i = 0; i < items.length; i++)
                  Positioned(
                    left:
                        box.maxWidth *
                            (items.length == 1
                                ? .5
                                : i == 0
                                ? .25
                                : .75) -
                        42,
                    top: i == 0 ? 125 : 80,
                    child: specimen(items[i]),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Draggable<String>(
              key: ValueKey('lab-soil-lens'),
              data: 'lens',
              feedback: Material(
                color: Colors.transparent,
                child: Icon(
                  Icons.search_rounded,
                  size: 80,
                  color: Color(0xFF436E80),
                ),
              ),
              child: SizedBox(
                width: 60,
                height: 60,
                child: Icon(
                  Icons.search_rounded,
                  size: 52,
                  color: Color(0xFF436E80),
                ),
              ),
            ),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'Tap a hand, or drag the magnifier.',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        if (discovered != null) caption(widget.step.label(discovered!)),
      ],
    );
  }

  Widget cleanup() => Column(
    children: [
      caption('Tap the litter, or drag it into the basket.'),
      scene(
        LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              for (var i = 0; i < options.length; i++)
                if (!visited.contains(options[i].id))
                  Positioned(
                    left: box.maxWidth * const [.20, .59, .40][i] - 42,
                    top: i == 2 ? 12 : 112,
                    child: specimen(options[i], litter: true),
                  ),
              Positioned(
                right: 10,
                bottom: 12,
                child: DragTarget<String>(
                  key: const ValueKey('lab-litter-basket'),
                  onWillAcceptWithDetails: (details) =>
                      !busy &&
                      options.any(
                        (item) =>
                            item.id == details.data &&
                            !visited.contains(item.id),
                      ),
                  onAcceptWithDetails: (details) => findItem(
                    options.firstWhere((item) => item.id == details.data),
                  ),
                  builder: (context, candidates, rejected) => Semantics(
                    label: 'Litter basket',
                    child: Container(
                      width: 90,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB18B61),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF785A3B),
                          width: candidates.isEmpty ? 2 : 4,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${visited.length} / ${options.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        beach: true,
        height: 300,
      ),
      if (visited.length == options.length)
        caption('The beach is clean. You helped protect its animals!'),
    ],
  );

  Future<void> nameGroups() async {
    final names = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _GroupNamesDialog(
        groups: groups,
        names: {for (final id in groups) id: groupName(id)},
      ),
    );
    if (names != null && mounted) await save({'groupLabels': names});
  }

  Widget rockBin(String group, double width) {
    final current = options[rock];
    final members = options
        .where((item) => widget.data[item.id] == group)
        .toList();
    return SizedBox(
      width: width,
      child: DragTarget<String>(
        key: ValueKey('rock-bin-$group'),
        onWillAcceptWithDetails: (details) =>
            !busy && options.any((item) => item.id == details.data),
        onAcceptWithDetails: (details) => placeRock(details.data, group),
        builder: (context, candidates, rejected) => Material(
          color: const Color(0xFFE8DDC5),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            key: ValueKey('lab-group-${current.id}-$group'),
            borderRadius: BorderRadius.circular(20),
            onTap: busy ? null : () => placeRock(current.id, group),
            child: Container(
              constraints: const BoxConstraints(minHeight: 110),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF92785C),
                  width: candidates.isEmpty ? 1 : 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    groupName(group),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      for (final item in members)
                        EarthRockPicture(
                          index: options.indexOf(item),
                          height: 38,
                        ),
                    ],
                  ),
                  if (members.isEmpty) const TouchCue(),
                  Text(
                    '${members.length} rocks',
                    style: const TextStyle(fontSize: 17),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget rockSort() {
    final item = options[rock];
    return Column(
      children: [
        scene(
          Center(
            child: Draggable<String>(
              key: ValueKey('lab-find-${item.id}'),
              data: item.id,
              maxSimultaneousDrags: busy ? 0 : 1,
              feedback: Material(
                color: Colors.transparent,
                child: EarthRockPicture(index: rock, height: 110),
              ),
              child: Stack(
                children: [
                  EarthRockPicture(index: rock, height: 125),
                  const Positioned(right: 0, bottom: 0, child: TouchCue()),
                ],
              ),
            ),
          ),
          height: 180,
        ),
        caption(item.label),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: const ValueKey('lab-rock-previous'),
              tooltip: 'Previous rock',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: busy || rock == 0
                  ? null
                  : () => setState(() => rock--),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                'Rock ${rock + 1} / ${options.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            IconButton(
              key: const ValueKey('lab-rock-next'),
              tooltip: 'Next rock',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: busy || rock + 1 == options.length
                  ? null
                  : () => setState(() => rock++),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
        TextButton.icon(
          key: const ValueKey('lab-rock-name-groups'),
          onPressed: busy ? null : nameGroups,
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          icon: const Icon(Icons.edit_rounded),
          label: const Text('Name my groups'),
        ),
        LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth < 440
                ? box.maxWidth
                : (box.maxWidth - 14) / 2;
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 14,
              children: [for (final group in groups) rockBin(group, width)],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (mode == 'soil')
        soil()
      else if (mode == 'cleanup')
        cleanup()
      else
        rockSort(),
      caption(
        '${visited.where((id) => options.any((item) => item.id == id)).length} / ${options.length} explored',
        size: 18,
      ),
    ],
  );
}

class _GroupNamesDialog extends StatefulWidget {
  const _GroupNamesDialog({required this.groups, required this.names});
  final List<String> groups;
  final Map<String, String> names;
  @override
  State<_GroupNamesDialog> createState() => _GroupNamesDialogState();
}

class _GroupNamesDialogState extends State<_GroupNamesDialog> {
  late final controllers = [
    for (final id in widget.groups)
      TextEditingController(text: widget.names[id]),
  ];
  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Name your groups'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose your own rule: size, colour, texture, or another idea.',
          ),
          for (var i = 0; i < widget.groups.length; i++)
            TextField(
              key: ValueKey('rock-group-name-$i'),
              controller: controllers[i],
              maxLength: 32,
              decoration: InputDecoration(labelText: widget.groups[i]),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Back'),
      ),
      FilledButton(
        key: const ValueKey('rock-group-names-save'),
        onPressed: () => Navigator.pop(context, {
          for (var i = 0; i < widget.groups.length; i++)
            widget.groups[i]: controllers[i].text.trim().isEmpty
                ? widget.groups[i]
                : controllers[i].text.trim(),
        }),
        child: const Text('Use my names'),
      ),
    ],
  );
}

class EarthRockPicture extends StatelessWidget {
  const EarthRockPicture({super.key, required this.index, this.height = 110});
  final int index;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: height * 1.4,
    height: height,
    child: CustomPaint(painter: _RockPainter(index)),
  );
}

class _RockPainter extends CustomPainter {
  const _RockPainter(this.index);
  final int index;
  @override
  void paint(Canvas canvas, Size size) {
    final shape = index % 4;
    final colour = const [
      Color(0xFF8B9295),
      Color(0xFF3F4546),
      Color(0xFF99744E),
      Color(0xFFE0D2AE),
    ][shape];
    final bounds = shape == 2
        ? Rect.fromLTWH(
            size.width * .22,
            size.height * .36,
            size.width * .54,
            size.height * .48,
          )
        : Rect.fromLTWH(
            size.width * .06,
            size.height * .20,
            size.width * .88,
            size.height * .68,
          );
    canvas.drawOval(
      Rect.fromLTWH(bounds.left, bounds.bottom - 6, bounds.width, 12),
      Paint()..color = const Color(0x22000000),
    );
    final path = Path();
    if (shape == 0 || shape == 3) {
      path.moveTo(bounds.left, bounds.center.dy);
      path.cubicTo(
        bounds.left,
        bounds.top,
        bounds.right * .75,
        bounds.top - 5,
        bounds.right,
        bounds.center.dy,
      );
      path.cubicTo(
        bounds.right + 3,
        bounds.bottom,
        bounds.left + 4,
        bounds.bottom + 6,
        bounds.left,
        bounds.center.dy,
      );
    } else {
      path.moveTo(bounds.left, bounds.top + bounds.height * .65);
      for (final point in const [
        Offset(.16, .14),
        Offset(.40, 0),
        Offset(.58, .13),
        Offset(.83, .05),
        Offset(1, .44),
        Offset(.89, .89),
        Offset(.62, 1),
        Offset(.21, .91),
      ]) {
        path.lineTo(
          bounds.left + bounds.width * point.dx,
          bounds.top + bounds.height * point.dy,
        );
      }
      path.close();
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(colour, Colors.white, .28)!,
            colour,
            Color.lerp(colour, Colors.black, .22)!,
          ],
        ).createShader(bounds),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Color.lerp(colour, Colors.black, .25)!,
    );
    canvas.save();
    canvas.clipPath(path);
    for (var i = 0; i < (shape == 0 ? 8 : 32); i++) {
      final x = bounds.left + bounds.width * ((i * 31 % 97) / 97);
      final y = bounds.top + bounds.height * ((i * 47 % 89) / 89);
      canvas.drawCircle(
        Offset(x, y),
        shape == 0 ? .7 : 1.5,
        Paint()
          ..color = i.isEven
              ? const Color(0x35FFFFFF)
              : const Color(0x35000000),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RockPainter old) => old.index != index;
}

class _CollectionGround extends CustomPainter {
  const _CollectionGround({this.beach = false});
  final bool beach;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * .43)
      ..quadraticBezierTo(
        size.width * .45,
        size.height * .25,
        size.width,
        size.height * .49,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = beach ? const Color(0xFFDBC899) : const Color(0xFFAF8961),
    );
    if (beach) {
      final water = Path()
        ..moveTo(0, size.height * .70)
        ..quadraticBezierTo(
          size.width * .5,
          size.height * .83,
          size.width,
          size.height * .73,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(water, Paint()..color = const Color(0xFF9CC8D1));
    }
  }

  @override
  bool shouldRepaint(_CollectionGround old) => old.beach != beach;
}

class _BagPainter extends CustomPainter {
  const _BagPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final bag = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(w * .17, h * .24)
      ..quadraticBezierTo(w * .19, h * .10, w * .35, h * .09)
      ..lineTo(w * .40, h * .33)
      ..lineTo(w * .60, h * .33)
      ..lineTo(w * .65, h * .09)
      ..quadraticBezierTo(w * .81, h * .10, w * .83, h * .24)
      ..lineTo(w * .87, h * .85)
      ..quadraticBezierTo(w * .5, h * 1.05, w * .13, h * .85)
      ..close()
      ..addOval(Rect.fromLTWH(w * .22, h * .16, w * .10, h * .19))
      ..addOval(Rect.fromLTWH(w * .68, h * .16, w * .10, h * .19));
    canvas.drawPath(bag, Paint()..color = const Color(0xAAF1F7EF));
    final edge = Paint()
      ..color = const Color(0xFF88A9A4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(bag, edge);
    canvas.drawPath(
      Path()
        ..moveTo(w * .25, h * .48)
        ..quadraticBezierTo(w * .45, h * .62, w * .30, h * .88)
        ..moveTo(w * .73, h * .40)
        ..quadraticBezierTo(w * .56, h * .64, w * .71, h * .87),
      edge..color = const Color(0xAAAFBFB0),
    );
  }

  @override
  bool shouldRepaint(_BagPainter old) => false;
}
