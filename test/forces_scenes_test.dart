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
import 'package:science_adventure/features/science/force_trolley_scene.dart';

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
    for (final file in forceArtAssets) {
      await Flame.images.load(file);
    }
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

  Map<dynamic, dynamic> current(MemoryProgressStore store) =>
      store.data.journeys[lesson.id]!['current'];
  Future<void> choose(WidgetTester t, String id) async {
    final item = find.byKey(ValueKey('science-item-$id'));
    const spots = {
      'push': 'gate',
      'pull': 'gate',
      'roll': 'lawn',
      'hop': 'lawn',
      'crawl': 'lawn',
      'swim': 'pond',
      'slither': 'pond',
      'fly': 'pond',
    };
    if (item.evaluate().isEmpty && spots.containsKey(id)) {
      final spot = find.byKey(ValueKey('force-garden-${spots[id]}'));
      if (spot.evaluate().isNotEmpty) {
        await helpers.tapVisible(t, spot);
      }
    }
    await helpers.tapVisible(t, item);
  }

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
    'Guided experiment reveals only the current action and preserves the guess',
    (t) async {
      size(t, const Size(1280, 800));
      final store = startAt(1), boundary = GlobalKey();
      await helpers.mount(
        t,
        RepaintBoundary(
          key: boundary,
          child: LessonPlayer(lesson: lesson),
        ),
        store,
      );
      expect(find.byKey(const ValueKey('lab-force-push')), findsOneWidget);
      expect(find.byKey(const ValueKey('lab-force-pull')), findsNothing);
      expect(
        find.byKey(const ValueKey('lab-force-guess-gentle')),
        findsNothing,
      );
      await tap(t, 'lab-force-listen');
      expect(current(store)['lab']?['visited'], isNull);
      expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      await capture(t, boundary, 'simple-lab-push');
      final track = find.byKey(const ValueKey('force-track-object'));
      await t.ensureVisible(track);
      await t.drag(track, const Offset(600, 0));
      await t.pump(const Duration(milliseconds: 300));
      expect(current(store)['lab']['visited'], contains('far'));
      expect(find.byKey(const ValueKey('lab-force-push')), findsNothing);
      await tap(t, 'lab-force-guide-next');
      expect(find.byKey(const ValueKey('lab-force-pull')), findsOneWidget);
      await capture(t, boundary, 'simple-lab-pull');
      await tap(t, 'lab-force-pull');
      expect(current(store)['lab']['visited'], contains('near'));
      expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      await tap(t, 'lab-force-guide-next');
      expect(find.byKey(const ValueKey('lab-force-test-gentle')), findsNothing);
      expect(find.byKey(const ValueKey('lab-force-test-strong')), findsNothing);
      await capture(t, boundary, 'simple-lab-guess');
      expect(
        find.text(lesson.steps[1].json['labUi']['guideInstructions']['guess']),
        findsOneWidget,
      );
      await tap(t, 'lab-force-guess-gentle');
      expect(current(store)['lab']['forceGuess'], 'gentle');
      expect(current(store)['lab']['pushTrials'], isNull);
      expect(find.byKey(const ValueKey('lab-force-test-strong')), findsNothing);
      await tap(t, 'lab-force-test-gentle');
      await t.pumpWidget(const SizedBox());
      await helpers.mount(
        t,
        RepaintBoundary(
          key: boundary,
          child: LessonPlayer(lesson: lesson),
        ),
        store,
      );
      expect(current(store)['lab']['forceGuess'], 'gentle');
      expect(current(store)['lab']['pushTrials'], ['gentle']);
      expect(current(store)['lab']['forceGuide'], 'gentle');
      expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      await capture(t, boundary, 'simple-lab-gentle');
      await tap(t, 'lab-force-guide-next');
      expect(current(store)['lab']['ballDistance'], 0);
      await tap(t, 'lab-force-test-strong');
      expect(current(store)['lab']['forceGuess'], 'gentle');
      expect(
        current(store)['lab']['pushTrials'],
        containsAll(['gentle', 'strong']),
      );
      expect(current(store)['outcome'], isNull);
      expect(current(store)['mistakes'], 0);
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      await capture(t, boundary, 'simple-lab-result');
      await tap(t, 'lab-force-guide-previous');
      await tap(t, 'lab-force-guide-previous');
      await tap(t, 'lab-force-guide-previous');
      expect(
        find.byKey(const ValueKey('lab-force-guess-gentle')),
        findsNothing,
      );
      expect(current(store)['lab']['forceGuess'], 'gentle');
      expect(current(store)['freeDone'], true);
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
    'Old comparison saves resume without losing guesses or bypassing moves',
    (t) async {
      size(t, const Size(1280, 800));
      for (final alreadyMoved in [true, false]) {
        final store = startAt(1);
        current(store)['lab'] = {
          'forcePart': 'compare',
          'forceGuess': 'strong',
          'visited': alreadyMoved ? ['near', 'far'] : ['far'],
          'position': .95,
          'pushTrials': ['gentle'],
          'ballDistance': .35,
          if (!alreadyMoved) 'forceGuide': 'done',
        };
        await helpers.mount(t, LessonPlayer(lesson: lesson), store);
        expect(current(store)['lab']['forceGuess'], 'strong');
        if (!alreadyMoved) {
          expect(
            find.byKey(const ValueKey('lab-force-test-strong')),
            findsNothing,
          );
          await tap(t, 'lab-force-pull');
          await tap(t, 'lab-force-guide-next');
          expect(
            find.byKey(const ValueKey('lab-force-guess-gentle')),
            findsNothing,
          );
          await tap(t, 'lab-force-guide-next');
          await tap(t, 'lab-force-guide-next');
        }
        expect(
          find.byKey(const ValueKey('lab-force-test-strong')),
          findsOneWidget,
        );
        await tap(t, 'lab-force-test-strong');
        expect(current(store)['lab']['forceGuess'], 'strong');
        expect(
          current(store)['lab']['pushTrials'],
          containsAll(['gentle', 'strong']),
        );
        expect(current(store)['mistakes'], 0);
        expect(current(store)['outcome'], isNull);
        expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
        await t.pumpWidget(const SizedBox());
      }
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Garden discovery and guided controls fit phone and compact enlarged text',
    (t) async {
      for (final viewport in [const Size(360, 740), const Size(800, 360)]) {
        size(t, viewport);
        for (final index in [0, 1]) {
          final store = startAt(index), boundary = GlobalKey();
          await helpers.mount(
            t,
            RepaintBoundary(
              key: boundary,
              child: LessonPlayer(lesson: lesson),
            ),
            store,
            scale: 1.5,
          );
          await capture(
            t,
            boundary,
            'simple-${index + 1}-${viewport.width.toInt()}-start',
          );
          if (viewport.height > 600) {
            final action = find.byKey(
              ValueKey(index == 0 ? 'science-item-push' : 'lab-force-push'),
            );
            expect(
              t.getRect(action).bottom,
              lessThanOrEqualTo(
                t.getRect(find.byType(SingleChildScrollView).first).bottom,
              ),
              reason: 'The first action must be visible without scrolling on a phone.',
            );
          }
          if (index == 0) {
            expect(
              find.byKey(const ValueKey('science-item-pull')),
              findsOneWidget,
            );
            await choose(t, 'push');
            await choose(t, 'pull');
            await choose(t, 'roll');
            expect(
              find.byKey(const ValueKey('science-item-hop')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('force-discovery-next')),
              findsNothing,
            );
            expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
          } else {
            for (final key in [
              'force-push',
              'force-guide-next',
              'force-pull',
              'force-guide-next',
            ]) {
              await tap(t, 'lab-$key');
            }
            await capture(
              t,
              boundary,
              'simple-guess-${viewport.width.toInt()}',
            );
            for (final key in [
              'force-guess-gentle',
              'force-test-gentle',
              'force-guide-next',
              'force-test-strong',
            ]) {
              final control = find.byKey(ValueKey('lab-$key'));
              await t.ensureVisible(control);
              expect(t.getRect(control).left, greaterThanOrEqualTo(0));
              expect(
                t.getRect(control).right,
                lessThanOrEqualTo(viewport.width),
              );
              expect(t.getRect(control).height, greaterThanOrEqualTo(48));
              await tap(t, 'lab-$key');
            }
            expect(current(store)['lab']['forceGuess'], 'gentle');
            expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
          }
          expect(t.takeException(), isNull, reason: '$viewport / $index');
          await t.pumpWidget(const SizedBox());
        }
      }
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
        await choose(t, id);
        for (final elapsed in [200, 700, 900]) {
          await t.pump(Duration(milliseconds: elapsed));
          final picture = find.descendant(
            of: find.byKey(ValueKey('science-item-$id')),
            matching: find.byType(ForcePicture),
          );
          final garden = t.getRect(
            find.byKey(const ValueKey('force-garden-scene-pond')),
          );
          final moving = t.getRect(picture);
          expect(moving.left, greaterThanOrEqualTo(garden.left));
          expect(moving.right, lessThanOrEqualTo(garden.right));
          expect(moving.top, greaterThanOrEqualTo(garden.top));
          expect(moving.bottom, lessThanOrEqualTo(garden.bottom));
        }
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
    'Garden spots can be explored freely and all eight touches survive restart',
    (t) async {
      size(t, const Size(1280, 800));
      final store = startAt(0), boundary = GlobalKey();
      await helpers.mount(
        t,
        RepaintBoundary(
          key: boundary,
          child: LessonPlayer(lesson: lesson),
        ),
        store,
      );
      expect(find.byKey(const ValueKey('science-item-push')), findsOneWidget);
      expect(find.byType(ForceTrolleyScene), findsOneWidget);
      expect(find.byKey(const ValueKey('science-item-pull')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('force-garden-scene-gate')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('force-discovery-next')), findsNothing);
      expect(
        find.byKey(const ValueKey('force-discovery-previous')),
        findsNothing,
      );
      await tap(t, 'force-discovery-listen');
      expect(current(store)['touched'], isEmpty);
      // Visiting garden locations and hearing instructions are not exploration
      // credit. Each original subject must be touched by the child.
      await tap(t, 'force-garden-pond');
      expect(
        find.byKey(const ValueKey('force-garden-scene-pond')),
        findsOneWidget,
      );
      expect(find.byType(MovementSprite), findsNWidgets(3));
      await tap(t, 'force-discovery-listen');
      await tap(t, 'force-garden-lawn');
      expect(
        find.byKey(const ValueKey('force-garden-scene-lawn')),
        findsOneWidget,
      );
      expect(current(store)['touched'], isEmpty);
      await tap(t, 'force-garden-gate');
      await capture(t, boundary, 'garden-discovery-start');
      await choose(t, 'push');
      expect(current(store)['touched'], ['push']);
      final pushDescription = lesson.steps[0].json['senseDescriptions']['push'];
      final pondStory =
          lesson.steps[0].json['forceScene']['gardenStories']['pond'];
      expect(current(store)['feedback'], pushDescription);
      await tap(t, 'force-garden-pond');
      expect(current(store)['feedback'], isEmpty);
      expect(find.text(pushDescription), findsNothing);
      expect(find.text(pondStory), findsOneWidget);
      expect(current(store)['touched'], ['push']);
      await tap(t, 'force-garden-gate');
      expect(current(store)['feedback'], isEmpty);
      expect(
        find.text(lesson.steps[0].json['forceScene']['gardenStories']['gate']),
        findsOneWidget,
      );
      await t.pumpWidget(const SizedBox());
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      // The shared trolley replays the first unseen action on a resumed gate.
      await helpers.tapVisible(t, find.byType(ForceTrolleyScene));
      expect(current(store)['touched'], containsAll(['push', 'pull']));
      await choose(t, 'fly');
      await choose(t, 'swim');
      final visited = List.of(current(store)['touched']);
      await tap(t, 'force-discovery-listen');
      expect(current(store)['touched'], visited);
      expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      await t.pumpWidget(const SizedBox());
      await helpers.mount(
        t,
        RepaintBoundary(
          key: boundary,
          child: LessonPlayer(lesson: lesson),
        ),
        store,
      );
      // Restoring opens the first location with an unseen subject, independent
      // of which location was visited last.
      expect(
        find.byKey(const ValueKey('force-garden-scene-lawn')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('science-item-roll')), findsOneWidget);
      expect(
        find.text(lesson.steps[0].json['senseDescriptions']['swim']),
        findsNothing,
      );
      expect(
        find.text(lesson.steps[0].json['forceScene']['gardenStories']['lawn']),
        findsOneWidget,
      );
      for (final id in ['crawl', 'roll', 'hop']) {
        expect(find.byKey(ValueKey('science-item-$id')), findsOneWidget);
        expect(find.byType(MovementSprite), findsNWidgets(3));
        await choose(t, id);
        expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      }
      await t.pumpWidget(const SizedBox());
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      expect(
        find.byKey(const ValueKey('force-garden-scene-pond')),
        findsOneWidget,
      );
      await choose(t, 'slither');
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      expect(
        current(store)['touched'],
        containsAll(lesson.steps[0].options.map((p) => p.id)),
      );
      expect(current(store)['mistakes'], 0);
      await tap(t, 'force-garden-lawn');
      await choose(t, 'hop');
      expect(current(store)['touched'].length, 8);
      await t.pumpWidget(const SizedBox());
      await helpers.mount(
        t,
        RepaintBoundary(
          key: boundary,
          child: LessonPlayer(lesson: lesson),
        ),
        store,
      );
      expect(
        find.byKey(const ValueKey('force-garden-scene-gate')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      await capture(t, boundary, 'garden-discovery-completed');
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Garden subjects have separate reachable touch targets on phone and tablet',
    (t) async {
      for (final viewport in [const Size(360, 740), const Size(1280, 800)]) {
        size(t, viewport);
        final store = startAt(0), boundary = GlobalKey();
        await helpers.mount(
          t,
          RepaintBoundary(
            key: boundary,
            child: LessonPlayer(lesson: lesson),
          ),
          store,
          scale: 1.5,
        );
        for (final spot in {
          'gate': ['push', 'pull'],
          'lawn': ['roll', 'hop', 'crawl'],
          'pond': ['swim', 'slither', 'fly'],
        }.entries) {
          await tap(t, 'force-garden-${spot.key}');
          final targets = [
            for (final id in spot.value)
              find.byKey(ValueKey('science-item-$id')),
          ];
          for (final target in targets) {
            await t.ensureVisible(target);
            final rect = t.getRect(target);
            expect(rect.width, greaterThanOrEqualTo(48));
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(viewport.width));
          }
          final rects = targets.map(t.getRect).toList();
          for (var i = 0; i < rects.length; i++) {
            for (var j = i + 1; j < rects.length; j++) {
              expect(
                rects[i].overlaps(rects[j]),
                false,
                reason:
                    '${spot.key} targets must not cover each other at $viewport.',
              );
            }
          }
          await capture(
            t,
            boundary,
            'garden-${spot.key}-${viewport.width.toInt()}',
          );
          expect(current(store)['touched'] ?? const [], isEmpty);
        }
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'Push keeps contact as child and trolley move; pull stays connected',
    (t) async {
      size(t, const Size(600, 360));
      for (final (width, motion) in [
        (240.0, 'push'),
        (240.0, 'pull'),
        (560.0, 'push'),
        (560.0, 'pull'),
      ]) {
        final boundary = GlobalKey();
        Widget scene() => MaterialApp(
          theme: ThemeData(fontFamily: 'Nunito'),
          home: RepaintBoundary(
            key: boundary,
            child: Scaffold(
              backgroundColor: const Color(0xFFE2EFEA),
              body: SizedBox(
                width: width,
                child: ForceTrolleyScene(
                  key: ValueKey(motion),
                  motion: motion,
                  active: true,
                  you: 'You',
                ),
              ),
            ),
          ),
        );
        await t.pumpWidget(scene());
        await t.pump();
        final cart = find.byWidgetPredicate(
          (w) => w is ForcePicture && w.art == 'trolley',
        );
        final child = find.byWidgetPredicate(
          (w) => w is ForcePicture && w.art.startsWith('explorer'),
        );
        final cartStart = t.getCenter(cart).dx,
            childStart = t.getCenter(child).dx;
        await t.pump(const Duration(milliseconds: 1100));
        final cartNow = t.getCenter(cart).dx;
        expect(
          cartNow,
          motion == 'push' ? greaterThan(cartStart) : lessThan(cartStart),
        );
        if (motion == 'push') {
          expect(
            t.getCenter(child).dx - childStart,
            closeTo(cartNow - cartStart, .01),
          );
        } else {
          expect(t.getCenter(child).dx, childStart);
        }
        expect(t.getRect(cart).right, lessThanOrEqualTo(width));
        expect(t.getRect(child).left, greaterThanOrEqualTo(0));
        await capture(t, boundary, '$motion-mid-motion-${width.toInt()}');
        await t.pump(const Duration(milliseconds: 1100));
        if (motion == 'push') {
          expect(
            t.getCenter(cart).dx - t.getCenter(child).dx,
            closeTo(cartStart - childStart, .01),
          );
        }
        expect(t.getRect(cart).right, lessThanOrEqualTo(width));
        await t.pumpWidget(const SizedBox());
      }
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
    'Direction challenge keeps the child neutral while the trolley moves',
    (t) async {
      size(t, const Size(1280, 800));
      final store = startAt(2);
      await helpers.mount(
        t,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: false),
            child: LessonPlayer(lesson: lesson),
          ),
        ),
        store,
      );
      for (final id in ['away_from_you', 'towards_you']) {
        await choose(t, id);
        await t.pump(const Duration(milliseconds: 600));
        final pictures = t.widgetList<ForcePicture>(
          find.descendant(
            of: find.byKey(ValueKey('science-item-$id')),
            matching: find.byType(ForcePicture),
          ),
        );
        expect(
          pictures.map((p) => p.art),
          containsAll(['explorer', 'trolley']),
        );
        expect(
          pictures.any(
            (p) => p.art == 'explorer_push' || p.art == 'explorer_pull',
          ),
          false,
        );
        expect(current(store)['outcome'], isNull);
        expect(current(store)['placements'], isEmpty);
      }
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Phone workshop and animal scene hitboxes never overlap', (
    t,
  ) async {
    size(t, const Size(360, 760));
    for (final index in [3, 6, 9, 10]) {
      await helpers.mount(
        t,
        LessonPlayer(lesson: lesson),
        startAt(index),
        scale: 1.5,
      );
      final rectangles = [
        for (final item in lesson.steps[index].options)
          t.getRect(find.byKey(ValueKey('science-item-${item.id}'))),
      ];
      for (var i = 0; i < rectangles.length; i++) {
        final rect = rectangles[i];
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(360));
        for (var j = i + 1; j < rectangles.length; j++) {
          expect(rect.overlaps(rectangles[j]), false);
        }
        await choose(t, lesson.steps[index].options[i].id);
      }
      expect(t.takeException(), isNull, reason: lesson.steps[index].id);
      await t.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
    'Movement trail keeps five original targets and one question with saved review',
    (t) async {
      size(t, const Size(1280, 1100));
      final store = startAt(12), step = lesson.steps[12];
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      final missions = step.json['forceScene']['missions'];
      final answers = step.answer!['value'] as Map;
      for (var index = 0; index < step.options.length; index++) {
        final question = step.options[index];
        expect(find.text(missions[question.id]), findsOneWidget);
        for (final other in step.options.where((p) => p.id != question.id)) {
          expect(find.text(missions[other.id]), findsNothing);
        }
        for (final target in step.targets) {
          expect(
            find.byKey(ValueKey('science-target-${target.id}')),
            findsOneWidget,
          );
        }
        await tap(t, 'science-target-${answers[question.id]}');
        expect(current(store)['placements'][question.id], answers[question.id]);
        if (index + 1 < step.options.length) await tap(t, 'force-next-mission');
      }
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(current(store)['outcome'], 'firstTry');
      final finished = Map.from(current(store));
      await choose(t, 'how_a_snake_moves');
      expect(find.text(missions['how_a_snake_moves']), findsOneWidget);
      expect(find.text('Your choice: Slithering'), findsOneWidget);
      expect(current(store), finished);
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
