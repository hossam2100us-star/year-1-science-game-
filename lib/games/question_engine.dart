import '../content/lesson.dart';
import '../core/models.dart';

bool matchesAnswer(Map<String, dynamic> answer, dynamic value) {
  final expected = answer['value'];
  final aliases = Map<String, dynamic>.from(answer['aliases'] ?? {});
  dynamic canonical(dynamic id) => aliases[id] ?? id;
  switch (answer['type']) {
    case 'single':
      return value is String && value == expected;
    case 'set':
      return value is List &&
          value.length == (expected as List).length &&
          value.toSet().length == value.length &&
          value.every((v) => expected.contains(v));
    case 'sequence':
      if (value is! List || value.length != (expected as List).length) {
        return false;
      }
      for (var i = 0; i < value.length; i++) {
        if (value[i] != expected[i]) return false;
      }
      return true;
    case 'mapping':
      if (value is! Map || value.length != (expected as Map).length) {
        return false;
      }
      return expected.entries.every(
        (e) => canonical(value[e.key]) == canonical(e.value),
      );
    case 'number':
      return value is String && int.tryParse(value) == expected;
    case 'sentence':
      return value is Map && sentenceMatches(Map.from(expected), value);
    case 'word':
      // Spelling is exact: a capital letter or a missing sound is the point.
      return value is String && value == expected;
    default:
      throw FormatException('Unknown answer type: ${answer['type']}');
  }
}

/// A written number sentence: the same numbers, sign and result. An
/// addition may be written either way round (9 + 6 = 15 or 6 + 9 = 15).
bool sentenceMatches(
  Map<Object?, Object?> expected,
  Map<Object?, Object?> value,
) {
  String at(Map<Object?, Object?> m, String key) => '${m[key] ?? ''}'.trim();
  final same = [
    'a',
    'op',
    'b',
    'c',
  ].every((k) => at(value, k) == at(expected, k));
  final swapped =
      at(expected, 'op') == '+' &&
      at(value, 'op') == '+' &&
      at(value, 'a') == at(expected, 'b') &&
      at(value, 'b') == at(expected, 'a') &&
      at(value, 'c') == at(expected, 'c');
  return same || swapped;
}

class QuestionEngine {
  QuestionEngine(
    this.step, {
    this.mistakes = 0,
    this.done = false,
    this.outcome,
  });
  final LessonStep step;
  int mistakes;
  bool done;
  DecisionOutcome? outcome;
  bool submit(dynamic selection) {
    if (done || step.answer == null || step.isFree) return false;
    final correct = matchesAnswer(step.answer!, selection);
    if (correct) {
      done = true;
      outcome = mistakes == 0
          ? DecisionOutcome.firstTry
          : DecisionOutcome.afterHint;
    } else {
      mistakes++;
      if (mistakes >= 2) {
        done = true;
        outcome = DecisionOutcome.explained;
      }
    }
    return correct;
  }

  String get feedback => done
      ? (outcome == DecisionOutcome.explained
                ? 'Let us discover it together. '
                : 'You looked really carefully! ') +
            step.explanation
      : mistakes > 0
      ? 'Hmm, let us look again! ${step.hint}'
      : '';
}

/// Combine sub-parts into one book objective: no extra points for repeated taps.
Map<String, DecisionOutcome> objectiveResults(
  Lesson lesson,
  Map<String, dynamic> responses,
) {
  final results = <String, DecisionOutcome>{};
  for (final step in lesson.steps.where((s) => s.assessed)) {
    final response = responses[step.id];
    if (response is Map && response['objectiveEvidence'] is Map) {
      for (final entry in (response['objectiveEvidence'] as Map).entries) {
        if (!step.assessedObjectives.contains(entry.key)) continue;
        final value = DecisionOutcome.values.byName(entry.value);
        if (results[entry.key] == null ||
            value.index > results[entry.key]!.index) {
          results[entry.key] = value;
        }
      }
      continue;
    }
    if (response is! Map || response['outcome'] == null) continue;
    final value = DecisionOutcome.values.byName(response['outcome']);
    final previous = results[step.objective];
    if (previous == null || value.index > previous.index) {
      results[step.objective] = value;
    }
  }
  return results;
}
