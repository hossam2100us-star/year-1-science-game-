import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/spaced_review.dart';
import 'package:science_adventure/features/garden/garden_model.dart';

void main() {
  final garden = GardenContent({
    'id': 'garden',
    'version': 1,
    'items': [
      for (final id in ['cat', 'tree'])
        {
          'id': id,
          'name': id,
          'nameAr': '',
          'alive': true,
          'hint': 'Look for living things.',
          'explanation': 'Living things grow.',
        },
    ],
  });
  Map<String, dynamic> question(
    String id,
    String goal, [
    List<String> extra = const [],
  ]) => {
    'id': id,
    'kind': 'tap-choice',
    'title': id,
    'prompt': 'Choose a discovery.',
    'assessed': true,
    'objective': goal,
    'extraObjectives': extra,
    'answer': {'type': 'single', 'value': 'right'},
    'options': [],
    'targets': [],
  };
  final lesson = Lesson({
    'id': 'unit_07',
    'contentVersion': 1,
    'title': 'Practice discoveries',
    'steps': [
      question('shared', 'a1', ['a2', 'a3', 'a4', 'a5']),
      question('second', 'b'),
      question('third', 'c'),
      question('fourth', 'd'),
    ],
  });
  final library = LessonLibrary({
    lesson.id: lesson,
    'unit_01': Lesson({
      'id': 'unit_01',
      'contentVersion': 1,
      'title': 'Garden',
      'steps': [],
      'garden': garden.json,
    }),
  });
  final attempt = UnitAttempt(
    unitId: lesson.id,
    completedAt: DateTime(2026, 10, 1),
    objectives: {
      for (final goal in lesson.objectives) goal: DecisionOutcome.explained,
    },
    completed: true,
    effortStars: 3,
    attemptId: 'original-score',
  );
  final today = DateTime(2026, 10, 4);
  AppData dataWithReview(AppData data, Map<String, dynamic> journal) => data
      .copyWith(journeys: {...data.journeys, SpacedReview.storageKey: journal});

  test('A resumed garden schedules each result from its decision time', () {
    final round = GardenRound(
      version: garden.version,
      requiredIds: garden.items.map((i) => i.id).toSet(),
      roundId: DateTime(2026, 10, 1).microsecondsSinceEpoch.toString(),
    );
    round.select('cat');
    round.answer(garden.item('cat'), true, now: today);
    round.next();
    round.select('tree');
    round.answer(garden.item('tree'), false, now: today);
    final explainedAt = DateTime(2026, 10, 5);
    round.answer(garden.item('tree'), false, now: explainedAt);
    final restored = GardenRound.restore(round.toJson(), garden);
    restored.answer(garden.item('tree'), true, now: DateTime(2026, 10, 6));
    expect(restored.results['tree'], 'explained');
    expect(restored.observedAt['tree'], explainedAt.toIso8601String());
    final journal = SpacedReview.schedule(
      AppData(journeys: {garden.storageKey: restored.toJson()}),
      library,
    );
    expect(journal['entries']['unit_01:scene.garden.cat']['due'], '2026-10-07');
    expect(
      journal['entries']['unit_01:scene.garden.tree']['due'],
      '2026-10-06',
    );
    expect(restored.replay().observedAt, isEmpty);
    expect(restored.replay().history.last['observedAt'], restored.observedAt);
  });

  test('Legacy garden timestamps have a stable overdue fallback', () {
    final dated = {
      'version': 1,
      'roundId': DateTime(2026, 10, 1).microsecondsSinceEpoch.toString(),
      'results': {'cat': 'afterHint'},
    };
    final datedReview = SpacedReview.schedule(
      AppData(journeys: {garden.storageKey: dated}),
      library,
    );
    expect(
      datedReview['entries']['unit_01:scene.garden.cat']['due'],
      '2026-10-02',
    );
    final undated = {...dated}..remove('roundId');
    final data = AppData(journeys: {garden.storageKey: undated});
    final first = SpacedReview.due(data, library, today).single;
    final tomorrow = SpacedReview.due(
      data,
      library,
      today.add(const Duration(days: 1)),
    ).single;
    expect(first.due, tomorrow.due);
    expect(first.due.isBefore(today), true);
    expect(
      GardenRound.restore(dated, garden).observedAt['cat'],
      DateTime(2026, 10, 1).toIso8601String(),
    );
    final restoredUndated = GardenRound.restore(undated, garden);
    expect(
      SpacedReview.due(
        AppData(journeys: {garden.storageKey: restoredUndated.toJson()}),
        library,
        today,
      ).single.due,
      first.due,
    );
  });

  test(
    'One shared discovery completes all goals but consumes one daily card',
    () {
      var data = AppData(
        profile: const ChildProfile(name: 'Nour'),
        attempts: [attempt],
        journeys: {
          'unit_07': {'marker': 'unfinished adventure'},
        },
      );
      final initial = data.toJson();
      final shared = SpacedReview.due(
        data,
        library,
        today,
      ).singleWhere((t) => t.stepId == 'shared');
      final journal = SpacedReview.complete(
        data,
        library,
        shared,
        DecisionOutcome.firstTry,
        today,
      );
      expect(journal['completed'], hasLength(5));
      expect(journal['completedCards'], [shared.cardKey]);
      for (final goal in ['a1', 'a2', 'a3', 'a4', 'a5']) {
        expect(journal['entries']['unit_07:$goal']['due'], '2026-10-07');
        expect(
          journal['entries']['unit_07:$goal']['evidence'],
          'original-score',
        );
      }
      expect(data.toJson(), initial);
      data = AppData.fromJson(dataWithReview(data, journal).toJson());
      expect(data.attempts.single.toJson(), attempt.toJson());
      expect(data.journeys['unit_07'], {'marker': 'unfinished adventure'});
      expect(
        SpacedReview.complete(
          data,
          library,
          shared,
          DecisionOutcome.firstTry,
          today,
        ),
        journal,
      );
      expect(SpacedReview.due(data, library, today), hasLength(2));
      expect(
        SpacedReview.due(data, library, today).any((t) => t.stepId == 'shared'),
        false,
      );
      for (var i = 0; i < 2; i++) {
        final task = SpacedReview.due(data, library, today).first;
        data = dataWithReview(
          data,
          SpacedReview.complete(
            data,
            library,
            task,
            DecisionOutcome.afterHint,
            today,
          ),
        );
      }
      expect(SpacedReview.due(data, library, today), isEmpty);
      expect(
        SpacedReview.due(data, library, today.add(const Duration(days: 1))),
        isNotEmpty,
      );
    },
  );

  test('Version one daily goal counts migrate to distinct activity counts', () {
    final data = AppData(attempts: [attempt]);
    final journal = {
      ...SpacedReview.schedule(data, library),
      'version': 1,
      'completedDay': SpacedReview.day(today),
      'completed': ['unit_07:a1', 'unit_07:a2'],
    };
    final tasks = SpacedReview.due(
      dataWithReview(data, journal),
      library,
      today,
    );
    expect(tasks, hasLength(2));
    expect(tasks.any((t) => t.stepId == 'shared'), false);
  });

  test('Review remains child scoped and reset removes only its owner data', () {
    final owner = AppData(
      profile: const ChildProfile(name: 'Nour'),
      attempts: [attempt],
    );
    final task = SpacedReview.due(owner, library, today).first;
    final both = owner.addChild('second', const ChildProfile(name: 'Adam'));
    final updated = both.changeChild(
      'local-child',
      (child) => dataWithReview(
        child,
        SpacedReview.complete(
          child,
          library,
          task,
          DecisionOutcome.firstTry,
          today,
        ),
      ),
    );
    expect(updated.activeChildId, 'second');
    expect(updated.journeys, isEmpty);
    expect(updated.attempts, isEmpty);
    expect(SpacedReview.due(updated, library, today), isEmpty);
    final restored = AppData.fromJson(updated.toJson());
    final originalChild = restored.selectChild('local-child');
    expect(originalChild.attempts.single.toJson(), attempt.toJson());
    expect(originalChild.journeys[SpacedReview.storageKey], isNotNull);
    expect(originalChild.resetProgress().journeys, isEmpty);
    expect(
      originalChild.resetProgress().selectChild('second').journeys,
      isEmpty,
    );
    expect(
      restored
          .removeChild('local-child', emptyId: 'empty')
          .childRecords
          .containsKey('local-child'),
      false,
    );
  });
}
