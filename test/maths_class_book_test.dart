import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/catalog.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/design.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/lesson/lesson_player.dart';
import 'package:science_adventure/features/lesson/session.dart';
import 'package:science_adventure/features/maths/maths_art.dart';

import 'setup_screen_test.dart' as helpers;
import 'support/review_images.dart';

/// Topics of the class book (Cambridge Primary Mathematics Learner's Book 1)
/// that the parent companion leaves out, added on 23 October 2026 at the
/// owner's request: pentagons and hexagons, position words, grid squares,
/// prisms, turning shapes, lists and tables, measuring tools.
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

  List<(Lesson, int)> bookQuestions() => [
    for (final lesson in maths.lessons.values)
      for (final (index, step) in lesson.steps.indexed)
        if (step.objective.contains('.book.')) (lesson, index),
  ];

  test('20 graded class-book questions close units 8, 15, 16 and 18', () {
    final byUnit = <String, int>{};
    for (final (lesson, index) in bookQuestions()) {
      final step = lesson.steps[index];
      byUnit[lesson.id] = (byUnit[lesson.id] ?? 0) + 1;
      expect(step.assessed, isTrue, reason: step.id);
      expect(step.section, 'Practice', reason: step.id);
      expect(step.objective, startsWith('math.u${lesson.id.substring(10)}.'));
      // Added after the unit's existing steps, so saved journeys and
      // finished units keep their places.
      expect(index, greaterThan(13), reason: step.id);
    }
    expect(byUnit, {
      'math_unit_08': 6,
      'math_unit_15': 6,
      'math_unit_16': 4,
      'math_unit_18': 4,
    });
  });

  testWidgets('each class-book question shows its picture and answers', (
    t,
  ) async {
    t.view.physicalSize = const Size(1280, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.runAsync(() async {
      for (final asset in [mathsObjectAsset, mathsBackdropAsset]) {
        await Flame.images.load(asset);
      }
    });
    for (final (lesson, index) in bookQuestions()) {
      final step = lesson.steps[index];
      final session = LessonSession.fresh(lesson)..index = index;
      final store = MemoryProgressStore(
        const AppData(
          profile: ChildProfile(name: 'Nour'),
        ).withSubjectProgress('maths', journeys: {lesson.id: session.toJson()}),
      );
      final key = GlobalKey();
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ProviderScope(
            overrides: [
              storeProvider.overrideWithValue(store),
              catalogProvider.overrideWithValue(science),
              lessonLibraryProvider.overrideWith((ref) async => maths),
              narrationProvider.overrideWith(
                (ref) => helpers.SilentNarration(),
              ),
            ],
            child: MaterialApp(
              theme: adventureTheme(store.data.profile),
              home: LessonPlayer(lesson: lesson),
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text(step.prompt), findsOneWidget, reason: step.id);
      final answers = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            [
              'maths-option-',
              'number-key-',
            ].any((widget.key! as ValueKey<String>).value.startsWith),
      );
      expect(answers, findsWidgets, reason: step.id);
      expect(t.takeException(), isNull, reason: step.id);
      if (writeReviewImages) {
        await t.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await saveReviewImage(
            'maths-class-book/${step.objective}.png',
            bytes,
          );
          image.dispose();
        });
      }
    }
    await t.pumpWidget(const SizedBox());
    await t.pump();
  });
}
