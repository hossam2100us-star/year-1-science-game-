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

  for (final scenario in ['foil', 'umbrella', 'all-match']) {
    testWidgets(
      'Water observations: $scenario retains predictions and gates continuation',
      (t) async {
        t.view.physicalSize = const Size(1280, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final index = scenario == 'umbrella' ? 11 : 5;
        final step = lesson.steps[index];
        final store = startAt(index);
        final wrongId = scenario == 'foil'
            ? 'foil'
            : scenario == 'umbrella'
            ? 'paper'
            : null;
        final boundaryKey = GlobalKey();
        await helpers.mount(
          t,
          RepaintBoundary(
            key: boundaryKey,
            child: LessonPlayer(lesson: lesson),
          ),
          store,
        );
        Future<void> tap(String key) =>
            helpers.tapVisible(t, find.byKey(ValueKey(key)));
        for (final option in step.options) {
          await tap('lab-choose-${option.id}');
          final actual = step.json['results'][option.id];
          final guess = option.id == wrongId
              ? (actual == 'dry' ? 'wet' : 'dry')
              : actual;
          await tap('lab-guess-$guess');
          await tap('lab-test');
        }
        expect(current(store)['lab']['tested'].length, step.options.length);
        if (wrongId != null) {
          final actual = step.json['results'][wrongId];
          final originalGuess = current(store)['lab']['guesses'][wrongId];
          expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
          expect(current(store)['freeDone'], false);
          // Switching materials must not hide or bypass the pending observation.
          await tap('lab-choose-${step.options.first.id}');
          expect(find.byKey(ValueKey('lab-review-$wrongId')), findsOneWidget);
          await tap('lab-review-$wrongId');
          await tap('lab-observe-$originalGuess');
          expect(
            find.text(step.json['observationUi']['retry']),
            findsOneWidget,
          );
          expect(current(store)['lab']['observed'], isNull);
          expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
          if (scenario == 'foil') {
            await t.runAsync(() async {
              final boundary =
                  boundaryKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await saveReviewImage('foil-observation.png', bytes);
              image.dispose();
            });
          }
          await t.pumpWidget(const SizedBox());
          await helpers.mount(t, LessonPlayer(lesson: lesson), store);
          await tap('lessonPrevious');
          await tap('lessonNext');
          expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
          expect(current(store)['lab']['guesses'][wrongId], originalGuess);
          await tap('lab-review-$wrongId');
          await tap('lab-observe-$actual');
          expect(current(store)['lab']['observed'], {wrongId: actual});
          expect(current(store)['lab']['guesses'][wrongId], originalGuess);
        } else {
          expect(find.byKey(const ValueKey('lab-observe-dry')), findsNothing);
        }
        if (scenario == 'umbrella') {
          expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
          await tap('lab-decision-paper');
          expect(current(store)['lab']['decision'], isNull);
          expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
          await tap('lab-decision-plastic');
          expect(current(store)['lab']['decision'], 'plastic');
          expect(current(store)['lab']['active'], 'plastic');
        }
        expect(current(store)['freeDone'], true);
        expect(current(store)['outcome'], isNull);
        expect(current(store)['mistakes'], 0);
        await t.pumpWidget(const SizedBox());
        await helpers.mount(t, LessonPlayer(lesson: lesson), store);
        await tap('lessonNext');
        expect(store.data.journeys[lesson.id]!['index'], index + 1);
        final response = store.data.journeys[lesson.id]!['responses'][step.id];
        expect(response['outcome'], isNull);
        expect(response['completed'], true);
        expect(store.data.attempts, isEmpty);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Mapping correction survives restart and navigation without changing the assessment',
    (t) async {
      t.view.physicalSize = const Size(1280, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final store = startAt(2), step = lesson.steps[2];
      final answers = Map<String, String>.from(step.answer!['value']);
      final wrongId = answers.keys.first;
      final wrongTarget = step.targets
          .firstWhere((o) => o.id != answers[wrongId])
          .id;
      final boundaryKey = GlobalKey();
      await helpers.mount(
        t,
        RepaintBoundary(
          key: boundaryKey,
          child: LessonPlayer(lesson: lesson),
        ),
        store,
      );
      expect(find.byKey(ValueKey('review-item-$wrongId')), findsNothing);
      for (final e in answers.entries) {
        await place(t, e.key, e.key == wrongId ? wrongTarget : e.value);
      }
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(find.byKey(ValueKey('review-item-$wrongId')), findsOneWidget);
      expect(current(store)['reviewItems'], [wrongId]);
      expect(current(store)['needsCorrection'], false);
      expect(current(store)['placements'][wrongId], wrongTarget);
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(current(store)['outcome'], 'explained');
      expect(current(store)['needsCorrection'], true);
      expect(
        current(store)['placements'][wrongId],
        wrongTarget,
      ); // Never auto-place the answer.
      expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      await helpers.tapVisible(t, find.text('Check my practice'));
      expect(
        current(store)['mistakes'],
        2,
      ); // Practice is not another graded attempt.
      expect(current(store)['needsCorrection'], true);
      await t.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await saveReviewImage('material-correction.png', bytes);
        image.dispose();
      });
      await t.pumpWidget(const SizedBox());
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      expect(find.text('Check my practice'), findsOneWidget);
      await helpers.tapVisible(t, find.byKey(const ValueKey('lessonPrevious')));
      await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
      expect(current(store)['needsCorrection'], true);
      await place(t, wrongId, answers[wrongId]!);
      await helpers.tapVisible(t, find.text('Check my practice'));
      expect(current(store)['needsCorrection'], false);
      expect(current(store)['outcome'], 'explained');
      await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
      expect(
        store.data.journeys[lesson.id]!['responses'][step.id]['outcome'],
        'explained',
      );
      expect(store.data.attempts, isEmpty);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Missing set choices are not revealed after the first try; practice retains explained score',
    (t) async {
      final store = startAt(3), step = lesson.steps[3];
      final answers = List<String>.from(step.answer!['value']);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      await choose(t, answers.first);
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(current(store)['reviewItems'], isEmpty);
      expect(current(store)['selected'], [answers.first]);
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(current(store)['needsCorrection'], true);
      for (final id in answers.skip(1)) {
        await choose(t, id);
      }
      await helpers.tapVisible(t, find.text('Check my practice'));
      expect(current(store)['outcome'], 'explained');
      expect(current(store)['needsCorrection'], false);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Single choice correction stays interactive and cannot improve the original score',
    (t) async {
      final store = startAt(9), step = lesson.steps[9];
      final answer = step.answer!['value'] as String;
      final wrong = step.options.firstWhere((o) => o.id != answer).id;
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      await choose(t, wrong);
      await choose(t, wrong);
      expect(current(store)['needsCorrection'], true);
      await choose(t, answer);
      expect(current(store)['needsCorrection'], false);
      expect(current(store)['outcome'], 'explained');
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Correcting after one hint retains the afterHint outcome without extra practice',
    (t) async {
      final store = startAt(9), step = lesson.steps[9];
      final answer = step.answer!['value'] as String;
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      await choose(t, step.options.firstWhere((o) => o.id != answer).id);
      await choose(t, answer);
      expect(current(store)['outcome'], 'afterHint');
      expect(current(store)['needsCorrection'], false);
    },
  );
}
