import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/biology/lesson_player.dart';
import 'package:science_adventure/features/biology/session.dart';
import 'package:science_adventure/features/plants/plant_mission_stage.dart';
import 'package:science_adventure/features/plants/plant_workshop.dart';

import 'setup_screen_test.dart' as helpers;
import 'support/review_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Lesson lesson;
  setUpAll(() async {
    helpers.testCatalog = await helpers.loadTestCatalog();
    lesson = (await LessonLibrary.load()).lessons['unit_02']!;
    await Flame.images.load('science-details-v2.webp');
  });
  test('Fridge neighbours belong to different food groups', () {
    final step = lesson.steps[4];
    final groups = step.answer!['value'] as Map;
    for (var i = 1; i < step.options.length; i++) {
      expect(groups[step.options[i].id], isNot(groups[step.options[i - 1].id]));
    }
  });
  testWidgets(
    'Workshop requires placement, saves and restores, stays ungraded',
    (t) async {
      t.view.physicalSize = const Size(1100, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final session = LessonSession.fresh(lesson)..index = 12;
      final store = MemoryProgressStore(
        AppData(
          profile: const ChildProfile(name: 'Nour'),
          journeys: {lesson.id: session.toJson()},
        ),
      );
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('workshop-piece-roots')),
      );
      expect(
        store.data.journeys[lesson.id]!['current']['touched'] ?? [],
        isEmpty,
      );
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('workshop-slot-roots')),
      );
      expect(store.data.journeys[lesson.id]!['current']['touched'], ['roots']);
      await t.pumpWidget(const SizedBox());
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      expect(t.widget<PlantWorkshop>(find.byType(PlantWorkshop)).placed, {
        'roots',
      });
      for (final id in ['stem', 'leaf', 'flower']) {
        await helpers.tapVisible(t, find.byKey(ValueKey('workshop-piece-$id')));
        await helpers.tapVisible(t, find.byKey(ValueKey('workshop-slot-$id')));
      }
      await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
      expect(store.data.journeys[lesson.id]!['index'], 13);
      expect(
        store.data.journeys[lesson.id]!['responses'][lesson
            .steps[12]
            .id]['outcome'],
        isNull,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Workshop drag assembles only the matching part', (t) async {
    t.view.physicalSize = const Size(1000, 850);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final placed = <String>{};
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlantWorkshop(
            step: lesson.steps[12],
            placed: placed,
            onPlace: placed.add,
          ),
        ),
      ),
    );
    await t.drag(
      find.byKey(const ValueKey('workshop-piece-flower')),
      t.getCenter(find.byKey(const ValueKey('workshop-slot-flower'))) -
          t.getCenter(find.byKey(const ValueKey('workshop-piece-flower'))),
    );
    await t.pump();
    expect(placed, {'flower'});
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'Render missing illustrations and completed workshop for review',
    (t) async {
      t.view.physicalSize = const Size(1000, 850);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: Column(
                children: [
                  Row(
                    children: [
                      for (final id in [
                        'toys',
                        'paper',
                        'wind',
                        'dry_and_drooping',
                      ])
                        Expanded(
                          child: Column(
                            children: [
                              PlantMissionPicture(id: id),
                              Text(id),
                            ],
                          ),
                        ),
                    ],
                  ),
                  PlantWorkshop(
                    step: lesson.steps[12],
                    placed: {'roots', 'stem', 'leaf', 'flower'},
                    onPlace: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await t.runAsync(() async {
        final picture = await boundary.toImage();
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        await saveReviewImage('plant-review.png', bytes);
        picture.dispose();
      });
    },
  );
}
