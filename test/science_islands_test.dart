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
import 'package:science_adventure/games/question_engine.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonLibrary library;
  const ids = [
    'unit_04',
    'unit_05',
    'unit_06',
    'unit_07',
    'unit_08',
    'unit_09',
    'quiz_02',
    'quiz_03',
    'quiz_04',
  ];
  setUpAll(() async {
    library = await LessonLibrary.load();
    helpers.testCatalog = await helpers.loadTestCatalog();
    for (final font in ['Nunito', 'Fredoka', 'Cairo']) {
      await (FontLoader(
        font,
      )..addFont(rootBundle.load('assets/fonts/$font.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final atlas in scienceAtlases.keys) {
      await Flame.images.load(atlas);
    }
    for (final atlas in ['five-senses-v2.webp', 'sense-objects-v2.webp']) {
      await Flame.images.load(atlas);
    }
    for (final atlas in ['sound-atlas-v2.png', 'sound-details-v2.png']) {
      await Flame.images.load(atlas);
    }
  });
  void size(WidgetTester t, Size s) {
    t.view.physicalSize = s;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  MemoryProgressStore storeFor(Lesson b, int i) => MemoryProgressStore(
    AppData(
      profile: const ChildProfile(name: 'Nour'),
      journeys: {b.id: (LessonSession.fresh(b)..index = i).toJson()},
    ),
  );
  test('All islands are available; quizzes retain ten source objectives', () {
    expect(library.lessons.length, 13);
    for (final id in ids) {
      final b = library.lessons[id]!;
      expect(b.steps.length, lessThanOrEqualTo(13));
      if (b.quiz) {
        expect(b.steps.length, 10);
        expect(b.objectives.length, 10);
      }
      final responses = <String, dynamic>{};
      for (final s in b.steps) {
        if (s.answer != null) {
          final engine = QuestionEngine(s);
          expect(engine.submit(s.answer!['value']), true, reason: s.id);
          responses[s.id] = {
            'completed': true,
            'outcome': engine.outcome!.name,
            if (s.json['objectiveItems'] is Map)
              'objectiveEvidence': {
                for (final goal in s.assessedObjectives)
                  goal: engine.outcome!.name,
              },
          };
        }
      }
      expect(objectiveResults(b, responses).keys.toSet(), b.objectives);
      for (final s in b.steps.where((s) => s.json['lab'] != null)) {
        expect(s.assessed, false);
        expect(s.answer, isNull);
      }
    }
  });
  testWidgets('All new screens fit small landscape with enlarged text', (
    t,
  ) async {
    size(t, const Size(800, 360));
    for (final id in ids) {
      final b = library.lessons[id]!;
      for (var i = 0; i < b.steps.length; i++) {
        await helpers.mount(
          t,
          LessonPlayer(lesson: b),
          storeFor(b, i),
          scale: 1.5,
        );
        expect(t.takeException(), isNull, reason: '$id / $i');
        await t.pumpWidget(const SizedBox());
      }
    }
  });
  testWidgets(
    'Every new assessed activity accepts touch and retains its score',
    (t) async {
      size(t, const Size(1280, 900));
      for (final id in ids) {
        final b = library.lessons[id]!;
        for (var i = 0; i < b.steps.length; i++) {
          final s = b.steps[i];
          if (!s.assessed) continue;
          final store = storeFor(b, i);
          await helpers.mount(t, LessonPlayer(lesson: b), store);
          final a = s.answer!['value'];
          if (s.isMapping) {
            for (final e in (a as Map).entries) {
              await helpers.tapVisible(
                t,
                find.byKey(ValueKey('science-item-${e.key}')),
              );
              await helpers.tapVisible(
                t,
                find.byKey(ValueKey('science-target-${e.value}')),
              );
            }
          } else {
            for (final v in a is List ? a : [a]) {
              await helpers.tapVisible(
                t,
                find.byKey(ValueKey('science-item-$v')),
              );
            }
          }
          if (s.isMapping || s.isMulti || s.isOrder)
            await helpers.tapVisible(t, find.text('Check my discovery'));
          expect(
            store.data.journeys[id]!['current']['outcome'],
            'firstTry',
            reason: s.id,
          );
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        }
      }
    },
  );
  for (final id in ['unit_04', 'unit_05', 'unit_06', 'unit_07']) {
    testWidgets(
      '$id predictions persist before revealing and are never graded',
      (t) async {
        size(t, const Size(1100, 850));
        final b = library.lessons[id]!;
        final i = b.steps.indexWhere((s) => s.json['results'] != null);
        final s = b.steps[i];
        final store = storeFor(b, i);
        await helpers.mount(t, LessonPlayer(lesson: b), store);
        final testButton = find.byKey(const ValueKey('lab-test'));
        expect(t.widget<FilledButton>(testButton).onPressed, isNull);
        final choices = (s.json['labUi']['choices'] as Map).keys.toList();
        await helpers.tapVisible(
          t,
          find.byKey(ValueKey('lab-guess-${choices.last}')),
        );
        expect(
          store.data.journeys[id]!['current']['lab']['guesses'],
          isNotEmpty,
        );
        expect(store.data.journeys[id]!['current']['lab']['tested'], isNull);
        await t.pumpWidget(const SizedBox());
        await helpers.mount(t, LessonPlayer(lesson: b), store);
        for (final p in s.options) {
          await helpers.tapVisible(
            t,
            find.byKey(ValueKey('lab-choose-${p.id}')),
          );
          await helpers.tapVisible(
            t,
            find.byKey(ValueKey('lab-guess-${choices.last}')),
          );
          await helpers.tapVisible(t, find.byKey(const ValueKey('lab-test')));
          if (s.json['observationUi'] != null &&
              choices.last != s.json['results'][p.id]) {
            await helpers.tapVisible(
              t,
              find.byKey(ValueKey('lab-observe-${s.json['results'][p.id]}')),
            );
          }
        }
        expect(store.data.journeys[id]!['current']['freeDone'], true);
        expect(store.data.journeys[id]!['current']['outcome'], isNull);
        await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
        expect(store.data.journeys[id]!['index'], i + 1);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('Free activities complete and restore without learning scores', (
    t,
  ) async {
    size(t, const Size(1280, 900));
    for (final id in ids.where((i) => i.startsWith('unit'))) {
      final b = library.lessons[id]!;
      for (var i = 0; i < b.steps.length; i++) {
        final s = b.steps[i];
        final mode = s.json['lab'];
        if (mode == null ||
            s.json['results'] != null ||
            ['force', 'distance', 'sailboat', 'stars'].contains(mode))
          continue;
        final store = storeFor(b, i);
        await helpers.mount(t, LessonPlayer(lesson: b), store);
        final keys = <String>[];
        if (mode == 'shape') {
          for (final trial in [
            ('dough', 'Twist'),
            ('rubber_band', 'Stretch'),
            ('sponge', 'Squash'),
            ('paper_straw', 'Bend'),
            ('stone', 'Squash'),
          ]) {
            keys.addAll([
              'lab-shape-${trial.$1}',
              'lab-action-${trial.$2}',
              'lab-shape-guess-change',
              'lab-shape-test',
            ]);
          }
        }
        if (mode == 'soil' || mode == 'cleanup')
          keys.addAll(s.options.map((p) => 'lab-find-${p.id}'));
        if (mode == 'rock-sort')
          keys.addAll(s.options.map((p) => 'lab-group-${p.id}-My first group'));
        if (mode == 'day-night') keys.addAll(List.filled(4, 'lab-turn'));
        if (mode == 'earth-paint') keys.addAll(['lab-water', 'lab-land']);
        for (final k in keys) {
          await helpers.tapVisible(t, find.byKey(ValueKey(k)));
        }
        expect(
          store.data.journeys[id]!['current']['freeDone'],
          true,
          reason: mode,
        );
        await t.pumpWidget(const SizedBox());
        await helpers.mount(t, LessonPlayer(lesson: b), store);
        expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
        expect(store.data.journeys[id]!['current']['outcome'], isNull);
        await t.pumpWidget(const SizedBox());
      }
    }
  });
  testWidgets(
    'Movement, sound distance, wind and star drawing save real interaction',
    (t) async {
      size(t, const Size(1280, 950));
      for (final id in ['unit_05', 'unit_06']) {
        final b = library.lessons[id]!;
        final mode = id == 'unit_05' ? 'force' : 'distance';
        final i = b.steps.indexWhere((s) => s.json['lab'] == mode);
        final store = storeFor(b, i);
        await helpers.mount(t, LessonPlayer(lesson: b), store);
        if (id == 'unit_05') {
          for (final key in [
            'force-pull',
            'force-push',
            'force-part-compare',
            'force-guess-gentle',
            'force-test-gentle',
            'force-test-strong',
          ]) {
            await helpers.tapVisible(t, find.byKey(ValueKey('lab-$key')));
          }
        } else {
          await helpers.tapVisible(
            t,
            find.byKey(const ValueKey('lab-distance-guess-fainter')),
          );
          var slider = t.widget<Slider>(
            find.byKey(const ValueKey('lab-slider')),
          );
          slider.onChanged!(.1);
          slider.onChangeEnd!(.1);
          await t.pump(const Duration(milliseconds: 300));
          await helpers.tapVisible(
            t,
            find.byKey(const ValueKey('lab-distance-listen')),
          );
          slider = t.widget<Slider>(find.byKey(const ValueKey('lab-slider')));
          slider.onChanged!(.9);
          slider.onChangeEnd!(.9);
          await t.pump(const Duration(milliseconds: 300));
          await helpers.tapVisible(
            t,
            find.byKey(const ValueKey('lab-distance-listen')),
          );
        }
        expect(store.data.journeys[id]!['current']['freeDone'], true);
        await t.pumpWidget(const SizedBox());
      }
      final forces = library.lessons['unit_05']!;
      final i = forces.steps.indexWhere((s) => s.json['lab'] == 'sailboat');
      final boat = storeFor(forces, i);
      await helpers.mount(t, LessonPlayer(lesson: forces), boat);
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('lab-boat-guess-still')),
      );
      for (var n = 0; n < 7; n++) {
        await helpers.tapVisible(t, find.byKey(const ValueKey('lab-blow')));
      }
      expect(boat.data.journeys[forces.id]!['current']['freeDone'], true);
      await t.pumpWidget(const SizedBox());
      final space = library.lessons['unit_09']!;
      final j = space.steps.indexWhere((s) => s.json['lab'] == 'stars');
      final stars = storeFor(space, j);
      await helpers.mount(t, LessonPlayer(lesson: space), stars);
      final canvas = find.byKey(const ValueKey('lab-stars'));
      await t.ensureVisible(canvas);
      await t.pump();
      final top = t.getTopLeft(canvas);
      final bounds = t.getSize(canvas);
      for (final p in [
        const Offset(.12, .25),
        const Offset(.3, .15),
        const Offset(.51, .32),
      ]) {
        await t.tapAt(top + Offset(bounds.width * p.dx, bounds.height * p.dy));
        await t.pump(const Duration(milliseconds: 300));
      }
      await t.enterText(find.byKey(const ValueKey('lab-star-name')), 'My kite');
      await t.pump();
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('lab-finish-stars')),
      );
      expect(
        stars.data.journeys[space.id]!['current']['lab']['name'],
        'My kite',
      );
      expect(stars.data.journeys[space.id]!['current']['freeDone'], true);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Render new islands for visual review', (t) async {
    size(t, const Size(1280, 950));
    for (final entry in {
      'unit_04': [0, 1, 2, 5, 11],
      'unit_05': [3, 4],
      'unit_06': [0, 7],
      'unit_07': [3, 8],
      'unit_08': [0, 3, 5],
      'unit_09': [1, 6, 8, 10],
    }.entries) {
      final b = library.lessons[entry.key]!;
      for (final i in entry.value) {
        final key = GlobalKey();
        await helpers.mount(
          t,
          RepaintBoundary(
            key: key,
            child: LessonPlayer(lesson: b),
          ),
          storeFor(b, i),
        );
        await t.pump(const Duration(milliseconds: 300));
        expect(t.takeException(), isNull);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await t.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('tmp').create(recursive: true);
          await File('tmp/${entry.key}-${i + 1}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await t.pumpWidget(const SizedBox());
      }
    }
  });
}
