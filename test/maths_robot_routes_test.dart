import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/features/maths/maths_visual.dart';

/// Teacher review 6, finding 3.6: the robot drives the route the child has
/// chosen, before the answer is checked.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const route = '2 forwards, turn right, 2 forwards';
  Map<String, dynamic> grid(List<String> show) => {
    'type': 'robot',
    'cols': 4,
    'rows': 5,
    'start': [0, 2],
    'facing': 'up',
    'star': [2, 0],
    'routes': {
      route: ['F', 'F', 'R', 'F', 'F'],
      'turn right, 2 forwards, turn left, 2 forwards': [
        'R',
        'F',
        'F',
        'L',
        'F',
        'F',
      ],
    },
    'show': show,
  };
  final boundary = GlobalKey();

  Future<void> show(
    WidgetTester t,
    List<String> chosen, {
    bool still = false,
  }) => t.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: still),
        child: Center(
          child: RepaintBoundary(
            key: boundary,
            child: SizedBox(width: 300, child: MathsVisual(data: grid(chosen))),
          ),
        ),
      ),
    ),
  );

  Map<String, dynamic> painted(WidgetTester t) {
    final paint = t.widget<CustomPaint>(
      find.descendant(
        of: find.byType(RobotRoutes),
        matching: find.byType(CustomPaint),
      ),
    );
    return (paint.painter! as dynamic).data as Map<String, dynamic>;
  }

  // Opt-in images to look at the drive: REVIEW_ROBOT_DIR=<folder>.
  Future<void> capture(WidgetTester t, String name) async {
    final dir = Platform.environment['REVIEW_ROBOT_DIR'];
    if (dir == null) return;
    await t.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('choosing a route drives the robot along it', (t) async {
    await show(t, []);
    expect(painted(t)['robotRoute'], isNull, reason: 'waits at the start');
    await capture(t, 'robot-0-start');

    await show(t, [route]);
    await t.pump(const Duration(milliseconds: 1000));
    expect(painted(t)['robotRoute'], route);
    final halfway = painted(t)['robotProgress'] as double;
    expect(halfway, inExclusiveRange(0, 1));
    await capture(t, 'robot-1-driving');

    await t.pump(const Duration(milliseconds: 1600));
    expect(painted(t)['robotProgress'], 1.0);
    await capture(t, 'robot-2-at-star');

    // Unchoosing the route sends the robot back to the start.
    await show(t, []);
    await t.pump();
    expect(painted(t)['robotRoute'], isNull);
    expect(t.takeException(), isNull);
  });

  testWidgets('a resumed question shows the chosen route already driven', (
    t,
  ) async {
    await show(t, [route]);
    expect(painted(t)['robotRoute'], route);
    expect(painted(t)['robotProgress'], 1.0);
  });

  testWidgets('with animations off the robot is at the end at once', (t) async {
    await show(t, [], still: true);
    await show(t, [route], still: true);
    await t.pump();
    expect(painted(t)['robotProgress'], 1.0);
  });
}
