import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/image_budget.dart';

void main() {
  Future<ui.Image> tiny(WidgetTester tester) async {
    final recorder = ui.PictureRecorder();
    Canvas(
      recorder,
    ).drawRect(const Rect.fromLTWH(0, 0, 2, 2), Paint()..color = Colors.blue);
    return (await tester.runAsync(
      () => recorder.endRecording().toImage(2, 2),
    ))!;
  }

  testWidgets('a unit releases only the images it loaded (AUD-008)', (
    tester,
  ) async {
    Flame.images.add('shared.png', await tiny(tester));
    addTearDown(Flame.images.clearCache);

    await tester.pumpWidget(const UnitImageScope(child: SizedBox()));
    Flame.images.add('unit-only.png', await tiny(tester));
    expect(Flame.images.containsKey('unit-only.png'), isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(Flame.images.containsKey('unit-only.png'), isFalse);
    expect(Flame.images.containsKey('shared.png'), isTrue);
  });

  testWidgets('the Flutter image cache is bounded', (tester) async {
    ImageBudget.configure();
    expect(
      PaintingBinding.instance.imageCache.maximumSizeBytes,
      ImageBudget.flutterCacheBytes,
    );
  });
}
