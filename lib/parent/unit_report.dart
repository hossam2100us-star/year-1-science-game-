import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/catalog.dart';
import '../core/models.dart';
import '../core/providers.dart';
import '../features/biology/lesson_player.dart';
import '../features/garden/alive_adventures.dart';
import '../features/garden/garden_model.dart';

class UnitReport extends ConsumerWidget {
  const UnitReport({super.key, required this.level, required this.arabic});
  final LevelInfo level;
  final bool arabic;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String t(String ar, String en) => arabic ? ar : en;
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
          if (level.id == 'unit_01' && lesson != null) ...[
            for (final scene in aliveScenes(lesson))
              _sceneReport(scene, data.journeys[scene.storageKey]),
            Text(
              t(
                'نتائج تدريب المشاهد منفصلة عن تقييم الوحدة الكاملة.',
                'Scene practice is separate from the full unit assessment.',
              ),
            ),
          ],
          if (bean != null)
            Text(
              t(
                'تجربة الفاصوليا: المرحلة ${(bean['frame'] as int? ?? 0) + 1} من ٤. التوقع مش بيتحسب بدرجة.',
                'Bean experiment: stage ${(bean['frame'] as int? ?? 0) + 1} of 4. Predictions are not graded.',
              ),
            ),
          if (journey != null && lesson != null)
            Text(
              t(
                'مكمل لحد خطوة ${journey['index']} من ${lesson.steps.length}.',
                'In progress: ${journey['index']} of ${lesson.steps.length} steps.',
              ),
            ),
          if (latest == null)
            Text(
              lesson == null
                  ? t('النشاط لسه مش متاح', 'Activity not available yet')
                  : t(
                      'لسه مفيش محاولة كاملة — مش معناه إن الطفل مش فاهم.',
                      'No completed attempt yet. This is not a learning score.',
                    ),
            ),
          if (latest != null) ...[
            Text(
              t(
                'آخر محاولة: ${date(latest.completedAt)}',
                'Latest attempt: ${date(latest.completedAt)}',
              ),
            ),
            Text(
              t(
                'من أول مرة: ${latest.firstTry} من ${latest.objectives.length}',
                'First try: ${latest.firstTry} of ${latest.objectives.length}',
              ),
            ),
            Text(
              t(
                'بعد تلميح: ${latest.afterHint} • بعد شرح: ${latest.explained}',
                'After a hint: ${latest.afterHint} • Explanation shown: ${latest.explained}',
              ),
            ),
            Text(
              t(
                'نجوم المجهود: ${latest.effortStars} من ٣',
                'Effort stars: ${latest.effortStars} of 3',
              ),
            ),
            if (best != null)
              Text(
                t(
                  'أفضل محاولة: ${best.firstTry} من ${best.objectives.length}',
                  'Best attempt: ${best.firstTry} of ${best.objectives.length}',
                ),
              ),
            if (all.length > 1)
              Text(
                t(
                  'الفرق عن المحاولة السابقة: ${latest.firstTry - all[1].firstTry}',
                  'Change from previous attempt: ${latest.firstTry - all[1].firstTry}',
                ),
              ),
            if (remaining.isNotEmpty) ...[
              Text(t('لسه محتاج تدريب:', 'Practice next:')),
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
                child: Text(t('ارجع للعبة للتدريب', 'Replay for practice')),
              ),
            ],
          ],
          if (lesson != null && latest != null && !lesson.quiz) ...[
            const SizedBox(height: 10),
            Text(
              t(
                'نشاط منزلي من الكتاب — مع شخص كبير:',
                'Book activity — with a grown-up:',
              ),
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
              Text(
                t(
                  'صفحات المرجع: ${activity['pages'].join(', ')}',
                  'Source pages: ${activity['pages'].join(', ')}',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sceneReport(GardenContent scene, Map<String, dynamic>? saved) {
    String t(String ar, String en) => arabic ? ar : en;
    final results = Map<String, String>.from(saved?['results'] ?? {});
    int count(String value) => results.values.where((v) => v == value).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(scene.text('titleAr'), scene.text('title')),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            t(
              'اكتشافات: ${results.length} من ${scene.items.length}',
              'Discoveries: ${results.length} of ${scene.items.length}',
            ),
          ),
          Text(
            t(
              'من أول مرة: ${count('firstTry')} • بعد تلميح: ${count('afterHint')} • احتاج شرح: ${count('explained')}',
              'First try: ${count('firstTry')} • After a hint: ${count('afterHint')} • Explanation needed: ${count('explained')}',
            ),
          ),
          for (final item in scene.items.where(
            (i) => results[i.id] == 'explained',
          ))
            Text(
              t('محتاج تدريب: ${item.nameAr}', 'Practice next: ${item.name}'),
            ),
        ],
      ),
    );
  }
}
