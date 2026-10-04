import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../content/lesson.dart';
import '../../core/mascot.dart';
import '../../core/models.dart';
import '../../core/widgets.dart';

/// Which unit to replay after a quiz: the first group of quiz objectives
/// that was not answered right first time decides (moved unchanged from the
/// lesson player).
String practiceUnitFor(Map<String, DecisionOutcome> results) {
  for (final id in ['quiz01.01', 'quiz01.02', 'quiz01.08']) {
    if (results[id] != DecisionOutcome.firstTry) return 'unit_01';
  }
  for (final id in ['quiz01.03', 'quiz01.04', 'quiz01.05']) {
    if (results[id] != DecisionOutcome.firstTry) return 'unit_02';
  }
  return 'unit_03';
}

/// Celebration shown when a unit or quiz is finished.
class LessonCompletion extends StatelessWidget {
  const LessonCompletion({
    super.key,
    required this.lesson,
    required this.gender,
    required this.message,
    required this.firstTry,
    required this.onBack,
    required this.onPractice,
  });

  final Lesson lesson;
  final ChildGender gender;
  final String message;

  /// Objectives right first time (the quiz score out of 10).
  final int firstTry;
  final Future<void> Function() onBack;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AdventurePage(
      maxWidth: 900,
      child: Column(
        children: [
          if (!MediaQuery.disableAnimationsOf(context))
            Lottie.asset(
              'assets/animations/celebrate.json',
              height: 100,
              repeat: false,
            ),
          ScientistOwl(gender: gender, mood: OwlMood.cheering, size: 160),
          StoryPanel(text: message),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < (lesson.quiz ? 10 : 3); i++)
                Icon(
                  !lesson.quiz || i < firstTry
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFF9E6D0F),
                  size: 40,
                ),
            ],
          ),
          if (lesson.stickers.isNotEmpty)
            Text(
              'New word stickers: ${lesson.stickers.map((s) => s['word']).join(', ')}',
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: onBack,
                child: const Text('Back to my island'),
              ),
              if (lesson.quiz && firstTry < 10)
                OutlinedButton(
                  onPressed: onPractice,
                  child: const Text('Play the tricky games again'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
