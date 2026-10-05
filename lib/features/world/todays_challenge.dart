import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/lesson.dart';
import '../../core/providers.dart';
import '../../core/spaced_review.dart';
import '../lesson/lesson_player.dart';
import '../garden/alive_adventures.dart';
import '../garden/garden_adventure.dart';
import '../garden/garden_model.dart';

class TodaysChallenge extends ConsumerWidget {
  const TodaysChallenge({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(lessonLibraryProvider).value;
    if (library == null) return const SizedBox.shrink();
    final data = ref.watch(appProvider);
    final tasks = SpacedReview.due(data, library, DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Today's Challenge",
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 26),
              ),
              Text(
                tasks.isEmpty
                    ? 'Your discoveries will return for a little practice. Explore an island today!'
                    : '${tasks.length} little discoveries to revisit. Take your time.',
              ),
              if (tasks.isNotEmpty)
                FilledButton.icon(
                  key: const ValueKey('todays-challenge'),
                  onPressed: () async {
                    await ref.read(narrationProvider).stop();
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ChallengeScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.explore_rounded),
                  label: const Text('Try a discovery'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChallengeScreen extends ConsumerWidget {
  const ChallengeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(lessonLibraryProvider).value;
    final data = ref.watch(appProvider);
    final tasks = library == null
        ? <ReviewTask>[]
        : SpacedReview.due(data, library, DateTime.now());
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Challenge")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            tasks.isEmpty
                ? 'All done for today. See you on the islands!'
                : 'Choose one discovery. Your adventure progress stays safe.',
          ),
          for (final task in tasks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FilledButton.icon(
                key: ValueKey('review-${task.key}'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  task.gardenScene != null
                      ? aliveScenes(library!.lessons['unit_01']!)
                            .firstWhere((s) => s.id == task.gardenScene)
                            .item(task.stepId)
                            .name
                      : library!.lessons[task.lessonId]!.steps
                            .firstWhere((s) => s.id == task.stepId)
                            .title,
                ),
                onPressed: () {
                  final original = library.lessons[task.lessonId]!;
                  final owner = data.activeChildId;
                  if (task.gardenScene != null) {
                    final scene = aliveScenes(original)
                        .firstWhere((s) => s.id == task.gardenScene);
                    final practice = GardenContent({
                      ...scene.json,
                      'ui': {
                        ...Map<String, dynamic>.from(scene.json['ui']),
                        'tutorial':
                            'Tap the ${scene.item(task.stepId).name.toLowerCase()}.',
                        'next': 'Done for now',
                      },
                      'items': (scene.json['items'] as List)
                          .where((i) => i['id'] == task.stepId)
                          .toList(),
                    });
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GardenAdventure(
                          content: practice,
                          onPracticeComplete: (outcome) => ref
                              .read(appProvider.notifier)
                              .completeReview(
                                owner,
                                library,
                                task,
                                outcome,
                                DateTime.now(),
                              ),
                        ),
                      ),
                    );
                    return;
                  }
                  final step = original.steps.firstWhere(
                    (s) => s.id == task.stepId,
                  );
                  final practice = Lesson({
                    ...original.json,
                    'steps': [step.json],
                    'quiz': false,
                    'stickers': [],
                  });
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LessonPlayer(
                        lesson: practice,
                        onPracticeComplete: (outcome) => ref
                            .read(appProvider.notifier)
                            .completeReview(
                              owner,
                              library,
                              task,
                              outcome,
                              DateTime.now(),
                            ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
