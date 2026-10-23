import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../science/discovery_world.dart';
import 'maths_art.dart';
import 'maths_visual.dart';
import 'number_line_jumps.dart';
import 'number_pad.dart';
import 'tap_counter.dart';

/// Maths supplies its own diagrams; navigation, feedback, marking and saved
/// attempts still belong to the same player used by the Science adventures.
class MathsStage extends StatelessWidget {
  const MathsStage({
    super.key,
    required this.step,
    required this.selected,
    required this.placements,
    required this.touched,
    required this.reviewItems,
    required this.locked,
    required this.onItem,
    required this.onPlace,
    this.onWrite,
    this.lab = const {},
    this.onSaveLab,
    this.onSay,
    this.revealed = false,
  });

  final LessonStep step;
  final Set<String> selected, touched, reviewItems;
  final Map<String, String> placements;
  final bool locked;
  final ValueChanged<String> onItem;
  final void Function(String item, String target) onPlace;

  /// A written answer (number pad, number sentence).
  final ValueChanged<Map<String, String>>? onWrite;

  /// Counting marks and number line jumps: learning aids saved with the
  /// step, never part of the answer.
  final Map<String, dynamic> lab;
  final Future<void> Function(Map<String, dynamic> lab, bool complete)?
  onSaveLab;
  final ValueChanged<String>? onSay;

  /// The question is answered: the number line shows the explanation.
  final bool revealed;

  Widget _visual(Map<String, dynamic> data) => MathsVisual(data: data);

  Map<String, dynamic>? get _diagram => switch (step.json['mathVisual']) {
    final Map<String, dynamic> diagram => diagram,
    _ => null,
  };

  /// The Carroll diagram is where the cards are sorted, so it takes the
  /// place of the target buttons.
  bool get _carroll => _diagram?['type'] == 'carroll' && step.isMapping;

  /// A robot draws the routes the child has chosen (teacher review 5).
  Widget _picture(Map<String, dynamic> diagram) {
    final save = onSaveLab, say = onSay;
    if (save != null && say != null && TapCounter.countable(diagram)) {
      return TapCounter(
        // One counter per question: the next question starts at zero.
        key: ValueKey('tap-counter-${step.id}'),
        data: diagram,
        initial: List<int>.from(lab['counted'] ?? const []),
        onSave: (counted) => save({...lab, 'counted': counted}, false),
        onSay: say,
        locked: locked,
      );
    }
    if (save != null && say != null && NumberLineJumps.jumpable(diagram)) {
      return NumberLineJumps(
        key: ValueKey('number-line-${step.id}'),
        data: diagram,
        initial: List<int>.from(lab['hops'] ?? const []),
        onSave: (hops) => save({...lab, 'hops': hops}, false),
        onSay: say,
        locked: locked,
        revealed: revealed,
      );
    }
    return _visual({
      ...diagram,
      if (diagram['type'] == 'robot')
        'show': [for (final id in selected) step.label(id)],
    });
  }

  Widget _carrollTable() => CarrollTable(
    data: _diagram!,
    columns: [for (final t in step.targets) (id: t.id, label: t.label)],
    placed: {
      for (final t in step.targets)
        t.id: [
          for (final o in step.options)
            if (placements[o.id] == t.id) o.label,
        ],
    },
    onColumn: locked || selected.isEmpty
        ? null
        : (target) => onPlace(selected.first, target),
  );

