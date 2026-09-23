import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/garden/garden_adventure.dart';
import 'package:science_adventure/features/garden/garden_model.dart';
import 'package:science_adventure/features/garden/garden_scene.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GardenContent content;
  setUpAll(() async {
    helpers.testCatalog = await helpers.loadTestCatalog();
    content = GardenContent(
      (await LessonLibrary.load()).lessons['unit_01']!.json['garden'],
    );
    await Flame.images.load('garden-v2.png');
  });
  test('Garden practice preserves first, hinted, and explained decisions without inflating unit scores', () {
    final round = GardenRound(version: content.version);
    final cat = content.item('cat');
    round.select('cat');
    expect(round.answer(cat, false), isNull);
    expect(round.feedback, isFalse);
    expect(round.mistakes, 1);
    final resumed = GardenRound.restore(round.toJson(), content);
    expect(resumed.answer(cat, true), DecisionOutcome.afterHint);
    expect(resumed.answer(cat, true), isNull);
    expect(resumed.results.length, 1);
    resumed.next();
    resumed.select('cloud');
    expect(resumed.answer(content.item('cloud'), true), isNull);
    expect(
      resumed.answer(content.item('cloud'), true),
      DecisionOutcome.explained,
    );
    resumed.next();
    resumed.select('tree');
    expect(
      resumed.answer(content.item('tree'), true),
      DecisionOutcome.firstTry,
    );
    final replay = resumed.replay();
    expect(replay.results, isEmpty);
    expect(replay.history.single['results'], hasLength(3));
  });
  for (final size in [const Size(800, 360), const Size(1280, 800)]) {
    testWidgets(
      'The same selected picture drives the question, hints and saved discovery at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = MemoryProgressStore(
          const AppData(
            profile: ChildProfile(name: 'Nour', gender: ChildGender.girl),
          ),
        );
        await helpers.mount(
          tester,
          GardenAdventure(content: content),
          store,
          scale: size.width == 800 ? 2 : 1,
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Tree'), findsNothing);
        await helpers.tapVisible(
          tester,
          find.byKey(const ValueKey('garden-cat')),
        );
        expect(find.text('Is the cat alive?'), findsOneWidget);
        expect(find.byKey(const ValueKey('garden-explanation')), findsNothing);
        await helpers.tapVisible(
          tester,
          find.byKey(const ValueKey('garden-not-alive')),
        );
        expect(find.byKey(const ValueKey('garden-hint')), findsOneWidget);
        expect(find.byKey(const ValueKey('garden-explanation')), findsNothing);
        await helpers.tapVisible(
          tester,
          find.byKey(const ValueKey('garden-not-alive')),
        );
        expect(
          find.byKey(const ValueKey('garden-explanation')),
          findsOneWidget,
        );
        await helpers.tapVisible(
          tester,
          find.byKey(const ValueKey('garden-next')),
        );
        expect(
          store.data.journeys[GardenRound.storageKey]!['results']['cat'],
          'explained',
        );
        expect(store.data.attempts, isEmpty);
        expect(find.text('1 / 7'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );
  }
  testWidgets(
    'Every garden target completes and replay retains practice history',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryProgressStore(
        const AppData(profile: ChildProfile(name: 'Nour')),
      );
      await helpers.mount(tester, GardenAdventure(content: content), store);
      await tester.pump(const Duration(milliseconds: 100));
      for (final item in content.items) {
        await helpers.tapVisible(
          tester,
          find.byKey(ValueKey('garden-${item.id}')),
        );
        await helpers.tapVisible(
          tester,
          find.byKey(
            ValueKey(item.alive ? 'garden-alive' : 'garden-not-alive'),
          ),
        );
        await helpers.tapVisible(
          tester,
          find.byKey(const ValueKey('garden-next')),
        );
      }
      expect(find.text('Great exploring, Nour!'), findsOneWidget);
      expect(
        store.data.journeys[GardenRound.storageKey]!['results'],
        hasLength(7),
      );
      expect(store.data.attempts, isEmpty);
      await helpers.tapVisible(tester, find.text('Play again'));
      expect(
        store.data.journeys[GardenRound.storageKey]!['history'],
        hasLength(1),
      );
      expect(find.text('0 / 7'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test(
    'Every target stays inside the illustration and meets the touch minimum',
    () {
      for (final size in [const Size(800, 360), const Size(1280, 800)]) {
        final targets = gardenRects(size, touch: true);
        for (final rect in targets.values) {
          expect(rect.width, greaterThanOrEqualTo(64));
          expect(rect.height, greaterThanOrEqualTo(64));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
        }
      }
    },
  );
}
