import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/mascot.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/parent/parent_gate.dart';

import 'setup_screen_test.dart' show gateAnswer;

void main() {
  late DateTime now;
  setUp(() {
    ParentGatePolicy.reset();
    now = DateTime(2026, 10, 4, 9);
    ParentGatePolicy.clock = () => now;
  });
  tearDown(ParentGatePolicy.reset);

  Future<bool?> Function() openGate(
    WidgetTester tester, {
    ChildGender? gender,
  }) {
    bool? result;
    return () async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await parentGate(context, gender: gender),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump(const Duration(milliseconds: 400));
      return result;
    };
  }

  String challenge(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('parent-challenge'))).data!;

  Future<void> answer(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(TextField), value);
    await tester.tap(find.text('كمّل • Continue'));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('a wrong answer always brings a new problem', (tester) async {
    await openGate(tester)();
    for (var i = 0; i < ParentGatePolicy.maxFailures - 1; i++) {
      final before = challenge(tester);
      await answer(tester, '0');
      expect(challenge(tester), isNot(before));
      expect(find.byType(ParentGateDialog), findsOneWidget);
    }
  });

  testWidgets('three failures lock the gate for 30 seconds, even after '
      'reopening it', (tester) async {
    await openGate(tester)();
    for (var i = 0; i < ParentGatePolicy.maxFailures; i++) {
      await answer(tester, '0');
    }
    expect(find.byKey(const ValueKey('parent-gate-wait')), findsOneWidget);
    final correct = gateAnswer(tester);
    await answer(tester, correct);
    expect(find.byType(ParentGateDialog), findsOneWidget, reason: 'locked');

    await tester.tap(find.text('رجوع • Back'));
    await tester.pump(const Duration(milliseconds: 400));
    await openGate(tester)();
    expect(find.byKey(const ValueKey('parent-gate-wait')), findsOneWidget);

    now = now.add(ParentGatePolicy.cooldown);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('parent-gate-wait')), findsNothing);
    await answer(tester, gateAnswer(tester));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ParentGateDialog), findsNothing);
  });

  testWidgets('products need an adult: two-digit by one-digit', (tester) async {
    await openGate(tester)();
    for (var i = 0; i < 2; i++) {
      final values = RegExp(r'\d+')
          .allMatches(challenge(tester))
          .map((m) => int.parse(m.group(0)!))
          .toList();
      expect(values[0], inInclusiveRange(11, 19));
      expect(values[1], inInclusiveRange(3, 9));
      await answer(tester, '0');
    }
  });

  testWidgets('the gate owl matches the child (AUD-018)', (tester) async {
    await openGate(tester, gender: ChildGender.girl)();
    expect(
      tester.widget<ScientistOwl>(find.byType(ScientistOwl)).gender,
      ChildGender.girl,
    );
  });
}
