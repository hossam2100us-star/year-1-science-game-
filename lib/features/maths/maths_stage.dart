import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import 'maths_art.dart';
import 'maths_visual.dart';

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
  });

  final LessonStep step;
  final Set<String> selected, touched, reviewItems;
  final Map<String, String> placements;
  final bool locked;
  final ValueChanged<String> onItem;
  final void Function(String item, String target) onPlace;

  Widget _visual(Map<String, dynamic> data) => MathsVisual(data: data);

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
              _visual(Map<String, dynamic>.from(visual)),
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

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1D5),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 3.4,
            child: MathsBackdrop(
              scene: mathsSceneForTheme(step.json['theme'] as String?),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (step.json['mathVisual']
            case final Map<String, dynamic> diagram) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: _visual(Map<String, dynamic>.from(diagram)),
          ),
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
        LayoutBuilder(
          builder: (context, box) {
            final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
            final columns = box.maxWidth < (large ? 650 : 450) ? 1 : 2;
            final width = (box.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final option in step.options)
                  _option(context, option, width),
              ],
            );
          },
        ),
        if (step.isMapping) ...[
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
  );
}
