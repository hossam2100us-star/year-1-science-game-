import '../../content/lesson.dart';

/// A saved lesson journey while it is being brought up to the bundled
/// content version. Migrations change it in place.
class JourneyRestore {
  JourneyRestore({
    required this.index,
    required this.responses,
    required this.current,
  });
  int index;
  Map<String, dynamic> responses, current;
}

/// One content-version step for one lesson (AUD-007).
///
/// [saved] is the journey as stored; [restore] already holds its index,
/// responses and current state.
typedef JourneyMigration = void Function(
  Lesson lesson,
  Map<String, dynamic> saved,
  JourneyRestore restore,
);

/// Versioned, pure migrations for saved lesson journeys, kept out of widgets
/// and the session so they can be tested on their own and reused by the
/// repository layer and, later, the server.
///
/// Keys are `(lessonId, savedVersion, bundledVersion)`. The logic was moved
/// unchanged from `LessonSession.restore`; the characterization test
/// (test/migrations) proves identical results for 4,000+ saved states.
abstract final class JourneyMigrations {
  static final Map<(String, int, int), JourneyMigration> _registry = {
    ('unit_06', 1, 2): _soundChart,
    ('unit_02', 1, 4): _unit02FromV1,
    ('unit_02', 2, 4): _unit02FromV2orV3,
    ('unit_02', 3, 4): _unit02FromV2orV3,
    ('unit_02', 2, 3): _unit02FromV2orV3,
    ('unit_02', 1, 3): _mergedSteps,
    ('unit_02', 1, 2): _mergedSteps,
    ('unit_03', 1, 2): _compactOurselves,
  };

  /// Whether a journey saved at [savedVersion] can be continued.
  static bool canRestore(Lesson lesson, Object? savedVersion) =>
      savedVersion == lesson.version ||
      (savedVersion is int &&
          _registry.containsKey((lesson.id, savedVersion, lesson.version)));

  /// Applies the matching migration, or relocates by step ID when the
  /// versions already match.
  static void apply(
    Lesson lesson,
    Map<String, dynamic> saved,
    JourneyRestore restore,
  ) {
    if (saved['version'] == lesson.version) {
      _relocate(lesson, saved, restore);
      return;
    }
    final migration =
        _registry[(lesson.id, saved['version'] as int, lesson.version)];
    if (migration == null) {
      throw StateError('No journey migration for ${lesson.id}');
    }
    migration(lesson, saved, restore);
  }

  static void _relocate(
    Lesson lesson,
    Map<String, dynamic> saved,
    JourneyRestore r,
  ) {
    final located = lesson.steps.indexWhere((s) => s.id == saved['stepId']);
    if (located >= 0) r.index = located;
    r.index = r.index.clamp(0, lesson.steps.length);
  }

  static bool _finished(Lesson lesson, JourneyRestore r) =>
      r.index >= lesson.steps.length;

  // ---- unit_06: sound chart v1 -> v2 ---------------------------------------

  static void _soundChart(
    Lesson lesson,
    Map<String, dynamic> saved,
    JourneyRestore r,
  ) {
    const chartId = 'unit_06.step.008';
    _relocate(lesson, saved, r);
    final chart = r.responses[chartId];
    if (chart is Map) {
      final migrated = _soundChartState(chart);
      final resume = chart['resumeState'];
      if (resume is Map) migrated['resumeState'] = _soundChartState(resume);
      r.responses[chartId] = migrated;
    }
    if (!_finished(lesson, r) && lesson.steps[r.index].id == chartId) {
      // A completed question keeps the exact question that earned its
      // outcome. Unfinished work resumes the new question without carrying
      // the obsolete "Maris" answer into its assessment.
      r.current = _soundChartState(
        r.current,
        completed: chart is Map && chart['completed'] == true,
      );
    }
  }

