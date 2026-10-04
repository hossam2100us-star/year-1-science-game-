import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/domain/canonical_json.dart';
import 'package:science_adventure/domain/journey/journey_state.dart';

import 'journey_characterization_test.dart' show restoredJson;
import 'journey_corpus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every saved and migrated journey round-trips exactly (AUD-003)',
    () async {
      final library = await LessonLibrary.load();
      var checked = 0;
      for (final c in journeyCorpus(library)) {
        final restored = restoredJson(library.lessons[c.lessonId]!, c.saved);
        for (final json in [
          c.saved,
          if (restored['canRestore'] != false) restored,
        ]) {
          final typed = JourneyState.fromJson(json);
          expect(
            canonicalJson(typed.toJson()),
            canonicalJson(json),
            reason: c.name,
          );
          checked++;
        }
      }
      expect(checked, greaterThan(8000));
    },
  );

  Map<String, dynamic> journey([Map<String, dynamic> current = const {}]) => {
    'version': 2,
    'attemptId': 'a',
    'index': 1,
    'stepId': 's',
    'responses': {
      's0': {'completed': true, 'outcome': 'afterHint'},
    },
    'current': current,
  };

  test('typed accessors read the saved values', () {
    final typed = JourneyState.fromJson(
      journey({
        'selected': ['a'],
        'placements': {'a': 'x'},
        'mistakes': 2,
        'outcome': null,
        'lab': {'step': 3},
        'futureField': [1, 2],
      }),
    );
    expect(typed.version, 2);
    expect(typed.responses['s0']!.outcome, 'afterHint');
    expect(typed.responses['s0']!.isCompleted, isTrue);
    expect(typed.current.selected, ['a']);
    expect(typed.current.placements, {'a': 'x'});
    expect(typed.current.mistakes, 2);
    expect(typed.current.extras['lab'], {'step': 3});
    expect(typed.current.extras['futureField'], [1, 2]);
    expect(typed.current.toJson().containsKey('outcome'), isTrue);
  });

  test('wrong types are rejected at the boundary, not later in a scene', () {
    for (final bad in <Map<String, dynamic>>[
      {...journey(), 'index': '1'},
      {...journey(), 'version': null},
      {...journey(), 'responses': []},
      journey({'outcome': 'lucky'}),
      journey({'mistakes': 'two'}),
      journey({
        'selected': [1],
      }),
      journey({
        'placements': {'a': 1},
      }),
      journey({
        'objectiveEvidence': {'o': 'guess'},
      }),
      journey({'resumeState': 'x'}),
    ]) {
      expect(
        () => JourneyState.fromJson(bad),
        throwsFormatException,
        reason: '$bad',
      );
    }
  });
}
