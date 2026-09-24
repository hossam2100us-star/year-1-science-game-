import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/features/plants/plant_lab_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/biology/lesson_player.dart';
import 'package:science_adventure/features/biology/session.dart';
import 'package:science_adventure/features/plants/plant_lab_game.dart';
import 'package:science_adventure/features/plants/plant_lab_stage.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Lesson lesson;
  setUpAll(() async {
    helpers.testCatalog = await helpers.loadTestCatalog();
    lesson = (await LessonLibrary.load()).lessons['unit_02']!;
    await Flame.images.load('plant-lab-v1.png');
  });
  MemoryProgressStore at(int index, {Map<String, dynamic>? current}) {
    final session = LessonSession.fresh(lesson)..index = index;
    session.current = current ?? {};
    return MemoryProgressStore(
      AppData(
        profile: const ChildProfile(name: 'Nour'),
        journeys: {'unit_02': session.toJson()},
      ),
    );
  }

  PlantLabGame game(WidgetTester t) => t
      .widget<GameWidget<PlantLabGame>>(find.byType(GameWidget<PlantLabGame>))
      .game!;
  testWidgets(
    'Review starts at the new plant without modifying a saved later journey',
    (t) async {
      t.view.physicalSize = const Size(1280, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final original = at(10, current: {'prediction': 'pale_and_floppy'});
      final before = original.data.toJson();
      await helpers.mount(
        t,
        ProviderScope(
          overrides: [
            lessonLibraryProvider.overrideWith(
              (ref) async => LessonLibrary({'unit_02': lesson}),
            ),
          ],
          child: const PlantLabPreview(),
        ),
        original,
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('plant-review-banner')), findsOneWidget);
      expect(find.text(lesson.steps.first.title), findsOneWidget);
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('plant-name-stem')),
      );
      final review = ProviderScope.containerOf(
        t.element(find.byType(PlantLabStage)),
      ).read(appProvider);
      expect(review.journeys['unit_02']!['index'], 0);
      expect(
        review.journeys['unit_02']!['current']['touched'],
        contains('stem'),
      );
      expect(original.data.toJson(), before);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump();
    },
  );
  test(
    'Story focus, picture choices and source text describe the same plant part',
    () {
      for (final step in lesson.steps.where((s) => s.kind == 'story')) {
        expect(step.json['playScene'], 'plant-lab');
        expect(step.options.single.id, step.focus);
        expect(step.prompt.toLowerCase(), startsWith(step.focus!));
      }
      for (final size in [const Size(390, 260), const Size(780, 520)]) {
        for (final id in plantPartRegions.keys) {
          final r = plantPartRect(id, size, touch: true);
          expect(r.width, greaterThanOrEqualTo(63.999));
          expect(r.height, greaterThanOrEqualTo(63.999));
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.bottom, lessThanOrEqualTo(size.height));
        }
      }
    },
  );
  for (final spec in [
    (const Size(824, 860), 1.0),
    (const Size(800, 360), 2.0),
    (const Size(1280, 800), 1.0),
  ]) {
    testWidgets(
      'Recovered Stem story points to Stem and waits for touching it at ${spec.$1}',
      (t) async {
        t.view.physicalSize = spec.$1;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final store = at(
          2,
          current: {
            'selected': ['plant'],
            'touched': ['plant'],
          },
        );
        await helpers.mount(
          t,
          LessonPlayer(lesson: lesson),
          store,
          scale: spec.$2,
        );
        expect(find.byType(PlantLabStage), findsOneWidget);
        expect(game(t).activePart, 'stem');
        expect(find.text('Plant'), findsNothing);
        expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
        await helpers.tapVisible(
          t,
          find.byKey(const ValueKey('plant-part-stem')),
        );
        expect(game(t).animationLeft, greaterThan(0));
        expect(
          store.data.journeys['unit_02']!['current']['touched'],
          contains('stem'),
        );
        await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
        expect(game(t).activePart, 'leaf');
        expect(find.text(lesson.steps[3].prompt), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.pump();
      },
    );
  }
  testWidgets(
    'Exploration speaks the selected part and all four touches persist',
    (t) async {
      final store = at(0);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      for (final part in ['roots', 'stem', 'leaf', 'flower']) {
        await helpers.tapVisible(t, find.byKey(ValueKey('plant-name-$part')));
        expect(game(t).activePart, part);
        expect(
          find.text(lesson.steps[0].json['partDescriptions'][part]),
          findsOneWidget,
        );
      }
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('plant-name-stem')),
      );
      expect(game(t).activePart, 'stem');
      expect(
        store.data.journeys['unit_02']!['current']['touched'],
        hasLength(4),
      );
      expect(store.data.attempts, isEmpty);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump();
    },
  );
  testWidgets(
    'Plant puzzle supports drag, retains assembled parts and uses two gentle attempts',
    (t) async {
      t.view.physicalSize = const Size(1280, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final store = at(5);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      final piece = find.byKey(const ValueKey('plant-piece'));
      final roots = find.byKey(const ValueKey('plant-part-roots'));
      await t.ensureVisible(roots);
      await t.pump(const Duration(milliseconds: 100));
      await t.dragFrom(
        t.getCenter(piece),
        t.getCenter(roots) - t.getCenter(piece),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(game(t).discovered, contains('roots'));
      expect(store.data.journeys['unit_02']!['current']['outcome'], 'firstTry');
      await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
      expect(game(t).discovered, contains('roots'));
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('plant-part-flower')),
      );
      expect(store.data.journeys['unit_02']!['current']['done'], isFalse);
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('plant-part-flower')),
      );
      expect(
        store.data.journeys['unit_02']!['current']['outcome'],
        'explained',
      );
      expect(game(t).discovered, containsAll(['roots', 'stem']));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump();
    },
  );
}
