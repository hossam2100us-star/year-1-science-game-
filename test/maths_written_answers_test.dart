import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
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
import 'package:science_adventure/features/lesson/step_rules.dart';
import 'package:science_adventure/games/question_engine.dart';

import 'setup_screen_test.dart' as helpers;

/// Owner request (21 October 2026): Maths questions the child answers in the
/// app instead of "Try it at home", and worksheet questions where the child
/// writes the number or the number sentence (number pad).
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

  LessonStep step(String id) => maths.lessons.values
      .expand((lesson) => lesson.steps)
      .firstWhere((s) => s.id == id);

  group('answers', () {
    test('a written number matches only its value', () {
      const answer = {'type': 'number', 'value': 7};
      expect(matchesAnswer(answer, '7'), isTrue);
      expect(matchesAnswer(answer, '8'), isFalse);
      expect(matchesAnswer(answer, ''), isFalse);
      expect(matchesAnswer(answer, null), isFalse);
    });

    test('an addition sentence may be written either way round', () {
      const answer = {
        'type': 'sentence',
        'value': {'a': '8', 'op': '+', 'b': '7', 'c': '15'},
      };
      expect(
        matchesAnswer(answer, {'a': '8', 'op': '+', 'b': '7', 'c': '15'}),
        isTrue,
      );
      expect(
        matchesAnswer(answer, {'a': '7', 'op': '+', 'b': '8', 'c': '15'}),
        isTrue,
      );
      expect(
        matchesAnswer(answer, {'a': '8', 'op': '-', 'b': '7', 'c': '15'}),
        isFalse,
      );
      expect(
        matchesAnswer(answer, {'a': '8', 'op': '+', 'b': '7', 'c': '16'}),
        isFalse,
      );
    });

    test('a subtraction sentence keeps its order', () {
      const answer = {
        'type': 'sentence',
        'value': {'a': '14', 'op': '-', 'b': '6', 'c': '8'},
      };
      expect(
        matchesAnswer(answer, {'a': '14', 'op': '-', 'b': '6', 'c': '8'}),
        isTrue,
      );
      expect(
        matchesAnswer(answer, {'a': '6', 'op': '-', 'b': '14', 'c': '8'}),
        isFalse,
      );
    });

    test('step rules read written answers from the slots', () {
      final number = step('math_unit_02.step.015');
      expect(number.isNumber, isTrue);
      expect(StepRules.selection(number, {}, {'answer': '7'}), '7');
      expect(StepRules.reviewItems(number, {}, {'answer': '6'}), {'answer'});
      expect(StepRules.reviewItems(number, {}, {'answer': '7'}), isEmpty);
      expect(StepRules.answerReference(number, {'answer'}), '7');

      final story = step('math_unit_11.step.020');
      expect(story.isSentence, isTrue);
      final slots = {'a': '14', 'op': '-', 'b': '5', 'c': '9'};
      expect(StepRules.selection(story, {}, slots), slots);
      expect(StepRules.reviewItems(story, {}, slots), {'b', 'c'});
      expect(StepRules.answerReference(story, {}), '14 − 6 = 8');
    });
  });

  test('no Maths step asks the child to work at home any more', () {
    for (final lesson in maths.lessons.values) {
      for (final s in lesson.steps) {
        expect(s.title, isNot('Try it at home'), reason: s.id);
        expect(s.kind, isNot('story'), reason: s.id);
        if (s.kind != 'explore') expect(s.assessed, isTrue, reason: s.id);
      }
    }
    // Six worksheet questions at the end of units 2, 11 and 14.
    for (final id in ['math_unit_02', 'math_unit_11', 'math_unit_14']) {
      final sheet = maths.lessons[id]!.steps.where(
        (s) => s.objective.contains('.sheet.'),
      );
      expect(sheet, hasLength(6), reason: id);
      expect(sheet.every((s) => s.section == 'Practice'), isTrue);
      expect(sheet.where((s) => s.isSentence), hasLength(1));
    }
  });

  test('a journey saved before the change still opens and scores', () {
    // A child had passed the old "Try it at home" step 6 of unit 1 (no
    // answer) and stopped at step 9.
    final lesson = maths.lessons['math_unit_01']!;
    final saved = {
      'version': lesson.version,
      'attemptId': 'old-attempt',
      'index': 8,
      'stepId': lesson.steps[8].id,
      'responses': {
        'math_unit_01.step.006': {'completed': true},
        'math_unit_01.step.002': {'completed': true, 'outcome': 'firstTry'},
      },
      'current': <String, dynamic>{},
    };
    expect(LessonSession.canRestore(lesson, saved), isTrue);
    final session = LessonSession.restore(lesson, saved);
    expect(session.step.id, lesson.steps[8].id);
    final results = session.result().objectives;
    expect(results.containsKey('math.u01.main.05'), isFalse);
    expect(results[lesson.steps[1].objective], DecisionOutcome.firstTry);
  });

  test('a child who stopped on the old "Try it at home" step gets the new '
      'question there', () {
    final lesson = maths.lessons['math_unit_01']!;
    final step = lesson.steps[5];
    expect(step.id, 'math_unit_01.step.006');
    expect(step.isNumber, isTrue);
    final saved = {
      'version': lesson.version,
      'attemptId': 'old-attempt',
      'index': 5,
      'stepId': step.id,
      'responses': {
        for (final s in lesson.steps.take(5))
          s.id: {'completed': true, 'outcome': 'firstTry'},
      },
      'current': <String, dynamic>{},
    };
    expect(LessonSession.canRestore(lesson, saved), isTrue);
    final session = LessonSession.restore(lesson, saved);
    expect(session.step.id, step.id);
    // Step 1 explores (no objective); steps 2-5 keep their results.
    expect(session.result().objectives.keys.toSet(), {
      for (final s in lesson.steps.take(5))
        if (s.assessed) s.objective,
    });
    expect(session.result().objectives, hasLength(4));
    expect(session.result().objectives.containsKey(step.objective), isFalse);
  });

  group('the child writes the answer', () {
    Future<MemoryProgressStore> open(WidgetTester t, String stepId) async {
      t.view.physicalSize = const Size(1280, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final lesson = maths.lessons.values.firstWhere(
        (l) => l.steps.any((s) => s.id == stepId),
      );
      final session = LessonSession.fresh(lesson)
        ..index = lesson.steps.indexWhere((s) => s.id == stepId);
      final store = MemoryProgressStore(
        const AppData(
          profile: ChildProfile(name: 'Nour'),
        ).withSubjectProgress('maths', journeys: {lesson.id: session.toJson()}),
      );
      await t.runAsync(
        () => Flame.images.loadAll([
          'maths-objects-v2.webp',
          'maths-backdrops-v2.webp',
          'maths-things-v1.webp',
        ]),
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
            theme: adventureTheme(store.data.profile),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: LessonPlayer(lesson: lesson),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      return store;
    }

    Future<void> press(WidgetTester t, String key) =>
        helpers.tapVisible(t, find.byKey(ValueKey(key)));

    Map<String, dynamic> current(MemoryProgressStore store, String lesson) =>
        Map<String, dynamic>.from(
          store.data.progressForSubject('maths').journeys[lesson]!['current'],
        );

    Finder check() => find.byKey(const ValueKey('lessonCheck'));

    testWidgets(
      'a wrong number is marked, then the right one counts after the hint',
      (t) async {
        final store = await open(t, 'math_unit_02.step.015');
        expect(t.widget<ButtonStyleButton>(check()).onPressed, isNull);
        await press(t, 'number-key-8');
        await helpers.tapVisible(t, check());
        expect(current(store, 'math_unit_02')['mistakes'], 1);
        expect(find.text('8'), findsWidgets);
        await press(t, 'number-key-del');
        await press(t, 'number-key-7');
        await helpers.tapVisible(t, check());
        final saved = current(store, 'math_unit_02');
        expect(saved['done'], isTrue);
        expect(saved['outcome'], 'afterHint');
        expect(saved['placements'], {'answer': '7'});
        expect(t.takeException(), isNull);
      },
    );

    testWidgets('a number sentence is built from boxes, a sign and the pad', (
      t,
    ) async {
      final store = await open(t, 'math_unit_14.step.020');
      // 7 + 8 = 15 is right too: Rana skipped 8 times, then 7 more.
      await press(t, 'number-key-7');
      await press(t, 'sentence-op-+');
      await press(t, 'number-key-8');
      await press(t, 'sentence-c');
      await press(t, 'number-key-1');
      await press(t, 'number-key-5');
      await helpers.tapVisible(t, check());
      final saved = current(store, 'math_unit_14');
      expect(saved['placements'], {'a': '7', 'op': '+', 'b': '8', 'c': '15'});
      expect(saved['done'], isTrue);
      expect(saved['outcome'], 'firstTry');
      expect(t.takeException(), isNull);
    });
  });
}
