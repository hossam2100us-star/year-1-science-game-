import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/features/lesson/lesson_completion.dart';

void main() {
  const right = DecisionOutcome.firstTry;
  test('quiz practice goes to the first unit with a missed objective', () {
    final all = {
      for (final id in ['01', '02', '03', '04', '05', '08'])
        'quiz01.$id': right,
    };
    expect(practiceUnitFor(all), 'unit_03');
    expect(
      practiceUnitFor({...all, 'quiz01.08': DecisionOutcome.afterHint}),
      'unit_01',
    );
    expect(
      practiceUnitFor({...all, 'quiz01.04': DecisionOutcome.explained}),
      'unit_02',
    );
    expect(practiceUnitFor(const {}), 'unit_01');
  });
}
