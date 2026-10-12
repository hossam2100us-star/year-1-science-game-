import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/domain/journey/journey_migrations.dart';
import 'package:science_adventure/domain/journey/journey_state.dart';
import 'package:science_adventure/features/lesson/session.dart';

Lesson revisedLesson(String id) {
  final quiz = id.startsWith('math_quiz_');
  final steps = <Map<String, dynamic>>[];
  for (var index = 0; index < 3; index++) {
    final intro = !quiz && index == 0;
    steps.add({
      'id': '$id.step.${(index + 1).toString().padLeft(3, '0')}',
      'kind': intro ? 'explore' : 'tap-choice',
      'title': intro ? 'Maths workshop' : 'Count the objects',
      'prompt': intro ? 'Build a group and compare it.' : 'How many objects?',
      'options': intro
          ? <Map<String, dynamic>>[]
          : [
              {'id': 'choice_2', 'label': '3', 'art': 'math_label'},
              {'id': 'choice_1', 'label': '2', 'art': 'math_label'},
            ],
      'targets': <Map<String, dynamic>>[],
      'answer': intro ? null : {'type': 'single', 'value': 'choice_1'},
      'assessed': !intro,
      'objective': intro ? '' : '$id.count.$index',
      'hint': 'Count each object once.',
      'explanation': 'There are two objects.',
      'playScene': 'maths',
      if (intro) 'mathWorkshop': {'type': 'count'},
    });
  }
  return Lesson({
    'schemaVersion': 1,
    'contentVersion': 2,
    'id': id,
    'subject': 'maths',
    'title': 'Maths',
    'quiz': quiz,
    'steps': steps,
    'stickers': <Map<String, dynamic>>[],
    'homeActivities': <Map<String, dynamic>>[],
  });
}

Map<String, dynamic> oldJourney(
  Lesson lesson, {
  int index = 0,
  String? stepId,
  Map<String, dynamic> responses = const {},
  Map<String, dynamic> current = const {},
}) => {
  'version': 1,
  'attemptId': '${lesson.id}-original-attempt',
  'index': index,
  'stepId': ?stepId,
  'responses': responses,
  'current': current,
};

const oldTouchState = <String, dynamic>{
  'touched': ['explore_1', 'explore_2', 'explore_3'],
  'selected': ['explore_1', 'explore_2', 'explore_3'],
  'freeDone': true,
  'done': true,
  'feedback': 'All three cards were visited.',
};

