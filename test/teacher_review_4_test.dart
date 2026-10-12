import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/biology/illustrated_art.dart';
import 'package:science_adventure/features/lesson/lesson_player.dart';
import 'package:science_adventure/features/lesson/session.dart';
import 'package:science_adventure/features/science/force_picture.dart';
import 'package:science_adventure/features/science/science_picture.dart';
import 'package:science_adventure/parent/parent_area.dart';

import 'setup_screen_test.dart' as helpers;
import 'support/review_images.dart';

/// Teacher review 4 (docs/TEACHER_REVIEW_2026_10_09.md), checked at the
/// tablet size the teacher used: 1280×800 landscape.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonLibrary library;
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
    for (final atlas in forceArtAssets) {
      await Flame.images.load(atlas);
    }
  });

  /// A 1280×800 Android tablet: the status bar (24) and the navigation bar
  /// (60) leave the app about 716 of the 800 (seen on the emulator).
  void tablet(WidgetTester t) {
    t.view.physicalSize = const Size(1280, 800);
    t.view.devicePixelRatio = 1;
    t.view.padding = const FakeViewPadding(top: 24, bottom: 60);
    t.view.viewPadding = const FakeViewPadding(top: 24, bottom: 60);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPadding);
    addTearDown(t.view.resetViewPadding);
  }

  Future<MemoryProgressStore> open(WidgetTester t, String stepId) async {
    final lesson = library.lessons[stepId.split('.').first]!;
    final index = lesson.steps.indexWhere((s) => s.id == stepId);
    final store = MemoryProgressStore(
      AppData(
        profile: const ChildProfile(name: 'Nour'),
        journeys: {
          lesson.id: (LessonSession.fresh(lesson)..index = index).toJson(),
        },
      ),
    );
    await helpers.mount(t, LessonPlayer(lesson: lesson), store);
    return store;
  }

  /// Visible without scrolling: inside the screen and above the fixed strip.
  void expectVisible(WidgetTester t, Finder finder, String what) {
    final rect = t.getRect(finder);
    final strip = t.getRect(find.byKey(const ValueKey('lesson-controls')));
    expect(
      rect.bottom,
      lessThanOrEqualTo(strip.top + 0.5),
      reason: '$what at $rect, strip starts at ${strip.top}',
    );
    expect(rect.top, greaterThanOrEqualTo(24), reason: what);
  }

  String discoveries(WidgetTester t) => t
      .widgetList<Text>(find.byType(Text))
      .map((w) => w.data ?? '')
      .firstWhere((s) => s.startsWith('Discoveries'));

  for (final stepId in [
    'unit_07.step.001',
    'unit_08.step.001',
    'unit_09.step.001',
  ]) {
    testWidgets('$stepId: marker, name and Next fit at 1280×800', (t) async {
      tablet(t);
      await open(t, stepId);
      final lesson = library.lessons[stepId.split('.').first]!;
      final step = lesson.steps.firstWhere((s) => s.id == stepId);
      final first = step.options.first.id;
      expectVisible(t, find.byKey(ValueKey('science-item-$first')), 'marker');
      expectVisible(
        t,
        find.byKey(const ValueKey('science-world-next')),
        'Next',
      );
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets('a tap on the safety picture itself is a discovery', (t) async {
    tablet(t);
    await open(t, 'unit_07.step.001');
    expect(discoveries(t), 'Discoveries 0 / 3');
    // T4-1 and review 5: no hand at the socket, the child well away from it.
    expect(
      t.widget<IllustratedArt>(find.byType(IllustratedArt)).asset,
      'electric-safety-socket-v3.webp',
    );
    await t.tap(find.byType(IllustratedArt));
    await t.pump(const Duration(milliseconds: 300));
    expect(discoveries(t), 'Discoveries 1 / 3');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Water world names the place first and marks visits', (t) async {
    tablet(t);
    await open(t, 'unit_08.step.001');
    // A tap on the open sea, near the ocean's marker but not on it.
    final picture = t.getRect(find.byKey(const ValueKey('water-picture')));
    await t.tapAt(
      Offset(
        picture.left + picture.width * .80,
        picture.top + picture.height * .45,
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    expect(discoveries(t), 'Discoveries 1 / 5');
    final feedback = t.widget<Text>(
      find.byKey(const ValueKey('lesson-feedback')),
    );
    expect(feedback.data, startsWith('Ocean. '));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('science-item-ocean')),
        matching: find.byIcon(Icons.check_circle_outline),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('science-item-pond')),
        matching: find.byIcon(Icons.check_circle_outline),
      ),
      findsNothing,
    );
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the action strip has the same place on every activity', (
    t,
  ) async {
    tablet(t);
    for (final id in ['unit_07', 'unit_08', 'quiz_03']) {
      final lesson = library.lessons[id]!;
      Rect? first;
      for (final step in lesson.steps) {
        await open(t, step.id);
        final strip = t.getRect(find.byKey(const ValueKey('lesson-controls')));
        first ??= strip;
        expect(strip, first, reason: step.id);
        await t.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('Space: a very large Sun partly outside the model', (t) async {
    tablet(t);
    await open(t, 'unit_09.step.001');
    final model = t.getRect(
      find.byKey(const ValueKey('space-discovery-model')),
    );
    final sun = t.getRect(find.byKey(const ValueKey('space-body-sun')));
    final earth = t.getRect(find.byKey(const ValueKey('space-body-earth')));
    expect(sun.height, greaterThan(earth.height * 4));
    expect(sun.left, lessThan(model.left));
    expect(find.textContaining('not to scale'), findsNothing);
    // A tap on the visible part of the Sun discovers it.
    await t.tapAt(Offset(model.left + 40, model.center.dy - 60));
    await t.pump(const Duration(milliseconds: 300));
    expect(discoveries(t), 'Discoveries 1 / 3');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('science-item-sun')),
        matching: find.byIcon(Icons.check_circle_outline),
      ),
      findsOneWidget,
    );
    // The unit report matches this type to show the note.
    expect(
      library.lessons['unit_09']!.json['parentNote'],
      isA<Map<String, dynamic>>(),
    );
    final note = library.lessons['unit_09']!.json['parentNote'] as Map;
    expect(note['en'], contains('not to scale'));
    expect(note['ar'], isNotEmpty);
    await t.pumpWidget(const SizedBox());
  });

  test(
    'every parent activity has Arabic and no translation is stale',
    () async {
      final arabic = jsonDecode(
        await rootBundle.loadString('assets/content/parent_ar.json'),
      ) as Map<String, dynamic>;
      var goals = 0, homes = 0;
      final safety = <String>{};
      for (final lesson in library.lessons.values) {
        for (final a in [
          ...?(lesson.json['goalActivities'] as List?),
          ...lesson.homeActivities,
        ]) {
          final activity = a as Map;
          final what = '${lesson.id} ${activity['objective'] ?? 'home'}';
          expect(activity['textAr'], isA<String>(), reason: what);
          expect(
            (activity['textAr'] as String).trim(),
            isNotEmpty,
            reason: what,
          );
          expect(activity['safetyAr'], isA<String>(), reason: what);
          activity.containsKey('objective') ? goals++ : homes++;
          safety.add(activity['safety'] as String);
        }
      }
      expect((arabic['goal'] as Map).length, goals);
      expect((arabic['home'] as Map).length, homes);
      expect((arabic['safety'] as Map).keys.toSet(), safety);
    },
  );

  testWidgets('the Arabic parent area shows activities in Arabic', (t) async {
    tablet(t);
    await helpers.mount(
      t,
      const ParentArea(),
      MemoryProgressStore(
        AppData(
          profile: const ChildProfile(name: 'Nour'),
          settings: const AppSettings(arabic: true),
          // A goal that needed an explanation brings its home activity.
          attempts: [
            UnitAttempt(
              unitId: 'unit_02',
              completedAt: DateTime(2026, 10, 9, 10),
              objectives: const {'u02.main.01': DecisionOutcome.explained},
              completed: true,
              effortStars: 2,
              attemptId: 'unit_02-1',
            ),
          ],
        ),
      ),
    );
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await t.pump();
    final lesson = library.lessons['unit_02']!;
    final goal = (lesson.json['goalActivities'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((a) => a['objective'] == 'u02.main.01');
    for (final activity in [goal, lesson.homeActivities.first]) {
      final shown = find.text(activity['textAr'] as String);
      expect(shown, findsOneWidget);
      expect(t.widget<Text>(shown).textDirection, TextDirection.rtl);
      expect(find.text(activity['text'] as String), findsNothing);
    }
    await t.pumpWidget(const SizedBox());
  });

  test('quiz 3: approved third choices; answers and goals unchanged', () {
    final quiz = library.lessons['quiz_03']!;
    LessonStep step(String n) =>
        quiz.steps.firstWhere((s) => s.id == 'quiz_03.step.$n');
    expect(step('004').options.map((o) => o.id), [
      'ears',
      'source_of_sound',
      'sink_of_sound',
    ]);
    expect(step('004').answer!['value'], 'source_of_sound');
    expect(step('004').json['objective'], 'quiz03.04');
    expect(step('005').options.map((o) => o.id), [
      'louder',
      'fainter_and_quieter',
      'stays_the_same',
    ]);
    expect(step('005').answer!['value'], 'fainter_and_quieter');
    expect(step('005').json['objective'], 'quiz03.05');
    // Push/pull and the book's true-or-false question stay two-way.
    for (final n in ['001', '002', '009']) {
      expect(step(n).options, hasLength(2), reason: n);
    }
  });

  /// Opt-in screenshots for review: --dart-define=REVIEW_IMAGES=true.
  testWidgets('review images at 1280×800', (t) async {
    if (!writeReviewImages) return;
    tablet(t);
    Future<void> shot(String stepId, String name, [Offset? tap]) async {
      final lesson = library.lessons[stepId.split('.').first]!;
      final index = lesson.steps.indexWhere((s) => s.id == stepId);
      final key = GlobalKey();
      await helpers.mount(
        t,
        RepaintBoundary(
          key: key,
          child: LessonPlayer(lesson: lesson),
        ),
        MemoryProgressStore(
          AppData(
            profile: const ChildProfile(name: 'Nour'),
            journeys: {
              lesson.id: (LessonSession.fresh(lesson)..index = index).toJson(),
            },
          ),
        ),
      );
      if (tap != null) {
        await t.tapAt(tap);
        await t.pump(const Duration(milliseconds: 400));
      }
      await t.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await saveReviewImage('teacher-review-4/$name.png', bytes);
        image.dispose();
      });
      await t.pumpWidget(const SizedBox());
    }

    await shot('unit_07.step.001', 'electricity-safety');
    await shot(
      'unit_07.step.001',
      'electricity-safety-tapped',
      const Offset(400, 520),
    );
    await shot('unit_08.step.001', 'water-world-ocean', const Offset(860, 330));
    await shot('quiz_03.step.001', 'quiz-3-first');
    await shot('unit_09.step.001', 'space-model');
  });
}
