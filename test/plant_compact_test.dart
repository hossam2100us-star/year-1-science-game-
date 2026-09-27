import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/features/biology/session.dart';
import 'package:science_adventure/features/plants/plant_lab_stage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Lesson lesson;
  setUpAll(
    () async => lesson = (await LessonLibrary.load()).lessons['unit_02']!,
  );
  test(
    'Version two journeys keep their current activity, evidence and completion',
    () {
      final ids = List<String>.from(lesson.json['previousStepIdsV2']);
      for (var i = 0; i <= ids.length; i++) {
        final saved = {
          'version': 2,
          'attemptId': 'preserved',
          'index': i,
          'stepId': i < ids.length ? ids[i] : null,
          'responses': {
            for (final id in ids.take(i)) id: {'completed': true},
          },
          'current': {'prediction': 'preserved'},
        };
        expect(LessonSession.canRestore(lesson, saved), isTrue);
        final restored = LessonSession.restore(lesson, saved);
        expect(restored.attemptId, 'preserved');
        if (i == ids.length) {
          expect(restored.finished, isTrue);
        } else if (i >= 1 && i <= 4) {
          expect(restored.step.id, 'unit_02.step.006');
          expect(restored.current, isEmpty);
        } else if (i >= 5 && i <= 8) {
          expect(restored.step.id, 'unit_02.step.006');
          expect(restored.current['touched'], hasLength(i - 5));
        } else {
          expect(restored.step.id, ids[i]);
          expect(restored.current, saved['current']);
        }
      }
    },
  );
  testWidgets(
    'Render the combined plant exploration with enlarged selected part',
    (t) async {
      t.view.physicalSize = const Size(1000, 850);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(lesson.steps.first.title),
                    Text(lesson.steps.first.json['partDescriptions']['roots']),
                    PlantLabStage(
                      step: lesson.steps.first,
                      selected: {'roots'},
                      touched: {'roots'},
                      placements: {},
                      done: false,
                      assembled: {},
                      onItem: (_) {},
                      onPlace: (_, _) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await t.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await t.pump();
      expect(t.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await t.runAsync(() async {
        final picture = await boundary.toImage();
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        await File('tmp/plant-compact.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
      await t.pumpWidget(const SizedBox());
    },
  );
}
