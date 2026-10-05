import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/features/lesson/lesson_player.dart';
import 'package:science_adventure/features/lesson/session.dart';
import 'package:science_adventure/features/plants/light_model.dart';
import 'package:science_adventure/features/plants/light_game.dart';
import 'package:science_adventure/features/plants/light_experiment.dart';
import 'package:science_adventure/features/plants/plant_lab_preview.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Lesson lesson;
  late LessonStep step;
  late int lightIndex;
  setUpAll(() async {
    helpers.testCatalog = await helpers.loadTestCatalog();
    lesson = (await LessonLibrary.load()).lessons['unit_02']!;
    lightIndex = lesson.steps.indexWhere(
      (s) => s.json['experiment'] == 'light',
    );
    expect(lightIndex, greaterThanOrEqualTo(0));
    step = lesson.steps[lightIndex];
    await Future.wait([
      Flame.images.load('light-room-v1.webp'),
      Flame.images.load('light-plants-v1.webp'),
    ]);
  });
  LightGame game(WidgetTester t) =>
      t.widget<GameWidget<LightGame>>(find.byType(GameWidget<LightGame>)).game!;
  test('Both predictions lead to the same observed result only after equal watering', () {
    expect(step.json['experiment'], 'light');
    expect(step.assessed, isFalse);
    for (final choice in LightProgress.choices) {
      var p = const LightProgress();
      expect(p.water('window').watered, isEmpty);
      p = p.predict(choice).water('window');
      expect(p.compare().revealed, isFalse);
      expect(p.water('window').watered, hasLength(1));
      expect(p.predict('invalid').prediction, choice);
      p = p.water('cupboard').compare();
      expect(p.revealed, isTrue);
      expect(LightProgress.restore(p.toJson()).prediction, choice);
    }
    expect(
      LightProgress.restore({
        'revealed': true,
        'watered': ['window', 'cupboard'],
      }).revealed,
      isFalse,
    );
    expect(
      LightProgress.fromLegacy({'prediction': 'green_and_strong', 'frame': 1})
          .readyToCompare,
      isTrue,
    );
    expect(
      LightProgress.fromLegacy({'prediction': 'pale_and_floppy', 'frame': 2})
          .revealed,
      isTrue,
    );
    expect(step.frames.map((f) => f['label']), ['Day 1', 'Day 9']);
  });
  for (final spec in [
    (const Size(824, 860), 1.0),
    (const Size(800, 360), 2.0),
    (const Size(1280, 800), 1.0),
  ]) {
    testWidgets(
      'Light experiment saves prediction, waters both, reveals Day 9 and continues at ${spec.$1}',
      (t) async {
        t.view.physicalSize = spec.$1;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final session = LessonSession.fresh(lesson)..index = lightIndex;
        final store = MemoryProgressStore(
          AppData(
            profile: const ChildProfile(name: 'Nour'),
            journeys: {'unit_02': session.toJson()},
          ),
        );
        await helpers.mount(
          t,
          LessonPlayer(lesson: lesson),
          store,
          scale: spec.$2,
        );
        await t.pump(const Duration(milliseconds: 100));
        expect(
          find.text('${lightIndex + 1}/${lesson.steps.length}'),
          findsOneWidget,
        );
        expect(game(t).progress.revealed, isFalse);
        await helpers.tapVisible(
          t,
          find.byKey(const ValueKey('light-pot-window')),
        );
        expect(game(t).progress.watered, isEmpty);
        await helpers.tapVisible(
          t,
          find.byKey(const ValueKey('light-guess-green_and_strong')),
        );
        expect(
          store.data.journeys['unit_02']!['current']['light']['prediction'],
          'green_and_strong',
        );
        expect(game(t).progress.revealed, isFalse);
        await helpers.tapVisible(
          t,
          find.byKey(const ValueKey('light-water-window')),
        );
        expect(find.byKey(const ValueKey('light-compare')), findsNothing);
        await helpers.tapVisible(
          t,
          find.byKey(const ValueKey('light-water-cupboard')),
        );
        await helpers.tapVisible(
          t,
          find.byKey(const ValueKey('light-compare')),
        );
        expect(game(t).progress.revealed, isTrue);
        expect(find.text('Day 9'), findsOneWidget);
        expect(
          store.data.journeys['unit_02']!['current']['light']['watered'],
          hasLength(2),
        );
        expect(store.data.attempts, isEmpty);
        await helpers.tapVisible(t, find.byKey(const ValueKey('light-finish')));
        expect(store.data.journeys['unit_02']!['index'], lightIndex + 1);
        expect(
          find.text('${lightIndex + 2}/${lesson.steps.length}'),
          findsOneWidget,
        );
        expect(store.data.attempts, isEmpty);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.pump();
      },
    );
  }
  testWidgets(
    'An existing finished generic light experiment resumes at Day 9',
    (t) async {
      final session = LessonSession.fresh(lesson)..index = lightIndex;
      session.current = {
        'prediction': 'pale_and_floppy',
        'frame': 2,
        'freeDone': true,
      };
      final store = MemoryProgressStore(
        AppData(
          profile: const ChildProfile(),
          journeys: {'unit_02': session.toJson()},
        ),
      );
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      await t.pump(const Duration(milliseconds: 100));
      expect(game(t).progress.revealed, isTrue);
      expect(find.text('Day 9'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('light-guess-green_and_strong')),
        findsNothing,
      );
      await helpers.tapVisible(t, find.byKey(const ValueKey('light-finish')));
      expect(store.data.journeys['unit_02']!['index'], lightIndex + 1);
      await t.pumpWidget(const SizedBox());
      await t.pump();
    },
  );
  testWidgets(
    'Failed result save leaves Day 1 and can be retried without losing the guess',
    (t) async {
      var fail = true;
      final initial = const LightProgress()
          .predict('pale_and_floppy')
          .water('window')
          .water('cupboard')
          .toJson();
      await helpers.mount(
        t,
        LightExperiment(
          step: step,
          initial: initial,
          position: '${lightIndex + 1}/${lesson.steps.length}',
          onSave: (j) async {
            if (fail && j['revealed'] == true) throw StateError('disk full');
          },
          onFinished: () async {},
          onLeave: () async {},
        ),
        MemoryProgressStore(),
      );
      await t.pump(const Duration(milliseconds: 100));
      await helpers.tapVisible(t, find.byKey(const ValueKey('light-compare')));
      expect(game(t).progress.revealed, isFalse);
      expect(find.text('Day 1'), findsOneWidget);
      fail = false;
      await helpers.tapVisible(t, find.byKey(const ValueKey('light-compare')));
      expect(game(t).progress.revealed, isTrue);
      expect(game(t).progress.prediction, 'pale_and_floppy');
      await t.pumpWidget(const SizedBox());
      await t.pump();
    },
  );
  testWidgets('Direct light review is isolated from the saved child journey', (
    t,
  ) async {
    final session = LessonSession.fresh(lesson)..index = 3;
    final store = MemoryProgressStore(
      AppData(
        profile: const ChildProfile(name: 'Nour'),
        journeys: {'unit_02': session.toJson()},
      ),
    );
    final before = store.data.toJson();
    await helpers.mount(
      t,
      ProviderScope(
        overrides: [
          lessonLibraryProvider.overrideWith(
            (ref) async => LessonLibrary({'unit_02': lesson}),
          ),
        ],
        child: PlantLabPreview(initialStep: lightIndex),
      ),
      store,
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byType(LightExperiment), findsOneWidget);
    expect(
      find.text('${lightIndex + 1}/${lesson.steps.length}'),
      findsOneWidget,
    );
    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('light-guess-pale_and_floppy')),
    );
    expect(store.data.toJson(), before);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump();
  });
}
