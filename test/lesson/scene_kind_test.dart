import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/features/lesson/scene_kind.dart';
import 'package:science_adventure/features/lesson/scene_renderers.dart';
import 'package:science_adventure/features/lesson/step_rules.dart';
import 'package:science_adventure/games/question_engine.dart';

/// The branch order of the old LessonPlayer.build, kept here as the
/// reference the registry must match (AUD-002 characterization).
SceneKind legacyBranch(LessonStep step) {
  final j = step.json;
  if (j['experiment'] == 'light') return SceneKind.lightExperiment;
  if (j['experiment'] == 'bean') return SceneKind.beanExperiment;
  if (j['playScene'] == 'science') {
    return j['lab'] != null ? SceneKind.scienceLab : SceneKind.scienceStage;
  }
  if (j['playScene'] == 'ourselves') return SceneKind.ourselves;
  if (j['playScene'] == 'plant-lab') return SceneKind.plantLab;
  if (j['playScene'] == 'plant-mission') return SceneKind.plantMission;
  return SceneKind.discovery;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonLibrary library;
  setUpAll(() async => library = await LessonLibrary.load());

  test('every content step resolves to the scene the old player used', () {
    final seen = <SceneKind>{};
    for (final lesson in library.lessons.values) {
      for (final step in lesson.steps) {
        final kind = SceneKind.of(step);
        expect(kind, legacyBranch(step), reason: step.id);
        seen.add(kind);
      }
    }
    expect(
      seen,
      SceneKind.values.toSet()
        ..remove(SceneKind.maths)
        ..remove(SceneKind.english),
      reason: 'all Science kinds are in use',
    );
  });

  test('every English step uses the English scene', () async {
    final english = await LessonLibrary.loadEnglish();
    expect(english.lessons, hasLength(LessonLibrary.englishIds.length));
    for (final lesson in english.lessons.values) {
      for (final step in lesson.steps) {
        expect(SceneKind.of(step), SceneKind.english, reason: step.id);
      }
    }
  });

  test('every Maths step uses the Maths scene', () async {
    final maths = await LessonLibrary.loadMaths();
    expect(maths.lessons, hasLength(LessonLibrary.mathsIds.length));
    for (final lesson in maths.lessons.values) {
      for (final step in lesson.steps) {
        expect(SceneKind.of(step), SceneKind.maths, reason: step.id);
      }
    }
  });

  test('the registry has exactly one renderer per scene kind', () {
    expect(SceneRenderer.registry.keys.toSet(), SceneKind.values.toSet());
  });

  test('only the two experiments are full-screen', () {
    expect(
      SceneKind.values.where((k) => k.fullScreen),
      unorderedEquals([SceneKind.lightExperiment, SceneKind.beanExperiment]),
    );
  });

  group('StepRules', () {
    LessonStep mapping() => LessonStep({
      'id': 's',
      'kind': 'mapping',
      'assessed': true,
      'options': [
        {'id': 'a', 'label': 'Apple'},
        {'id': 'b', 'label': 'Ball'},
      ],
      'targets': [
        {'id': 'x', 'label': 'Alive'},
        {'id': 'y', 'label': 'Not alive'},
      ],
      'answer': {
        'type': 'mapping',
        'value': {'a': 'x', 'b': 'y'},
      },
    });

    test('selection has the shape the engine expects', () {
      final step = mapping();
      expect(StepRules.selection(step, {'a'}, {'a': 'x'}), {'a': 'x'});
    });

    test('mapping review marks only misplaced items', () {
      final step = mapping();
      final placed = {'a': 'x', 'b': 'x'};
      expect(StepRules.mappingItemMatches(step, placed, 'a'), isTrue);
      expect(StepRules.mappingItemMatches(step, placed, 'b'), isFalse);
      expect(StepRules.reviewItems(step, {}, placed), {'b'});
      expect(StepRules.answerReference(step, {'b'}), 'Ball: Not alive');
    });

    test('feedback after a mistake names what to look at again', () {
      final step = mapping();
      final engine = QuestionEngine(step)..submit({'a': 'x', 'b': 'x'});
      expect(
        StepRules.assessmentFeedback(step, engine, {}, {'a': 'x', 'b': 'x'}),
        endsWith(' Look again: Ball.'),
      );
    });

    test('a step that needs correction can never be skipped', () {
      expect(
        StepRules.canContinue(
          step: mapping(),
          needsCorrection: true,
          alreadyCompleted: true,
          lab: const {},
          touched: const {},
          engineDone: true,
          freeDone: true,
        ),
        isFalse,
      );
    });

    test('explore steps continue after enough touches', () {
      final step = LessonStep({
        'id': 'e',
        'kind': 'explore',
        'minTouches': 2,
        'options': <Object>[],
        'targets': <Object>[],
      });
      bool can(Set<String> touched) => StepRules.canContinue(
        step: step,
        needsCorrection: false,
        alreadyCompleted: false,
        lab: const {},
        touched: touched,
        engineDone: false,
        freeDone: false,
      );
      expect(can({'a'}), isFalse);
      expect(can({'a', 'b'}), isTrue);
    });
  });
}
