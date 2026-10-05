import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/domain/journey/journey_migrations.dart';

JourneyRestore run(Lesson lesson, Map<String, dynamic> saved) {
  final restore = JourneyRestore(
    index: saved['index'] as int,
    responses: Map<String, dynamic>.from(saved['responses'] as Map),
    current: Map<String, dynamic>.from(saved['current'] as Map),
  );
  JourneyMigrations.apply(lesson, saved, restore);
  return restore;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonLibrary library;
  setUpAll(() async => library = await LessonLibrary.load());

  test('which saved versions can be continued (AUD-007)', () {
    final unit02 = library.lessons['unit_02']!;
    final unit03 = library.lessons['unit_03']!;
    final unit06 = library.lessons['unit_06']!;
    for (final (lesson, version, expected) in [
      (unit02, 4, true),
      (unit02, 3, true),
      (unit02, 2, true),
      (unit02, 1, true),
      (unit02, 5, false),
      (unit03, 1, true),
      (unit03, 0, false),
      (unit06, 1, true),
      (library.lessons['unit_04']!, 0, false),
      (unit02, null, false),
      (unit02, 'x', false),
    ]) {
      expect(
        JourneyMigrations.canRestore(lesson, version),
        expected,
        reason: '${lesson.id} v$version',
      );
    }
  });

  test('an unknown version is refused instead of guessed', () {
    final lesson = library.lessons['unit_04']!;
    expect(
      () => run(lesson, {
        'version': 0,
        'index': 0,
        'responses': <String, dynamic>{},
        'current': <String, dynamic>{},
      }),
      throwsStateError,
    );
  });

  test('same version relocates by step id when steps moved', () {
    final lesson = library.lessons['unit_04']!;
    final target = lesson.steps[3].id;
    final r = run(lesson, {
      'version': lesson.version,
      'index': 0,
      'stepId': target,
      'responses': <String, dynamic>{},
      'current': <String, dynamic>{},
    });
    expect(r.index, 3);
  });

  test('sound chart v1: obsolete "Maris" answers leave unfinished work', () {
    final lesson = library.lessons['unit_06']!;
    const chart = 'unit_06.step.008';
    final index = lesson.steps.indexWhere((s) => s.id == chart);
    final r = run(lesson, {
      'version': 1,
      'index': index,
      'stepId': chart,
      'responses': {
        chart: {
          'completed': false,
          'placements': {'maris_took': 'quiet', 'david_drum': 'loud'},
          'selected': ['maris_took', 'david_drum'],
          'feedback': 'old',
        },
      },
      'current': {
        'selected': ['maris_took'],
      },
    });
    final saved = r.responses[chart] as Map;
    expect(saved['placements'], {'david_drum': 'loud'});
    expect(saved['selected'], ['david_drum']);
    expect(saved['feedback'], '');
    expect(r.current['selected'], isEmpty);
  });

  test('sound chart v1: a finished answer keeps its original question', () {
    final lesson = library.lessons['unit_06']!;
    const chart = 'unit_06.step.008';
    final r = run(lesson, {
      'version': 1,
      'index': 0,
      'responses': {
        chart: {'completed': true, 'done': true, 'outcome': 'firstTry'},
      },
      'current': <String, dynamic>{},
    });
    expect((r.responses[chart] as Map)['legacySoundChart'], isTrue);
    expect((r.responses[chart] as Map)['outcome'], 'firstTry');
  });

  test('plant builder v1-v3: four built parts become one completed step', () {
    final lesson = library.lessons['unit_02']!;
    for (final version in [1, 2, 3]) {
      final r = run(lesson, {
        'version': version,
        'index': 0,
        'responses': {
          for (final n in [6, 7, 8, 9])
            'unit_02.step.00$n': {'completed': true},
        },
        'current': <String, dynamic>{},
      });
      expect(
        (r.responses['unit_02.step.006'] as Map)['touched'],
        unorderedEquals(['roots', 'stem', 'leaf', 'flower']),
        reason: 'v$version',
      );
    }
  });
}
