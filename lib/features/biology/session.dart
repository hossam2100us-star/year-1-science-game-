import '../../content/lesson.dart';
import '../../core/models.dart';
import '../../games/question_engine.dart';

class LessonSession {
  LessonSession.fresh(this.lesson)
    : attemptId = '${lesson.id}-${DateTime.now().microsecondsSinceEpoch}',
      index = 0,
      responses = {},
      current = {};
  LessonSession.restore(this.lesson, Map<String, dynamic> json)
    : attemptId = json['attemptId'],
      index = json['index'],
      responses = Map<String, dynamic>.from(json['responses']),
      current = Map<String, dynamic>.from(json['current']) {
    if (json['version'] == lesson.version) {
      final savedId = json['stepId'];
      final located = lesson.steps.indexWhere((s) => s.id == savedId);
      if (located >= 0) index = located;
      index = index.clamp(0, lesson.steps.length);
      return;
    }
    final oldIds = List<String>.from(lesson.json['legacyStepIds']);
    final oldId = index < oldIds.length ? oldIds[index] : null;
    for (final step in lesson.steps) {
      final merged = List<String>.from(step.json['legacyMergedFrom'] ?? []);
      if (merged.isEmpty ||
          !merged.every((id) => responses[id]?['completed'] == true))
        continue;
      final outcomes = merged.map((id) => responses[id]?['outcome']).toList();
      final result = outcomes.contains('explained')
          ? 'explained'
          : outcomes.contains('afterHint')
          ? 'afterHint'
          : 'firstTry';
      responses[step.id] = {
        'completed': true,
        'done': true,
        'outcome': result,
        'placements': Map<String, dynamic>.from(step.answer!['value']),
        'feedback': step.explanation,
      };
    }
    // Retain old evidence, but only active step IDs contribute to the new result.
    index = lesson.steps.indexWhere(
      (s) => responses[s.id]?['completed'] != true,
    );
    if (index < 0) index = lesson.steps.length;
    if (finished || step.id != oldId) current = {};
  }
  static bool canRestore(Lesson lesson, Map<String, dynamic> saved) =>
      saved['version'] == lesson.version ||
      (lesson.id == 'unit_02' && lesson.version == 2 && saved['version'] == 1);
  final Lesson lesson;
  final String attemptId;
  int index;
  Map<String, dynamic> responses, current;
  LessonStep get step => lesson.steps[index];
  bool get finished => index >= lesson.steps.length;
  Map<String, dynamic> toJson() => {
    'version': lesson.version,
    'attemptId': attemptId,
    'index': index,
    'stepId': finished ? null : step.id,
    'responses': responses,
    'current': current,
  };
  UnitAttempt result() => UnitAttempt(
    unitId: lesson.id,
    completedAt: DateTime.now(),
    objectives: objectiveResults(lesson, responses),
    completed: true,
    effortStars:
        lesson.steps.every((s) => responses[s.id]?['completed'] == true)
        ? 3
        : 1,
    attemptId: attemptId,
    contentVersion: lesson.version,
  );
}
