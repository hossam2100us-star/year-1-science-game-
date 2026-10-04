import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/garden/alive_adventures.dart';
import 'package:science_adventure/features/garden/garden_model.dart';
import 'package:science_adventure/features/garden/garden_scene.dart';
import 'package:science_adventure/features/garden/garden_adventure.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Lesson lesson;
  late List<GardenContent> scenes;
  setUpAll(() async {
    helpers.testCatalog = await helpers.loadTestCatalog();
    lesson = (await LessonLibrary.load()).lessons['unit_01']!;
    scenes = aliveScenes(lesson);
    for (final scene in scenes) {
      await Flame.images.load(scene.asset);
    }
  });
  test(
    'Three source-linked scenes have 21 distinct discoveries and difficulties',
    () {
      expect(scenes.map((s) => s.difficulty), [1, 2, 3]);
      expect(scenes.map((s) => s.storageKey).toSet(), hasLength(3));
      final ids = <String>{};
      for (final scene in scenes) {
        expect(scene.items, hasLength(7));
        for (final item in scene.items) {
          expect(ids.add(item.id), isTrue, reason: item.id);
          expect(item.hint, isNotEmpty);
          expect(item.explanation, isNotEmpty);
        }
        for (final size in [const Size(800, 360), const Size(1280, 800)]) {
          final targets = gardenRects(
            size,
            touch: true,
            bounds: scene.bounds ?? gardenBounds,
          );
          expect(targets.keys.toSet(), scene.items.map((i) => i.id).toSet());
          for (final rect in targets.values) {
            expect(rect.width, greaterThanOrEqualTo(64));
            expect(rect.height, greaterThanOrEqualTo(64));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(size.width));
            expect(rect.top, greaterThanOrEqualTo(0));
            expect(rect.bottom, lessThanOrEqualTo(size.height));
          }
        }
      }
      expect(
        scenes.last.item('egg').question,
        contains('chick growing inside'),
      );
    },
  );
  test('Completion and replay use each scene IDs and retain legacy garden completion', () {
    for (final scene in scenes) {
      final round = GardenRound(
        version: scene.version,
        requiredIds: scene.items.map((i) => i.id).toSet(),
      );
      for (final item in scene.items) {
        round.select(item.id);
        round.answer(item, item.alive);
        round.next();
      }
      expect(scene.completed(round.toJson()), isTrue);
      final replay = GardenRound.restore(round.toJson(), scene).replay();
      expect(replay.results, isEmpty);
      expect(scene.completed(replay.toJson()), isTrue);
      expect(replay.history.single['results'], hasLength(7));
    }
  });
  for (final sceneIndex in [0, 1, 2]) {
    for (final size in [const Size(800, 360), const Size(1280, 800)]) {
      testWidgets(
        'All targets, honest explanation and independent saves $sceneIndex $size',
        (t) async {
          t.view.physicalSize = size;
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final scene = scenes[sceneIndex];
          final store = MemoryProgressStore(
            const AppData(profile: ChildProfile(name: 'Nour')),
          );
          await helpers.mount(
            t,
            GardenAdventure(content: scene),
            store,
            scale: size.width == 800 ? 2 : 1,
          );
          await t.pump(const Duration(milliseconds: 100));
          for (final item in scene.items) {
            await helpers.tapVisible(
              t,
              find.byKey(ValueKey('garden-${item.id}')),
            );
            expect(
              find.text(
                item.question ??
                    scene
                        .text('question')
                        .replaceAll('{name}', item.name.toLowerCase()),
              ),
              findsOneWidget,
            );
            final wrong = find.byKey(
              ValueKey(item.alive ? 'garden-not-alive' : 'garden-alive'),
            );
            await helpers.tapVisible(t, wrong);
            expect(find.byKey(const ValueKey('garden-hint')), findsOneWidget);
            expect(
              find.byKey(const ValueKey('garden-explanation')),
              findsNothing,
            );
            await helpers.tapVisible(t, wrong);
            expect(find.text(scene.text('explained')), findsOneWidget);
            expect(find.text(scene.text('praise')), findsNothing);
            expect(find.text(item.explanation), findsOneWidget);
            expect(
              t
                  .widget<GameWidget<GardenScene>>(
                    find.byType(GameWidget<GardenScene>),
                  )
                  .game!
                  .celebration,
              0,
            );
            await helpers.tapVisible(
              t,
              find.byKey(
                ValueKey(item.alive ? 'garden-alive' : 'garden-not-alive'),
              ),
            );
            expect(
              store.data.journeys[scene.storageKey]!['needsCorrection'],
              false,
            );
            await helpers.tapVisible(
              t,
              find.byKey(const ValueKey('garden-next')),
            );
            expect(
              store.data.journeys[scene.storageKey]!['results'][item.id],
              'explained',
            );
          }
          expect(store.data.journeys.keys.toList(), [scene.storageKey]);
          expect(store.data.attempts, isEmpty);
          expect(
            scene.completed(store.data.journeys[scene.storageKey]),
            isTrue,
          );
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        },
      );
    }
  }
  testWidgets('Normal unit menu offers all three distinct adventures', (
    t,
  ) async {
    t.view.physicalSize = const Size(1280, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final store = MemoryProgressStore(const AppData(profile: ChildProfile()));
    await helpers.mount(t, AliveAdventures(lesson: lesson), store);
    expect(find.byKey(const ValueKey('adventure-garden')), findsOneWidget);
    expect(find.byKey(const ValueKey('adventure-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('adventure-river')), findsOneWidget);
    await helpers.tapVisible(t, find.byKey(const ValueKey('adventure-home')));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('garden-grandmother')), findsOneWidget);
    expect(find.byKey(const ValueKey('garden-cat')), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
