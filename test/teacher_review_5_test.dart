import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/catalog.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/lesson/lesson_player.dart';
import 'package:science_adventure/features/lesson/session.dart';
import 'package:science_adventure/features/maths/maths_art.dart';
import 'package:science_adventure/features/maths/maths_visual.dart';

import 'setup_screen_test.dart' as helpers;
import 'support/review_images.dart';

/// Teacher review 5 (docs/TEACHER_REVIEW_2026_10_12.md), section 4: content
/// errors to fix before Maths is merged. Checked in the production player
/// on a 1280×800 tablet with its system bars.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonLibrary maths;
  late Catalog science;
  setUpAll(() async {
    maths = await LessonLibrary.loadMaths();
    science = await Catalog.load();
    for (final font in ['Nunito', 'Fredoka', 'Cairo']) {
      await (FontLoader(
        font,
      )..addFont(rootBundle.load('assets/fonts/$font.ttf'))).load();
    }
  });

  Iterable<LessonStep> assessed() => maths.lessons.values.expand(
    (lesson) => lesson.steps.where((step) => step.assessed),
  );

  Future<void> open(WidgetTester t, String stepId, GlobalKey key) async {
    t.view.physicalSize = const Size(1280, 800);
    t.view.devicePixelRatio = 1;
    t.view.padding = const FakeViewPadding(top: 24, bottom: 60);
    t.view.viewPadding = const FakeViewPadding(top: 24, bottom: 60);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPadding);
    addTearDown(t.view.resetViewPadding);
    await t.runAsync(() async {
      for (final asset in [
        mathsObjectAsset,
        mathsBackdropAsset,
        mathsBirdAsset,
        mathsThingAsset,
      ]) {
        await Flame.images.load(asset);
      }
    });
    final lesson = maths.lessons[stepId.split('.').first]!;
    final session = LessonSession.fresh(lesson)
      ..index = lesson.steps.indexWhere((step) => step.id == stepId);
    final store = MemoryProgressStore(
      const AppData(
        profile: ChildProfile(name: 'Nour'),
      ).withSubjectProgress('maths', journeys: {lesson.id: session.toJson()}),
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
          catalogProvider.overrideWithValue(science),
          lessonLibraryProvider.overrideWith((ref) async => maths),
          narrationProvider.overrideWith((ref) => helpers.SilentNarration()),
        ],
        child: MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: LessonPlayer(lesson: lesson),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
  }

  Future<ui.Image> capture(WidgetTester t, GlobalKey key, String name) async {
    late ui.Image image;
    await t.runAsync(() async {
      image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      await saveReviewImage(
        'review5/$name.png',
        await image.toByteData(format: ui.ImageByteFormat.png),
      );
    });
    return image;
  }

  /// How many pixels are close to [colour] (each channel within 24).
  Future<int> pixelsNear(WidgetTester t, ui.Image image, Color colour) async {
    final bytes = (await t.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    var n = 0;
    for (var i = 0; i < bytes.lengthInBytes; i += 4) {
      if ((bytes.getUint8(i) - (colour.r * 255).round()).abs() < 24 &&
          (bytes.getUint8(i + 1) - (colour.g * 255).round()).abs() < 24 &&
          (bytes.getUint8(i + 2) - (colour.b * 255).round()).abs() < 24) {
        n++;
      }
    }
    return n;
  }

  test('no explanation stops in the middle of a sentence', () {
    for (final step in assessed()) {
      final short = step.shortExplanation;
      expect(short, matches(RegExp(r'[.!?)]$')), reason: step.id);
      expect(step.explanation.startsWith(short), isTrue, reason: step.id);
    }
    final solid = maths.lessons['math_unit_08']!.steps.firstWhere(
      (step) => step.id == 'math_unit_08.step.014',
    );
    expect(solid.shortExplanation, isNot(endsWith('as well as')));
  });

  test('answers named by letters keep the order a, b, c', () {
    var lettered = 0;
    for (final step in assessed()) {
      final labels = [for (final option in step.options) option.label];
      if (labels.isEmpty ||
          !labels.every((l) => RegExp(r'^[A-Za-z]$').hasMatch(l))) {
        continue;
      }
      lettered++;
      expect(
        labels,
        [...labels]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
        reason: step.id,
      );
    }
    expect(lettered, greaterThanOrEqualTo(2), reason: 'units 12 and 13');
  });

  test('a hundred piastres is the 1 pound coin', () {
    expect(coinDenomination(25), (amount: '25', unit: 'piastres'));
    expect(coinDenomination(50), (amount: '50', unit: 'piastres'));
    expect(coinDenomination(100), (amount: '1', unit: 'pound'));
    expect(coinDenomination(200), (amount: '2', unit: 'pounds'));
  });

  testWidgets('4 blue dots and 3 orange dots are blue and orange', (t) async {
    final key = GlobalKey();
    await open(t, 'math_unit_02.step.005', key);
    final image = await capture(t, key, 'unit02-step005-dots');
    expect(
      await pixelsNear(t, image, const Color(0xFF2170B5)),
      greaterThan(800),
    );
    expect(
      await pixelsNear(t, image, const Color(0xFFE88A2E)),
      greaterThan(800),
    );
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('pigeons, sparrows and crows have their own pictures', (t) async {
    final key = GlobalKey();
    await open(t, 'math_charts.step.008', key);
    await capture(t, key, 'charts-step008-birds');
    for (final bird in ['pigeon', 'sparrow', 'crow']) {
      expect(
        find.byWidgetPredicate((w) => w is MathsArt && w.item == bird),
        findsWidgets,
        reason: bird,
      );
    }
    expect(
      find.byWidgetPredicate((w) => w is MathsArt && w.item == 'bird'),
      findsNothing,
    );
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the fruit pictogram counts people and shows its key', (t) async {
    final key = GlobalKey();
    final lesson = maths.lessons['math_unit_04']!;
    final pictogram = lesson.steps.firstWhere(
      (step) =>
          step.assessed && step.json['mathVisual']?['unit'] == 'one person',
    );
    await open(t, pictogram.id, key);
    await capture(t, key, 'unit04-pictogram');
    expect(find.byKey(const ValueKey('maths-pictogram-key')), findsOneWidget);
    // No coral counters that look like the apples in the first row.
    expect(
      find.byWidgetPredicate((w) => w is MathsArt && w.item == 'counter'),
      findsNothing,
    );
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the coin question shows 50 piastres, 1 pound, 25 piastres', (
    t,
  ) async {
    final key = GlobalKey();
    await open(t, 'math_unit_13.step.008', key);
    await capture(t, key, 'unit13-step008-coins');
    final step = maths.lessons['math_unit_13']!.steps.firstWhere(
      (step) => step.id == 'math_unit_13.step.008',
    );
    expect([for (final o in step.options) o.label], ['a', 'b', 'c']);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  // Section 3: one tap was graded at once, so an accidental tap became a
  // mistake in the parent report. Owner decision: both subjects.
  for (final (subject, lessonId, index, prefix) in [
    ('Maths', 'math_unit_01', 1, 'maths-option-'),
    ('Science', 'unit_04', 9, 'science-item-'),
  ]) {
    testWidgets('$subject: a tap chooses and only Check sends the answer', (
      t,
    ) async {
      final library = subject == 'Maths'
          ? maths
          : await t.runAsync(LessonLibrary.load);
      final lesson = library!.lessons[lessonId]!, step = lesson.steps[index];
      final right = step.answer!['value'] as String;
      final wrong = step.options.firstWhere((o) => o.id != right).id;
      final session = LessonSession.fresh(lesson)..index = index;
      final store = MemoryProgressStore(
        subject == 'Maths'
            ? const AppData(profile: ChildProfile(name: 'Nour'))
                  .withSubjectProgress(
                    'maths',
                    journeys: {lesson.id: session.toJson()},
                  )
            : AppData(
                profile: const ChildProfile(name: 'Nour'),
                journeys: {lesson.id: session.toJson()},
              ),
      );
      Map<String, dynamic> current() => Map<String, dynamic>.from(
        store.data
                .progressForSubject(lesson.subject)
                .journeys[lesson.id]!['current']
            as Map,
      );
      Future<void> mount() async {
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              storeProvider.overrideWithValue(store),
              catalogProvider.overrideWithValue(science),
              lessonLibraryProvider.overrideWith((ref) async => library),
              narrationProvider.overrideWith(
                (ref) => helpers.SilentNarration(),
              ),
            ],
            child: MaterialApp(home: LessonPlayer(lesson: lesson)),
          ),
        );
        await t.pump();
      }

      Future<void> tap(String key) =>
          helpers.tapVisible(t, find.byKey(ValueKey(key)));
      FilledButton check() =>
          t.widget<FilledButton>(find.byKey(const ValueKey('lessonCheck')));

      t.view.physicalSize = const Size(1280, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await mount();
      expect(check().onPressed, isNull, reason: 'nothing chosen yet');
      await tap('$prefix$wrong');
      expect(current()['mistakes'] ?? 0, 0, reason: 'a tap only chooses');
      expect(current()['outcome'], isNull);
      expect(current()['selected'], [wrong]);
      // A choice saved before Check comes back as a choice, not an answer.
      await t.pumpWidget(const SizedBox());
      await mount();
      expect(current()['selected'], [wrong]);
      expect(current()['mistakes'] ?? 0, 0);
      expect(check().onPressed, isNotNull);
      await tap('lessonCheck');
      expect(current()['mistakes'], 1);
      expect(check().onPressed, isNull, reason: 'the same answer again');
      await tap('lessonCheck');
      expect(current()['mistakes'], 1);
      await tap('$prefix$right');
      await tap('lessonCheck');
      expect(current()['outcome'], 'afterHint');
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }

  // Section 1: 28 questions talked about something not shown.
  const listed = {
    'math_quiz_01': [4, 5, 6],
    'math_quiz_02': [6],
    'math_quiz_03': [7],
    'math_unit_01': [12],
    'math_unit_02': [12],
    'math_unit_03': [13],
    'math_unit_04': [10, 11, 12, 14],
    'math_unit_06': [10],
    'math_unit_07': [5, 10, 13, 14],
    'math_unit_08': [7, 14],
    'math_unit_10': [7, 11, 12],
    'math_unit_15': [9, 10],
    'math_unit_16': [10, 13, 14],
    'math_unit_18': [10],
  };

  testWidgets('every question the teacher listed shows its picture', (t) async {
    var shown = 0;
    for (final MapEntry(key: lessonId, value: numbers) in listed.entries) {
      for (final n in numbers) {
        final id = '$lessonId.step.${n.toString().padLeft(3, '0')}';
        final key = GlobalKey();
        // A fresh player for each question (the same widget type would
        // otherwise keep the previous lesson).
        await t.pumpWidget(const SizedBox());
        await open(t, id, key);
        expect(
          find.byType(MathsVisual).evaluate().isNotEmpty ||
              find.byType(CarrollTable).evaluate().isNotEmpty,
          isTrue,
          reason: id,
        );
        await capture(t, key, 'pictures/$id');
        expect(t.takeException(), isNull, reason: id);
        shown++;
      }
    }
    expect(shown, 28);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('numbers are sorted into the Carroll diagram itself', (t) async {
    final key = GlobalKey();
    await open(t, 'math_unit_07.step.005', key);
    final step = maths.lessons['math_unit_07']!.steps.firstWhere(
      (s) => s.id == 'math_unit_07.step.005',
    );
    final card = step.options.firstWhere((o) => o.label == '12');
    final column = step.targets.firstWhere(
      (target) => target.label == 'not less than 10',
    );
    expect(find.byKey(ValueKey('maths-target-${column.id}')), findsNothing);
    await helpers.tapVisible(
      t,
      find.byKey(ValueKey('maths-option-${card.id}')),
    );
    await helpers.tapVisible(
      t,
      find.byKey(ValueKey('maths-carroll-${column.id}')),
    );
    expect(
      find.descendant(
        of: find.byKey(ValueKey('maths-carroll-${column.id}')),
        matching: find.text('12'),
      ),
      findsOneWidget,
    );
    await capture(t, key, 'unit07-carroll-sorted');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the robot draws each chosen route from the start', (t) async {
    final key = GlobalKey();
    await open(t, 'math_unit_15.step.009', key);
    final step = maths.lessons['math_unit_15']!.steps.firstWhere(
      (s) => s.id == 'math_unit_15.step.009',
    );
    List<Object?> shown() =>
        t
                .widgetList<MathsVisual>(find.byType(MathsVisual))
                .firstWhere((v) => v.data['type'] == 'robot')
                .data['show']
            as List<Object?>;
    expect(shown(), isEmpty);
    for (final option in step.options.take(2)) {
      await helpers.tapVisible(
        t,
        find.byKey(ValueKey('maths-option-${option.id}')),
      );
    }
    expect(shown(), [for (final o in step.options.take(2)) o.label]);
    await capture(t, key, 'unit15-robot-routes');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  // Section 2: questions did not use what the practice taught.
  Future<MemoryProgressStore> play(
    WidgetTester t,
    String stepId, {
    MemoryProgressStore? store,
  }) async {
    t.view.physicalSize = const Size(1280, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.runAsync(() async {
      for (final asset in [mathsObjectAsset, mathsBackdropAsset]) {
        await Flame.images.load(asset);
      }
    });
    final lesson = maths.lessons[stepId.split('.').first]!;
    final session = LessonSession.fresh(lesson)
      ..index = lesson.steps.indexWhere((step) => step.id == stepId);
    final saved =
        store ??
        MemoryProgressStore(
          const AppData(profile: ChildProfile(name: 'Nour'))
              .withSubjectProgress(
                'maths',
                journeys: {lesson.id: session.toJson()},
              ),
        );
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(saved),
          catalogProvider.overrideWithValue(science),
          lessonLibraryProvider.overrideWith((ref) async => maths),
          narrationProvider.overrideWith((ref) => helpers.SilentNarration()),
        ],
        child: MaterialApp(home: LessonPlayer(lesson: lesson)),
      ),
    );
    await t.pump();
    return saved;
  }

  Map<String, dynamic> currentOf(MemoryProgressStore store, String lessonId) =>
      Map<String, dynamic>.from(
        store.data.progressForSubject('maths').journeys[lessonId]!['current']
            as Map,
      );

  testWidgets('the apples of a counting question are counted by touch', (
    t,
  ) async {
    final store = await play(t, 'math_unit_01.step.002');
    for (var i = 0; i < 8; i++) {
      await t.tap(find.byKey(ValueKey('maths-tap-count-$i')));
      await t.pump(const Duration(milliseconds: 40));
    }
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('8 counted'), findsOneWidget);
    for (var i = 0; i < 8; i++) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('maths-tap-count-$i')),
          matching: find.text('${i + 1}'),
        ),
        findsOneWidget,
      );
    }
    var current = currentOf(store, 'math_unit_01');
    expect(current['lab']['counted'], List.generate(8, (i) => i));
    expect(current['mistakes'] ?? 0, 0, reason: 'counting is not answering');
    expect(current['outcome'], isNull);
    expect(current['selected'] ?? [], isEmpty);
    // The marks come back after a restart.
    await play(t, 'math_unit_01.step.002', store: store);
    expect(find.text('8 counted'), findsOneWidget);
    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('maths-tap-count-reset')),
    );
    expect(find.text('0 counted'), findsOneWidget);
    current = currentOf(store, 'math_unit_01');
    expect(current['lab']['counted'], isEmpty);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('number line questions are solved by jumping', (t) async {
    final store = await play(t, 'math_unit_02.step.003');
    expect(find.text('Start on 5'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('maths-jump-forward')),
      );
    }
    expect(find.text('3 jumps: on 8'), findsOneWidget);
    await helpers.tapVisible(t, find.byKey(const ValueKey('maths-jump-back')));
    expect(find.text('4 jumps: on 7'), findsOneWidget);
    var current = currentOf(store, 'math_unit_02');
    expect(current['lab']['hops'], [1, 1, 1, -1]);
    expect(current['outcome'], isNull, reason: 'jumping is not answering');
    await helpers.tapVisible(t, find.byKey(const ValueKey('maths-jump-reset')));
    expect(find.text('Start on 5'), findsOneWidget);
    final step = maths.lessons['math_unit_02']!.steps.firstWhere(
      (s) => s.id == 'math_unit_02.step.003',
    );
    final eight = step.options.firstWhere((o) => o.label == '8');
    await helpers.tapVisible(
      t,
      find.byKey(ValueKey('maths-option-${eight.id}')),
    );
    await helpers.tapVisible(t, find.byKey(const ValueKey('lessonCheck')));
    current = currentOf(store, 'math_unit_02');
    expect(current['outcome'], 'firstTry');
    // The explanation draws the three jumps from 5 to 8.
    expect(find.byKey(const ValueKey('maths-jumps-explained')), findsOneWidget);
    expect(find.byKey(const ValueKey('maths-jump-forward')), findsNothing);
    final line = t
        .widgetList<MathsVisual>(find.byType(MathsVisual))
        .firstWhere((v) => v.data['type'] == 'numberLine');
    expect(line.data['shown'], [1, 1, 1]);
    await t.pump(const Duration(seconds: 2));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the next counting question starts at zero', (t) async {
    // Found on the tablet: the counter kept the apples' count on the stars
    // of the next question.
    final store = await play(t, 'math_unit_01.step.002');
    for (var i = 0; i < 8; i++) {
      await t.tap(find.byKey(ValueKey('maths-tap-count-$i')));
      await t.pump(const Duration(milliseconds: 40));
    }
    final step = maths.lessons['math_unit_01']!.steps[1];
    final eight = step.options.firstWhere((o) => o.label == '8');
    await helpers.tapVisible(
      t,
      find.byKey(ValueKey('maths-option-${eight.id}')),
    );
    await helpers.tapVisible(t, find.byKey(const ValueKey('lessonCheck')));
    await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Count the stars. How many are there?'), findsWidgets);
    expect(find.text('0 counted'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('maths-tap-count-0')));
    await t.pump(const Duration(milliseconds: 300));
    expect(currentOf(store, 'math_unit_01')['lab']['counted'], [0]);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  // Section 1 again: a picture in every question.
  test('every Maths question has a picture', () {
    bool pictured(LessonStep step) =>
        step.json['mathVisual'] is Map ||
        (step.json['options'] as List).any((o) => (o as Map)['visual'] != null);
    final without = [
      for (final step in assessed())
        if (!pictured(step)) step.objective,
    ];
    expect(without, isEmpty);
    // 258 book questions, the 15 former "Try it at home" questions, the
    // 18 worksheet questions (owner request, 21 October) and 20 class-book
    // questions (23 October).
    expect(assessed().where(pictured), hasLength(311));
  });

  testWidgets('questions about real things show those things', (t) async {
    for (final (stepId, label, item) in [
      ('math_unit_10.step.014', 'a watermelon', 'watermelon'),
      ('math_unit_06.step.006', 'a blink', 'closed eye'),
      ('math_quiz_03.step.010', 'scales', 'scales'),
    ]) {
      final key = GlobalKey();
      await t.pumpWidget(const SizedBox());
      await open(t, stepId, key);
      final lesson = maths.lessons[stepId.split('.').first]!;
      final option = lesson.steps
          .firstWhere((s) => s.id == stepId)
          .options
          .firstWhere((o) => o.label == label);
      expect(
        find.descendant(
          of: find.byKey(ValueKey('maths-option-${option.id}')),
          matching: find.byWidgetPredicate(
            (w) => w is MathsArt && w.item == item,
          ),
        ),
        findsOneWidget,
        reason: stepId,
      );
      await capture(t, key, 'things/$stepId');
      expect(t.takeException(), isNull, reason: stepId);
    }
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('a double shows two equal rows in two colours', (t) async {
    final key = GlobalKey();
    await open(t, 'math_unit_14.step.010', key);
    final image = await capture(t, key, 'unit14-double-6');
    final red = await pixelsNear(t, image, const Color(0xFFD0504B));
    final blue = await pixelsNear(t, image, const Color(0xFF2170B5));
    expect(red, greaterThan(800));
    expect(blue / red, inInclusiveRange(.8, 1.25));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the days of the week go round in a circle', (t) async {
    final key = GlobalKey();
    await open(t, 'math_unit_10.step.013', key);
    expect(
      find.byWidgetPredicate(
        (w) => w is MathsVisual && w.data['type'] == 'cycle',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Names in order around a circle'),
      findsOneWidget,
    );
    await capture(t, key, 'unit10-week');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('a Carroll diagram in a question shows sorted numbers', (
    t,
  ) async {
    final key = GlobalKey();
    await open(t, 'math_unit_07.step.011', key);
    for (final card in ['3', '7', '12', '15']) {
      expect(
        find.descendant(
          of: find.byType(CarrollTable),
          matching: find.text(card),
        ),
        findsOneWidget,
      );
    }
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('cards to sort and times of day show pictures', (t) async {
    for (final (stepId, label) in [
      ('math_unit_03.step.007', 'tin'),
      ('math_unit_06.step.011', 'evening'),
      ('math_unit_11.step.010', '6 and 4'),
    ]) {
      final key = GlobalKey();
      await t.pumpWidget(const SizedBox());
      await open(t, stepId, key);
      final lesson = maths.lessons[stepId.split('.').first]!;
      final option = lesson.steps
          .firstWhere((s) => s.id == stepId)
          .options
          .firstWhere((o) => o.label == label);
      expect(
        find.descendant(
          of: find.byKey(ValueKey('maths-option-${option.id}')),
          matching: find.byType(MathsVisual),
        ),
        findsOneWidget,
        reason: stepId,
      );
      expect(t.takeException(), isNull, reason: stepId);
    }
    await t.pumpWidget(const SizedBox());
  });

  // Section 6: 22 questions had only two choices. Five gained a useful
  // third; the other 17 are true or false, or pairs with no third answer
  // (odd or even, up or down, the two hands of a clock, two pans).
  test('two choices only where no third answer makes sense', () {
    final pairs = [
      for (final step in assessed())
        if (const {'single', 'set'}.contains(step.answer?['type']) &&
            step.options.length == 2)
          step.objective,
    ];
    expect(pairs, hasLength(17));
    for (final id in [
      'math.q01.09',
      'math.u06.main.01',
      'math.u06.main.02',
      'math.u06.main.04',
      'math.u06.main.05',
    ]) {
      expect(pairs, isNot(contains(id)));
    }
  });

  // Section 6: a challenge repeated a unit question word for word. Now the
  // same words only come back with a different picture (another clock time,
  // another chart); otherwise the challenge asks in a new example.
  test('a challenge never repeats a unit question and its picture', () {
    final units = [
      for (final step in assessed())
        if (step.objective.startsWith('math.u')) step,
    ];
    for (final step in assessed()) {
      if (!step.objective.startsWith('math.q')) continue;
      for (final unit in units) {
        if (unit.prompt.toLowerCase() != step.prompt.toLowerCase()) continue;
        expect(
          jsonEncode(unit.json['mathVisual']),
          isNot(jsonEncode(step.json['mathVisual'])),
          reason: '${step.objective} repeats ${unit.objective}',
        );
      }
    }
  });

  // Section 1: questions that asked what a word means ("Fraction means...")
  // now ask about a picture; the book's answer stays in the step's source.
  test('definition questions ask about their picture', () {
    const ids = [
      'math.u02.choice.01',
      'math.u04.choice.03',
      'math.u05.choice.01',
      'math.u08.choice.04',
      'math.u09.choice.05',
      'math.u12.choice.01',
      'math.u12.choice.05',
      'math.u13.choice.01',
      'math.u16.choice.04',
      'math.u16.choice.05',
      'math.u17.choice.01',
    ];
    for (final id in ids) {
      final step = assessed().firstWhere((s) => s.objective == id);
      expect(step.prompt, isNot(matches(RegExp(r'means|must be|needs a'))));
      expect(step.prompt, endsWith('?'), reason: id);
      expect(step.json['source']['answerKeyText'], isNotEmpty, reason: id);
    }
    final words = [
      for (final step in assessed())
        if (RegExp(r'\.\.\.$|…$').hasMatch(step.prompt) &&
            RegExp(r' means\b').hasMatch(step.prompt))
          step.objective,
    ];
    expect(words, isEmpty);
  });

  // Section 6: every parent goal activity was one template ("Discuss this
  // question with an adult..."). Each goal now has a home activity of its own.
  test('each Maths goal has its own home activity', () async {
    final books = [
      for (final file in [
        for (var n = 1; n <= 18; n++)
          'math_unit_${n.toString().padLeft(2, '0')}',
        'math_quiz_01',
        'math_quiz_02',
        'math_quiz_03',
        'math_charts',
      ])
        jsonDecode(
          await rootBundle.loadString('assets/content/playable/$file.json'),
        ) as Map<String, dynamic>,
    ];
    final english = <String>{};
    final arabic = <String>{};
    for (final book in books) {
      for (final activity in book['goalActivities'] as List) {
        expect(activity['text'], isNot(startsWith('Discuss this question')));
        expect(
          activity['textAr'],
          isNot(contains('اتكلّم مع طفلك في السؤال ده')),
        );
        english.add(activity['text']);
        arabic.add(activity['textAr']);
      }
    }
    // One per goal: 273 book, 18 worksheet and 20 class-book questions.
    expect(english, hasLength(311));
    expect(arabic, hasLength(311));
  });

  // Section 5: one hint for a whole unit, "Maths discovery N" titles and
  // explanations that began "... is the answer."
  test('every Maths question has its own title, hint and reason', () {
    for (final lesson in maths.lessons.values) {
      final graded = [
        for (final step in lesson.steps)
          if (step.assessed) step,
      ];
      final titles = [for (final step in graded) step.title];
      expect(titles.toSet(), hasLength(titles.length), reason: lesson.id);
      for (final step in graded) {
        expect(step.title, isNot(startsWith('Maths discovery')));
        expect(step.explanation, isNot(contains(' is the answer.')));
        final sameHint = graded.where((other) => other.hint == step.hint);
        expect(sameHint.length, lessThanOrEqualTo(2), reason: step.id);
      }
    }
  });

  testWidgets('a wrong answer brings the hint written for that question', (
    t,
  ) async {
    final store = await play(t, 'math_unit_02.step.003');
    expect(find.textContaining('Counting on'), findsWidgets);
    final step = maths.lessons['math_unit_02']!.steps.firstWhere(
      (s) => s.id == 'math_unit_02.step.003',
    );
    final wrong = step.options.firstWhere((o) => o.label == '7');
    await helpers.tapVisible(
      t,
      find.byKey(ValueKey('maths-option-${wrong.id}')),
    );
    await helpers.tapVisible(t, find.byKey(const ValueKey('lessonCheck')));
    expect(currentOf(store, 'math_unit_02')['mistakes'], 1);
    expect(
      find.textContaining('Start on 5, then make three jumps forward.'),
      findsWidgets,
    );
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
