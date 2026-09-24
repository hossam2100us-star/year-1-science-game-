import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/adventure_progress.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/features/garden/garden_model.dart';
import 'package:science_adventure/features/biology/lesson_player.dart';
import 'package:science_adventure/features/world/world_map.dart';

import 'setup_screen_test.dart' as helpers;

Map<String, dynamic> legacyGarden() => {
  'version': 1,
  'results': {for (final id in gardenDiscoveryIds) id: 'firstTry'},
};
AppData withGarden(Map<String, dynamic> garden) => AppData(
  profile: const ChildProfile(name: 'Nour'),
  journeys: {GardenRound.storageKey: garden},
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GardenContent content;
  setUpAll(() async {
    helpers.testCatalog = await helpers.loadTestCatalog();
    content = GardenContent(
      (await LessonLibrary.load()).lessons['unit_01']!.json['garden'],
    );
  });
  test('Legacy completion unlocks Plants, but does not fabricate an assessment or skip other levels', () {
    expect(content.items.map((i) => i.id).toSet(), gardenDiscoveryIds);
    final data = AppData.fromJson(withGarden(legacyGarden()).toJson());
    expect(helpers.testCatalog.levelUnlocked(0, 1, data), isTrue);
    expect(helpers.testCatalog.levelUnlocked(0, 2, data), isFalse);
    expect(helpers.testCatalog.islandUnlocked(1, data), isFalse);
    expect(data.attempts, isEmpty);
    expect(data.isComplete('unit_01'), isFalse);
    expect(data.isAdventureComplete('unit_01'), isTrue);
    expect(
      helpers.testCatalog.levelUnlocked(0, 1, data.resetProgress()),
      isFalse,
    );
  });
  test('Partial or invalid discoveries do not unlock Plants', () {
    for (final results in [
      <String, String>{},
      {
        for (final id in gardenDiscoveryIds.where((id) => id != 'cloud'))
          id: 'firstTry',
      },
      {for (final id in gardenDiscoveryIds) id: 'unknown'},
      {for (var i = 0; i < 7; i++) 'invented-$i': 'firstTry'},
    ]) {
      expect(
        helpers.testCatalog.levelUnlocked(
          0,
          1,
          withGarden({'version': 1, 'results': results}),
        ),
        isFalse,
      );
    }
  });
  test('Historical completion stays unlocked across restarts and more than 20 replays', () {
    var round = GardenRound.restore({
      'version': 1,
      'results': <String, String>{},
      'history': [
        {'results': legacyGarden()['results']},
      ],
    }, content);
    for (var i = 0; i < 25; i++) {
      round = GardenRound.restore(round.replay().toJson(), content);
      expect(withGarden(round.toJson()).isAdventureComplete('unit_01'), isTrue);
    }
    expect(round.results, isEmpty);
    expect(round.history, hasLength(20));
  });
  testWidgets(
    'Existing garden save shows a star and Plants opens from the island path',
    (tester) async {
      tester.view.physicalSize = const Size(824, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await helpers.mount(
        tester,
        const IslandScreen(index: 0),
        MemoryProgressStore(withGarden(legacyGarden())),
      );
      final first = find.byKey(const ValueKey('level-unit_01'));
      final plants = find.byKey(const ValueKey('level-unit_02'));
      expect(
        find.descendant(of: first, matching: find.text('Play again')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: plants, matching: find.byIcon(Icons.lock_rounded)),
        findsNothing,
      );
      await helpers.tapVisible(tester, plants);
      expect(find.byType(LessonRoute), findsOneWidget);
      expect(
        tester.widget<LessonRoute>(find.byType(LessonRoute)).id,
        'unit_02',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  for (final spec in [
    (const Size(824, 860), 1.0),
    (const Size(824, 860), 1.3),
    (const Size(800, 360), 2.0),
    (const Size(1280, 800), 1.0),
  ]) {
    testWidgets(
      'Island captions never cover artwork at ${spec.$1}, scale ${spec.$2}',
      (tester) async {
        tester.view.physicalSize = spec.$1;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await helpers.mount(
          tester,
          WorldMap(onParentChanged: (_) {}),
          MemoryProgressStore(
            const AppData(profile: ChildProfile(name: 'Nour')),
          ),
          scale: spec.$2,
        );
        for (var i = 0; i < 4; i++) {
          final art = tester.getRect(find.byKey(ValueKey('island-art-$i')));
          final caption = tester.getRect(
            find.byKey(ValueKey('island-caption-$i')),
          );
          expect(caption.top, greaterThanOrEqualTo(art.bottom));
          expect(art.width, greaterThan(200));
          expect(art.height, greaterThan(100));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );
  }
}
