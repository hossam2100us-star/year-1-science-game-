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
import 'package:science_adventure/features/science/sound_picture.dart';
import 'package:science_adventure/features/science/sound_distance.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Lesson lesson;
  final audio = <Map>[];
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
    await Flame.images.load('sound-atlas-v2.png');
    await Flame.images.load('sound-details-v2.png');
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

  Map current(MemoryProgressStore store) =>
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
        await Directory('tmp/sound-scenes').create(recursive: true);
        await File('tmp/sound-scenes/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
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
        for (final position in [0.0, 1.0]) {
          final slider = t.widget<Slider>(
            find.byKey(const ValueKey('sound-distance-slider')),
          );
          slider.onChanged!(position);
          await t.pump(const Duration(milliseconds: 500));
          final scene = t.getRect(find.byType(SoundDistance));
          final child = t.getRect(find.byKey(const ValueKey('sound-listener')));
          expect(child.left, greaterThanOrEqualTo(scene.left));
          expect(child.right, lessThanOrEqualTo(scene.right));
          await tap(t, 'sound-distance-listen');
          expect(t.takeException(), isNull);
        }
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
