import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/lesson/lesson_player.dart';
import 'package:science_adventure/features/lesson/session.dart';
import 'package:science_adventure/features/science/science_picture.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Lesson lesson;
  late Lesson materials;
  const chartId = 'unit_06.step.008';
  setUpAll(() async {
    final library = await LessonLibrary.load();
    lesson = library.lessons['unit_06']!;
    materials = library.lessons['unit_04']!;
    helpers.testCatalog = await helpers.loadTestCatalog();
    for (final atlas in scienceAtlases.keys) {
      await Flame.images.load(atlas);
    }
    await Flame.images.load('sound-atlas-v2.webp');
    await Flame.images.load('sound-details-v2.webp');
  });

  Map<String, dynamic> chartState({
    bool done = false,
    bool correction = false,
  }) => {
    'selected': ['maris_took'],
    'placements': {'furthest_listener': 'maris', 'maris_took': '23_steps'},
    'reviewItems': ['furthest_listener', 'maris_took'],
    'mistakes': done ? 2 : 1,
    'outcome': done ? 'explained' : null,
    'done': done,
    'needsCorrection': correction,
    'feedback': 'Maris took 23 steps.',
  };

  Map<String, dynamic> saved({
    int index = 7,
    Map<String, dynamic>? current,
    Map<String, dynamic>? responses,
  }) => {
    'version': 1,
    'attemptId': 'existing-sound-attempt',
    'index': index,
    'stepId': index < lesson.steps.length ? lesson.steps[index].id : null,
    'current': current ?? {},
    'responses': responses ?? {},
  };

  for (final outcome in ['hint', 'explained', 'firstTry']) {
    testWidgets('Restoring $outcome refreshes wording without regrading', (
      t,
    ) async {
      t.view.physicalSize = const Size(1280, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final step = materials.steps[1];
      final answers = Map<String, String>.from(step.answer!['value']);
      final done = outcome != 'hint';
      final mistakes = outcome == 'firstTry'
          ? 0
          : outcome == 'hint'
          ? 1
          : 2;
      final placements = outcome == 'firstTry'
          ? answers
          : {
              for (final entry in answers.entries)
                entry.key: step.targets
                    .firstWhere((target) => target.id != entry.value)
                    .id,
            };
      final old = {
        'selected': [step.options.first.id],
        'placements': placements,
        'mistakes': mistakes,
        'done': done,
        'outcome': done ? outcome : null,
        'needsCorrection': outcome == 'explained',
        'feedback': 'a) materials b) objects',
      };
      final session = LessonSession.fresh(materials)..index = 1;
      session.current = Map<String, dynamic>.from(old);
      if (outcome == 'firstTry') {
        session.responses[step.id] = {...old, 'completed': true};
      }
      final store = MemoryProgressStore(
        AppData(
          profile: const ChildProfile(name: 'Nour'),
          journeys: {materials.id: session.toJson()},
        ),
      );
      await helpers.mount(t, LessonPlayer(lesson: materials), store);
      expect(find.textContaining('a) materials'), findsNothing);
      expect(
        find.textContaining(done ? step.shortExplanation : step.hint),
        findsOneWidget,
      );
      if (outcome == 'hint') {
        expect(find.textContaining(step.explanation), findsNothing);
      }
      if (outcome == 'explained') {
        expect(find.text('Check my practice'), findsOneWidget);
        expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      }
      // Reopening and closing writes the updated wording, never a new grade.
      await t.pumpWidget(const SizedBox());
      await t.pump();
      final current = store.data.journeys[materials.id]!['current'];
      expect(current['placements'], placements);
      expect(current['mistakes'], mistakes);
      expect(current['outcome'], done ? outcome : null);
      expect(current['needsCorrection'], outcome == 'explained');
      if (outcome == 'firstTry') {
        expect(
          store.data.journeys[materials.id]!['responses'][step.id]['outcome'],
          'firstTry',
        );
      }
      expect(t.takeException(), isNull);
    });
  }

  testWidgets(
    'Historical Maris review refreshes its explanation and keeps its question',
    (t) async {
      t.view.physicalSize = const Size(1280, 950);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final old = {
        ...chartState(done: true),
        'feedback': 'a) Maris (23 steps) b) 23 steps',
      };
      final store = MemoryProgressStore(
        AppData(
          profile: const ChildProfile(name: 'Nour'),
          journeys: {
            lesson.id: saved(
              current: old,
              responses: {
                chartId: {...old, 'completed': true},
              },
            ),
          },
        ),
      );
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      expect(find.textContaining('a) Maris'), findsNothing);
      expect(
        find.textContaining(lesson.json['legacySoundChart']['explanation']),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('science-item-maris_took')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('science-item-david_took')),
        findsNothing,
      );
      await t.pumpWidget(const SizedBox());
      await t.pump();
      final state = store.data.journeys[lesson.id]!;
      expect(state['current']['placements'], old['placements']);
      expect(state['current']['mistakes'], 2);
      expect(state['current']['outcome'], 'explained');
      expect(state['responses'][chartId]['outcome'], 'explained');
      expect(t.takeException(), isNull);
    },
  );

  test(
    'Pending Maris answer is cleared without erasing first answer or effort',
    () {
      final previous = saved(current: chartState());
      expect(LessonSession.canRestore(lesson, previous), isTrue);
      final restored = LessonSession.restore(lesson, previous);
      expect(restored.attemptId, 'existing-sound-attempt');
      expect(restored.index, 7);
      expect(restored.current['placements'], {'furthest_listener': 'maris'});
      expect(restored.current['selected'], isEmpty);
      expect(restored.current['reviewItems'], ['furthest_listener']);
      expect(restored.current['mistakes'], 1);
      expect(restored.current['feedback'], isEmpty);
      expect(restored.current['legacySoundChart'], isNull);
      expect(previous['current']['placements']['maris_took'], '23_steps');
    },
  );

  test(
    'Pending chart resume state migrates while unrelated work is unchanged',
    () {
      final unrelated = {
        'prediction': 'quiet',
        'lab': {
          'tested': ['feather'],
        },
      };
      final restored = LessonSession.restore(
        lesson,
        saved(
          index: 9,
          current: {
            'selected': ['cat_steps'],
          },
          responses: {
            'unit_06.step.004': unrelated,
            chartId: {'resumeState': chartState()},
          },
        ),
      );
      expect(restored.index, 9);
      expect(restored.current, {
        'selected': ['cat_steps'],
      });
      expect(restored.responses['unit_06.step.004'], unrelated);
      final chart = restored.responses[chartId]['resumeState'];
      expect(chart['placements'], {'furthest_listener': 'maris'});
      expect(chart['mistakes'], 1);
      expect(chart['legacySoundChart'], isNull);
    },
  );

  test(
    'Explained chart practice uses David without changing its original grade',
    () {
      final restored = LessonSession.restore(
        lesson,
        saved(current: chartState(done: true, correction: true)),
      );
      expect(restored.current['done'], isTrue);
      expect(restored.current['needsCorrection'], isTrue);
      expect(restored.current['mistakes'], 2);
      expect(restored.current['outcome'], 'explained');
      expect(restored.current['placements'], {'furthest_listener': 'maris'});
      expect(restored.current['legacySoundChart'], isNull);
    },
  );

  test(
    'Completed chart keeps its historical answers and result through resave',
    () {
      final previous = {...chartState(done: true), 'completed': true};
      final restored = LessonSession.restore(
        lesson,
        saved(current: chartState(done: true), responses: {chartId: previous}),
      );
      expect(restored.current, {
        ...chartState(done: true),
        'legacySoundChart': true,
      });
      expect(restored.responses[chartId], {
        ...previous,
        'legacySoundChart': true,
      });
      expect(
        restored.result().objectives['u06.main.05'],
        DecisionOutcome.explained,
      );
      final reloaded = LessonSession.restore(lesson, restored.toJson());
      expect(reloaded.current, restored.current);
      expect(reloaded.responses, restored.responses);
      expect(reloaded.attemptId, restored.attemptId);
      expect(reloaded.result().objectives, restored.result().objectives);
    },
  );

  test(
    'Finished legacy journey stays finished with the same assessed evidence',
    () {
      final restored = LessonSession.restore(
        lesson,
        saved(
          index: lesson.steps.length,
          responses: {
            chartId: {...chartState(done: true), 'completed': true},
          },
        ),
      );
      expect(restored.finished, isTrue);
      expect(restored.current, isEmpty);
      expect(restored.responses[chartId]['legacySoundChart'], isTrue);
      expect(
        restored.result().objectives['u06.main.05'],
        DecisionOutcome.explained,
      );
    },
  );

  test('Fresh and current-version journeys use the new David question', () {
    final fresh = LessonSession.fresh(lesson)..index = 7;
    expect(lesson.version, 2);
    expect(fresh.step.options.map((p) => p.id), [
      'furthest_listener',
      'david_took',
    ]);
    expect(fresh.step.answer!['value']['david_took'], '8_steps');
    fresh.current = {
      'placements': {'david_took': '8_steps'},
    };
    final restored = LessonSession.restore(lesson, fresh.toJson());
    expect(restored.current, fresh.current);
    expect(restored.current['legacySoundChart'], isNull);
  });

  testWidgets('Legacy chart review stays Maris after navigation and restart', (
    t,
  ) async {
    t.view.physicalSize = const Size(1280, 950);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final complete = {...chartState(done: true), 'completed': true};
    final store = MemoryProgressStore(
      AppData(
        profile: const ChildProfile(name: 'Nour'),
        journeys: {
          lesson.id: saved(
            index: 8,
            current: {
              'selected': ['tap_harder'],
            },
            responses: {chartId: complete},
          ),
        },
      ),
    );
    await helpers.mount(t, LessonPlayer(lesson: lesson), store);
    await helpers.tapVisible(t, find.byKey(const ValueKey('lessonPrevious')));
    expect(
      find.byKey(const ValueKey('science-item-maris_took')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('science-item-david_took')), findsNothing);
    expect(find.text('Check my discovery'), findsNothing);
    await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
    expect(
      store.data.journeys[lesson.id]!['responses'][chartId]['outcome'],
      'explained',
    );
    await helpers.tapVisible(t, find.byKey(const ValueKey('lessonPrevious')));
    expect(
      store.data.journeys[lesson.id]!['current']['legacySoundChart'],
      isTrue,
    );
    await t.pumpWidget(const SizedBox());
    await helpers.mount(t, LessonPlayer(lesson: lesson), store);
    expect(
      find.byKey(const ValueKey('science-item-maris_took')),
      findsOneWidget,
    );
    expect(store.data.attempts, isEmpty);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'Pending legacy chart opens with David and retains the first choice',
    (t) async {
      t.view.physicalSize = const Size(1280, 950);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final store = MemoryProgressStore(
        AppData(
          profile: const ChildProfile(name: 'Nour'),
          journeys: {lesson.id: saved(current: chartState())},
        ),
      );
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      expect(
        find.byKey(const ValueKey('science-item-maris_took')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('science-item-david_took')),
        findsOneWidget,
      );
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('science-item-david_took')),
      );
      final state = store.data.journeys[lesson.id]!['current'];
      expect(state['placements'], {'furthest_listener': 'maris'});
      expect(state['selected'], ['david_took']);
      expect(state['mistakes'], 1);
      expect(state['done'], isFalse);
      expect(t.takeException(), isNull);
    },
  );
}
