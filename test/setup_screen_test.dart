import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/main.dart';

void main() {
  for (final size in [const Size(800, 360), const Size(1280, 800)]) {
    testWidgets('Setup is usable at $size with enlarged text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const SetupWelcomeScreen(),
        ),
      );
      expect(tester.takeException(), isNull);
      final button = find.text('Try a tap');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(find.text('Your screen is ready!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
