import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import 'science_picture.dart';
import '../biology/illustrated_art.dart';

/// Ungraded experiments retain guesses before revealing any source-defined result.
class ScienceLab extends StatefulWidget {
  const ScienceLab({
    super.key,
    required this.step,
    required this.data,
    required this.onChange,
    required this.onSpeak,
    required this.onSound,
  });
  final LessonStep step;
  final Map<String, dynamic> data;
  final Future<void> Function(Map<String, dynamic>, bool) onChange;
  final ValueChanged<String> onSpeak;
  final void Function(String, double) onSound;
  @override
  State<ScienceLab> createState() => _ScienceLabState();
}

class _ScienceLabState extends State<ScienceLab> {
  bool busy = false;
  Timer? breeze;
  String? starName;
  String get mode => widget.step.json['lab'];
  Map<String, dynamic> get state => widget.data;
  Map<String, dynamic> get ui =>
      Map<String, dynamic>.from(widget.step.json['labUi'] ?? {});
  List<String> get visited => List<String>.from(state['visited'] ?? []);
  Future<void> save(Map<String, dynamic> patch, {bool complete = false}) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await widget.onChange({...state, ...patch}, complete);
    } catch (_) {
      if (mounted) widget.onSpeak("Saving needs help. Please try again.");
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    breeze?.cancel();
    super.dispose();
  }

  Widget button(String key, String label, VoidCallback? action) => Padding(
    padding: const EdgeInsets.all(5),
    child: FilledButton.tonal(
      key: ValueKey('lab-$key'),
      onPressed: busy ? null : action,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    ),
  );
  Widget caption(String s) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(
      s,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
    ),
  );
  Widget picture(String art, [double height = 160]) =>
      SciencePicture(art, height: height);
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFE7EFF0),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      children: [
        if (['waterproof', 'tank', 'magnet', 'sound-box'].contains(mode))
          _experiment(),
        if (mode == 'force' || mode == 'distance') _slider(),
        if (mode == 'sailboat') _boat(),
        if (mode == 'shape') _shape(),
        if (mode == 'soil' || mode == 'cleanup' || mode == 'rock-sort')
          _collection(),
        if (mode == 'day-night') _day(),
        if (mode == 'earth-paint') _paint(),
        if (mode == 'stars') _stars(),
      ],
    ),
  );
  Widget _experiment() {
    final opts = widget.step.options;
    final active = state['active'] as String? ?? opts.first.id;
    final item = opts.firstWhere((o) => o.id == active);
    final guesses = Map<String, dynamic>.from(state['guesses'] ?? {});
    final tested = List<String>.from(state['tested'] ?? []);
    final revealed = tested.contains(active);
    final result = widget.step.json['results'][active] as String;
    final choices = Map<String, dynamic>.from(ui['choices']);
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (final p in opts)
              button('choose-${p.id}', p.label, () => save({'active': p.id})),
          ],
        ),
        SizedBox(
          height: 300,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              alignment: Alignment.center,
              children: [
                if (mode == 'tank')
                  Positioned(
                    left: box.maxWidth * .15,
                    right: box.maxWidth * .15,
                    top: 90,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF9FD5E5),
                        border: Border.all(
                          color: const Color(0xFF43778D),
                          width: 4,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(28),
                        ),
                      ),
                    ),
                  ),
                if (mode == 'waterproof')
                  Positioned(
                    top: 70,
                    child: Container(
                      width: 190,
                      height: 220,
                      decoration: BoxDecoration(
                        color: revealed && result == 'wet'
                            ? const Color(0xFF9FD5E5)
                            : const Color(0xFFFDFBF1),
                        border: Border.all(
                          color: const Color(0xFF67848E),
                          width: 4,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(30),
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: revealed
                            ? caption(choices[result])
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                if (mode == 'sound-box')
                  Positioned(
                    top: 75,
                    child: Container(
                      width: 235,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7B78A),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: revealed
                          ? Align(
                              alignment: Alignment.bottomCenter,
                              child: Icon(
                                result == 'loud'
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_down_rounded,
                                size: 52,
                                color: const Color(0xFF3B5665),
                              ),
                            )
                          : null,
                    ),
                  ),
                if (mode == 'magnet')
                  Positioned(
                    left: box.maxWidth * .08,
                    top: 60,
                    child: Draggable<String>(
                      data: 'magnet',
                      feedback: Material(
                        color: Colors.transparent,
                        child: picture('magnet', 130),
                      ),
                      childWhenDragging: const SizedBox(
                        width: 130,
                        height: 130,
                      ),
                      child: picture('magnet', 130),
                    ),
                  ),
                AnimatedPositioned(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 850),
                  curve: Curves.easeInOut,
                  left: mode == 'magnet' && revealed && result == 'pull'
                      ? box.maxWidth * .15
                      : (box.maxWidth - 140) / 2,
                  top: mode == 'tank'
                      ? (revealed ? (result == 'float' ? 60 : 170) : 0)
                      : mode == 'waterproof'
                      ? 20
                      : 75,
                  child: DragTarget<String>(
                    onWillAcceptWithDetails: (d) =>
                        mode == 'magnet' &&
                        d.data == 'magnet' &&
                        guesses.containsKey(active) &&
                        !revealed,
                    onAcceptWithDetails: (_) =>
                        test(active, tested, opts.length),
                    builder: (context, c, r) => picture(item.art, 130),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!revealed)
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (final e in choices.entries)
                button(
                  'guess-${e.key}',
                  '${guesses[active] == e.key ? '✓ ' : ''}${e.value}',
                  () => save({
                    'guesses': {...guesses, active: e.key},
                  }),
                ),
            ],
          ),
        if (!revealed)
          button(
            'test',
            ui['action'],
            guesses.containsKey(active)
                ? () => test(active, tested, opts.length)
                : null,
          ),
        if (revealed) ...[
          caption('${ui['result']}: ${choices[result]}'),
          caption('Your prediction: ${choices[guesses[active]]}'),
          const Icon(Icons.visibility_rounded, size: 30),
        ],
        caption('${tested.length} / ${opts.length} explored'),
      ],
    );
  }

  Future<void> test(String active, List<String> tested, int count) async {
    if (tested.contains(active) ||
        !(state['guesses'] as Map? ?? {}).containsKey(active))
      return;
    final next = {...tested, active}.toList();
    if (mode == 'sound-box')
      widget.onSound(active == 'stone_box' ? 'stone' : 'feather', 1);
    await save({'tested': next}, complete: next.length == count);
    if (mounted) {
      final item = widget.step.options.firstWhere((p) => p.id == active);
      final result = widget.step.json['results'][active];
      widget.onSpeak(
        next.length == count
            ? widget.step.explanation
            : '${item.label}. ${ui['choices'][result]}.',
      );
    }
  }

  Widget _slider() {
    final v = (state['position'] as num? ?? .5).toDouble();
    final marks = visited.toSet();
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              children: [
                if (mode == 'distance')
                  Positioned(left: 0, top: 35, child: picture('drum', 140)),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  left: (c.maxWidth - 150) * v,
                  top: 50,
                  child: picture(mode == 'force' ? 'drawer' : 'ears', 140),
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: mode == 'distance' ? 1 - v : v,
                    minHeight: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        caption(
          mode == 'force'
              ? (v < .5 ? ui['left'] : ui['right'])
              : (v < .5 ? ui['near'] : ui['far']),
        ),
        Slider(
          key: const ValueKey('lab-slider'),
          value: v,
          onChangeEnd: (x) {
            if (mode == 'distance') widget.onSound('drum', 1 - x);
          },
          onChanged: busy
              ? null
              : (x) => save(
                  {
                    'position': x,
                    'visited': {
                      ...marks,
                      if (x < .25) 'near',
                      if (x > .75) 'far',
                    }.toList(),
                  },
                  complete:
                      (marks.contains('near') || x < .25) &&
                      (marks.contains('far') || x > .75),
                ),
        ),
      ],
    );
  }

  Widget _boat() {
    final v = (state['distance'] as num? ?? 0).toDouble();
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              children: [
                Positioned.fill(
                  top: 160,
                  child: Container(color: const Color(0xFF9EDBE9)),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  left: (c.maxWidth - 160) * v,
                  top: 40,
                  child: picture('sailboat', 160),
                ),
              ],
            ),
          ),
        ),
        Listener(
          onPointerDown: (_) {
            breeze?.cancel();
            breeze = Timer.periodic(const Duration(milliseconds: 200), (_) {
              final d = ((state['distance'] as num? ?? 0) + .055).clamp(
                0.0,
                1.0,
              );
              save({'distance': d}, complete: d >= 1);
              if (d >= 1) breeze?.cancel();
            });
          },
          onPointerUp: (_) => breeze?.cancel(),
          onPointerCancel: (_) => breeze?.cancel(),
          child: button(
            'blow',
            ui['action'],
            () => save({
              'distance': (v + .15).clamp(0.0, 1.0),
            }, complete: v + .15 >= 1),
          ),
        ),
      ],
    );
  }

  Widget _shape() {
    final item = widget.step.options.firstWhere(
      (p) => p.id == state['active'],
      orElse: () => widget.step.options.first,
    );
    final action = state['action'];
    final soft = [
      'dough',
      'sponge',
      'rubber_band',
      'paper_straw',
    ].contains(item.id);
    return Column(
      children: [
        Wrap(
          children: [
            for (final p in widget.step.options)
              button(
                'shape-${p.id}',
                p.label,
                () => save({'active': p.id, 'action': null}),
              ),
          ],
        ),
        SizedBox(
          height: 240,
          child: Center(
            child: AnimatedRotation(
              turns: soft && action == 'Twist' ? 0.1 : 0,
              duration: const Duration(milliseconds: 600),
              child: AnimatedScale(
                scale: soft && action == 'Stretch' ? 1.2 : 1,
                duration: const Duration(milliseconds: 600),
                child: Transform.scale(
                  scaleX: soft && action == 'Squash' ? 1.4 : 1,
                  scaleY: soft && action == 'Squash' ? 0.55 : 1,
                  child: Transform.rotate(
                    angle: soft && action == 'Bend' ? 0.3 : 0,
                    child: picture(item.art),
                  ),
                ),
              ),
            ),
          ),
        ),
        Wrap(
          children: [
            for (final a in ui['actions'])
              button('action-$a', a, () {
                final v = {...visited, a as String}.toList();
                save({'action': a, 'visited': v}, complete: v.length == 4);
                widget.onSpeak('$a. ${widget.step.explanation}');
              }),
          ],
        ),
      ],
    );
  }

  Widget _collection() {
    final seen = visited;
    final all = widget.step.options;
    return Column(
      children: [
        if (mode == 'cleanup') picture('ocean', 170),
        if (mode == 'soil') ...[
          picture('soil', 150),
          const Draggable<String>(
            data: 'lens',
            feedback: Material(
              color: Colors.transparent,
              child: Icon(
                Icons.search_rounded,
                size: 100,
                color: Color(0xFF436E80),
              ),
            ),
            child: Icon(
              Icons.search_rounded,
              size: 72,
              color: Color(0xFF436E80),
            ),
          ),
        ],
        Wrap(
          spacing: 18,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            for (final p in all)
              if (mode != 'cleanup' || !seen.contains(p.id))
                DragTarget<String>(
                  onWillAcceptWithDetails: (d) =>
                      mode == 'soil' && d.data == 'lens',
                  onAcceptWithDetails: (_) {
                    final v = {...seen, p.id}.toList();
                    save({'visited': v}, complete: v.length == all.length);
                    widget.onSpeak(p.label);
                  },
                  builder: (context, hover, rejected) => InkWell(
                    key: ValueKey('lab-find-${p.id}'),
                    onTap: mode == 'rock-sort'
                        ? null
                        : () {
                            final v = {...seen, p.id}.toList();
                            save({
                              'visited': v,
                            }, complete: v.length == all.length);
                            widget.onSpeak(p.label);
                          },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: seen.contains(p.id)
                            ? const Color(0xFFCEEBDB)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          picture(
                            p.art,
                            mode == 'soil' && seen.contains(p.id) ? 155 : 110,
                          ),
                          caption(p.label),
                          if (mode == 'rock-sort')
                            Wrap(
                              children: [
                                for (final g in ui['groups'])
                                  button(
                                    'group-${p.id}-$g',
                                    '${state[p.id] == g ? '✓ ' : ''}$g',
                                    () {
                                      final v = {...seen, p.id}.toList();
                                      save({
                                        p.id: g,
                                        'visited': v,
                                      }, complete: v.length == all.length);
                                    },
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
        caption('${seen.length} / ${all.length} explored'),
      ],
    );
  }

  Widget _day() {
    final turns = (state['turns'] as int? ?? 0);
    final angle = turns * math.pi / 2;
    return Column(
      children: [
        SizedBox(
          height: 310,
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              alignment: Alignment.center,
              children: [
                Positioned(left: 0, child: picture('sun', 110)),
                Positioned(
                  right: c.maxWidth * .1,
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      children: [
                        ClipOval(
                          child: Transform.rotate(
                            angle: angle,
                            child: const SizedBox(
                              width: 220,
                              height: 220,
                              child: IllustratedArt(
                                asset: 'earth-atlas-v1.png',
                                crop: Rect.fromLTWH(.009, .75, .225, .225),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 110,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xBB172A43),
                              borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(110),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 95 + 80 * math.cos(angle),
                          top: 95 + 80 * math.sin(angle),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 28,
                            color: Color(0xFFEB5D51),
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
        caption(math.cos(angle) < 0 ? 'Your place: Day' : 'Your place: Night'),
        button(
          'turn',
          ui['action'],
          () => save({'turns': turns + 1}, complete: turns + 1 >= 4),
        ),
      ],
    );
  }

  Widget _paint() => Column(
    children: [
      SizedBox(
        height: 280,
        width: 280,
        child: CustomPaint(
          painter: PlanetPainter(
            water: state['water'] == true,
            land: state['land'] == true,
          ),
        ),
      ),
      Wrap(
        children: [
          button(
            'water',
            ui['water'],
            () => save({'water': true}, complete: state['land'] == true),
          ),
          button(
            'land',
            ui['land'],
            () => save({'land': true}, complete: state['water'] == true),
          ),
        ],
      ),
    ],
  );
  Widget _stars() {
    final points = List<int>.from(state['points'] ?? []);
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: LayoutBuilder(
            builder: (context, c) => GestureDetector(
              key: const ValueKey('lab-stars'),
              onTapUp: (d) {
                final p = StarPainter.locations;
                var nearest = 0;
                var dist = double.infinity;
                for (var i = 0; i < p.length; i++) {
                  final x =
                      (Offset(p[i].dx * c.maxWidth, p[i].dy * 320) -
                              d.localPosition)
                          .distance;
                  if (x < dist) {
                    nearest = i;
                    dist = x;
                  }
                }
                if (dist < 48 && !points.contains(nearest))
                  save({
                    'points': [...points, nearest],
                  });
              },
              child: CustomPaint(
                size: Size(c.maxWidth, 320),
                painter: StarPainter(points),
              ),
            ),
          ),
        ),
        TextFormField(
          key: const ValueKey('lab-star-name'),
          initialValue: state['name'] ?? '',
          decoration: InputDecoration(labelText: ui['name']),
          onChanged: (s) {
            starName = s;
            save({'name': s});
          },
        ),
        button(
          'finish-stars',
          ui['finish'],
          points.length >= 3
              ? () => save({
                  'name': starName ?? state['name'] ?? '',
                }, complete: true)
              : null,
        ),
      ],
    );
  }
}

class PlanetPainter extends CustomPainter {
  PlanetPainter({required this.water, required this.land});
  final bool water, land;
  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawOval(
      r,
      Paint()
        ..color = water ? const Color(0xFF4AA6D5) : const Color(0xFFDFE8EF),
    );
    c.save();
    c.clipPath(Path()..addOval(r));
    for (final rect in [
      const Rect.fromLTWH(.18, .12, .28, .25),
      const Rect.fromLTWH(.28, .48, .16, .35),
      const Rect.fromLTWH(.63, .2, .32, .22),
    ]) {
      c.drawOval(
        Rect.fromLTWH(
          rect.left * s.width,
          rect.top * s.height,
          rect.width * s.width,
          rect.height * s.height,
        ),
        Paint()
          ..color = land ? const Color(0xFF75AA72) : const Color(0xFFB8BEC1),
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(PlanetPainter old) =>
      old.water != water || old.land != land;
}

class StarPainter extends CustomPainter {
  StarPainter(this.points);
  final List<int> points;
  static const locations = [
    Offset(.12, .25),
    Offset(.3, .15),
    Offset(.51, .32),
    Offset(.75, .15),
    Offset(.9, .4),
    Offset(.78, .77),
    Offset(.55, .68),
    Offset(.3, .83),
    Offset(.14, .63),
  ];
  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(25)),
      Paint()..color = const Color(0xFF213754),
    );
    Offset p(int i) =>
        Offset(locations[i].dx * s.width, locations[i].dy * s.height);
    for (var i = 1; i < points.length; i++) {
      c.drawLine(
        p(points[i - 1]),
        p(points[i]),
        Paint()
          ..color = const Color(0xFFF6D692)
          ..strokeWidth = 3,
      );
    }
    for (var i = 0; i < locations.length; i++) {
      c.drawCircle(
        p(i),
        points.contains(i) ? 10 : 7,
        Paint()..color = const Color(0xFFFFE5AA),
      );
    }
  }

  @override
  bool shouldRepaint(StarPainter old) => true;
}
