import 'package:flutter/material.dart';

/// Back, home, title and step position at the top of a lesson (moved out of
/// the lesson player, AUD-002). On phones the title gets its own line and
/// ends with an ellipsis; the full text stays available on long-press.
class LessonHeader extends StatelessWidget {
  const LessonHeader({
    super.key,
    required this.title,
    required this.position,
    required this.onPrevious,
    required this.onHome,
  });

  final String title;

  /// "3/13".
  final String position;
  final VoidCallback? onPrevious;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        // A shortened phone title keeps its full text on long-press (AUD-018).
        final heading = Tooltip(
          message: title,
          excludeFromSemantics: true,
          child: Text(
            title,
            key: const ValueKey('lesson-title'),
            maxLines: compact ? 2 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
            style: compact
                ? Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)
                : Theme.of(context).textTheme.titleLarge,
          ),
        );
        final controls = Row(
          children: [
            IconButton(
              key: const ValueKey('lessonPrevious'),
              tooltip: 'Previous screen',
              onPressed: onPrevious,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            IconButton(
              onPressed: onHome,
              tooltip: 'Save and return to map',
              icon: const Icon(Icons.home_rounded),
            ),
            if (compact) const Spacer() else Expanded(child: heading),
            Text(position, style: const TextStyle(fontSize: 22)),
          ],
        );
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  controls,
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: heading,
                  ),
                ],
              )
            : controls;
      },
    ),
  );
}
