import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/plants/bean_experiment.dart';
import 'package:science_adventure/features/plants/bean_model.dart';

import '../test/setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonStep step;
  setUpAll(() async {
    helpers.testCatalog = await helpers.loadTestCatalog();
    step = (await LessonLibrary.load()).lessons['unit_02']!.steps.firstWhere(
      (s) => s.json['experiment'] == 'bean',
    );
    await Future.wait([
      Flame.images.load('bean-stages-v1.webp'),
      Flame.images.load('greenhouse-v1.webp'),
    ]);
  });
  test(
    'A prediction is necessary, immutable after testing, and never graded',
    () {
      var p = BeanProgress();
      expect(p.watered().frame, 0);
      p = p.predict('leaf').watered();
      expect(p.frame, 1);
      expect(p.predict('root').prediction, 'leaf');
      p = p.watered().watered().watered();
      expect(p.frame, 3);
      expect(p.finished, isTrue);
      expect(BeanProgress.restore(p.toJson()).prediction, 'leaf');
      expect(BeanProgress.restore({'frame': 3}).frame, 0);
      expect(step.frames.map((f) => f['label']), [
        'Day 1',
        'Day 4',
        'Day 7',
        'Day 8',
      ]);
      expect(step.assessed, isFalse);
    },
  );
  for (final size in [const Size(800, 360), const Size(1280, 800)]) {
    testWidgets(
      'Watering follows a saved guess through all four book days at $size',
      (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final saved = <Map<String, dynamic>>[];
        var finished = false;
        final store = MemoryProgressStore(
          const AppData(profile: ChildProfile(name: 'Nour')),
        );
        await helpers.mount(
          t,
          BeanExperiment(
            step: step,
            initial: {},
            onSave: (j) async {
              saved.add(Map.from(j));
            },
            onFinished: () async {
              finished = true;
            },
          ),
          store,
          scale: size.width == 800 ? 2 : 1,
        );
        await t.pump(const Duration(milliseconds: 100));
        expect(
          t
              .widget<FilledButton>(find.byKey(const ValueKey('bean-water')))
              .onPressed,
          isNull,
        );
        await helpers.tapVisible(t, find.byKey(const ValueKey('bean-leaf')));
        expect(saved.last, {'prediction': 'leaf', 'frame': 0});
        for (var frame = 1; frame <= 3; frame++) {
          await helpers.tapVisible(t, find.byKey(const ValueKey('bean-water')));
          await t.pump(const Duration(milliseconds: 1000));
          await t.pump();
          expect(saved.last['frame'], frame);
          expect(saved.last['prediction'], 'leaf');
        }
        await helpers.tapVisible(t, find.byKey(const ValueKey('bean-finish')));
        expect(finished, isTrue);
        expect(store.data.attempts, isEmpty);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.pump();
      },
    );
  }
  testWidgets('A failed prediction save cannot reveal a later day', (t) async {
    final store = MemoryProgressStore(const AppData(profile: ChildProfile()));
    await helpers.mount(
      t,
      BeanExperiment(
        step: step,
        initial: {},
        onSave: (j) async {
          throw StateError('disk full');
        },
        onFinished: () async {},
      ),
      store,
    );
    await t.pump(const Duration(milliseconds: 100));
    await helpers.tapVisible(t, find.byKey(const ValueKey('bean-root')));
    expect(
      t
          .widget<FilledButton>(find.byKey(const ValueKey('bean-water')))
          .onPressed,
      isNull,
    );
    expect(find.text('Day 4'), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
