import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/lesson/lesson_player.dart';
import 'package:science_adventure/features/lesson/session.dart';
import 'package:science_adventure/features/science/science_lab.dart';
import 'package:science_adventure/features/science/material_workshop.dart';
import 'package:science_adventure/features/science/science_picture.dart';

import 'setup_screen_test.dart' as helpers;
import 'support/review_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Lesson lesson;
  setUpAll(() async {
    lesson = (await LessonLibrary.load()).lessons['unit_04']!;
    helpers.testCatalog = await helpers.loadTestCatalog();
    for (final name in ['Nunito', 'Fredoka', 'Cairo']) {
      await (FontLoader(
        name,
      )..addFont(rootBundle.load('assets/fonts/$name.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final file in [
      'materials-atlas-v2.webp',
      'science-details-v2.webp',
      'physics-atlas-v1.webp',
    ]) {
      await Flame.images.load(file);
    }
  });
  MemoryProgressStore startAt(int index) {
    final session = LessonSession.fresh(lesson)..index = index;
    for (final s in lesson.steps.take(index)) {
      session.responses[s.id] = {'completed': true};
    }
    return MemoryProgressStore(
      AppData(
        profile: const ChildProfile(name: 'Nour'),
        journeys: {lesson.id: session.toJson()},
      ),
    );
  }

  Map<dynamic, dynamic> current(MemoryProgressStore store) =>
      store.data.journeys[lesson.id]!['current'];
  Future<void> choose(WidgetTester t, String id) =>
      helpers.tapVisible(t, find.byKey(ValueKey('science-item-$id')));
  Future<void> place(WidgetTester t, String id, String target) async {
    await choose(t, id);
    await helpers.tapVisible(t, find.byKey(ValueKey('science-target-$target')));
  }

  void size(WidgetTester t, Size value) {
    t.view.physicalSize = value;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> tap(WidgetTester t, String key) =>
      helpers.tapVisible(t, find.byKey(ValueKey(key)));
  Future<void> capture(WidgetTester t, GlobalKey key, String name) =>
      t.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await saveReviewImage('material-missions/$name.png', bytes);
        image.dispose();
      });

  testWidgets(
    'Object and material pairs show both examples named by the question',
    (t) async {
      size(t, const Size(1280, 1000));
      final store = startAt(1), step = lesson.steps[1];
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      final expected = [
        ['spoon', 'chair'],
        ['metal', 'wood'],
      ];
      for (var i = 0; i < step.options.length; i++) {
        final pictures = find.descendant(
          of: find.byKey(ValueKey('science-item-${step.options[i].id}')),
          matching: find.byType(SciencePicture),
        );
        expect(
          t.widgetList<SciencePicture>(pictures).map((p) => p.art),
          expected[i],
        );
      }
      expect(current(store)['placements'] as Map? ?? const {}, isEmpty);
      expect(current(store)['outcome'], isNull);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Every material room touch area stays separate and inside the phone scene',
    (t) async {
      size(t, const Size(360, 740));
      for (final index in [0, 12]) {
        await helpers.mount(
          t,
          LessonPlayer(lesson: lesson),
          startAt(index),
          scale: 1.5,
        );
        final scene = t.getRect(
          find
              .descendant(
                of: find.byType(MaterialWorkshop),
                matching: find.byType(ClipRRect),
              )
              .first,
        );
        final touchAreas = <Rect>[];
        for (final item in lesson.steps[index].options) {
          final area = t.getRect(
            find.byKey(ValueKey('science-item-${item.id}')),
          );
          expect(area.width, greaterThanOrEqualTo(48));
          expect(area.height, greaterThanOrEqualTo(48));
          expect(scene.contains(area.topLeft), true, reason: item.id);
          expect(
            scene.contains(area.bottomRight - const Offset(.1, .1)),
            true,
            reason: item.id,
          );
          for (final other in touchAreas) {
            expect(area.overlaps(other), false, reason: item.id);
          }
          touchAreas.add(area);
        }
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'Rain kit supports dragging, removal, restart and guided correction',
    (t) async {
      size(t, const Size(1280, 1000));
      final store = startAt(6);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      final paper = find.byKey(const ValueKey('science-item-paper'));
      final bag = find.byKey(const ValueKey('material-rain-bag'));
      await t.ensureVisible(bag);
      await t.pump();
      await t.dragFrom(
        t.getCenter(paper),
        t.getCenter(bag) - t.getCenter(paper),
      );
      await t.pump(const Duration(milliseconds: 500));
      expect(current(store)['selected'], contains('paper'));
      await tap(t, 'unpack-paper');
      expect(current(store)['selected'], isEmpty);
      await choose(t, 'paper');
      await choose(t, 'aluminium_foil');
      await helpers.tapVisible(t, find.text('Check my discovery'));
      // A second try needs a different answer (teacher review 5).
      await choose(t, 'cotton_cloth');
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(current(store)['needsCorrection'], true);
      await t.pumpWidget(const SizedBox());
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      await tap(t, 'unpack-paper');
      await tap(t, 'unpack-cotton_cloth');
      await choose(t, 'plastic');
      await helpers.tapVisible(t, find.text('Check my practice'));
      expect(current(store)['outcome'], 'explained');
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Shape trials require predictions and different actions on soft and hard objects',
    (t) async {
      size(t, const Size(1280, 1000));
      final store = startAt(7), step = lesson.steps[7];
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      expect(
        t
            .widget<FilledButton>(find.byKey(const ValueKey('lab-shape-test')))
            .onPressed,
        isNull,
      );
      await tap(t, 'lab-shape-guess-same');
      await t.pumpWidget(const SizedBox());
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      expect(current(store)['lab']['shapeGuesses']['dough:Twist'], 'same');
      await tap(t, 'lab-shape-test');
      expect(current(store)['lab']['shapeTried'], ['dough:Twist']);
      for (final trial in [
        ('rubber_band', 'Stretch'),
        ('sponge', 'Squash'),
        ('paper_straw', 'Bend'),
      ]) {
        await tap(t, 'lab-shape-${trial.$1}');
        await tap(t, 'lab-action-${trial.$2}');
        await tap(t, 'lab-shape-guess-change');
        await tap(t, 'lab-shape-test');
      }
      expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      await tap(t, 'lab-shape-metal_spoon');
      expect(find.byKey(const ValueKey('lab-action-Stretch')), findsNothing);
      await tap(t, 'lab-shape-guess-change');
      await tap(t, 'lab-shape-test');
      expect(
        ScienceLab.shapeComplete(
          step,
          Map<String, dynamic>.from(current(store)['lab']),
        ),
        true,
      );
      expect(
        current(store)['lab']['shapeGuesses']['metal_spoon:Squash'],
        'change',
      );
      expect(current(store)['mistakes'], 0);
      expect(current(store)['outcome'], isNull);
      await t.pumpWidget(const SizedBox());
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Squash trays accept a drag and allow correcting a placement', (
    t,
  ) async {
    size(t, const Size(1280, 1000));
    final store = startAt(8);
    await helpers.mount(t, LessonPlayer(lesson: lesson), store);
    final item = find.byKey(const ValueKey('science-item-stone'));
    final tray = find.byKey(const ValueKey('science-target-can_squash'));
    await t.dragFrom(t.getCenter(item), t.getCenter(tray) - t.getCenter(item));
    await t.pump(const Duration(milliseconds: 500));
    expect(current(store)['placements']['stone'], 'can_squash');
    await place(t, 'stone', 'cannot_squash');
    expect(current(store)['placements']['stone'], 'cannot_squash');
    expect(current(store)['outcome'], isNull);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'Later materials scenes render with context and remain usable at enlarged text',
    (t) async {
      size(t, const Size(1280, 1000));
      for (var index = 6; index < 13; index++) {
        final store = startAt(index), key = GlobalKey();
        await helpers.mount(
          t,
          RepaintBoundary(
            key: key,
            child: LessonPlayer(lesson: lesson),
          ),
          store,
        );
        await t.pump(const Duration(milliseconds: 500));
        await capture(t, key, 'step-${index + 1}');
        expect(t.takeException(), isNull, reason: 'screen ${index + 1}');
        await t.pumpWidget(const SizedBox());
      }
      t.view.physicalSize = const Size(800, 360);
      for (var index = 6; index < 13; index++) {
        final store = startAt(index);
        await helpers.mount(t, LessonPlayer(lesson: lesson), store, scale: 1.5);
        if (lesson.steps[index].assessed) {
          await choose(t, lesson.steps[index].options.last.id);
        }
        expect(t.takeException(), isNull, reason: 'small screen ${index + 1}');
        await t.pumpWidget(const SizedBox());
      }
    },
  );
}
