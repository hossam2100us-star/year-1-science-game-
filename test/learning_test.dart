import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/lesson/lesson_player.dart';
import 'package:science_adventure/features/lesson/session.dart';
import 'package:science_adventure/games/question_engine.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonLibrary library;
  setUpAll(() async {
    library = await LessonLibrary.load();
    await Future.wait([
      Flame.images.load('bean-stages-v1.webp'),
      Flame.images.load('greenhouse-v1.webp'),
    ]);
    helpers.testCatalog = await helpers.loadTestCatalog();
  });
  test('Every graded task accepts its answer and completes only once', () {
    for (final lesson in library.lessons.values) {
      for (final step in lesson.steps.where((s) => !s.isFree)) {
        final engine = QuestionEngine(step);
        expect(engine.feedback, isEmpty, reason: step.id);
        expect(engine.submit(step.answer!['value']), isTrue, reason: step.id);
        expect(engine.outcome, DecisionOutcome.firstTry);
        expect(engine.submit(step.answer!['value']), isFalse);
        expect(engine.outcome, DecisionOutcome.firstTry);
      }
    }
  });
  test(
    'Hint follows one miss; solution follows the second, without a lost life',
    () {
      final step = library.lessons['unit_01']!.steps.firstWhere(
        (s) => !s.isFree,
      );
      final engine = QuestionEngine(step);
      engine.submit(null);
      expect(engine.done, isFalse);
      expect(engine.feedback, contains(step.hint));
      expect(engine.feedback, isNot(contains(step.explanation)));
      engine.submit(null);
      expect(engine.done, isTrue);
      expect(engine.outcome, DecisionOutcome.explained);
      expect(engine.feedback, contains(step.explanation));
    },
  );
  test('Set and ordering answers reject duplicates and incorrect order', () {
    expect(
      matchesAnswer(
        {
          'type': 'set',
          'value': ['a', 'b'],
        },
        ['a', 'a'],
      ),
      isFalse,
    );
    expect(
      matchesAnswer(
        {
          'type': 'set',
          'value': ['a', 'b'],
        },
        ['b', 'a'],
      ),
      isTrue,
    );
    expect(
      matchesAnswer(
        {
          'type': 'sequence',
          'value': ['a', 'b'],
        },
        ['b', 'a'],
      ),
      isFalse,
    );
    expect(
      matchesAnswer(
        {
          'type': 'mapping',
          'value': {'a': 'b'},
        },
        {'a': 'b', 'x': 'y'},
      ),
      isFalse,
    );
  });
  test('Quiz stays out of ten and subparts do not inflate unit scores', () {
    for (final lesson in library.lessons.values) {
      final responses = <String, dynamic>{
        for (final step in lesson.steps)
          step.id: {
            'outcome': 'firstTry',
            'completed': true,
            if (step.json['objectiveItems'] is Map)
              'objectiveEvidence': {
                for (final objective in step.assessedObjectives)
                  objective: 'firstTry',
              },
          },
      };
      final results = objectiveResults(lesson, responses);
      expect(results.length, lesson.objectives.length);
      if (lesson.quiz) expect(results.length, 10);
      final assessed = lesson.steps.where((s) => s.assessed).toList();
      responses[assessed.last.id] = {'outcome': 'explained', 'completed': true};
      expect(
        objectiveResults(lesson, responses)[assessed.last.objective],
        DecisionOutcome.explained,
      );
    }
  });
  test(
    'Completing a recovered attempt twice is idempotent and keeps the profile',
    () async {
      final store = MemoryProgressStore(
        const AppData(profile: ChildProfile(name: 'Nour')),
      );
      final container = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final session = LessonSession.fresh(library.lessons['quiz_01']!);
      final controller = container.read(appProvider.notifier);
      await controller.saveJourney('quiz_01', session.toJson());
      final restored = LessonSession.restore(
        session.lesson,
        store.data.journeys['quiz_01']!,
      );
      expect(restored.attemptId, session.attemptId);
      final result = UnitAttempt(
        unitId: 'quiz_01',
        completedAt: DateTime(2026),
        objectives: {},
        completed: true,
        effortStars: 3,
        attemptId: session.attemptId,
      );
      await controller.completeJourney(result);
      await controller.completeJourney(result);
      expect(store.data.attempts.length, 1);
      expect(store.data.journeys, isEmpty);
      expect(store.data.profile!.name, 'Nour');
    },
  );
  test('Version one profile saves without journeys still load', () {
    final old = const AppData(profile: ChildProfile(name: 'Alex')).toJson()
      ..remove('journeys');
    expect(AppData.fromJson(old).journeys, isEmpty);
    expect(AppData.fromJson(old).profile!.name, 'Alex');
  });
  for (final size in [const Size(800, 360), const Size(1280, 800)]) {
    testWidgets(
      'Exploration requires touching and saves the next step at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = MemoryProgressStore(
          const AppData(profile: ChildProfile(name: 'Nour')),
        );
        final lesson = library.lessons['unit_01']!;
        await helpers.mount(
          tester,
          LessonPlayer(lesson: lesson),
          store,
          scale: size.width == 800 ? 2 : 1,
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
        for (final label in ['Tree', 'Cat', 'Car']) {
          await helpers.tapVisible(tester, find.text(label));
        }
        await helpers.tapVisible(
          tester,
          find.byKey(const ValueKey('lessonNext')),
        );
        expect(store.data.journeys['unit_01']!['index'], 1);
        expect(store.data.attempts, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );
  }
  testWidgets('Prediction is stored before revealing the bean result', (
    tester,
  ) async {
    final lesson = library.lessons['unit_02']!;
    final index = lesson.steps.indexWhere(
      (s) => s.kind == 'predict-then-reveal',
    );
    final session = LessonSession.fresh(lesson)..index = index;
    final store = MemoryProgressStore(
      AppData(
        profile: const ChildProfile(),
        journeys: {lesson.id: session.toJson()},
      ),
    );
    await helpers.mount(tester, LessonPlayer(lesson: lesson), store);
    await helpers.tapVisible(tester, find.text('Leaf'));
    expect(store.data.journeys[lesson.id]!['current']['frame'], 0);
    await helpers.tapVisible(tester, find.text('Water and watch'));
    expect(
      store.data.journeys[lesson.id]!['current']['bean']['prediction'],
      'leaf',
    );
    expect(store.data.journeys[lesson.id]!['current']['bean']['frame'], 1);
    expect(store.data.attempts, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