void main() {
  final lessons = [for (final id in LessonLibrary.mathsIds) revisedLesson(id)];
  final workshops = lessons.where((lesson) => !lesson.quiz);

  test('all 22 Maths lessons accept only known saved versions', () {
    expect(lessons, hasLength(22));
    expect(workshops, hasLength(19));
    for (final lesson in lessons) {
      for (final version in [1, 2]) {
        expect(JourneyMigrations.canRestore(lesson, version), isTrue);
      }
      for (final version in [0, 3, null, '1']) {
        expect(JourneyMigrations.canRestore(lesson, version), isFalse);
      }
    }
    expect(
      JourneyMigrations.canRestore(revisedLesson('math_unpublished'), 1),
      isFalse,
    );
  });

  test('old intro touch and completed resume state cannot skip a workshop', () {
    for (final lesson in workshops) {
      final intro = lesson.steps.first.id;
      final graded = lesson.steps[1].id;
      final gradedResponse = {
        'completed': true,
        'done': true,
        'outcome': 'afterHint',
        'selected': ['choice_1'],
        'resumeState': {
          'selected': ['choice_1'],
          'mistakes': 1,
        },
      };
      final saved = oldJourney(
        lesson,
        responses: {
          intro: {
            'completed': true,
            ...oldTouchState,
            'resumeState': oldTouchState,
          },
          graded: gradedResponse,
        },
        current: oldTouchState,
      );
      final before = jsonEncode(saved);
      final restored = LessonSession.restore(lesson, saved);
      expect(restored.index, 0, reason: lesson.id);
      expect(restored.attemptId, saved['attemptId']);
      expect(restored.current, isEmpty);
      expect(restored.responses.containsKey(intro), isFalse);
      expect(restored.responses, {graded: gradedResponse});
      expect(restored.toJson()['version'], 2);
      expect(jsonEncode(saved), before, reason: 'Stored evidence is immutable');
      expect(
        JourneyState.fromJson(restored.toJson()).toJson(),
        restored.toJson(),
      );
    }
  });

  test(
    'later work keeps original evidence, selection and intro completion',
    () {
      for (final lesson in lessons) {
        final responses = {
          for (final step in lesson.steps)
            step.id: {
              'completed': true,
              'done': true,
              if (step.assessed) 'outcome': 'firstTry',
              if (!step.assessed) ...oldTouchState,
            },
        };
        final current = {
          'selected': ['choice_2'],
          'placements': {'choice_2': 'target'},
          'mistakes': 1,
          'needsCorrection': true,
          'reviewItems': ['choice_2'],
          'feedback': 'Keep the original in-progress assessment.',
        };
        final saved = oldJourney(
          lesson,
          index: 1,
          stepId: lesson.steps[1].id,
          responses: responses,
          current: current,
        );
        final restored = LessonSession.restore(lesson, saved);
        expect(restored.index, 1, reason: lesson.id);
        expect(restored.current, current);
        expect(restored.responses, responses);
        expect(restored.attemptId, saved['attemptId']);
        final result = restored.result();
        expect(result.attemptId, saved['attemptId']);
        expect(result.firstTry, lesson.objectives.length);
        expect(result.effortStars, 3, reason: 'Do not erase earned completion');
      }
    },
  );

  test(
    'stable step ID governs whether a stale saved index resets the intro',
    () {
      final lesson = workshops.first;
      final graded = {'completed': true, 'outcome': 'explained'};
      final current = {
        'selected': ['choice_2'],
        'mistakes': 2,
      };
      final gradedRestore = LessonSession.restore(
        lesson,
        oldJourney(
          lesson,
          index: 0,
          stepId: lesson.steps[1].id,
          responses: {lesson.steps[1].id: graded},
          current: current,
        ),
      );
      expect(gradedRestore.index, 1);
      expect(gradedRestore.current, current);
      final introRestore = LessonSession.restore(
        lesson,
        oldJourney(
          lesson,
          index: 2,
          stepId: lesson.steps.first.id,
          responses: {
            lesson.steps.first.id: {'completed': true, ...oldTouchState},
            lesson.steps[1].id: graded,
          },
          current: oldTouchState,
        ),
      );
      expect(introRestore.index, 0);
      expect(introRestore.current, isEmpty);
      expect(introRestore.responses, {lesson.steps[1].id: graded});
    },
  );

  test('quiz first questions and finished Maths journeys remain intact', () {
    for (final lesson in lessons) {
      final responses = {
        for (final step in lesson.steps)
          step.id: {
            'completed': true,
            if (step.assessed) 'outcome': 'afterHint',
          },
      };
      final finished = LessonSession.restore(
        lesson,
        oldJourney(lesson, index: lesson.steps.length, responses: responses),
      );
      expect(finished.finished, isTrue, reason: lesson.id);
      expect(finished.responses, responses);
      expect(finished.result().effortStars, 3);
      if (lesson.quiz) {
        final current = {
          'selected': ['choice_1'],
          'done': true,
        };
        final quiz = LessonSession.restore(
          lesson,
          oldJourney(lesson, responses: responses, current: current),
        );
        expect(quiz.index, 0);
        expect(quiz.responses, responses);
        expect(quiz.current, current);
      }
    }
  });

  test('same-version workshop work is not reset on subsequent restores', () {
    final lesson = workshops.first;
    final saved = oldJourney(
      lesson,
      current: {
        'lab': {
          'moves': 4,
          'objects': ['apple_1', 'apple_2'],
        },
      },
    )..['version'] = 2;
    final restored = LessonSession.restore(lesson, saved);
    expect(restored.current, saved['current']);
    expect(restored.attemptId, saved['attemptId']);
  });
}