  static Map<String, dynamic> _soundChartState(
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
      migrated['placements'] = Map<String, dynamic>.from(
        state['placements'] as Map,
      )..remove('maris_took');
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

  // ---- unit_02: plant builder ----------------------------------------------

  /// Steps 006-009 of older versions each built one plant part; v4 builds
  /// all four in one step.
  static Set<String> _builtParts(
    Lesson lesson,
    Map<String, dynamic> saved,
    JourneyRestore r,
  ) {
    final built = <String>{};
    final previousIds = List<String>.from(
      lesson.json[saved['version'] == 1
              ? 'legacyStepIds'
              : saved['version'] == 2
              ? 'previousStepIdsV2'
              : 'previousStepIdsV3']
          as List,
    );
    final oldId =
        saved['stepId'] ??
        (r.index < previousIds.length ? previousIds[r.index] : null);
    for (final entry in {
      6: 'roots',
      7: 'stem',
      8: 'leaf',
      9: 'flower',
    }.entries) {
      final id = 'unit_02.step.${entry.key.toString().padLeft(3, '0')}';
      if (r.responses[id]?['completed'] == true ||
          (oldId == id && r.current['done'] == true)) {
        built.add(entry.value);
      }
    }
    if (built.length == 4) {
      r.responses['unit_02.step.006'] = {
        'completed': true,
        'done': true,
        'touched': built.toList(),
      };
    } else {
      r.responses.remove('unit_02.step.006');
    }
    return built;
  }

  static void _unit02FromV1(
    Lesson lesson,
    Map<String, dynamic> saved,
    JourneyRestore r,
  ) {
    final built = lesson.version == 4 ? _builtParts(lesson, saved, r) : null;
    _mergedSteps(lesson, saved, r, built: built);
  }

  static void _unit02FromV2orV3(
    Lesson lesson,
    Map<String, dynamic> saved,
    JourneyRestore r,
  ) {
    final built = lesson.version == 4 ? _builtParts(lesson, saved, r) : null;
    final previousIds = List<String>.from(
      lesson.json[saved['version'] == 3
              ? 'previousStepIdsV3'
              : 'previousStepIdsV2']
          as List,
    );
    final oldId =
        saved['stepId'] ??
        (r.index < previousIds.length ? previousIds[r.index] : null);
    if (oldId == null && r.index >= previousIds.length) {
      r.index = lesson.steps.length;
      r.current = {};
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
      r.index = built.length == 4 ? 2 : 1;
      r.current = built.length == 4
          ? {}
          : {'touched': built.toList(), 'selected': built.toList()};
    } else if (located >= 0) {
      r.index = located;
    } else {
      // The four ungraded explanations now live in the first exploration.
      r.index = r.responses[lesson.steps.first.id]?['completed'] == true
          ? 1
          : 0;
      r.current = {};
    }
  }

  // ---- generic: steps merged from older steps ------------------------------

  /// A new step listing `legacyMergedFrom` is complete when every old step
  /// was; its outcome is the worst of theirs, so no score is inflated.
  static void _mergedSteps(
    Lesson lesson,
    Map<String, dynamic> saved,
    JourneyRestore r, {
    Set<String>? built,
  }) {
    final oldIds = List<String>.from(lesson.json['legacyStepIds'] as List);
    final oldId = r.index < oldIds.length ? oldIds[r.index] : null;
    for (final step in lesson.steps) {
      final merged = List<String>.from(
        (step.json['legacyMergedFrom'] as List?) ?? [],
      );
      if (merged.isEmpty ||
          !merged.every((id) => r.responses[id]?['completed'] == true)) {
        continue;
      }
      final outcomes = merged.map((id) => r.responses[id]?['outcome']).toList();
      final result = outcomes.contains('explained')
          ? 'explained'
          : outcomes.contains('afterHint')
          ? 'afterHint'
          : 'firstTry';
      r.responses[step.id] = {
        'completed': true,
        'done': true,
        'outcome': result,
        'placements': Map<String, dynamic>.from(step.answer!['value'] as Map),
        'feedback': step.explanation,
      };
    }
    // Keep old evidence; only active step IDs count towards the new result.
    r.index = lesson.steps.indexWhere(
      (s) => r.responses[s.id]?['completed'] != true,
    );
    if (r.index < 0) r.index = lesson.steps.length;
    final finished = _finished(lesson, r);
    if (finished || lesson.steps[r.index].id != oldId) r.current = {};
    if (!finished &&
        built != null &&
        lesson.steps[r.index].id == 'unit_02.step.006') {
      r.current = {'touched': built.toList(), 'selected': built.toList()};
    }
  }

  // ---- unit_03: compact "ourselves" v1 -> v2 -------------------------------

  static void _compactOurselves(
    Lesson lesson,
    Map<String, dynamic> saved,
    JourneyRestore r,
  ) {
    final legacyIds = List<String>.from(lesson.json['legacyStepIds'] as List);
    final oldId =
        saved['stepId'] ??
        (r.index < legacyIds.length ? legacyIds[r.index] : null);
    final oldCurrent = Map<String, dynamic>.from(r.current);
    final legacyObjectives = Map<String, dynamic>.from(
      lesson.json['legacyAssessmentObjectives'] as Map,
    );
    for (final next in lesson.steps) {
      final ids = List<String>.from(
        (next.json['legacyMergedFrom'] as List?) ?? [next.id],
      );
      final groups = List<List<dynamic>>.from(
        (next.json['legacyCompletionGroups'] as List?) ?? [ids],
      );
      final complete = groups.every(
        (group) => group.any((id) => r.responses[id]?['completed'] == true),
      );
      final evidence = <String, String>{};
      final placed = <String, String>{};
      final touched = <String>{};
      var mistakes = 0;
      for (final id in ids) {
        final record = r.responses[id] ?? (id == oldId ? oldCurrent : null);
        if (record is! Map) continue;
        final outcome = record['outcome'];
        final objective = legacyObjectives[id];
        if (outcome is String && next.assessedObjectives.contains(objective)) {
          const ranks = ['firstTry', 'afterHint', 'explained'];
          if (evidence[objective] == null ||
              ranks.indexOf(outcome) > ranks.indexOf(evidence[objective]!)) {
            evidence[objective as String] = outcome;
          }
        }
        final previousMistakes = record['mistakes'] as int? ?? 0;
        if (previousMistakes > mistakes) mistakes = previousMistakes;
        if (record['completed'] == true || record['done'] == true) {
          touched.addAll(
            List<String>.from(
              ((next.json['legacyTouchSources'] as Map?)?[id] as List?) ?? [],
            ),
          );
          final subset = !next.assessed || legacyObjectives.containsKey(id)
              ? ((next.json['legacyPlacementSources'] as Map?)?[id])
              : null;
          if (subset is Map) placed.addAll(Map<String, String>.from(subset));
        }
      }
      for (final objective in evidence.keys.toList()) {
        final contributors = ids.where(
          (id) => legacyObjectives[id] == objective,
        );
        if (!contributors.every(
          (id) => r.responses[id]?['completed'] == true,
        )) {
          evidence.remove(objective);
        }
      }
      final objectiveItems = next.json['objectiveItems'];
      if (objectiveItems is Map) {
        for (final objective in next.assessedObjectives) {
          if (evidence.containsKey(objective)) continue;
          for (final id in List<String>.from(
            (objectiveItems[objective] as List?) ?? [],
          )) {
            placed.remove(id);
          }
        }
      }
      if (complete) {
        r.responses[next.id] = {
          ...(r.responses[next.id] is Map
              ? Map<String, dynamic>.from(r.responses[next.id] as Map)
              : <String, dynamic>{}),
          'completed': true,
          'migrated': true,
          'done': true,
          'objectiveEvidence': evidence,
        };
      } else if (next.id == oldId) {
        r.responses[next.id] = {'completed': false, 'resumeState': oldCurrent};
      } else if (placed.isNotEmpty ||
          evidence.isNotEmpty ||
          mistakes > 0 ||
          touched.isNotEmpty) {
        r.responses[next.id] = {
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
    r.index = lesson.steps.indexWhere(
      (s) => r.responses[s.id]?['completed'] != true,
    );
    if (r.index < 0) r.index = lesson.steps.length;
    r.current = _finished(lesson, r)
        ? {}
        : lesson.steps[r.index].id == oldId
        ? oldCurrent
        : Map<String, dynamic>.from(
            (r.responses[lesson.steps[r.index].id]?['resumeState'] as Map?) ??
                {},
          );
  }
}
