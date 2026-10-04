import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/features/science/science_picture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Flame.images.load('physics-atlas-v1.webp');
  });

  testWidgets('Magnet can still be dragged by its open center', (t) async {
    var started = false;
    const magnet = SciencePicture('magnet', height: 140);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Draggable<String>(
              data: 'magnet',
              onDragStarted: () => started = true,
              feedback: const Material(
                color: Colors.transparent,
                child: magnet,
              ),
              childWhenDragging: const SizedBox(width: 175, height: 140),
              child: magnet,
            ),
          ),
        ),
      ),
    );
    await t.pump();
    final handle = find.byType(Draggable<String>);
    final gesture = await t.startGesture(t.getCenter(handle));
    await gesture.moveBy(const Offset(45, 15));
    await t.pump();
    expect(started, true);
    expect(
      find.descendant(of: handle, matching: find.byType(SciencePicture)),
      findsNothing,
    );
    expect(find.byType(SciencePicture), findsOneWidget);
    await gesture.cancel();
    await t.pump();
    expect(
      find.descendant(of: handle, matching: find.byType(SciencePicture)),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('Painted magnet has no paper rectangle or filled U opening', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 280);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await t.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: const SizedBox(
              width: 280,
              height: 223,
              child: SciencePicture('magnet', height: 223),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    await t.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final rendered = await boundary.toImage();
      final bytes = (await rendered.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      int channel(int x, int y, int c) =>
          bytes[(y * rendered.width + x) * 4 + c];

      // Real rendered pixels must reveal the scene around AND inside the U.
      for (final point in [
        const Offset(5, 5),
        const Offset(275, 5),
        const Offset(5, 218),
        const Offset(275, 218),
        const Offset(35, 110),
        const Offset(140, 140),
        const Offset(140, 180),
        const Offset(140, 220),
      ]) {
        expect(
          channel(point.dx.toInt(), point.dy.toInt(), 3),
          0,
          reason: '$point',
        );
      }
      // Preserve the source's two painted halves and visible metal tips.
      expect(channel(70, 100, 3), 255);
      expect(channel(70, 100, 0), greaterThan(channel(70, 100, 2)));
      expect(channel(205, 100, 3), 255);
      expect(channel(205, 100, 2), greaterThan(channel(205, 100, 0)));
      expect(channel(80, 204, 3), 255);
      expect(channel(204, 198, 3), 255);
      rendered.dispose();
    });
    expect(t.takeException(), isNull);
  });
}
