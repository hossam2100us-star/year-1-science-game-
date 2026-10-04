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
    if (lesson.id == 'unit_06' && lesson.version == 2 && json['version'] == 1) {
      _restoreSoundChart(json);
      return;
    }
    Set<String>? built;
    if (lesson.id == 'unit_02' && lesson.version == 4) {
      built = <String>{};
      final previousIds = List<String>.from(
        lesson.json[json['version'] == 1
            ? 'legacyStepIds'
            : json['version'] == 2
            ? 'previousStepIdsV2'
            : 'previousStepIdsV3'],
      );
      final oldId =
          json['stepId'] ??
          (index < previousIds.length ? previousIds[index] : null);
      for (final entry in {
        6: 'roots',
        7: 'stem',
        8: 'leaf',
        9: 'flower',
      }.entries) {
        final id = 'unit_02.step.${entry.key.toString().padLeft(3, '0')}';
        if (responses[id]?['completed'] == true ||
            (oldId == id && current['done'] == true)) {
          built.add(entry.value);
        }
      }
      if (built.length == 4) {
        responses['unit_02.step.006'] = {
          'completed': true,
          'done': true,
          'touched': built.toList(),
        };
      } else {
        responses.remove('unit_02.step.006');
      }
    }
    if (lesson.id == 'unit_02' &&
        lesson.version >= 3 &&
        const [2, 3].contains(json['version'])) {
      final previousIds = List<String>.from(
        lesson.json[json['version'] == 3
            ? 'previousStepIdsV3'
            : 'previousStepIdsV2'],
      );
      final oldId =
          json['stepId'] ??
          (index < previousIds.length ? previousIds[index] : null);
      if (oldId == null && index >= previousIds.length) {
        index = lesson.steps.length;
        current = {};
        return;
      }
      final located = lesson.steps.indexWhere((s) => s.id == oldId);
      if (built != null &&
          const [
            'unit_02.step.006',
            'unit_02.step.007',
            'unit_02.step.008',
            'unit_02.step.009',
          ].contains(oldId)) {
        index = built.length == 4 ? 2 : 1;
        current = built.length == 4
            ? {}
            : {'touched': built.toList(), 'selected': built.toList()};
      } else if (located >= 0) {
        index = located;
      } else {
        // The four ungraded explanations now live in the first exploration.
        index = responses[lesson.steps.first.id]?['completed'] == true ? 1 : 0;
        current = {};
      }
      return;
    }
    if (lesson.id == 'unit_03' && lesson.version == 2 && json['version'] == 1) {
      _restoreCompactOurselves(json);
      return;
    }
    final oldIds = List<String>.from(lesson.json['legacyStepIds']);
    final oldId = index < oldIds.length ? oldIds[index] : null;
    for (final step in lesson.steps) {
      final merged = List<String>.from(step.json['legacyMergedFrom'] ?? []);
      if (merged.isEmpty ||
          !merged.every((id) => responses[id]?['completed'] == true)) {
        continue;
      }
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
    if (!finished && built != null && step.id == 'unit_02.step.006') {
      current = {'touched': built.toList(), 'selected': built.toList()};
    }
  }
  static bool canRestore(Lesson lesson, Map<String, dynamic> saved) =>
      saved['version'] == lesson.version ||
      (lesson.id == 'unit_06' &&
          lesson.version == 2 &&
          saved['version'] == 1) ||
      (lesson.id == 'unit_02' &&
          lesson.version >= 3 &&
          const [1, 2, 3].contains(saved['version'])) ||
      (const ['unit_02', 'unit_03'].contains(lesson.id) &&
          lesson.version == 2 &&
          saved['version'] == 1);

  void _restoreSoundChart(Map<String, dynamic> saved) {
    const chartId = 'unit_06.step.008';
    final located = lesson.steps.indexWhere((s) => s.id == saved['stepId']);
    if (located >= 0) index = located;
    index = index.clamp(0, lesson.steps.length);
    final chart = responses[chartId];
    if (chart is Map) {
      final migrated = _migrateSoundChartState(chart);
      final resume = chart['resumeState'];
      if (resume is Map) {
        migrated['resumeState'] = _migrateSoundChartState(resume);
      }
      responses[chartId] = migrated;
    }
    if (!finished && step.id == chartId) {
      // A completed question keeps the exact question that earned its outcome.
      // Unfinished work instead resumes the new David question without carrying
      // the obsolete Maris answer into its assessment.
      current = _migrateSoundChartState(
        current,
        completed: chart is Map && chart['completed'] == true,
      );
    }
  }

  Map<String, dynamic> _migrateSoundChartState(
    Map<dynamic, dynamic> state, {
    bool completed = false,
  }) {
    final migrated = Map<String, dynamic>.from(state);
    if (state['needsCorrection'] != true &&
        (completed || state['completed'] == true || state['done'] == true)) {
      migrated['legacySoundChart'] = true;
      return migrated;
    }
    migrated.remove('legacySoundChart');
    if (state['placements'] is Map) {
      migrated['placements'] = Map<String, dynamic>.from(state['placements'])
        ..remove('maris_took');
    }
    for (final key in ['selected', 'reviewItems']) {
      if (state[key] is List) {
        migrated[key] = (state[key] as List)
            .where((id) => id != 'maris_took')
            .toList();
      }
    }
    if (state.containsKey('feedback')) migrated['feedback'] = '';
    return migrated;
  }

  void _restoreCompactOurselves(Map<String, dynamic> saved) {
    final legacyIds = List<String>.from(lesson.json['legacyStepIds']);
    final oldId =
        saved['stepId'] ?? (index < legacyIds.length ? legacyIds[index] : null);
    final oldCurrent = Map<String, dynamic>.from(current);
    final legacyObjectives = Map<String, dynamic>.from(
      lesson.json['legacyAssessmentObjectives'],
    );
    for (final next in lesson.steps) {
      final ids = List<String>.from(next.json['legacyMergedFrom'] ?? [next.id]);
      final groups = List<List<dynamic>>.from(
        next.json['legacyCompletionGroups'] ?? [ids],
      );
      final complete = groups.every(
        (group) => group.any((id) => responses[id]?['completed'] == true),
      );
      final evidence = <String, String>{};
      final placed = <String, String>{};
      final touched = <String>{};
      var mistakes = 0;
      for (final id in ids) {
        final record = responses[id] ?? (id == oldId ? oldCurrent : null);
        if (record is! Map) continue;
        final outcome = record['outcome'];
        final objective = legacyObjectives[id];
        if (outcome is String && next.assessedObjectives.contains(objective)) {
          const ranks = ['firstTry', 'afterHint', 'explained'];
          if (evidence[objective] == null ||
              ranks.indexOf(outcome) > ranks.indexOf(evidence[objective]!)) {
            evidence[objective] = outcome;
          }
        }
        final previousMistakes = record['mistakes'] as int? ?? 0;
        if (previousMistakes > mistakes) mistakes = previousMistakes;
        if (record['completed'] == true || record['done'] == true) {
          touched.addAll(
            List<String>.from(next.json['legacyTouchSources']?[id] ?? []),
          );
          final subset = !next.assessed || legacyObjectives.containsKey(id)
              ? (next.json['legacyPlacementSources']?[id])
              : null;
          if (subset is Map) placed.addAll(Map<String, String>.from(subset));
        }
      }
      for (final objective in evidence.keys.toList()) {
        final contributors = ids.where(
          (id) => legacyObjectives[id] == objective,
        );
        if (!contributors.every((id) => responses[id]?['completed'] == true)) {
          evidence.remove(objective);
        }
      }
      final objectiveItems = next.json['objectiveItems'];
      if (objectiveItems is Map) {
        for (final objective in next.assessedObjectives) {
          if (evidence.containsKey(objective)) continue;
          for (final id in List<String>.from(objectiveItems[objective] ?? [])) {
            placed.remove(id);
          }
        }
      }
      if (complete) {
        responses[next.id] = {
          ...(responses[next.id] is Map
              ? Map<String, dynamic>.from(responses[next.id])
              : <String, dynamic>{}),
          'completed': true,
          'migrated': true,
          'done': true,
          'objectiveEvidence': evidence,
        };
      } else if (next.id == oldId) {
        responses[next.id] = {'completed': false, 'resumeState': oldCurrent};
      } else if (placed.isNotEmpty ||
          evidence.isNotEmpty ||
          mistakes > 0 ||
          touched.isNotEmpty) {
        responses[next.id] = {
          'completed': false,
          'resumeState': {
            'touched': touched.toList(),
            'selected': touched.toList(),
            'placements': placed,
            'objectiveEvidence': evidence,
            'mistakes': mistakes,
          },
        };
      }
    }
    index = lesson.steps.indexWhere(
      (s) => responses[s.id]?['completed'] != true,
    );
    if (index < 0) index = lesson.steps.length;
    current = finished
        ? {}
        : step.id == oldId
        ? oldCurrent
        : Map<String, dynamic>.from(responses[step.id]?['resumeState'] ?? {});
  }

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
