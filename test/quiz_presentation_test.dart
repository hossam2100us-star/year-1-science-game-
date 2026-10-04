import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/features/science/science_picture.dart';
import 'package:science_adventure/features/science/science_stage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonLibrary library;
  setUpAll(() async {
    library = await LessonLibrary.load();
  });

  Future<void> mount(
    WidgetTester t,
    LessonStep step,
    List<String> selections,
    List<(String, String)> placements,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ScienceStage(
                step: step,
                selected: const {},
                placements: const {},
                done: false,
                onItem: selections.add,
                onPlace: (item, target) => placements.add((item, target)),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
  }

  testWidgets(
    'All thirty science quiz contexts open without selecting or placing answers',
    (t) async {
      t.view.physicalSize = const Size(360, 740);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      var questions = 0;
      for (final lessonId in ['quiz_02', 'quiz_03', 'quiz_04']) {
        for (final step in library.lessons[lessonId]!.steps) {
          final selections = <String>[], placements = <(String, String)>[];
          await mount(t, step, selections, placements);
          expect(step.json['quizContext'], isA<Map<dynamic, dynamic>>());
          expect(selections, isEmpty, reason: step.id);
          expect(placements, isEmpty, reason: step.id);
          for (final option
              in step.isMapping ? step.options.take(1) : step.options) {
            expect(
              find.byKey(ValueKey('science-item-${option.id}')),
              findsOneWidget,
              reason: step.id,
            );
          }
          if (step.isMapping) {
            for (final target in step.targets) {
              expect(
                find.byKey(ValueKey('science-target-${target.id}')),
                findsOneWidget,
                reason: step.id,
              );
            }
          }
          expect(t.takeException(), isNull, reason: step.id);
          await t.pumpWidget(const SizedBox());
          questions++;
        }
      }
      expect(questions, 30);
    },
  );

  testWidgets(
    'A neutral glass claim suppresses the legacy clear-window focus',
    (t) async {
      final step = library.lessons['quiz_02']!.steps.singleWhere(
        (step) => step.id == 'quiz_02.step.009',
      );
      // A clear window would supply a visual counterexample to the claim.
      // Explicit null must override old saved presentation metadata.
      expect(step.focus, 'window');
      expect(step.json['quizContext']['art'], isNull);
      final selections = <String>[], placements = <(String, String)>[];
      await mount(t, step, selections, placements);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is SciencePicture && widget.art == 'window',
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('material-context-window')),
        findsNothing,
      );
      expect(selections, isEmpty);
      expect(placements, isEmpty);
      final first = find.byKey(
        ValueKey('science-item-${step.options.first.id}'),
      );
      await t.ensureVisible(first);
      await t.pump();
      await t.tap(first);
      await t.pump();
      expect(selections, [step.options.first.id]);
      expect(placements, isEmpty);
      expect(t.takeException(), isNull);
    },
  );
}
