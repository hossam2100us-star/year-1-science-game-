import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/domain/merge/journey_merge.dart';

Map<String, dynamic> journey(
  int index,
  Map<String, String> outcomes, {
  String attempt = 'unit_02-1',
  Map<String, dynamic>? current,
}) => {
  'version': 3,
  'attemptId': attempt,
  'index': index,
  'stepId': 'unit_02.step.00$index',
  'responses': {
    for (final e in outcomes.entries)
      e.key: {'outcome': e.value, 'completed': true},
  },
  'current': current ?? {'outcome': null},
};

String outcome(Map<String, dynamic> j, String step) =>
    ((j['responses'] as Map)[step] as Map)['outcome'] as String;

void main() {
  group('lesson journeys', () {
    test(
      'keeps every finished step from both devices and the further position',
      () {
        final phone = journey(3, {'s1': 'firstTry', 's2': 'afterHint'});
        final tablet = journey(5, {
          's1': 'firstTry',
          's3': 'explained',
          's4': 'firstTry',
        });
        final merged = mergeJourney(phone, tablet);
        expect(merged['index'], 5);
        expect(
          (merged['responses'] as Map).keys,
          containsAll(['s1', 's2', 's3', 's4']),
        );
      },
    );

    test('never moves the child backwards, whichever copy is "local"', () {
      final ahead = journey(6, {'s1': 'firstTry'});
      final behind = journey(2, {'s1': 'firstTry'});
      expect(mergeJourney(ahead, behind)['index'], 6);
      expect(mergeJourney(behind, ahead)['index'], 6);
    });

    test("keeps the server's outcome for a step both devices answered (first recorded)", () {
      final local = journey(4, {'s2': 'firstTry'});
      final server = journey(3, {'s2': 'explained'});
      expect(outcome(mergeJourney(local, server), 's2'), 'explained');
    });

    test("takes the unfinished step of the copy that is further along", () {
      final local = journey(
        4,
        {},
        current: {
          'outcome': null,
          'selected': ['cat'],
        },
      );
      final server = journey(
        2,
        {},
        current: {
          'outcome': null,
          'selected': ['car'],
        },
      );
      expect((mergeJourney(local, server)['current'] as Map)['selected'], [
        'cat',
      ]);
    });

    test('does not mix two different runs through the lesson', () {
      final first = journey(5, {'s1': 'explained'}, attempt: 'unit_02-1');
      final restarted = journey(2, {'s1': 'firstTry'}, attempt: 'unit_02-2');
      final merged = mergeJourney(restarted, first);
      expect(merged['attemptId'], 'unit_02-1');
      expect(outcome(merged, 's1'), 'explained');
    });

    test('is monotonic and loses no finished step (randomised)', () {
      final random = Random(7);
      for (var i = 0; i < 2000; i++) {
        Map<String, String> answers() => {
          for (var s = 0; s < 6; s++)
            if (random.nextBool())
              's$s': ['firstTry', 'afterHint', 'explained'][random.nextInt(3)],
        };
        final a = journey(random.nextInt(8), answers());
        final b = journey(random.nextInt(8), answers());
        final merged = mergeJourney(a, b);
        expect(merged['index'], max(a['index'] as int, b['index'] as int));
        final keys = {
          ...(a['responses'] as Map).keys,
          ...(b['responses'] as Map).keys,
        };
        expect((merged['responses'] as Map).keys.toSet(), keys);
        for (final step in (b['responses'] as Map).keys) {
          expect(outcome(merged, step as String), outcome(b, step));
        }
      }
    });
  });

  group('other progress records', () {
    test('discovery results from both devices are kept', () {
      final local = {
        'version': 1,
        'results': {'cat': 'firstTry', 'car': 'afterHint'},
      };
      final server = {
        'version': 1,
        'results': {'cat': 'explained', 'bird': 'firstTry'},
      };
      final merged = mergeJourney(local, server);
      expect(merged['results'], {
        'cat': 'explained',
        'car': 'afterHint',
        'bird': 'firstTry',
      });
    });

    test('a key only one side has is never dropped', () {
      final merged = mergeRecords(
        {
          'a': 1,
          'nested': {'x': 1},
        },
        {
          'b': 2,
          'nested': {'y': 2},
        },
      );
      expect(merged, {
        'a': 1,
        'b': 2,
        'nested': {'x': 1, 'y': 2},
      });
    });
  });
}
