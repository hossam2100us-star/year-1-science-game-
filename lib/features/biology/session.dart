import '../../content/lesson.dart';
import '../../core/models.dart';
import '../../domain/journey/journey_migrations.dart';
import '../../games/question_engine.dart';

class LessonSession {
  LessonSession.fresh(this.lesson)
    : attemptId = '${lesson.id}-${DateTime.now().microsecondsSinceEpoch}',
      index = 0,
      responses = {},
      current = {};

  /// Continues a saved journey. Content-version changes are handled by the
  /// versioned migration registry (AUD-007), not here.
  LessonSession.restore(this.lesson, Map<String, dynamic> json)
    : attemptId = json['attemptId'],
      index = json['index'],
      responses = Map<String, dynamic>.from(json['responses']),
      current = Map<String, dynamic>.from(json['current']) {
    final restore = JourneyRestore(
      index: index,
      responses: responses,
      current: current,
    );
    JourneyMigrations.apply(lesson, json, restore);
    index = restore.index;
    responses = restore.responses;
    current = restore.current;
  }
  static bool canRestore(Lesson lesson, Map<String, dynamic> saved) =>
      JourneyMigrations.canRestore(lesson, saved['version']);
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
