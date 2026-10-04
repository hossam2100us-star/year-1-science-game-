import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/biology/session.dart';
import 'package:science_adventure/features/biology/lesson_player.dart';
import 'package:science_adventure/features/plants/plant_workshop.dart';

import 'setup_screen_test.dart' as helpers;
import 'support/review_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Lesson lesson;
  setUpAll(() async {
    helpers.testCatalog = await helpers.loadTestCatalog();
    lesson = (await LessonLibrary.load()).lessons['unit_02']!;
  });
  test(
    'Version three partly built plant retains completed and current pieces',
    () {
      final restored = LessonSession.restore(lesson, {
        'version': 3,
        'attemptId': 'old-build',
        'index': 2,
        'stepId': 'unit_02.step.007',
        'responses': {
          'unit_02.step.001': {'completed': true},
          'unit_02.step.006': {'completed': true},
        },
        'current': {
          'done': true,
          'placements': {'stem': 'stem'},
        },
      });
      expect(restored.index, 1);
      expect(restored.current['touched'], containsAll(['roots', 'stem']));
      expect(restored.responses['unit_02.step.006'], isNull);
      expect(
        LessonSession.restore(lesson, restored.toJson()).current,
        restored.current,
      );
    },
  );
  for (final size in [const Size(800, 360), const Size(1280, 900)]) {
    testWidgets(
      'Builder rejects wrong placement and resumes a partial plant at $size',
      (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final session = LessonSession.fresh(lesson)..index = 1;
        final store = MemoryProgressStore(
          AppData(
            profile: const ChildProfile(name: 'Nour'),
            journeys: {lesson.id: session.toJson()},
          ),
        );
        await helpers.mount(t, LessonPlayer(lesson: lesson), store);
        expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
        Map<String, Decoration?> slotStyles() => {
          for (final id in ['roots', 'stem', 'leaf', 'flower'])
            id:
                (t
                            .widget<InkWell>(
                              find.byKey(ValueKey('workshop-slot-$id')),
                            )
                            .child
                        as Container)
                    .decoration,
        };
        final neutralStyles = slotStyles();
        await helpers.tapVisible(
          t,
          find.byKey(const ValueKey('workshop-piece-roots')),
        );
        expect(
          slotStyles(),
          neutralStyles,
          reason: 'Choosing a piece must not reveal its destination',
        );
        await helpers.tapVisible(
          t,
          find.byKey(const ValueKey('workshop-slot-flower')),
        );
        expect(
          t.widget<PlantWorkshop>(find.byType(PlantWorkshop)).placed,
          isEmpty,
        );
        await helpers.tapVisible(
          t,
          find.byKey(const ValueKey('workshop-slot-roots')),
        );
        await t.pumpWidget(const SizedBox());
        await helpers.mount(t, LessonPlayer(lesson: lesson), store);
        expect(t.widget<PlantWorkshop>(find.byType(PlantWorkshop)).placed, {
          'roots',
        });
        for (final part in ['stem', 'flower', 'leaf']) {
          await helpers.tapVisible(
            t,
            find.byKey(ValueKey('workshop-piece-$part')),
          );
          await helpers.tapVisible(
            t,
            find.byKey(ValueKey('workshop-slot-$part')),
          );
        }
        await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
        expect(store.data.journeys[lesson.id]!['index'], 2);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('Render builder without a hidden plant or answer labels', (
    t,
  ) async {
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
            child: PlantWorkshop(
              step: lesson.steps[1],
              placed: {},
              onPlace: (_) {},
            ),
          ),
        ),
      ),
    );
    await t.pump();
    expect(find.text('Roots'), findsOneWidget);
    final painter = t
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<WorkshopCanvas>()
        .single;
    expect(painter.placed, isEmpty);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await t.runAsync(() async {
      final picture = await boundary.toImage();
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      await saveReviewImage('plant-builder.png', bytes);
      picture.dispose();
    });
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