  Widget _option(BuildContext context, PictureItem item, double width) {
    final json = (step.json['options'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((o) => o['id'] == item.id);
    final visual = json['visual'];
    final picked = selected.contains(item.id);
    final visited = step.isFree && touched.contains(item.id);
    final revisit = reviewItems.contains(item.id);
    return SizedBox(
      width: width,
      child: OutlinedButton(
        key: ValueKey('maths-option-${item.id}'),
        onPressed: locked ? null : () => onItem(item.id),
        style: OutlinedButton.styleFrom(
          backgroundColor: picked || visited
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.white,
          padding: const EdgeInsets.all(14),
          side: BorderSide(
            color: revisit
                ? const Color(0xFF9E6D0F)
                : Theme.of(context).colorScheme.primary,
            width: picked ? 3 : 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (visual is Map) ...[
              _visual({
                ...Map<String, dynamic>.from(visual),
                // Pictures in answers are smaller, so the answers fit.
                'height': visual['type'] == 'shape' ? 100 : 110,
              }),
              const SizedBox(height: 8),
            ],
            Text(item.label, textAlign: TextAlign.center),
            if (visited) const Icon(Icons.check_circle_outline_rounded),
            if (picked && step.isOrder)
              Text('${selected.toList().indexOf(item.id) + 1}'),
            if (placements[item.id] case final String target)
              Text('→ ${step.label(target)}', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  /// Charts are tall: on a wide screen (a tablet held sideways, a computer)
  /// their answers sit beside the chart instead of below it, so the child
  /// never scrolls to answer (teacher review 6).
  /// A written answer (number pad) sits beside its number line or picture
  /// too, for the same reason.
  bool _answersBeside(double width) =>
      width >= 900 &&
      (_diagram?['type'] == 'chart' || (step.isWritten && _diagram != null)) &&
      !_carroll &&
      !step.isMapping &&
      !step.isOrder;

  Widget _written() => step.isNumber
      ? WrittenNumber(
          key: ValueKey('written-${step.id}'),
          value: placements['answer'] ?? '',
          locked: locked,
          review: reviewItems.contains('answer'),
          onSay: onSay,
          onChanged: (value) => onWrite?.call({'answer': value}),
        )
      : NumberSentence(
          key: ValueKey('sentence-${step.id}'),
          slots: placements,
          locked: locked,
          review: reviewItems,
          onSay: onSay,
          onChanged: (slots) => onWrite?.call(slots),
        );

  Widget _diagramBox() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: _picture(Map<String, dynamic>.from(_diagram!)),
  );

  /// The answer cards in rows, or one under another when [stacked].
  Widget _answers(
    BuildContext context,
    double maxWidth, {
    bool stacked = false,
  }) {
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final pictures = (step.json['options'] as List).any(
      (o) => (o as Map)['visual'] is Map,
    );
    // Short answers share one row on a tablet; answers with a picture need
    // more room each.
    final columns = stacked
        ? 1
        : math.min(
            step.options.length,
            large
                ? (maxWidth < 650 ? 1 : 2)
                : maxWidth < 450
                ? 1
                : maxWidth < 900
                ? 2
                : pictures
                ? 3
                : 4,
          );
    final width = (maxWidth - (columns - 1) * 12) / columns;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final option in step.options) _option(context, option, width),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1D5),
      borderRadius: BorderRadius.circular(24),
    ),
    child: LayoutBuilder(
      builder: (context, box) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The setting is decoration: on a short screen (a tablet between
          // its system bars) it is a strip, so the diagram and every answer
          // fit without scrolling more often, and a chart leaves no room for
          // it.
          if (!(_diagram?['type'] == 'chart' &&
              DiscoveryWorld.usableHeight(context) < 760))
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: double.infinity,
                height: mathsBannerHeight(context, box.maxWidth),
                child: MathsBackdrop(
                  scene: mathsSceneForTheme(step.json['theme'] as String?),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (_answersBeside(box.maxWidth))
            Row(
              children: [
                Expanded(flex: 3, child: _diagramBox()),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: step.isWritten
                      ? _written()
                      : LayoutBuilder(
                          builder: (context, side) =>
                              _answers(context, side.maxWidth, stacked: true),
                        ),
                ),
              ],
            )
          else ...[
            if (_diagram != null && !_carroll) ...[
              _diagramBox(),
              const SizedBox(height: 16),
            ],
            if (step.isOrder)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Tap in order. Tap a chosen card again to move it.',
                  textAlign: TextAlign.center,
                ),
              ),
            if (step.isMapping && !locked)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Choose a card, then choose where it belongs.',
                  textAlign: TextAlign.center,
                ),
              ),
            if (step.isWritten) _written() else _answers(context, box.maxWidth),
          ],
          if (_carroll) ...[
            const SizedBox(height: 16),
            _carrollTable(),
          ] else if (step.isMapping) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final target in step.targets)
                  FilledButton.tonal(
                    key: ValueKey('maths-target-${target.id}'),
                    onPressed: locked || selected.isEmpty
                        ? null
                        : () => onPlace(selected.first, target.id),
                    child: Text(target.label, textAlign: TextAlign.center),
                  ),
              ],
            ),
          ],
          if (step.isOrder && selected.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              selected.map(step.label).join(' → '),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ),
  );
}
