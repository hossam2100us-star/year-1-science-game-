import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/biology/lesson_player.dart';
import 'package:science_adventure/features/biology/session.dart';
import 'package:science_adventure/features/science/science_picture.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Lesson lesson;
  const chartId = 'unit_06.step.008';
  setUpAll(() async {
    lesson = (await LessonLibrary.load()).lessons['unit_06']!;
    helpers.testCatalog = await helpers.loadTestCatalog();
    for (final atlas in scienceAtlases.keys) {
      await Flame.images.load(atlas);
    }
    await Flame.images.load('sound-atlas-v2.png');
    await Flame.images.load('sound-details-v2.png');
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
