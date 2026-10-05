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
import 'package:science_adventure/features/science/science_picture.dart';
import 'package:science_adventure/features/science/sound_picture.dart';
import 'package:science_adventure/features/science/sound_distance.dart';
import 'package:science_adventure/features/science/sound_stage.dart';
import 'package:science_adventure/features/science/sound_box_lab.dart';
import 'package:science_adventure/games/question_engine.dart';

import 'setup_screen_test.dart' as helpers;
import 'support/review_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Lesson lesson;
  final audio = <Map<dynamic, dynamic>>[];
  const channel = MethodChannel('science_adventure/sounds');
  setUpAll(() async {
    lesson = (await LessonLibrary.load()).lessons['unit_06']!;
    helpers.testCatalog = await helpers.loadTestCatalog();
    for (final name in ['Nunito', 'Fredoka', 'Cairo']) {
      await (FontLoader(
        name,
      )..addFont(rootBundle.load('assets/fonts/$name.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final atlas in scienceAtlases.keys) {
      await Flame.images.load(atlas);
    }
    await Flame.images.load('sound-atlas-v2.webp');
    await Flame.images.load('sound-details-v2.webp');
  });
  setUp(() {
    audio.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'play') audio.add(Map.from(call.arguments));
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  MemoryProgressStore start(int index) {
    final session = LessonSession.fresh(lesson)..index = index;
    for (final step in lesson.steps.take(index)) {
      session.responses[step.id] = {'completed': true};
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
  void size(WidgetTester t, Size value) {
    t.view.physicalSize = value;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> tap(WidgetTester t, String key) =>
      helpers.tapVisible(t, find.byKey(ValueKey(key)));
  Future<void> choose(WidgetTester t, String id) => tap(t, 'science-item-$id');
  Future<void> place(WidgetTester t, String id, String target) async {
    await choose(t, id);
    await tap(t, 'science-target-$target');
  }

  Future<void> dragSound(
    WidgetTester t,
    String id,
    int slot, {
    bool ranked = false,
  }) async {
    final source = find.byKey(
      ValueKey('sound-order-${ranked ? 'ranked' : 'source'}-$id'),
    );
    final target = find.byKey(ValueKey('sound-order-slot-$slot'));
    await t.ensureVisible(source);
    await t.pump();
    final gesture = await t.startGesture(t.getCenter(source));
    await gesture.moveBy(const Offset(0, 25));
    await t.pump();
    await t.ensureVisible(target);
    await t.pump();
    await gesture.moveTo(t.getCenter(target));
    await t.pump();
    await gesture.up();
    await t.pump(const Duration(milliseconds: 300));
  }

  Future<void> move(WidgetTester t, double value) async {
    final slider = t.widget<Slider>(find.byKey(const ValueKey('lab-slider')));
    slider.onChanged!(value);
    slider.onChangeEnd!(value);
    await t.pump(const Duration(milliseconds: 300));
  }

  Future<void> capture(WidgetTester t, GlobalKey key, String name) =>
      t.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await saveReviewImage('sound-scenes/$name.png', bytes);
        image.dispose();
      });

  testWidgets(
    'Band exploration persists, replays sound and does not demonstrate an assessment answer',
    (t) async {
      size(t, const Size(1280, 950));
      final store = start(0);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      await choose(t, 'triangle');
      await choose(t, 'triangle');
      expect(audio.where((e) => e['name'] == 'triangle').length, 2);
      expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      await t.pumpWidget(const SizedBox());
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      for (final id in ['maracas', 'trumpet', 'sitar', 'drum']) {
        await choose(t, id);
      }
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      expect(current(store)['outcome'], isNull);
      await t.pumpWidget(const SizedBox());
      await helpers.mount(t, LessonPlayer(lesson: lesson), start(2));
      await choose(t, 'triangle');
      expect(
        t
            .widgetList<SoundDemonstration>(find.byType(SoundDemonstration))
            .any((demo) => demo.play),
        false,
      );
      expect(t.takeException(), isNull);
    },
  );

  for (final configuration in [
    (const Size(1280, 800), 1.0),
    (const Size(800, 360), 1.5),
  ]) {
    testWidgets(
      'Band action positions stay fixed during selection, answers and replay at ${configuration.$1} with ${configuration.$2} text',
      (t) async {
        size(t, configuration.$1);
        await helpers.mount(
          t,
          LessonPlayer(lesson: lesson),
          start(2),
          scale: configuration.$2,
        );
        Map<String, Rect> positions() {
          final origin = t.getTopLeft(find.byType(SoundStage));
          return {
            for (final target in lesson.steps[2].targets)
              target.id: t
                  .getRect(find.byKey(ValueKey('science-target-${target.id}')))
                  .shift(-origin),
          };
        }

        final initial = positions();
        await choose(t, 'sitar');
        expect(positions(), initial);
        await tap(t, 'science-target-pluck');
        expect(positions(), initial);
        await helpers.tapVisible(t, find.byTooltip('Listen again'));
        expect(positions(), initial);
        for (final entry in [
          ('triangle', 'hit'),
          ('drum', 'beat'),
          ('trumpet', 'blow'),
          ('maracas', 'shake'),
        ]) {
          await place(t, entry.$1, entry.$2);
          expect(positions(), initial);
        }
        await helpers.tapVisible(t, find.text('Check my discovery'));
        expect(positions(), initial);
        expect(t.takeException(), isNull);
      },
    );
  }

  test(
    'Band accepts Hit and Beat for percussion while rejecting other actions',
    () {
      final answer = lesson.steps[2].answer!;
      final canonical = Map<String, dynamic>.from(answer['value']);
      expect(canonical['triangle'], 'hit');
      expect(canonical['drum'], 'beat');
      for (final triangle in ['hit', 'beat']) {
        for (final drum in ['hit', 'beat']) {
          expect(
            matchesAnswer(answer, {
              ...canonical,
              'triangle': triangle,
              'drum': drum,
            }),
            true,
          );
        }
      }
      for (final wrong in [
        ('triangle', 'shake'),
        ('drum', 'blow'),
        ('trumpet', 'hit'),
        ('sitar', 'beat'),
        ('maracas', 'pluck'),
      ]) {
        expect(
          matchesAnswer(answer, {...canonical, wrong.$1: wrong.$2}),
          false,
        );
      }
    },
  );

  testWidgets(
    'Accepted percussion wording scores once and survives navigation',
    (t) async {
      size(t, const Size(1280, 950));
      final store = start(2);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      for (final entry in [
        ('triangle', 'beat'),
        ('drum', 'hit'),
        ('trumpet', 'blow'),
        ('sitar', 'pluck'),
        ('maracas', 'shake'),
      ]) {
        await place(t, entry.$1, entry.$2);
      }
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(current(store)['outcome'], 'firstTry');
      expect(current(store)['mistakes'], 0);
      expect(current(store)['placements'], {
        'triangle': 'beat',
        'drum': 'hit',
        'trumpet': 'blow',
        'sitar': 'pluck',
        'maracas': 'shake',
      });
      final completed = Map.from(current(store));
      await tap(t, 'lessonPrevious');
      await tap(t, 'lessonNext');
      expect(current(store), completed);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Band correction names only wrong actions and keeps accepted wording',
    (t) async {
      size(t, const Size(1280, 950));
      final store = start(2);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      for (final entry in [
        ('triangle', 'beat'),
        ('drum', 'hit'),
        ('trumpet', 'pluck'),
        ('sitar', 'pluck'),
        ('maracas', 'shake'),
      ]) {
        await place(t, entry.$1, entry.$2);
      }
      await helpers.tapVisible(t, find.text('Check my discovery'));
      final feedback = t
          .widget<Text>(find.byKey(const ValueKey('lesson-feedback')))
          .data!;
      expect(feedback.split('Look again:').last.trim(), 'Trumpet.');
      expect(current(store)['reviewItems'], ['trumpet']);
      expect(current(store)['mistakes'], 1);
      await tap(t, 'lessonPrevious');
      await tap(t, 'lessonNext');
      expect(current(store)['placements']['triangle'], 'beat');
      expect(current(store)['placements']['drum'], 'hit');
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(current(store)['outcome'], 'explained');
      expect(current(store)['needsCorrection'], true);
      expect(current(store)['reviewItems'], ['trumpet']);
      await place(t, 'trumpet', 'blow');
      await helpers.tapVisible(t, find.text('Check my practice'));
      expect(current(store)['needsCorrection'], false);
      expect(current(store)['reviewItems'], isEmpty);
      expect(current(store)['outcome'], 'explained');
      expect(current(store)['mistakes'], 2);
      expect(current(store)['placements']['triangle'], 'beat');
      expect(current(store)['placements']['drum'], 'hit');
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'A mismatched box prediction needs observation, survives restart and can replay',
    (t) async {
      size(t, const Size(1280, 1000));
      final store = start(3);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      expect(
        t
            .widget<FilledButton>(find.byKey(const ValueKey('lab-test')))
            .onPressed,
        isNull,
      );
      await tap(t, 'lab-choose-stone_box');
      await tap(t, 'lab-guess-quiet');
      await tap(t, 'lab-test');
      await tap(t, 'lab-replay');
      expect(audio.where((e) => e['name'] == 'stone').length, 2);
      await tap(t, 'lab-choose-feather_box');
      await tap(t, 'lab-guess-quiet');
      await tap(t, 'lab-test');
      expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      await t.pumpWidget(const SizedBox());
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      await tap(t, 'lab-review-stone_box');
      await tap(t, 'lab-observe-quiet');
      expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      await tap(t, 'lab-observe-loud');
      expect(current(store)['lab']['guesses']['stone_box'], 'quiet');
      expect(current(store)['lab']['observed']['stone_box'], 'loud');
      expect(current(store)['outcome'], isNull);
      expect(current(store)['mistakes'], 0);
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  for (final configuration in [
    (const Size(1280, 800), 1.0),
    (const Size(800, 360), 1.5),
  ]) {
    testWidgets(
      'Wrong box observations give visible feedback at ${configuration.$1}',
      (t) async {
        size(t, configuration.$1);
        final store = start(3);
        final boundary = GlobalKey();
        await helpers.mount(
          t,
          RepaintBoundary(
            key: boundary,
            child: LessonPlayer(lesson: lesson),
          ),
          store,
          scale: configuration.$2,
        );
        final step = lesson.steps[3];
        final observation = step.json['observationUi'];
        String footer() =>
            t.widget<Text>(find.byKey(const ValueKey('lesson-feedback'))).data!;
        for (final box in [
          ('stone_box', 'quiet', 'loud'),
          ('feather_box', 'loud', 'quiet'),
        ]) {
          await tap(t, 'lab-choose-${box.$1}');
          expect(footer(), step.json['labUi']['prediction']);
          await tap(t, 'lab-guess-${box.$2}');
          expect(footer(), contains(step.json['labUi']['afterPrediction']));
          expect(footer(), isNot(contains(observation['retry'])));
          await tap(t, 'lab-test');
          expect(footer(), contains(observation['changed']));
          expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
          await tap(t, 'lab-observe-${box.$2}');
          expect(footer(), observation['retry']);
          final feedbackRect = t.getRect(
            find.byKey(const ValueKey('lesson-feedback')),
          );
          expect(feedbackRect.top, greaterThanOrEqualTo(0));
          expect(
            feedbackRect.bottom,
            lessThanOrEqualTo(configuration.$1.height),
          );
          expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
          if (box.$1 == 'stone_box') {
            await capture(
              t,
              boundary,
              'box-retry-${configuration.$1.width.toInt()}',
            );
          }
          await tap(t, 'lab-observe-${box.$3}');
          expect(footer(), contains(observation['complete']));
          expect(current(store)['lab']['guesses'][box.$1], box.$2);
          expect(current(store)['lab']['observed'][box.$1], box.$3);
          expect(current(store)['mistakes'], 0);
          expect(current(store)['outcome'], isNull);
        }
        expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Every wrong observation speaks again without cutting off the experiment',
    (t) async {
      size(t, const Size(1280, 800));
      final spoken = <String>[];
      final messages = <String>[];
      final sounds = <String>[];
      Map<String, dynamic> data = {};
      var complete = false;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, update) => SoundBoxLab(
                  step: lesson.steps[3],
                  data: data,
                  onSpeak: spoken.add,
                  onFeedback: messages.add,
                  onSound: (name, volume) => sounds.add(name),
                  onChange: (next, done) async {
                    update(() {
                      data = next;
                      complete = done;
                    });
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tap(t, 'lab-guess-quiet');
      final beforeSound = spoken.length;
      await tap(t, 'lab-test');
      expect(sounds, ['stone']);
      expect(
        spoken.length,
        beforeSound,
        reason: 'Narration must not stop the stone rattle',
      );
      final retry = lesson.steps[3].json['observationUi']['retry'];
      await tap(t, 'lab-observe-quiet');
      await tap(t, 'lab-observe-quiet');
      expect(spoken.where((text) => text == retry).length, 2);
      expect(messages.where((text) => text == retry).length, 2);
      expect(complete, false);
      expect(data['guesses']['stone_box'], 'quiet');
      expect(data['observed'], isNull);
      await tap(t, 'lab-replay');
      expect(sounds, ['stone', 'stone']);
      await tap(t, 'lab-observe-loud');
      expect(data['observed']['stone_box'], 'loud');
      expect(
        spoken.last,
        contains(lesson.steps[3].json['observationUi']['complete']),
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Moving alone cannot complete distance; prediction and both listening trials are retained',
    (t) async {
      size(t, const Size(1280, 1000));
      final store = start(5);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      expect(
        t
            .widget<FilledButton>(
              find.byKey(const ValueKey('lab-distance-listen')),
            )
            .onPressed,
        isNull,
      );
      await move(t, .1);
      await move(t, .9);
      expect(current(store)['freeDone'], false);
      await tap(t, 'lab-distance-guess-louder');
      expect(current(store)['lab']['heard'], isNull);
      await tap(t, 'lab-distance-listen');
      expect(current(store)['lab']['heard'], ['far']);
      expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      await t.pumpWidget(const SizedBox());
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      final person = find.byKey(const ValueKey('sound-listener'));
      await t.ensureVisible(person);
      await t.drag(person, const Offset(-700, 0));
      await t.pump(const Duration(milliseconds: 500));
      await tap(t, 'lab-distance-drum');
      final drum = audio.where((e) => e['name'] == 'drum').toList();
      expect(drum.length, 2);
      expect(drum.first['volume'], lessThan(drum.last['volume']));
      expect(current(store)['lab']['soundGuess'], 'louder');
      expect(current(store)['lab']['heard'], containsAll(['near', 'far']));
      expect(current(store)['outcome'], isNull);
      expect(current(store)['mistakes'], 0);
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Distance question replays near and far without choosing or grading an answer',
    (t) async {
      size(t, const Size(1280, 1000));
      final store = start(6);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      final beforeListening = Map.from(current(store));
      await tap(t, 'sound-distance-listen');
      final listener = find.byKey(const ValueKey('sound-listener'));
      await t.ensureVisible(listener);
      await t.drag(listener, const Offset(-800, 0));
      await t.pump(const Duration(milliseconds: 500));
      await tap(t, 'lab-distance-drum');
      final drum = audio.where((e) => e['name'] == 'drum').toList();
      expect(drum.length, 2);
      expect(drum.first['volume'], lessThan(drum.last['volume']));
      expect(current(store)['selected'] ?? [], isEmpty);
      expect(current(store)['outcome'], isNull);
      expect(current(store), beforeListening);
      expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      await choose(t, 'quieter_and_fainter');
      expect(current(store)['outcome'], 'firstTry');
      await tap(t, 'sound-distance-listen');
      expect(audio.where((e) => e['name'] == 'drum').length, 3);
      expect(current(store)['outcome'], 'firstTry');
      expect(current(store)['mistakes'], 0);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Graded band listening replays one instrument without selecting or grading',
    (t) async {
      size(t, const Size(360, 760));
      final store = start(2);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store, scale: 1.5);
      final before = Map.from(current(store));
      for (final id in ['triangle', 'maracas', 'triangle']) {
        await tap(t, 'sound-listen-$id');
        expect(current(store), before);
        final playing = t
            .widgetList<SoundDemonstration>(find.byType(SoundDemonstration))
            .where((demo) => demo.play);
        expect(playing.map((demo) => demo.art), [id]);
        final listen = t.getRect(find.byKey(ValueKey('sound-listen-$id')));
        expect(listen.height, greaterThanOrEqualTo(48));
        expect(listen.left, greaterThanOrEqualTo(0));
        expect(listen.right, lessThanOrEqualTo(360));
      }
      expect(audio.map((sound) => sound['name']), [
        'triangle',
        'maracas',
        'triangle',
      ]);
      expect(current(store)['selected'] ?? [], isEmpty);
      expect(current(store)['outcome'], isNull);
      expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      await choose(t, 'triangle');
      expect(current(store)['selected'], ['triangle']);
      expect(current(store)['outcome'], isNull);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Listener stays inside the scene at both ends on phone and tablet',
    (t) async {
      size(t, const Size(360, 760));
      for (final width in [360.0, 1280.0]) {
        t.view.physicalSize = Size(width, 950);
        await helpers.mount(
          t,
          LessonPlayer(lesson: lesson),
          start(6),
          scale: 1.3,
        );
        final positions = <double>[];
        for (final position in [0.0, 1.0]) {
          final slider = t.widget<Slider>(
            find.byKey(const ValueKey('sound-distance-slider')),
          );
          slider.onChanged!(position);
          await t.pump(const Duration(milliseconds: 500));
          final scene = t.getRect(find.byType(SoundDistance));
          final child = t.getRect(find.byKey(const ValueKey('sound-listener')));
          positions.add(child.center.dx);
          final drum = t.getRect(
            find.byKey(const ValueKey('lab-distance-drum')),
          );
          expect(child.overlaps(drum), false);
          expect(child.width, greaterThanOrEqualTo(48));
          expect(child.height, greaterThanOrEqualTo(48));
          expect(child.left, greaterThanOrEqualTo(scene.left));
          expect(child.right, lessThanOrEqualTo(scene.right));
          await tap(t, 'sound-distance-listen');
          expect(t.takeException(), isNull);
        }
        expect(positions.last - positions.first, greaterThan(60));
        await t.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'Chart correction preserves original choices and scoring through navigation',
    (t) async {
      size(t, const Size(1280, 1000));
      final store = start(7);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      await place(t, 'furthest_listener', 'zara');
      await place(t, 'david_took', '23_steps');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('science-item-furthest_listener')),
          matching: find.text('Zara'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('science-item-david_took')),
          matching: find.text('23 steps'),
        ),
        findsOneWidget,
      );
      await helpers.tapVisible(t, find.text('Check my discovery'));
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(current(store)['needsCorrection'], true);
      expect(current(store)['placements']['furthest_listener'], 'zara');
      expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      await tap(t, 'lessonPrevious');
      await tap(t, 'lessonNext');
      expect(current(store)['needsCorrection'], true);
      await place(t, 'furthest_listener', 'maris');
      await place(t, 'david_took', '8_steps');
      await helpers.tapVisible(t, find.text('Check my practice'));
      expect(current(store)['outcome'], 'explained');
      expect(current(store)['mistakes'], 2);
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Sticks compare one sound at two volumes without selecting an assessed answer',
    (t) async {
      size(t, const Size(1280, 950));
      final store = start(8);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      await tap(t, 'sound-try-gentle');
      await tap(t, 'sound-try-harder');
      final sticks = audio.where((e) => e['name'] == 'sticks').toList();
      expect(sticks.length, 2);
      expect(sticks.first['volume'], lessThan(sticks.last['volume']));
      expect(current(store)['selected'] ?? [], isEmpty);
      expect(current(store)['outcome'], isNull);
      await choose(t, 'tap_harder');
      expect(current(store)['outcome'], 'firstTry');
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Box comparison playback is separate from the assessed choice', (
    t,
  ) async {
    size(t, const Size(1280, 950));
    final store = start(4);
    await helpers.mount(t, LessonPlayer(lesson: lesson), store);
    final before = Map.from(current(store));
    await tap(t, 'sound-listen-stone_box');
    await tap(t, 'sound-listen-feather_box');
    expect(audio.map((e) => e['name']), ['stone', 'feather']);
    expect(current(store), before);
    expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
    await choose(t, 'stone_box');
    expect(current(store)['outcome'], 'firstTry');
    await tap(t, 'sound-listen-feather_box');
    expect(current(store)['outcome'], 'firstTry');
    expect(current(store)['mistakes'], 0);
  });

  testWidgets(
    'Sound images play first; sparse drags, swaps, replacements and resumed edits grade only on Check',
    (t) async {
      size(t, const Size(1280, 1100));
      final store = start(9);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      final untouched = Map.from(current(store));
      for (final p in lesson.steps[9].options) {
        await choose(t, p.id);
      }
      expect(audio.map((e) => e['name']), [
        'thunder',
        'door',
        'whisper',
        'cat_steps',
      ]);
      expect(current(store), untouched);
      await dragSound(t, 'thunder', 3);
      expect(current(store)['placements'], {'3': 'thunder'});
      expect(current(store)['selected'], ['thunder']);
      expect(current(store)['outcome'], isNull);
      expect(current(store)['mistakes'], 0);
      await t.pumpWidget(const SizedBox());
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      expect(current(store)['placements'], {'3': 'thunder'});
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('sound-order-slot-0')),
          matching: find.byType(SoundPicture),
        ),
        findsNothing,
      );
      await dragSound(t, 'door_slamming', 0);
      await dragSound(t, 'whisper', 1);
      await dragSound(t, 'cat_walking', 2);
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(current(store)['mistakes'], 1);
      await dragSound(t, 'cat_walking', 0, ranked: true);
      expect(current(store)['selected'], [
        'cat_walking',
        'whisper',
        'door_slamming',
        'thunder',
      ]);
      await tap(t, 'sound-order-remove-0');
      expect(current(store)['placements'], {
        '1': 'whisper',
        '2': 'door_slamming',
        '3': 'thunder',
      });
      expect(current(store)['selected'], [
        'whisper',
        'door_slamming',
        'thunder',
      ]);
      await dragSound(t, 'cat_walking', 2);
      expect(current(store)['placements'], {
        '1': 'whisper',
        '2': 'cat_walking',
        '3': 'thunder',
      });
      await dragSound(t, 'door_slamming', 0);
      await dragSound(t, 'cat_walking', 0, ranked: true);
      await tap(t, 'sound-order-right-0');
      await tap(t, 'sound-order-left-1');
      expect(current(store)['outcome'], isNull);
      expect(current(store)['mistakes'], 1);
      await tap(t, 'lessonPrevious');
      await tap(t, 'lessonNext');
      expect(current(store)['selected'], [
        'cat_walking',
        'whisper',
        'door_slamming',
        'thunder',
      ]);
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(current(store)['outcome'], 'afterHint');
      expect(current(store)['mistakes'], 1);
      final finished = Map.from(current(store));
      await choose(t, 'thunder');
      expect(audio.last['name'], 'thunder');
      await dragSound(t, 'thunder', 0);
      expect(current(store), finished);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Phone ordering has explicit placement controls as a drag alternative',
    (t) async {
      size(t, const Size(360, 760));
      final store = start(9);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store, scale: 1.3);
      for (final entry in [
        ('thunder', 3),
        ('cat_walking', 0),
        ('whisper', 1),
        ('door_slamming', 2),
      ]) {
        await choose(t, entry.$1);
        await tap(t, 'sound-order-place-${entry.$2}');
      }
      expect(current(store)['selected'], [
        'cat_walking',
        'whisper',
        'door_slamming',
        'thunder',
      ]);
      expect(current(store)['outcome'], isNull);
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(current(store)['outcome'], 'firstTry');
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Phone face targets stay separate and touchable', (t) async {
    size(t, const Size(360, 760));
    final key = GlobalKey();
    await helpers.mount(
      t,
      RepaintBoundary(
        key: key,
        child: LessonPlayer(lesson: lesson),
      ),
      start(1),
      scale: 1.5,
    );
    expect(
      t.getSize(find.byKey(const ValueKey('lesson-title'))).height,
      lessThan(90),
    );
    expect(
      t.getSize(find.byKey(const ValueKey('lesson-prompt'))).width,
      greaterThan(300),
    );
    final targets = [
      for (final id in ['eyes', 'nose', 'ears'])
        t.getRect(find.byKey(ValueKey('science-item-$id'))),
    ];
    for (var i = 0; i < targets.length; i++) {
      expect(targets[i].width, closeTo(48, .01));
      for (var j = i + 1; j < targets.length; j++) {
        expect(targets[i].overlaps(targets[j]), false);
      }
    }
    await t.ensureVisible(find.byKey(const ValueKey('science-item-ears')));
    await t.pump();
    await capture(t, key, 'phone-face');
    await choose(t, 'ears');
    expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'Final discoveries show one task, retain answers and allow completed review without rescoring',
    (t) async {
      size(t, const Size(1280, 1100));
      final store = start(11);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      final missionUi = lesson.steps[11].json['soundScene']['missions'];
      const choices = {
        'play_a_drum': ['blowing', 'beating', 'plucking'],
        'louder_shaken_box': ['feather', 'stone'],
        'instrument_you_blow': ['trumpet', 'sitar', 'triangle'],
        'walk_away_from_sound': ['louder', 'fainter'],
        'something_making_a_sound': ['source_of_sound', 'sink_of_sound'],
      };
      void expectChoices(String id) {
        final buttons = t.widgetList<FilledButton>(
          find.byWidgetPredicate(
            (widget) =>
                widget is FilledButton &&
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'science-target-',
                ),
          ),
        );
        expect(
          buttons.map((button) => (button.key! as ValueKey<String>).value),
          choices[id]!.map((choice) => 'science-target-$choice'),
        );
      }

      expect(find.text(missionUi['play_a_drum']), findsOneWidget);
      expect(find.text(missionUi['louder_shaken_box']), findsNothing);
      expectChoices('play_a_drum');
      await tap(t, 'science-target-beating');
      expect(current(store)['placements']['play_a_drum'], 'beating');
      for (final entry in [
        ('louder_shaken_box', 'stone'),
        ('instrument_you_blow', 'trumpet'),
        ('walk_away_from_sound', 'fainter'),
        ('something_making_a_sound', 'source_of_sound'),
      ]) {
        await tap(t, 'sound-next-mission');
        expectChoices(entry.$1);
        await tap(t, 'science-target-${entry.$2}');
      }
      expect(current(store)['placements'].length, 5);
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(current(store)['outcome'], 'firstTry');
      final finished = Map.from(current(store));
      await tap(t, 'science-item-play_a_drum');
      expectChoices('play_a_drum');
      expect(find.text(missionUi['play_a_drum']), findsOneWidget);
      expect(find.text('Your choice: Beating'), findsOneWidget);
      await tap(t, 'science-item-walk_away_from_sound');
      expectChoices('walk_away_from_sound');
      expect(find.text(missionUi['walk_away_from_sound']), findsOneWidget);
      expect(current(store), finished);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Every sound screen renders, and face markers do not overlap at enlarged text',
    (t) async {
      size(t, const Size(1280, 1000));
      for (var i = 0; i < lesson.steps.length; i++) {
        final key = GlobalKey();
        await helpers.mount(
          t,
          RepaintBoundary(
            key: key,
            child: LessonPlayer(lesson: lesson),
          ),
          start(i),
        );
        await t.pump(const Duration(milliseconds: 300));
        await capture(t, key, 'step-${i + 1}');
        expect(t.takeException(), isNull, reason: lesson.steps[i].id);
        await t.pumpWidget(const SizedBox());
      }
      t.view.physicalSize = const Size(800, 360);
      for (final i in [0, 1, 2, 4, 6, 7, 8, 9, 10, 11]) {
        await helpers.mount(
          t,
          LessonPlayer(lesson: lesson),
          start(i),
          scale: 1.5,
        );
        if (i == 1) {
          final eyes = t.getRect(
            find.byKey(const ValueKey('science-item-eyes')),
          );
          final nose = t.getRect(
            find.byKey(const ValueKey('science-item-nose')),
          );
          final ears = t.getRect(
            find.byKey(const ValueKey('science-item-ears')),
          );
          expect(eyes.overlaps(nose), false);
          expect(ears.overlaps(nose), false);
        }
        for (final item in lesson.steps[i].options) {
          await choose(t, item.id);
        }
        expect(t.takeException(), isNull, reason: lesson.steps[i].id);
        await t.pumpWidget(const SizedBox());
      }
    },
  );
}
