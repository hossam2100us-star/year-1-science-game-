import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/biology/lesson_player.dart';
import 'package:science_adventure/features/biology/session.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Lesson lesson;
  setUpAll(() async {
    helpers.testCatalog = await helpers.loadTestCatalog();
    lesson = (await LessonLibrary.load()).lessons['unit_02']!;
    for (final asset in [
      'plant-foods-v1.webp',
      'plant-lab-v1.webp',
      'greenhouse-v1.webp',
      'bean-stages-v1.webp',
      'light-plants-v1.webp',
      'science-details-v2.png',
    ]) {
      await Flame.images.load(asset);
    }
  });
  test('Plants has one food collection and no repeated carrot, lettuce or part questions', () {
    expect(lesson.version, 4);
    expect(lesson.steps, hasLength(14));
    expect(
      lesson.steps.where((s) => s.prompt.contains('Move the carrot')),
      isEmpty,
    );
    expect(
      lesson.steps.where((s) => s.prompt.contains('Move the lettuce')),
      isEmpty,
    );
    expect(
      lesson.steps.where((s) => s.id == 'unit_02.fridge.v2').single.options,
      hasLength(13),
    );
    expect(lesson.steps.where((s) => s.kind == 'order-sequence'), hasLength(1));
    expect(lesson.steps.map((s) => s.prompt).toSet(), hasLength(14));
  });
  test('Legacy light test retains saved prediction and same step', () {
    final responses = {
      for (final id in List<String>.from(lesson.json['legacyStepIds']).take(10))
        id: {'completed': true},
    };
    final old = {
      'version': 1,
      'attemptId': 'legacy',
      'index': 10,
      'responses': responses,
      'current': {
        'light': {
          'prediction': 'pale_and_floppy',
          'watered': ['window'],
          'revealed': false,
        },
      },
    };
    expect(LessonSession.canRestore(lesson, old), isTrue);
    final resumed = LessonSession.restore(lesson, old);
    expect(resumed.index, 3);
    expect(resumed.current, old['current']);
    expect(resumed.attemptId, 'legacy');
  });
  test(
    'Old food discoveries merge once without inventing first-try results',
    () {
      final oldIds = List<String>.from(lesson.json['legacyStepIds']);
      final responses = {
        for (final id in oldIds.take(25))
          id: {'completed': true, 'done': true, 'outcome': 'firstTry'},
      };
      responses[oldIds[12]]!['outcome'] = 'explained';
      final old = {
        'version': 1,
        'attemptId': 'legacy',
        'index': 25,
        'responses': responses,
        'current': {},
      };
      final resumed = LessonSession.restore(lesson, old);
      expect(resumed.step.id, 'unit_02.bean-trail.v2');
      expect(resumed.responses['unit_02.fridge.v2']['outcome'], 'explained');
      expect(
        resumed.result().objectives['u02.main.08'],
        DecisionOutcome.explained,
      );
      expect(resumed.responses[oldIds[12]]['outcome'], 'explained');
      expect(
        LessonSession.restore(lesson, resumed.toJson()).step.id,
        resumed.step.id,
      );
    },
  );
  for (final size in [const Size(800, 360), const Size(1280, 800)]) {
    testWidgets(
      'Fridge can be sorted by touch, stays ungraded until complete at $size',
      (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final session = LessonSession.fresh(lesson)..index = 4;
        final store = MemoryProgressStore(
          AppData(
            profile: const ChildProfile(name: 'Nour'),
            journeys: {lesson.id: session.toJson()},
          ),
        );
        await helpers.mount(
          t,
          LessonPlayer(lesson: lesson),
          store,
          scale: size.width == 800 ? 1.5 : 1,
        );
        final step = lesson.steps[4];
        expect(
          t
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Check my discovery'),
              )
              .onPressed,
          isNull,
        );
        for (var i = 0; i < step.options.length; i++) {
          final item = step.options[i];
          final visibleFoods = find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key as ValueKey<String>).value.startsWith('mission-item-'),
          );
          expect(visibleFoods, findsOneWidget);
          await helpers.tapVisible(
            t,
            find.byKey(ValueKey('mission-item-${item.id}')),
          );
          await helpers.tapVisible(
            t,
            find.byKey(
              ValueKey("mission-target-${step.answer!['value'][item.id]}"),
            ),
          );
          expect(
            store.data.journeys[lesson.id]!['current']['outcome'],
            isNull,
            reason: 'A basket choice must not award a result before checking',
          );
          if (i + 1 < step.options.length) {
            await helpers.tapVisible(
              t,
              find.byKey(const ValueKey('plant-collection-next')),
            );
          }
        }
        await helpers.tapVisible(t, find.text('Check my discovery'));
        expect(
          find.textContaining('You looked really carefully!'),
          findsOneWidget,
        );
        expect(
          store.data.journeys[lesson.id]!['current']['outcome'],
          'firstTry',
        );
        await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
        expect(store.data.journeys[lesson.id]!['index'], 5);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('Food trail resumes and lets a wrong basket be corrected', (
    t,
  ) async {
    t.view.physicalSize = const Size(1100, 850);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final step = lesson.steps[4];
    final session = LessonSession.fresh(lesson)..index = 4;
    final store = MemoryProgressStore(
      AppData(
        profile: const ChildProfile(name: 'Nour'),
        journeys: {lesson.id: session.toJson()},
      ),
    );
    await helpers.mount(t, LessonPlayer(lesson: lesson), store);
    final first = step.options.first;
    final correct = step.answer!['value'][first.id] as String;
    final wrong = step.targets.firstWhere((p) => p.id != correct).id;
    await helpers.tapVisible(
      t,
      find.byKey(ValueKey('mission-item-${first.id}')),
    );
    await helpers.tapVisible(t, find.byKey(ValueKey('mission-target-$wrong')));
    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('plant-collection-next')),
    );
    final second = step.options[1];
    await t.pumpWidget(const SizedBox());
    await helpers.mount(t, LessonPlayer(lesson: lesson), store);
    expect(find.byKey(ValueKey('mission-item-${second.id}')), findsOneWidget);
    expect(
      store.data.journeys[lesson.id]!['current']['placements'][first.id],
      wrong,
    );
    expect(store.data.journeys[lesson.id]!['current']['outcome'], isNull);
    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('plant-collection-previous')),
    );
    final food = find.byKey(ValueKey('mission-item-${first.id}'));
    final basket = find.byKey(ValueKey('mission-target-$correct'));
    await t.ensureVisible(food);
    await t.pump();
    await t.drag(food, t.getCenter(basket) - t.getCenter(food));
    await t.pump();
    expect(
      store.data.journeys[lesson.id]!['current']['placements'][first.id],
      correct,
    );
    expect(store.data.journeys[lesson.id]!['current']['outcome'], isNull);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
