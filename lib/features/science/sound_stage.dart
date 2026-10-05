import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/touch_cue.dart';
import 'sound_picture.dart';
import 'sound_distance.dart';
import 'sound_ui.dart';

/// Playback and context never consult assessment answers.
class SoundStage extends StatefulWidget {
  const SoundStage({
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
  final Set<String> selected, reviewItems;
  final Map<String, String> placements;
  final bool done;
  final ValueChanged<String> onItem;
  final void Function(String, String) onPlace;
  final void Function(String, double)? onSound;
  final ValueChanged<String>? onSpeak;
  final ValueChanged<List<String>>? onOrder;
  final ValueChanged<Map<String, String>>? onOrderPlacements;
  @override
  State<SoundStage> createState() => _SoundStageState();
}

class _SoundStageState extends State<SoundStage> {
  String? played;
  String? focused;
  int pulse = 0;
  double listenerPosition = .85;
  String? orderFocus;
  LessonStep get step => widget.step;
  Map<dynamic, dynamic> get ui => step.json['soundScene'];
  String get mode => ui['mode'];
  @override
  void didUpdateWidget(covariant SoundStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.id != widget.step.id) {
      focused = null;
      orderFocus = null;
      played = null;
      pulse = 0;
      listenerPosition = .85;
    }
  }

  void choose(String id) {
    if (widget.done && !step.isFree) return;
    focused = id;
    if (step.isFree) {
      setState(() {
        played = id;
        pulse++;
      });
    }
    widget.onItem(id);
  }

  void play(String art, {double volume = 1, String? id}) {
    setState(() {
      played = id ?? art;
      pulse++;
    });
    widget.onSound?.call(art, volume);
  }

  Widget text(String value, {double size = 21}) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w600),
    ),
  );
  Widget reservedText(
    String? value,
    Iterable<String> possibleValues, {
    double size = 21,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final style = DefaultTextStyle.of(context).style
          .merge(TextStyle(fontSize: size, fontWeight: FontWeight.w600));
      var height = 0.0;
      for (final label in possibleValues) {
        final painter =
            TextPainter(
              text: TextSpan(text: label, style: style),
              textDirection: Directionality.of(context),
              textAlign: TextAlign.center,
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(
              maxWidth: (constraints.maxWidth - 20).clamp(0.0, double.infinity),
            );
        if (painter.height > height) height = painter.height;
        painter.dispose();
      }
      return SizedBox(
        height: height.ceilToDouble() + 20,
        child: value == null ? null : text(value, size: size),
      );
    },
  );
  Widget cue(String id) => widget.reviewItems.contains(id)
      ? Semantics(
          key: ValueKey('review-item-$id'),
          label: step.json['correctionUi']['review'],
          child: const Icon(
            Icons.help_outline_rounded,
            size: 30,
            color: Color(0xFF956E42),
          ),
        )
      : const TouchCue();
  Widget artwork(
    String art,
    double height, {
    String? id,
    bool animate = false,
  }) {
    if (art == 'band_question') {
      return SizedBox(
        height: height,
        width: height * 1.25,
        child: Row(
          children: [
            SoundPicture('trumpet', height: height * .5),
            SoundPicture('sitar', height: height * .5),
          ],
        ),
      );
    }
    if (art == 'music') {
      return SizedBox(
        height: height,
        width: height * 1.25,
        child: const Icon(
          Icons.music_note_rounded,
          size: 70,
          color: Color(0xFF648B9F),
        ),
      );
    }
    return SoundDemonstration(
      art,
      height: height,
      key: ValueKey(
        'sound-art-${id ?? art}-${played == (id ?? art) ? pulse : 0}',
      ),
      play: animate && played == (id ?? art),
      strength: id == 'gentle' ? .35 : 1,
    );
  }

  Widget object(PictureItem p, {double height = 145, double width = 200}) {
    final chosen = widget.selected.contains(p.id);
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('science-item-${p.id}'),
          onTap: widget.done && !step.isFree ? null : () => choose(p.id),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: mode == 'band'
                  ? Colors.transparent
                  : chosen
                  ? const Color(0xFFE1EBEE)
                  : const Color(0xFFFDF5E7),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: mode == 'band' && !chosen
                    ? Colors.transparent
                    : chosen
                    ? const Color(0xFF5C8291)
                    : const Color(0xFFD8C9AE),
                width: mode == 'band' || chosen ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    artwork(
                      p.art,
                      height,
                      id: p.id,
                      animate: step.isFree || mode == 'boxes' || mode == 'band',
                    ),
                    if (!widget.done)
                      Positioned(bottom: 0, right: 0, child: cue(p.id)),
                  ],
                ),
                text(p.label, size: 19),
                if (mode == 'band' && !step.isFree)
                  Semantics(
                    label: '${ui['listen']}: ${p.label}',
                    child: replay(
                      'sound-listen-${p.id}',
                      () => play(p.art, id: p.id),
                    ),
                  ),
                if (mode == 'band' && step.isMapping)
                  reservedText(
                    widget.placements.containsKey(p.id)
                        ? step.label(widget.placements[p.id]!)
                        : null,
                    step.targets.map((target) => target.label),
                    size: 18,
                  )
                else if (step.isMapping && widget.placements.containsKey(p.id))
                  text(step.label(widget.placements[p.id]!), size: 18),
                if (step.isOrder && chosen)
                  Text(
                    '${widget.selected.toList().indexOf(p.id) + 1}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget choice(
    PictureItem p, {
    bool target = false,
    double width = 220,
    String? item,
  }) => SizedBox(
    width: width,
    child: FilledButton.tonal(
      key: ValueKey('science-${target ? 'target' : 'item'}-${p.id}'),
      onPressed:
          widget.done || (target && item == null && widget.selected.isEmpty)
          ? null
          : () => target
                ? widget.onPlace(item ?? widget.selected.first, p.id)
                : choose(p.id),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.all(14),
        backgroundColor: !target && widget.selected.contains(p.id)
            ? const Color(0xFFD7E6EB)
            : const Color(0xFFF8F1E6),
        foregroundColor: const Color(0xFF3D5966),
        side: BorderSide(
          color: !target && widget.selected.contains(p.id)
              ? const Color(0xFF507D91)
              : const Color(0xFFC6BCA9),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            p.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21),
          ),
          if (!target && step.isMapping && widget.placements.containsKey(p.id))
            text(step.label(widget.placements[p.id]!), size: 18),
          if (!target && !widget.done) cue(p.id),
        ],
      ),
    ),
  );
  Widget choices() => Wrap(
    alignment: WrapAlignment.center,
    spacing: 12,
    runSpacing: 12,
    children: [for (final p in step.options) choice(p)],
  );
  Widget replay(String key, VoidCallback action, {String? label}) =>
      TextButton.icon(
        key: ValueKey(key),
        onPressed: action,
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        icon: const Icon(Icons.volume_up_rounded),
        label: Text(
          label ?? ui['listen'],
          style: const TextStyle(fontSize: 19),
        ),
      );
  List<PictureItem> get targets => step.targets.where((p) {
    final groups = ui['targetGroups'];
    return groups == null ||
        (widget.selected.isNotEmpty &&
            (groups[widget.selected.first] as List).contains(p.id));
  }).toList();
  Widget answerTray() => Column(
    children: [
      if (mode == 'band')
        reservedText(
          widget.selected.isNotEmpty
              ? '${ui['answerFor']} ${step.label(widget.selected.first)}'
              : null,
          step.options.map((item) => '${ui['answerFor']} ${item.label}'),
        )
      else if (widget.selected.isNotEmpty)
        text('${ui['answerFor']} ${step.label(widget.selected.first)}'),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final p in targets) choice(p, target: true, width: 170),
        ],
      ),
      text(
        '${ui['progress']}: ${widget.placements.length} / ${step.options.length}',
        size: 18,
      ),
    ],
  );
  Widget band() => SoundStudio(
    child: Column(
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final compact = box.maxWidth < 500;
            final columns = compact && box.maxWidth >= 270 ? 2 : 1;
            final width = compact
                ? (box.maxWidth - 12 * (columns - 1)) / columns
                : step.isMapping
                ? 155.0
                : 190.0;
            final height = (width - 20) / 1.25;
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final p in step.options)
                  object(
                    p,
                    height: height.clamp(60.0, step.isMapping ? 100.0 : 145.0),
                    width: width,
                  ),
              ],
            );
          },
        ),
        if (step.isFree) ...[
          text(
            '${ui['explored']}: ${widget.selected.length} / ${step.options.length}',
            size: 18,
          ),
          if (played != null) ...[
            text(step.json['senseDescriptions'][played]),
            if (widget.onSpeak != null)
              replay(
                'sound-action-explain',
                () => widget.onSpeak!(step.json['senseDescriptions'][played]),
                label: ui['hearAction'],
              ),
          ],
        ] else ...[
          const SizedBox(height: 16),
          answerTray(),
        ],
      ],
    ),
  );
  Widget face() => SoundSurface(
    child: LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth.clamp(0.0, 350.0);
        final height = width * .8;
        final markers = <String, Offset>{
          'ears': Offset(24, height * .50),
          'eyes': Offset(width * .36, 24),
          'nose': Offset(width - 24, height * .54),
        };
        final parts = <String, Offset>{
          'ears': Offset(width * .22, height * .50),
          'eyes': Offset(width * .36, height * .44),
          'nose': Offset(width * .50, height * .54),
        };
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(child: SoundPicture('hearing', height: height)),
                Positioned.fill(
                  child: CustomPaint(painter: _SoundFaceGuides(markers, parts)),
                ),
                for (final p in step.options)
                  Positioned(
                    left: markers[p.id]!.dx - 24,
                    top: markers[p.id]!.dy - 24,
                    child: Semantics(
                      label: p.label,
                      button: true,
                      child: InkWell(
                        key: ValueKey('science-item-${p.id}'),
                        onTap: widget.done ? null : () => choose(p.id),
                        borderRadius: BorderRadius.circular(30),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(child: cue(p.id)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
  Widget boxes() => SoundSurface(
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 16,
      children: [
        for (final p in step.options)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              object(
                PictureItem.fromJson({
                  'id': p.id,
                  'label': p.label,
                  'art': p.id,
                }),
                height: 170,
              ),
              replay(
                'sound-listen-${p.id}',
                () => play(p.id == 'stone_box' ? 'stone' : 'feather', id: p.id),
              ),
            ],
          ),
      ],
    ),
  );
  Widget chart() => SoundSurface(
    outdoor: true,
    child: LayoutBuilder(
      builder: (context, box) {
        final compact =
            box.maxWidth < 520 ||
            MediaQuery.textScalerOf(context).scale(1) >= 1.5;
        return Column(
          children: [
            choices(),
            const SizedBox(height: 18),
            const SoundPicture('drum', height: 65),
            text(ui['walkStart'], size: 18),
            for (final row in step.table)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 85,
                      child: Text(
                        row['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 56,
                            child: LayoutBuilder(
                              builder: (context, lane) {
                                final distance =
                                    (lane.maxWidth - 50).clamp(0.0, 1500.0) *
                                    (row['value'] as int) /
                                    25;
                                return Stack(
                                  children: [
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 5,
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFCAD5BA),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      width: distance + 25,
                                      bottom: 5,
                                      child: Container(
                                        height: 8,
                                        color: const Color(0xFF7F9E98),
                                      ),
                                    ),
                                    Positioned(
                                      left: distance,
                                      top: 0,
                                      child: const SoundPicture(
                                        'listener',
                                        height: 40,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Text(
                            '${row['value']} ${ui['steps']}',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    if (!compact && widget.selected.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      choice(
                        targets.firstWhere(
                          (p) => widget.selected.first == 'furthest_listener'
                              ? p.id == row['name'].toString().toLowerCase()
                              : p.id == '${row['value']}_steps',
                        ),
                        target: true,
                        width: 105,
                      ),
                    ],
                  ],
                ),
              ),
            if (compact && widget.selected.isNotEmpty)
              answerTray()
            else
              text(
                '${ui['progress']}: ${widget.placements.length} / 2',
                size: 18,
              ),
          ],
        );
      },
    ),
  );
  Widget sticks() => Column(
    children: [
      SoundSurface(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 12,
          children: [
            for (final id in ['gentle', 'harder'])
              SizedBox(
                width: 220,
                child: Column(
                  children: [
                    artwork('sticks', 150, id: id, animate: true),
                    FilledButton.tonalIcon(
                      key: ValueKey('sound-try-$id'),
                      onPressed: () => play(
                        'sticks',
                        volume: id == 'gentle' ? .3 : 1,
                        id: id,
                      ),
                      icon: const Icon(Icons.volume_up_rounded),
                      label: Text(ui[id], style: const TextStyle(fontSize: 19)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      text(ui['answerPrompt']),
      choices(),
    ],
  );
  void listenToDrum() => play('drum', volume: 1 - listenerPosition * .65);
  Widget distance() => Column(
    children: [
      SoundDistance(
        position: listenerPosition,
        pulse: pulse,
        onMove: (value) => setState(() => listenerPosition = value),
        listenerLabel: ui['you'],
        onListen: listenToDrum,
      ),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        children: [
          for (final id in ['near', 'far'])
            OutlinedButton(
              key: ValueKey('sound-distance-$id'),
              onPressed: () =>
                  setState(() => listenerPosition = id == 'near' ? .05 : .95),
              child: Text(ui[id], style: const TextStyle(fontSize: 20)),
            ),
        ],
      ),
      Slider(
        key: const ValueKey('sound-distance-slider'),
        value: listenerPosition,
        semanticFormatterCallback: (v) => '${ui['you']}: ${(v * 100).round()}%',
        onChanged: (value) => setState(() => listenerPosition = value),
      ),
      FilledButton.tonalIcon(
        key: const ValueKey('sound-distance-listen'),
        onPressed: listenToDrum,
        icon: const Icon(Icons.volume_up_rounded),
        label: Text(ui['listen'], style: const TextStyle(fontSize: 21)),
      ),
      const SizedBox(height: 18),
      choices(),
    ],
  );
  Map<String, String> get orderSlots => widget.placements.isNotEmpty
      ? Map<String, String>.from(widget.placements)
      : {
          for (var i = 0; i < widget.selected.length; i++)
            '$i': widget.selected.elementAt(i),
        };

  void updateOrderSlots(Map<String, String> slots) {
    if (widget.done) return;
    if (widget.onOrderPlacements != null) {
      widget.onOrderPlacements!(slots);
    } else {
      widget.onOrder?.call([
        for (var i = 0; i < step.options.length; i++)
          if (slots.containsKey('$i')) slots['$i']!,
      ]);
    }
  }

  void reorder(int i, int direction) {
    final slots = orderSlots;
    final target = i + direction;
    if (target < 0 ||
        target >= step.options.length ||
        !slots.containsKey('$i')) {
      return;
    }
    final source = slots.remove('$i')!;
    final displaced = slots.remove('$target');
    slots['$target'] = source;
    if (displaced != null) slots['$i'] = displaced;
    updateOrderSlots(slots);
  }

  void listenToSource(PictureItem item) {
    setState(() => orderFocus = item.id);
    play(
      {
        'cat_walking': 'cat_steps',
        'door_slamming': 'door',
        'whisper': 'whisper',
        'thunder': 'thunder',
      }[item.id]!,
      id: item.id,
    );
  }

  bool canPlaceInOrder(String id, int index) =>
      !widget.done &&
      step.options.any((p) => p.id == id) &&
      index >= 0 &&
      index < step.options.length;

  void placeInOrder(String id, int index) {
    if (!canPlaceInOrder(id, index)) return;
    final slots = orderSlots;
    final previous = slots.entries
        .where((entry) => entry.value == id)
        .firstOrNull;
    if (previous?.key == '$index') return;
    final displaced = slots.remove('$index');
    if (previous != null) {
      slots.remove(previous.key);
      if (displaced != null) slots[previous.key] = displaced;
    }
    slots['$index'] = id;
    updateOrderSlots(slots);
  }

  Widget draggableSound(PictureItem p, Widget child, {required String key}) =>
      Draggable<String>(
        key: ValueKey(key),
        data: p.id,
        maxSimultaneousDrags: widget.done ? 0 : 1,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: 125,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F1E6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF5C8291), width: 2),
            ),
            child: SoundPicture(p.art, height: 90),
          ),
        ),
        childWhenDragging: Opacity(opacity: .35, child: child),
        child: child,
      );

  Widget orderSource(PictureItem p) => draggableSound(
    p,
    Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('science-item-${p.id}'),
        onTap: () => listenToSource(p),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 165,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF5E7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: orderFocus == p.id
                  ? const Color(0xFF5C8291)
                  : const Color(0xFFD8C9AE),
              width: orderFocus == p.id ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              artwork(p.art, 100, id: p.id, animate: true),
              text(p.label, size: 19),
              const Icon(Icons.volume_up_rounded, color: Color(0xFF5C8291)),
              if (!widget.done) const Icon(Icons.drag_indicator_rounded),
            ],
          ),
        ),
      ),
    ),
    key: 'sound-order-source-${p.id}',
  );

  Widget orderSlot(int index) {
    final slots = orderSlots;
    final item = slots.containsKey('$index')
        ? step.options.firstWhere((p) => p.id == slots['$index'])
        : null;
    return DragTarget<String>(
      key: ValueKey('sound-order-slot-$index'),
      onWillAcceptWithDetails: (details) =>
          canPlaceInOrder(details.data, index),
      onAcceptWithDetails: (details) => placeInOrder(details.data, index),
      builder: (context, candidates, rejected) => Container(
        width: 220,
        constraints: const BoxConstraints(minHeight: 230),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? const Color(0xFFDEEAF0)
              : const Color(0xFFF6EDD9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: candidates.isNotEmpty
                ? const Color(0xFF5C8291)
                : const Color(0xFFD3C4A6),
            width: candidates.isNotEmpty ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${index + 1}',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            if (item != null) ...[
              draggableSound(
                item,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SoundPicture(item.art, height: 75),
                    text(item.label, size: 17),
                  ],
                ),
                key: 'sound-order-ranked-${item.id}',
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    key: ValueKey('sound-order-left-$index'),
                    tooltip: ui['moveEarlier'],
                    onPressed: widget.done || index == 0
                        ? null
                        : () => reorder(index, -1),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  IconButton(
                    key: ValueKey('sound-order-remove-$index'),
                    tooltip: ui['remove'],
                    onPressed: widget.done
                        ? null
                        : () => updateOrderSlots(slots..remove('$index')),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  IconButton(
                    key: ValueKey('sound-order-right-$index'),
                    tooltip: ui['moveLater'],
                    onPressed: widget.done || index + 1 == step.options.length
                        ? null
                        : () => reorder(index, 1),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
              ),
            ] else
              text(ui['emptySlot'], size: 18),
            if (!widget.done)
              TextButton.icon(
                key: ValueKey('sound-order-place-$index'),
                onPressed:
                    orderFocus != null && canPlaceInOrder(orderFocus!, index)
                    ? () => placeInOrder(orderFocus!, index)
                    : null,
                icon: const Icon(Icons.add_rounded),
                label: Text(ui['placeHere'] ?? 'Place the sound here'),
              ),
          ],
        ),
      ),
    );
  }

  Widget order() => Column(
    children: [
      SoundSurface(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [for (final p in step.options) orderSource(p)],
        ),
      ),
      text(ui['quietFirst']),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 12,
        children: [for (var i = 0; i < step.options.length; i++) orderSlot(i)],
      ),
    ],
  );
  Widget discoveries() {
    final id = focused ?? widget.selected.firstOrNull ?? step.options.first.id;
    final index = step.options.indexWhere((p) => p.id == id);
    final question = step.options[index];
    final configuredChoices = ui['missionChoices']?[id] as List?;
    final missionTargets = configuredChoices == null
        ? step.targets
        : [
            for (final target in configuredChoices)
              step.targets.firstWhere((p) => p.id == target),
          ];
    return SoundSurface(
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < step.options.length; i++)
                OutlinedButton(
                  key: ValueKey('science-item-${step.options[i].id}'),
                  onPressed: () => widget.done
                      ? setState(() => focused = step.options[i].id)
                      : choose(step.options[i].id),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: id == step.options[i].id
                        ? const Color(0xFFDEEAF0)
                        : const Color(0xFFF9F3E8),
                  ),
                  child: Text(
                    '${i + 1}${widget.reviewItems.contains(step.options[i].id)
                        ? ' ?'
                        : widget.placements.containsKey(step.options[i].id)
                        ? ' ✓'
                        : ''}',
                    style: const TextStyle(fontSize: 21),
                  ),
                ),
            ],
          ),
          text('${ui['mission']} ${index + 1} / ${step.options.length}'),
          if (id == 'walk_away_from_sound')
            const SizedBox(
              width: 360,
              height: 175,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: SoundPicture('drum', height: 110)),
                  Icon(Icons.arrow_forward_rounded, color: Color(0xFF718D8D)),
                  Expanded(child: SoundPicture('listener', height: 135)),
                ],
              ),
            )
          else if (id == 'something_making_a_sound')
            const Wrap(
              alignment: WrapAlignment.center,
              children: [
                SoundPicture('drum', height: 140),
                SoundPicture('maracas', height: 140),
              ],
            )
          else
            artwork(question.art, 180),
          text(ui['missions']?[id] ?? question.label),
          if (widget.placements.containsKey(id))
            text('${ui['yourAnswer']}: ${step.label(widget.placements[id]!)}'),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 12,
            children: [
              for (final p in missionTargets)
                choice(p, target: true, item: id, width: 170),
            ],
          ),
          const SizedBox(height: 12),
          if (index < step.options.length - 1)
            TextButton.icon(
              key: const ValueKey('sound-next-mission'),
              onPressed: () => widget.done
                  ? setState(() => focused = step.options[index + 1].id)
                  : choose(step.options[index + 1].id),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                ui['nextMission'],
                style: const TextStyle(fontSize: 20),
              ),
            ),
          text(
            '${ui['progress']}: ${widget.placements.length} / ${step.options.length}',
            size: 18,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      text(ui['instruction']),
      if (mode == 'band')
        band()
      else if (mode == 'hearing')
        face()
      else if (mode == 'boxes')
        boxes()
      else if (mode == 'chart')
        chart()
      else if (mode == 'sticks')
        sticks()
      else if (mode == 'distance')
        distance()
      else if (mode == 'order')
        order()
      else if (mode == 'hum') ...[
        SoundSurface(
          child: Column(
            children: [
              const SoundPicture('hum', height: 235),
              text(ui['humSteps'], size: 20),
            ],
          ),
        ),
        const SizedBox(height: 18),
        choices(),
      ] else
        discoveries(),
    ],
  );
}

class _SoundFaceGuides extends CustomPainter {
  const _SoundFaceGuides(this.markers, this.parts);
  final Map<String, Offset> markers, parts;
  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = const Color(0xFF6C8890)
      ..strokeWidth = 1.2;
    for (final id in markers.keys) {
      canvas.drawLine(markers[id]!, parts[id]!, ink);
      canvas.drawCircle(parts[id]!, 2.5, ink);
    }
  }

  @override
  bool shouldRepaint(_SoundFaceGuides old) => true;
}
