import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/touch_cue.dart';
import 'force_picture.dart';
import 'science_picture.dart';

/// Alternative ways to respond to the same source-linked quiz choices.
/// Trying a slider/sound does not submit an answer or receive a grade.
class QuizActionStage extends StatefulWidget {
  const QuizActionStage({
    super.key,
    required this.step,
    required this.done,
    required this.onItem,
    this.onSound,
  });
  final LessonStep step;
  final bool done;
  final ValueChanged<String> onItem;
  final void Function(String, double)? onSound;
  @override
  State<QuizActionStage> createState() => _QuizActionStageState();
}

class _QuizActionStageState extends State<QuizActionStage> {
  double delta = 0, distance = 0;
  String get mode => widget.step.json['quizInteraction'];
  void choose(String id) {
    if (!widget.done) widget.onItem(id);
  }

  Widget choices() => Wrap(
    spacing: 12,
    runSpacing: 12,
    alignment: WrapAlignment.center,
    children: [
      for (final item in widget.step.options)
        FilledButton.tonal(
          key: ValueKey('science-item-${item.id}'),
          onPressed: widget.done ? null : () => choose(item.id),
          child: Text(item.label),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFE7F0E8),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        if (mode == 'source-drop') ...[
          const Text(
            'Drag the sound maker to its name. You can also touch a name.',
          ),
          const SizedBox(height: 12),
          Draggable<String>(
            data: 'sound-maker',
            maxSimultaneousDrags: widget.done ? 0 : 1,
            feedback: const Material(
              color: Colors.transparent,
              child: SciencePicture('drum', height: 100),
            ),
            child: Semantics(
              label: 'Sound maker',
              child: const SciencePicture('drum', height: 130),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final item in widget.step.options)
                DragTarget<String>(
                  key: ValueKey('quiz-drop-${item.id}'),
                  onWillAcceptWithDetails: (_) => !widget.done,
                  onAcceptWithDetails: (_) => choose(item.id),
                  builder: (context, hovering, rejected) => Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hovering.isEmpty
                          ? Colors.white
                          : const Color(0xFFC9DFD2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextButton(
                      key: ValueKey('science-item-${item.id}'),
                      onPressed: widget.done ? null : () => choose(item.id),
                      child: Text(item.label),
                    ),
                  ),
                ),
            ],
          ),
        ] else if (mode == 'distance-observe') ...[
          const Text(
            'Listen nearby and farther away. Then describe the change.',
          ),
          const SciencePicture('drum', height: 140),
          Slider(
            key: const ValueKey('quiz-listening-distance'),
            value: distance,
            divisions: 4,
            semanticFormatterCallback: (v) =>
                v < .5 ? 'Nearby' : 'Farther away',
            onChanged: (v) => setState(() => distance = v),
          ),
          Text(distance < .5 ? 'Nearby' : 'Farther away'),
          OutlinedButton.icon(
            key: const ValueKey('quiz-listen-distance'),
            onPressed: () => widget.onSound?.call('drum', 1 - distance * .85),
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('Listen here'),
          ),
          choices(),
        ] else ...[
          Text(
            mode == 'drawer-gesture'
                ? 'Move the handle. Which force will you use? You can also touch a force.'
                : 'Try pressing or moving the button. Which force will you use? You can also touch a force.',
          ),
          GestureDetector(
            key: const ValueKey('quiz-action-object'),
            onTap: mode == 'doorbell-action' && !widget.done
                ? () => choose('push')
                : null,
            onPanStart: widget.done ? null : (_) => delta = 0,
            onPanUpdate: widget.done
                ? null
                : (event) => delta += event.delta.dy,
            onPanEnd: widget.done
                ? null
                : (_) {
                    if (delta.abs() >= 24) choose(delta > 0 ? 'pull' : 'push');
                  },
            child: SizedBox(
              width: double.infinity,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ForcePicture(
                    mode == 'drawer-gesture' ? 'drawer' : 'doorbell',
                    height: 180,
                  ),
                  const Positioned(bottom: 4, child: TouchCue()),
                ],
              ),
            ),
          ),
          choices(),
        ],
      ],
    ),
  );
}
