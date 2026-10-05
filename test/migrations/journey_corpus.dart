import 'package:science_adventure/content/lesson.dart';

/// Deterministic saved journeys covering every content migration that
/// `LessonSession.restore` performs today (AUD-007 characterization).
///
/// Each case is a saved journey as it could exist on a device: a content
/// version, an index into that version's step list, optional `stepId`,
/// responses for earlier steps, and the in-progress `current` state.
class JourneyCase {
  JourneyCase(this.name, this.lessonId, this.saved);
  final String name, lessonId;
  final Map<String, dynamic> saved;
}

const _outcomes = ['firstTry', 'afterHint', 'explained'];

List<String> _ids(Lesson lesson, int savedVersion) {
  if (savedVersion == lesson.version) {
    return [for (final s in lesson.steps) s.id];
  }
  final key = switch ((lesson.id, savedVersion)) {
    ('unit_02', 2) => 'previousStepIdsV2',
    ('unit_02', 3) => 'previousStepIdsV3',
    ('unit_06', 1) => null,
    _ => 'legacyStepIds',
  };
  if (key == null) return [for (final s in lesson.steps) s.id];
  return List<String>.from(lesson.json[key] as List);
}

Map<String, dynamic> _response(String id, int n, {bool varied = false}) => {
  'completed': true,
  'done': true,
  'outcome': varied ? _outcomes[n % 3] : 'firstTry',
  'mistakes': varied ? n % 3 : 0,
  'touched': ['$id.touch'],
  'feedback': 'saved feedback',
};

Iterable<JourneyCase> _versionCases(Lesson lesson, int savedVersion) sync* {
  final ids = _ids(lesson, savedVersion);
  for (var index = 0; index <= ids.length; index++) {
    for (final withStepId in [true, false]) {
      for (final pattern in ['none', 'before', 'varied']) {
        for (final working in [false, true]) {
          final responses = <String, dynamic>{
            if (pattern != 'none')
              for (var i = 0; i < index; i++)
                ids[i]: _response(ids[i], i, varied: pattern == 'varied'),
          };
          final current = <String, dynamic>{
            if (working && index < ids.length) ...{
              'done': index.isEven,
              'touched': ['a', 'b'],
              'selected': ['a'],
              'placements': {'a': 'x'},
              'outcome': _outcomes[index % 3],
              'mistakes': index % 2,
              'feedback': 'working feedback',
            },
          };
          yield JourneyCase(
            '${lesson.id} v$savedVersion→v${lesson.version} i$index '
            '${withStepId ? 'stepId' : 'noStepId'} $pattern'
            '${working ? ' working' : ''}',
            lesson.id,
            {
              'version': savedVersion,
              'attemptId': '${lesson.id}-attempt',
              'index': index,
              if (withStepId) 'stepId': index < ids.length ? ids[index] : null,
              'responses': responses,
              'current': current,
            },
          );
        }
      }
    }
  }
}

/// Extra unit_06 v1 sound-chart states: completed, needing correction, and
/// unfinished answers that still mention the removed "Maris" option.
Iterable<JourneyCase> _soundChartCases(Lesson lesson) sync* {
  const chart = 'unit_06.step.008';
  final ids = [for (final s in lesson.steps) s.id];
  final chartIndex = ids.indexOf(chart);
  final states = <String, Map<String, dynamic>>{
    'completed': {
      'completed': true,
      'done': true,
      'outcome': 'firstTry',
      'placements': {'maris_took': 'quiet', 'david_drum': 'loud'},
    },
    'needsCorrection': {
      'completed': false,
      'needsCorrection': true,
      'placements': {'maris_took': 'quiet', 'david_drum': 'loud'},
      'selected': ['maris_took', 'david_drum'],
      'reviewItems': ['maris_took'],
      'feedback': 'old',
    },
    'unfinished': {
      'completed': false,
      'placements': {'maris_took': 'quiet'},
      'selected': ['maris_took'],
      'feedback': 'old',
      'resumeState': {
        'placements': {'maris_took': 'quiet'},
        'selected': ['maris_took', 'x'],
        'done': false,
      },
    },
  };
  for (final entry in states.entries) {
    for (final atChart in [true, false]) {
      final index = atChart ? chartIndex : chartIndex + 1;
      yield JourneyCase(
        'unit_06 v1→v2 chart ${entry.key} ${atChart ? 'at chart' : 'after'}',
        lesson.id,
        {
          'version': 1,
          'attemptId': 'unit_06-attempt',
          'index': index,
          'stepId': index < ids.length ? ids[index] : null,
          'responses': {
            for (var i = 0; i < chartIndex; i++) ids[i]: _response(ids[i], i),
            chart: Map<String, dynamic>.from(entry.value),
          },
          'current': atChart
              ? {
                  'placements': {'maris_took': 'quiet'},
                  'selected': ['maris_took'],
                  'reviewItems': ['maris_took', 'y'],
                  'feedback': 'current',
                  'done': entry.key == 'completed',
                }
              : <String, dynamic>{},
        },
      );
    }
  }
}

List<JourneyCase> journeyCorpus(LessonLibrary library) {
  final cases = <JourneyCase>[];
  for (final lesson in library.lessons.values) {
    // Same-version restores for every lesson.
    cases.addAll(_versionCases(lesson, lesson.version));
  }
  final unit02 = library.lessons['unit_02']!;
  for (final v in [1, 2, 3]) {
    cases.addAll(_versionCases(unit02, v));
  }
  cases.addAll(_versionCases(library.lessons['unit_03']!, 1));
  final unit06 = library.lessons['unit_06']!;
  cases.addAll(_versionCases(unit06, 1));
  cases.addAll(_soundChartCases(unit06));
  return cases;
}
