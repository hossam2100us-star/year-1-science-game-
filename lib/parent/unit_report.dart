import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/catalog.dart';
import '../core/models.dart';
import '../core/providers.dart';
import '../games/question_engine.dart';
import '../features/lesson/lesson_player.dart';
import '../features/garden/alive_adventures.dart';
import '../features/garden/garden_model.dart';
import '../l10n/parent_strings.dart';

class UnitReport extends ConsumerWidget {
  const UnitReport({super.key, required this.level, required this.arabic});
  final LevelInfo level;
  final bool arabic;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = parentStrings(arabic);
    final data = ref.watch(appProvider);
    final lesson = ref.watch(lessonLibraryProvider).value?.lessons[level.id];
    final bean = level.id == 'unit_02' ? data.journeys['unit_02.bean'] : null;
    final latest = data.latest(level.id),
        best = data.best(level.id),
        journey = data.journeys[level.id];
    final remaining =
        latest?.objectives.entries
            .where((e) => e.value != DecisionOutcome.firstTry)
            .map((e) => e.key)
            .toSet() ??
        <String>{};
    final liveResults = lesson == null || journey == null
        ? <String, DecisionOutcome>{}
        : objectiveResults(lesson, {
            ...Map<String, dynamic>.from(journey['responses'] ?? {}),
            if (journey['stepId'] != null && journey['current'] is Map)
              journey['stepId']: journey['current'],
          });
    final weakAlive =
        level.id == 'unit_01' &&
        lesson != null &&
        aliveScenes(lesson).any(
          (scene) => Map<String, String>.from(
            data.journeys[scene.storageKey]?['results'] ?? {},
          ).values.any((outcome) => outcome != 'firstTry'),
        );
    String titleFor(String id) =>
        lesson?.steps
            .where((s) => s.assessedObjectives.contains(id))
            .firstOrNull
            ?.title ??
        id;
    String date(DateTime d) => '${d.day}/${d.month}/${d.year}';
    final all =
        data.attempts.where((a) => a.unitId == level.id && a.completed).toList()
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            arabic ? level.arabic : level.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (lesson != null)
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LessonRoute(id: level.id),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l.unitReportOpenUnitForPractice),
            ),
          if (liveResults.isNotEmpty) ...[
            Text(l.unitReportLearningSoFarUnitIn),
            for (final entry in liveResults.entries)
              Row(
                children: [
                  Icon(
                    entry.value == DecisionOutcome.firstTry
                        ? Icons.check_circle_outline_rounded
                        : Icons.replay_rounded,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${titleFor(entry.key)} — ${entry.value == DecisionOutcome.firstTry ? l.unitReportIndependentThisTime : l.unitReportPracticeNext}',
                    ),
                  ),
                ],
              ),
          ],
          if (level.id == 'unit_01' && lesson != null) ...[
            for (final scene in aliveScenes(lesson))
              _sceneReport(scene, data.journeys[scene.storageKey]),
            Text(l.unitReportScenePracticeIsSeparateFrom),
          ],
          if (bean != null)
            Text(l.unitReportBeanStage((bean['frame'] as int? ?? 0) + 1)),
          if (journey != null && lesson != null)
            Text(
              l.unitReportInProgress(
                journey['index'] as Object,
                lesson.steps.length,
              ),
            ),
          if (latest == null)
            Text(
              lesson == null
                  ? l.unitReportActivityNotAvailableYet
                  : l.unitReportNoCompletedAttemptYetThis,
            ),
          if (latest != null) ...[
            Text(l.unitReportLatestAttempt(date(latest.completedAt))),
            Text(
              l.unitReportFirstTryOf(latest.firstTry, latest.objectives.length),
            ),
            Text(
              l.unitReportAfterAHintExplanationShown(
                latest.afterHint,
                latest.explained,
              ),
            ),
            Text(l.unitReportEffortStarsOf3(latest.effortStars)),
            if (best != null)
              Text(
                l.unitReportBestAttemptOf(
                  best.firstTry,
                  best.objectives.length,
                ),
              ),
            if (all.length > 1)
              Text(
                l.unitReportChangeFromPreviousAttempt(
                  latest.firstTry - all[1].firstTry,
                ),
              ),
            if (remaining.isNotEmpty) ...[
              Text(l.unitReportPracticeNext2),
              for (final id in remaining) Text('• ${titleFor(id)}'),
              OutlinedButton(
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute<void>(
                      builder: (_) => LessonRoute(
                        id: level.id.startsWith('quiz') ? 'unit_01' : level.id,
                      ),
                    ),
                  );
                },
                child: Text(l.unitReportReplayForPractice),
              ),
            ],
          ],
          // Facts for grown-ups that would confuse a child on the screen
          // ("the space model is not to scale"; teacher review 4).
          if (lesson?.json['parentNote']
              case final Map<String, dynamic> note) ...[
            const SizedBox(height: 8),
            Text(
              '${note[arabic ? 'ar' : 'en'] ?? note['en']}',
              key: ValueKey('parent-note-${level.id}'),
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
          if (lesson != null) ...[
            for (final activity
                in List<Map<String, dynamic>>.from(
                  lesson.json['goalActivities'] ?? [],
                ).where(
                  (a) =>
                      remaining.contains(a['objective']) ||
                      (weakAlive && a['objective'] == 'u01.main.01') ||
                      (liveResults[a['objective']] != null &&
                          liveResults[a['objective']] !=
                              DecisionOutcome.firstTry),
                )) ...[
              const SizedBox(height: 12),
              Text(
                l.unitReportPracticeFor(titleFor(activity['objective'])),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(activity['text'], textDirection: TextDirection.ltr),
              Text(
                activity['safety'],
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Color(0xFFC0392B)),
              ),
              Text(l.unitReportGoalSourcePages(activity['pages'].join(', '))),
            ],
          ],
          if (lesson != null &&
              (latest != null || liveResults.isNotEmpty) &&
              !lesson.quiz) ...[
            const SizedBox(height: 10),
            Text(
              l.unitReportBookActivityWithAGrown,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final activity in lesson.homeActivities) ...[
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFFCE8E6),
                child: Text(
                  activity['safety'],
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(color: Color(0xFFC0392B)),
                ),
              ),
              Text(activity['text'], textDirection: TextDirection.ltr),
              Text(l.unitReportSourcePages(activity['pages'].join(', '))),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sceneReport(GardenContent scene, Map<String, dynamic>? saved) {
    final l = parentStrings(arabic);
    // Scene titles come bilingual from the lesson content, not from ARB.
    String fromContent(String ar, String en) => arabic ? ar : en;
    final results = Map<String, String>.from(saved?['results'] ?? {});
    int count(String value) => results.values.where((v) => v == value).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fromContent(scene.text('titleAr'), scene.text('title')),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(l.unitReportDiscoveriesOf(results.length, scene.items.length)),
          Text(
            l.unitReportOutcomeCounts(
              count('firstTry'),
              count('afterHint'),
              count('explained'),
            ),
          ),
          for (final item in scene.items.where(
            (i) => results[i.id] == 'explained',
          ))
            Text(l.unitReportPracticeItem(arabic ? item.nameAr : item.name)),
        ],
      ),
    );
  }
}
