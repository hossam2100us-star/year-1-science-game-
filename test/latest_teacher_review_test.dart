import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/answer_summary.dart';
import 'package:science_adventure/core/design.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/spaced_review.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/lesson/lesson_player.dart';
import 'package:science_adventure/features/lesson/session.dart';
import 'package:science_adventure/features/garden/garden_model.dart';
import 'package:science_adventure/features/science/quiz_action_stage.dart';
import 'package:science_adventure/features/world/todays_challenge.dart';
import 'package:science_adventure/parent/unit_report.dart';

import 'setup_screen_test.dart' as helpers;
import 'support/review_images.dart';

class _Voice extends helpers.SilentNarration {
  final spoken = <String>[];
  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonLibrary library;
  setUpAll(() async {
    library = await LessonLibrary.load();
    helpers.testCatalog = await helpers.loadTestCatalog();
    for (final font in ['Nunito', 'Fredoka', 'Cairo']) {
      await (FontLoader(
        font,
      )..addFont(rootBundle.load('assets/fonts/$font.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final assets = await AssetManifest.loadFromAssetBundle(rootBundle);
    for (final asset in assets.listAssets().where(
      (p) =>
          p.startsWith('assets/images/') &&
          (p.endsWith('.png') || p.endsWith('.webp')),
    )) {
      await Flame.images.load(asset.substring('assets/images/'.length));
    }
  });
  void size(WidgetTester t, Size value) {
    t.view.physicalSize = value;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> mount(
    WidgetTester t,
    Widget child,
    MemoryProgressStore store, {
    double scale = 1,
    _Voice? voice,
  }) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
          catalogProvider.overrideWithValue(helpers.testCatalog),
          narrationProvider.overrideWith((ref) => voice ?? _Voice()),
          lessonLibraryProvider.overrideWith((ref) async => library),
        ],
        child: MaterialApp(
          theme: adventureTheme(store.data.profile),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: child,
        ),
      ),
    );
    await t.pump();
    await t.pump();
  }

  Future<void> tap(WidgetTester t, String key) =>
      helpers.tapVisible(t, find.byKey(ValueKey(key)));
  MemoryProgressStore start(String id, int index) {
    final lesson = library.lessons[id]!;
    return MemoryProgressStore(
      AppData(
        profile: const ChildProfile(name: 'Nour'),
        journeys: {id: (LessonSession.fresh(lesson)..index = index).toJson()},
      ),
    );
  }

  Map<dynamic, dynamic> current(MemoryProgressStore store, String id) =>
      store.data.journeys[id]!['current'];
  Future<void> capture(WidgetTester t, GlobalKey key, String name) =>
      t.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await saveReviewImage('latest-review/$name.png', bytes);
        image.dispose();
      });

  test('Every assessed goal has an adapted safe home activity and short display explanation', () {
    for (final lesson in library.lessons.values) {
      final goals = List<Map<String, dynamic>>.from(
        lesson.json['goalActivities'],
      );
      expect(goals.map((g) => g['objective']).toSet(), lesson.objectives);
      for (final step in lesson.steps.where((s) => s.assessed)) {
        expect(
          step.shortExplanation.split(RegExp(r'\s+')).length,
          lessThanOrEqualTo(16),
        );
        expect(step.explanation, isNotEmpty);
      }
    }
    for (final step in library.lessons['unit_07']!.steps) {
      for (final book in step.options.where((p) => p.id == 'book')) {
        expect(book.art, 'book');
      }
    }
  });

  test('Review intervals, three-card daily limit, reload, and new evidence preserve original scores', () {
    final lesson = library.lessons['unit_07']!;
    final date = DateTime(2026, 10, 1);
    final outcomes = {
      for (final goal in lesson.objectives) goal: DecisionOutcome.explained,
    };
    final attempt = UnitAttempt(
      unitId: lesson.id,
      completedAt: date,
      objectives: outcomes,
      completed: true,
      effortStars: 3,
      attemptId: 'original',
      contentVersion: lesson.version,
    );
    var data = AppData(profile: const ChildProfile(), attempts: [attempt]);
    expect(SpacedReview.due(data, library, date), isEmpty);
    final today = DateTime(2026, 10, 2);
    for (var i = 0; i < 3; i++) {
      final tasks = SpacedReview.due(data, library, today);
      expect(tasks.length, 3 - i);
      final task = tasks.first;
      final journal = SpacedReview.complete(
        data,
        library,
        task,
        DecisionOutcome.firstTry,
        today,
      );
      expect(journal['entries'][task.key]['due'], '2026-10-05');
      expect(
        SpacedReview.complete(
          data.copyWith(journeys: {SpacedReview.storageKey: journal}),
          library,
          task,
          DecisionOutcome.firstTry,
          today,
        ),
        journal,
      );
      data = AppData.fromJson(
        data.copyWith(journeys: {SpacedReview.storageKey: journal}).toJson(),
      );
    }
    expect(SpacedReview.due(data, library, today), isEmpty);
    expect(
      SpacedReview.due(data, library, today.add(const Duration(days: 1))),
      isNotEmpty,
    );
    expect(data.attempts.single.toJson(), attempt.toJson());
    final secondChild = data.addChild(
      'second',
      const ChildProfile(name: 'Adam'),
    );
    expect(SpacedReview.due(secondChild, library, today), isEmpty);
    expect(
      secondChild.selectChild('local-child').journeys[SpacedReview.storageKey],
      isNotNull,
    );
    expect(data.resetProgress().journeys, isEmpty);
  });

  test('Garden discoveries also become scheduled practice without creating unit grades', () {
    final garden = GardenContent(library.lessons['unit_01']!.json['garden']);
    final round = GardenRound(
      version: garden.version,
      roundId: DateTime(2026, 10, 1).microsecondsSinceEpoch.toString(),
    );
    round.select('cat');
    round.answer(garden.item('cat'), false, now: DateTime(2026, 10, 1));
    round.answer(garden.item('cat'), false, now: DateTime(2026, 10, 1));
    final restored = GardenRound.restore(round.toJson(), garden);
    restored.next();
    expect(restored.selected, 'cat');
    restored.select('tree');
    expect(restored.selected, 'cat');
    restored.answer(garden.item('cat'), true);
    restored.next();
    final data = AppData(journeys: {garden.storageKey: restored.toJson()});
    final tasks = SpacedReview.due(data, library, DateTime(2026, 10, 2));
    expect(tasks.single.gardenScene, 'garden');
    expect(tasks.single.stepId, 'cat');
    expect(data.attempts, isEmpty);
    expect(restored.results['cat'], 'explained');
  });

  testWidgets(
    'Review writes remain with their owning child through a queued switch',
    (t) async {
      final date = DateTime(2026, 10, 1);
      final lesson = library.lessons['unit_07']!;
      final attempt = UnitAttempt(
        unitId: lesson.id,
        completedAt: date,
        objectives: {lesson.steps[6].objective: DecisionOutcome.explained},
        completed: true,
        effortStars: 3,
      );
      final data =
          AppData(
                profile: const ChildProfile(name: 'Nour'),
                attempts: [attempt],
              )
              .addChild('second', const ChildProfile(name: 'Adam'))
              .selectChild('local-child');
      final task = SpacedReview.due(
        data,
        library,
        date.add(const Duration(days: 1)),
      ).single;
      final store = MemoryProgressStore(data);
      final container = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final controller = container.read(appProvider.notifier);
      await controller.selectChild('second');
      await controller.completeReview(
        'local-child',
        library,
        task,
        DecisionOutcome.firstTry,
        date.add(const Duration(days: 1)),
      );
      expect(
        container.read(appProvider).journeys[SpacedReview.storageKey],
        isNull,
      );
      expect(
        container
            .read(appProvider)
            .selectChild('local-child')
            .journeys[SpacedReview.storageKey]!['completed'],
        [task.key],
      );
      await controller.removeChild('local-child');
      expect(
        container.read(appProvider).childRecords.containsKey('local-child'),
        false,
      );
    },
  );

  for (final config in [
    (const Size(360, 740), 1.5),
    (const Size(1280, 900), 1.0),
  ]) {
    testWidgets(
      'Shared discovery scenes and synchronized safety speech fit ${config.$1}',
      (t) async {
        size(t, config.$1);
        for (final id in ['unit_07', 'unit_08', 'unit_09']) {
          final store = start(id, 0), key = GlobalKey(), voice = _Voice();
          await mount(
            t,
            RepaintBoundary(
              key: key,
              child: LessonPlayer(lesson: library.lessons[id]!),
            ),
            store,
            scale: config.$2,
            voice: voice,
          );
          await capture(t, key, '$id-${config.$1.width.toInt()}');
          final step = library.lessons[id]!.steps.first;
          if (id == 'unit_07') {
            await tap(t, 'science-item-${step.options[0].id}');
            await tap(t, 'science-world-next');
            final description =
                // The name comes first (teacher review 4).
                step.discoveryText(step.options[1].id);
            expect(
              t
                  .widget<Text>(find.byKey(const ValueKey('lesson-feedback')))
                  .data,
              description,
            );
            expect(current(store, id)['touched'], [step.options[0].id]);
            await helpers.tapVisible(t, find.byTooltip('Listen to feedback'));
            expect(voice.spoken.last, description);
            await capture(t, key, 'safety-dry-${config.$1.width.toInt()}');
            await tap(t, 'science-world-next');
            await capture(t, key, 'safety-adult-${config.$1.width.toInt()}');
          } else {
            final rects = <Rect>[];
            for (final item in step.options) {
              final marker = find.byKey(ValueKey('science-item-${item.id}'));
              expect(marker, findsOneWidget);
              final rect = t.getRect(marker);
              expect(rect.width, greaterThanOrEqualTo(47.99));
              expect(rect.height, greaterThanOrEqualTo(47.99));
              if (id == 'unit_09') {
                final bounds = t.getRect(
                  find.byKey(const ValueKey('space-discovery-model')),
                );
                expect(bounds.contains(rect.topLeft), true);
                expect(bounds.contains(rect.bottomRight), true);
              }
              for (final previous in rects) {
                expect(rect.overlaps(previous), false);
              }
              rects.add(rect);
              await tap(t, 'science-item-${item.id}');
            }
            expect(
              current(store, id)['touched'].toSet(),
              step.options.map((o) => o.id).toSet(),
            );
            expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
            if (id == 'unit_09') {
              expect(
                // Moved to the parent report (teacher review 4).
                find.text('Model: sizes and distances are not to scale.'),
                findsNothing,
              );
            }
          }
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        }
      },
    );
  }

  for (final example in [
    // Two-option questions cannot reach 'explained' any more: after one wrong
    // answer the only other choice is right (teacher review 5).
    ('unit_02', 11, 'mission'),
    ('unit_03', 9, 'biology'),
    ('unit_07', 6, 'science'),
    ('unit_08', 1, 'science'),
    ('unit_09', 3, 'science'),
  ]) {
    testWidgets(
      'Explained ${example.$1} answer requires saved child correction without regrading',
      (t) async {
        size(t, const Size(1280, 900));
        final lesson = library.lessons[example.$1]!,
            step = lesson.steps[example.$2];
        final store = start(lesson.id, example.$2);
        final wrong = [
          for (final o in step.options)
            if (o.id != step.answer!['value']) o,
        ];
        final right = step.answer!['value'];
        await mount(t, LessonPlayer(lesson: lesson), store);
        // A tap only chooses; Check sends it. Two different wrong answers.
        for (final choice in wrong.take(2)) {
          await tap(t, '${example.$3}-item-${choice.id}');
          await tap(t, 'lessonCheck');
        }
        expect(current(store, lesson.id)['needsCorrection'], true);
        expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
        await t.pumpWidget(const SizedBox());
        await mount(t, LessonPlayer(lesson: lesson), store);
        expect(current(store, lesson.id)['needsCorrection'], true);
        await tap(t, '${example.$3}-item-$right');
        await tap(t, 'lessonCheck');
        expect(current(store, lesson.id)['needsCorrection'], false);
        expect(current(store, lesson.id)['outcome'], 'explained');
        expect(current(store, lesson.id)['mistakes'], 2);
        expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Accepted Beat survives success and reload; screen is short while Listen stays complete',
    (t) async {
      size(t, const Size(1280, 900));
      final lesson = library.lessons['unit_06']!, step = lesson.steps[2];
      final session = LessonSession.fresh(lesson)..index = 2;
      final answer = Map<String, String>.from(step.answer!['value']);
      answer['triangle'] = 'beat';
      session.current = {'placements': answer};
      final store = MemoryProgressStore(
        AppData(
          profile: const ChildProfile(name: 'Nour'),
          journeys: {lesson.id: session.toJson()},
        ),
      );
      final voice = _Voice();
      await mount(t, LessonPlayer(lesson: lesson), store, voice: voice);
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(current(store, lesson.id)['outcome'], 'firstTry');
      expect(current(store, lesson.id)['placements']['triangle'], 'beat');
      expect(
        t.widget<Text>(find.byKey(const ValueKey('lesson-feedback'))).data,
        step.shortExplanation,
      );
      await helpers.tapVisible(t, find.byTooltip('Listen to feedback'));
      expect(voice.spoken.last, contains(step.explanation));
      await t.pumpWidget(const SizedBox());
      await mount(t, LessonPlayer(lesson: lesson), store);
      expect(current(store, lesson.id)['placements']['triangle'], 'beat');
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Daily practice changes its schedule and leaves real progress and attempts untouched',
    (t) async {
      size(t, const Size(1280, 900));
      final lesson = library.lessons['unit_07']!, step = lesson.steps[6];
      final original = {
        'version': lesson.version,
        'index': 3,
        'marker': 'real unfinished work',
      };
      final attempt = UnitAttempt(
        unitId: lesson.id,
        completedAt: DateTime.now().subtract(const Duration(days: 2)),
        objectives: {step.objective: DecisionOutcome.explained},
        completed: true,
        effortStars: 3,
        attemptId: 'real',
      );
      final store = MemoryProgressStore(
        AppData(
          profile: const ChildProfile(name: 'Nour'),
          journeys: {lesson.id: original},
          attempts: [attempt],
        ),
      );
      await mount(t, const ChallengeScreen(), store);
      final task = SpacedReview.due(store.data, library, DateTime.now()).single;
      await tap(t, 'review-${task.key}');
      await tap(t, 'science-item-${step.answer!['value']}');
      await tap(t, 'lessonCheck');
      await tap(t, 'lessonNext');
      expect(
        find.text('All done for today. See you on the islands!'),
        findsOneWidget,
      );
      expect(store.data.journeys[lesson.id], original);
      expect(store.data.attempts.single.toJson(), attempt.toJson());
      expect(store.data.journeys[SpacedReview.storageKey]!['completed'], [
        task.key,
      ]);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Garden daily practice names its selected subject and preserves the whole adventure',
    (t) async {
      size(t, const Size(1280, 900));
      final content = GardenContent(library.lessons['unit_01']!.json['garden']);
      final round = GardenRound(
        version: content.version,
        requiredIds: content.items.map((i) => i.id).toSet(),
      );
      round.select('tree');
      round.answer(
        content.item('tree'),
        true,
        now: DateTime.now().subtract(const Duration(days: 4)),
      );
      round.next();
      final original = round.toJson();
      final store = MemoryProgressStore(
        AppData(
          profile: const ChildProfile(name: 'Nour'),
          journeys: {content.storageKey: original},
        ),
      );
      await mount(t, const ChallengeScreen(), store);
      final task = SpacedReview.due(store.data, library, DateTime.now()).single;
      await tap(t, 'review-${task.key}');
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Tap the tree.'), findsOneWidget);
      expect(find.byKey(const ValueKey('garden-cat')), findsNothing);
      await tap(t, 'garden-tree');
      await tap(t, 'garden-alive');
      await tap(t, 'garden-next');
      expect(
        find.text('All done for today. See you on the islands!'),
        findsOneWidget,
      );
      expect(store.data.journeys[content.storageKey], original);
      expect(store.data.attempts, isEmpty);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Quiz gestures, drop and listening offer alternatives without grading previews',
    (t) async {
      size(t, const Size(800, 800));
      final choices = <String>[], sounds = <double>[];
      final quiz = library.lessons['quiz_03']!;
      for (final index in [0, 1, 3, 4]) {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: QuizActionStage(
                  step: quiz.steps[index],
                  done: false,
                  onItem: choices.add,
                  onSound: (_, volume) => sounds.add(volume),
                ),
              ),
            ),
          ),
        );
        await t.pump();
        expect(choices, isEmpty);
        if (index == 0) {
          await t.drag(
            find.byKey(const ValueKey('quiz-action-object')),
            const Offset(0, 80),
          );
          expect(choices, ['pull']);
        } else if (index == 1) {
          await t.tap(find.byKey(const ValueKey('quiz-action-object')));
          expect(choices, ['push']);
        } else if (index == 3) {
          final from = find.byType(Draggable<String>),
              to = find.byKey(const ValueKey('quiz-drop-source_of_sound'));
          await t.drag(from, t.getCenter(to) - t.getCenter(from));
          expect(choices, ['source_of_sound']);
        } else {
          await tap(t, 'quiz-listen-distance');
          await t.drag(find.byType(Slider), const Offset(300, 0));
          await tap(t, 'quiz-listen-distance');
          expect(sounds.last, lessThan(sounds.first));
          expect(choices, isEmpty);
          await tap(t, 'science-item-fainter_and_quieter');
          expect(choices, ['fainter_and_quieter']);
        }
        choices.clear();
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'Relationship summaries and weak-goal parent activities fit enlarged text',
    (t) async {
      size(t, const Size(360, 740));
      final lesson = library.lessons['unit_07']!;
      final level = helpers.testCatalog.islands
          .expand((i) => i.levels)
          .firstWhere((l) => l.id == lesson.id);
      final store = MemoryProgressStore(
        AppData(
          profile: const ChildProfile(),
          attempts: [
            UnitAttempt(
              unitId: lesson.id,
              completedAt: DateTime.now(),
              objectives: {
                lesson.steps[6].objective: DecisionOutcome.explained,
              },
              completed: true,
              effortStars: 3,
            ),
          ],
        ),
      );
      await mount(
        t,
        Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const AnswerSummary(
                  pairs: [
                    (
                      'A long description of the instrument',
                      'Beat the drum gently',
                    ),
                  ],
                ),
                UnitReport(level: level, arabic: false),
              ],
            ),
          ),
        ),
        store,
        scale: 2,
      );
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      expect(find.text('Practice for: Inside the torch'), findsOneWidget);
      final activity = (lesson.json['goalActivities'] as List).firstWhere(
        (a) => a['objective'] == lesson.steps[6].objective,
      );
      expect(find.text(activity['text']), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
