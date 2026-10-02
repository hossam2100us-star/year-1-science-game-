import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/biology/lesson_player.dart';
import 'package:science_adventure/features/biology/session.dart';
import 'package:science_adventure/features/science/science_picture.dart';
import 'package:science_adventure/features/science/force_picture.dart';
import 'package:science_adventure/features/science/force_stage.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Lesson lesson;
  setUpAll(() async {
    lesson = (await LessonLibrary.load()).lessons['unit_05']!;
    helpers.testCatalog = await helpers.loadTestCatalog();
    for (final name in ['Nunito', 'Fredoka', 'Cairo']) {
      await (FontLoader(
        name,
      )..addFont(rootBundle.load('assets/fonts/$name.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await Flame.images.load('sense-objects-v2.webp');
    for (final file in scienceAtlases.keys) {
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

  Map current(MemoryProgressStore store) =>
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
        await Directory('tmp/forces-scenes').create(recursive: true);
        await File('tmp/forces-scenes/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });

  testWidgets(
    'Trolley drag and push comparison persist without grading a prediction',
    (t) async {
      size(t, const Size(1280, 1000));
      final store = startAt(1);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      final track = find.byKey(const ValueKey('force-track-object')).first;
      await t.ensureVisible(track);
      await t.drag(track, const Offset(600, 0));
      await t.pump(const Duration(milliseconds: 300));
      expect(current(store)['lab']['visited'], contains('far'));
      await tap(t, 'lab-force-pull');
      expect(current(store)['lab']['visited'], contains('near'));
      expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      await tap(t, 'lab-force-part-compare');
      expect(
        t
            .widget<FilledButton>(
              find.byKey(const ValueKey('lab-force-test-gentle')),
            )
            .onPressed,
        isNull,
      );
      await tap(t, 'lab-force-guess-gentle');
      await tap(t, 'lab-force-test-gentle');
      await t.pumpWidget(const SizedBox());
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      expect(current(store)['lab']['forceGuess'], 'gentle');
      expect(current(store)['lab']['pushTrials'], ['gentle']);
      await tap(t, 'lab-force-test-strong');
      expect(current(store)['lab']['forceGuess'], 'gentle');
      expect(current(store)['outcome'], isNull);
      expect(current(store)['mistakes'], 0);
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Tank placements are learner choices and guided correction survives navigation',
    (t) async {
      size(t, const Size(1280, 1000));
      final store = startAt(5), step = lesson.steps[5];
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      for (final e in (step.answer!['value'] as Map).entries) {
        await place(t, e.key, e.key == 'stone' ? 'float' : e.value);
      }
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(find.byKey(const ValueKey('review-item-stone')), findsOneWidget);
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(current(store)['placements']['stone'], 'float');
      expect(current(store)['needsCorrection'], true);
      await tap(t, 'lessonPrevious');
      // Return from a previously completed review activity.
      await tap(t, 'lessonNext');
      expect(current(store)['needsCorrection'], true);
      await place(t, 'stone', 'sink');
      await helpers.tapVisible(t, find.text('Check my practice'));
      expect(current(store)['outcome'], 'explained');
      expect(current(store)['mistakes'], 2);
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Sailboat requires a saved prediction before touch or hold can move it',
    (t) async {
      size(t, const Size(1280, 1000));
      final store = startAt(7);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      final blow = find.byKey(const ValueKey('lab-blow'));
      await t.ensureVisible(blow);
      final touch = await t.startGesture(t.getCenter(blow));
      await t.pump(const Duration(seconds: 1));
      await touch.up();
      expect(current(store)['lab']?['distance'], isNull);
      await tap(t, 'lab-boat-guess-still');
      await t.pumpWidget(const SizedBox());
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      for (var i = 0; i < 7; i++) {
        await tap(t, 'lab-blow');
      }
      expect(current(store)['lab']['boatPrediction'], 'still');
      expect(current(store)['freeDone'], true);
      expect(current(store)['outcome'], isNull);
      expect(current(store)['mistakes'], 0);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'A touch animates only that subject, can replay, and respects reduced motion',
    (t) async {
      size(t, const Size(1280, 950));
      final boundary = GlobalKey();
      await helpers.mount(
        t,
        RepaintBoundary(
          key: boundary,
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: false),
              child: LessonPlayer(lesson: lesson),
            ),
          ),
        ),
        startAt(0),
      );
      Future<void> touch(String id) async {
        final item = find.byKey(ValueKey('science-item-$id'));
        await t.ensureVisible(item);
        await t.tap(item);
        await t.pump();
        await t.pump(const Duration(milliseconds: 600));
      }

      await touch('fly');
      final flying = t.widget<ForcePicture>(
        find.descendant(
          of: find.byKey(const ValueKey('science-item-fly')),
          matching: find.byType(ForcePicture),
        ),
      );
      expect(flying.phase, greaterThan(0));
      await capture(t, boundary, 'bird-mid-flight');
      await touch('swim');
      final moving = t
          .widgetList<MovementSprite>(find.byType(MovementSprite))
          .where((sprite) => sprite.active)
          .toList();
      expect(moving.map((sprite) => sprite.art), ['fish']);
      await t.pump(const Duration(seconds: 3));
      await touch('swim');
      final fish = t.widget<ForcePicture>(
        find.descendant(
          of: find.byKey(const ValueKey('science-item-swim')),
          matching: find.byType(ForcePicture),
        ),
      );
      expect(fish.phase, inExclusiveRange(0, 6 * 3.141593));
      await t.pump(const Duration(seconds: 3));
      final stoppedPhase = t
          .widget<ForcePicture>(
            find.descendant(
              of: find.byKey(const ValueKey('science-item-swim')),
              matching: find.byType(ForcePicture),
            ),
          )
          .phase;
      await t.pump(const Duration(seconds: 2));
      expect(
        t
            .widget<ForcePicture>(
              find.descendant(
                of: find.byKey(const ValueKey('science-item-swim')),
                matching: find.byType(ForcePicture),
              ),
            )
            .phase,
        stoppedPhase,
      );
      await t.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: MovementSprite(
              art: 'bird',
              motion: 'fly',
              active: true,
              size: 100,
            ),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 3));
      expect(t.widget<ForcePicture>(find.byType(ForcePicture)).phase, 0);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'All forces cutouts render on a coloured scene without white tiles',
    (t) async {
      size(t, const Size(1200, 900));
      final key = GlobalKey();
      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Nunito'),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              backgroundColor: const Color(0xFFBCD8CB),
              body: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final art in ForcePicture.subjects)
                    SizedBox(
                      width: 185,
                      height: 180,
                      child: Column(
                        children: [
                          ForcePicture(art, height: 135, phase: 1),
                          Text(art),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await capture(t, key, 'cutout-contact-sheet');
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Forces screens render and named touch cues remain reachable with larger text',
    (t) async {
      size(t, const Size(1280, 950));
      for (var index = 0; index < lesson.steps.length; index++) {
        final key = GlobalKey(), store = startAt(index);
        await helpers.mount(
          t,
          RepaintBoundary(
            key: key,
            child: LessonPlayer(lesson: lesson),
          ),
          store,
        );
        await t.pump(const Duration(milliseconds: 300));
        await capture(t, key, 'step-${index + 1}');
        expect(t.takeException(), isNull, reason: lesson.steps[index].id);
        await t.pumpWidget(const SizedBox());
      }
      t.view.physicalSize = const Size(800, 360);
      for (final index in [0, 2, 3, 6, 9, 10, 12]) {
        await helpers.mount(
          t,
          LessonPlayer(lesson: lesson),
          startAt(index),
          scale: 1.5,
        );
        for (final item in lesson.steps[index].options) {
          await choose(t, item.id);
        }
        expect(t.takeException(), isNull, reason: lesson.steps[index].id);
        await t.pumpWidget(const SizedBox());
      }
    },
  );
}
