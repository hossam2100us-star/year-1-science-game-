import '../../content/lesson.dart';
import '../../games/question_engine.dart';
import '../science/science_lab.dart';
import 'scene_kind.dart';

/// Pure assessment and progression rules for one lesson step (AUD-002).
///
/// Moved unchanged out of the lesson player so they can be tested without
/// widgets. They never change state; the player applies their results.
abstract final class StepRules {
  /// What the child answered, in the shape the question engine expects.
  static Object? selection(
    LessonStep step,
    Set<String> selected,
    Map<String, String> placements,
  ) => step.isMapping
      ? placements
      : step.isMulti || step.isOrder
      ? selected.toList()
      : selected.firstOrNull;

  /// Whether one mapped item sits where the answer key puts it.
  static bool mappingItemMatches(
    LessonStep step,
    Map<String, String> placements,
    String id,
  ) => matchesAnswer(
    {
      ...step.answer!,
      'value': {id: (step.answer!['value'] as Map)[id]},
    },
    {id: placements[id]},
  );

  /// Engine feedback plus a gentle pointer at what to look at again.
  static String assessmentFeedback(
    LessonStep step,
    QuestionEngine engine,
    Set<String> selected,
    Map<String, String> placements,
  ) {
    var feedback = engine.feedback;
    if (!engine.done && engine.mistakes > 0 && step.isMapping) {
      final expected = Map<String, dynamic>.from(step.answer!['value'] as Map);
      final revisit = expected.keys.where(
        (id) => !mappingItemMatches(step, placements, id),
      );
      feedback += ' Look again: ${revisit.map(step.label).join(', ')}.';
    } else if (!engine.done && engine.mistakes > 0 && step.isMulti) {
      final expected = List<String>.from(step.answer!['value'] as List);
      final found = selected.where(expected.contains).length;
      feedback +=
          ' $found of ${expected.length} discoveries found. Check your collection.';
    }
    return feedback;
  }

  /// Items the child should look at again. Missing correct choices are not
  /// revealed before the explanation.
  static Set<String> reviewItems(
    LessonStep step,
    Set<String> selected,
    Map<String, String> placements,
  ) {
    final expected = step.answer!['value'];
    if (step.isMapping) {
      return (expected as Map).keys
          .cast<String>()
          .where((id) => !mappingItemMatches(step, placements, id))
          .toSet();
    }
    if (step.isMulti) {
      return selected.where((id) => !(expected as List).contains(id)).toSet();
    }
    return selected.where((id) => id != expected).toSet();
  }

  /// The correct answer for the items under review, in words.
  static String answerReference(LessonStep step, Set<String> reviewItems) {
    final expected = step.answer!['value'];
    if (expected is Map) {
      return expected.entries
          .where((e) => reviewItems.contains(e.key))
          .map(
            (e) =>
                '${step.label(e.key as String)}: ${step.label(e.value as String)}',
          )
          .join('. ');
    }
    return (expected is List ? expected : [expected])
        .map((id) => step.label(id as String))
        .join(' • ');
  }

  /// Whether "Keep exploring" is available on this step.
  static bool canContinue({
    required LessonStep step,
    required bool needsCorrection,
    required bool alreadyCompleted,
    required Map<String, dynamic> lab,
    required Set<String> touched,
    required bool engineDone,
    required bool freeDone,
  }) {
    if (needsCorrection) return false;
    if (alreadyCompleted) return true;
    final kind = SceneKind.of(step);
    final json = step.json;
    if (kind.isScience && json['lab'] == 'distance') {
      return ScienceLab.distanceComplete(lab);
    }
    if (kind.isScience && json['lab'] == 'force') {
      return ScienceLab.forceComplete(lab);
    }
    if (kind.isScience && json['lab'] == 'sailboat') {
      return ScienceLab.boatComplete(lab);
    }
    if (kind.isScience && json['shapeResults'] != null) {
      return ScienceLab.shapeComplete(step, lab);
    }
    if (kind.isScience && json['observationUi'] != null) {
      return ScienceLab.experimentComplete(step, lab);
    }
    if (kind.isScience && json['lab'] != null) return freeDone;
    if (kind.isScience && step.kind == 'explore') {
      return step.options.every((o) => touched.contains(o.id));
    }
    if (kind == SceneKind.ourselves &&
        (step.kind == 'explore' || step.kind == 'story')) {
      return step.options.every((o) => touched.contains(o.id));
    }
    if (kind == SceneKind.plantLab && step.kind == 'story') {
      return touched.contains(step.focus);
    }
    if (kind == SceneKind.plantLab &&
        (step.kind == 'explore' || step.kind == 'free-plant')) {
      return step.options.every((item) => touched.contains(item.id));
    }
    if (engineDone || freeDone || step.kind == 'story') return true;
    if (step.kind == 'explore' || step.kind == 'free-plant') {
      return touched.length >= ((json['minTouches'] as int?) ?? 3);
    }
    return false;
  }
}
