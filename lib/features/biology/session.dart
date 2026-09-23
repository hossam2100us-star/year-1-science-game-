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
      current = Map<String, dynamic>.from(json['current']);
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
    'responses': responses,
    'current': current,
  };
  UnitAttempt result() => UnitAttempt(
    unitId: lesson.id,
    completedAt: DateTime.now(),
    objectives: objectiveResults(lesson, responses),
    completed: true,
    effortStars: responses.length == lesson.steps.length ? 3 : 1,
    attemptId: attemptId,
    contentVersion: lesson.version,
  );
}
