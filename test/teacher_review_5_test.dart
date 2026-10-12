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
}
