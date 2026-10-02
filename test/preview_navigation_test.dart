import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/biology/lesson_player.dart';
import 'package:science_adventure/features/plants/plant_lab_preview.dart';
import 'package:science_adventure/features/world/world_map.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonLibrary library;
  setUpAll(() async {
    library = await LessonLibrary.load();
    helpers.testCatalog = await helpers.loadTestCatalog();
    for (final file in ['materials-atlas-v1.webp', 'science-details-v1.webp']) {
      await Flame.images.load(file);
    }
  });
  for (final complete in [false, true]) {
    testWidgets(
      'Direct preview returns to its island and map; complete=$complete',
      (t) async {
        t.view.physicalSize = const Size(1280, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final original = MemoryProgressStore(
          const AppData(
            profile: ChildProfile(name: 'Nour'),
            journeys: {
              'unit_02': {'index': 3},
            },
          ),
        );
        final before = original.data.toJson();
        await helpers.mount(
          t,
          ProviderScope(
            overrides: [
              lessonLibraryProvider.overrideWith((ref) async => library),
            ],
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProviderScope(
                        overrides: [
                          lessonLibraryProvider.overrideWith(
                            (ref) async => library,
                          ),
                        ],
                        child: const PlantLabPreview(
                          lessonId: 'unit_04',
                          initialStep: 12,
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Outer app home'),
                ),
              ),
            ),
          ),
          original,
        );
        await helpers.tapVisible(t, find.text('Outer app home'));
        await t.pump(const Duration(milliseconds: 500));
        await t.runAsync(
          () => precacheImage(
            const AssetImage('assets/images/islands-v2.webp'),
            t.element(find.byType(LessonPlayer)),
          ),
        );
        if (complete) {
          final answers =
              library.lessons['unit_04']!.steps.last.answer!['value'] as Map;
          for (final entry in answers.entries) {
            await helpers.tapVisible(
              t,
              find.byKey(ValueKey('science-item-${entry.key}')),
            );
            await helpers.tapVisible(
              t,
              find.byKey(ValueKey('science-target-${entry.value}')),
            );
          }
          await helpers.tapVisible(t, find.text('Check my discovery'));
          await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
          expect(find.text('Back to my island'), findsOneWidget);
          await helpers.tapVisible(t, find.text('Back to my island'));
        } else {
          await helpers.tapVisible(t, find.byTooltip('Save and return to map'));
        }
        await t.pump(const Duration(milliseconds: 500));
        expect(find.byType(IslandScreen), findsOneWidget);
        final island = t.widget<IslandScreen>(find.byType(IslandScreen));
        expect(island.index, 1);
        expect(find.text('Outer app home'), findsNothing);
        final scope = ProviderScope.containerOf(
          t.element(find.byType(IslandScreen)),
        );
        expect(scope.read(appProvider).profile!.name, 'Nour');
        expect(
          scope.read(appProvider).isAdventureComplete('unit_04'),
          complete,
        );
        expect(original.data.toJson(), before);
        // Preview access does not manufacture prerequisites or change real locks.
        expect(scope.read(appProvider).isAdventureComplete('quiz_01'), false);
        expect(helpers.testCatalog.islandUnlocked(1, original.data), false);
        await helpers.tapVisible(t, find.byTooltip('My map'));
        await t.pump(const Duration(milliseconds: 500));
        expect(find.byType(WorldMap), findsOneWidget);
        expect(find.text('Outer app home'), findsNothing);
        expect(
          ProviderScope.containerOf(t.element(find.byType(WorldMap)))
              .read(appProvider)
              .profile!
              .name,
          'Nour',
        );
        await helpers.tapVisible(t, find.byKey(const ValueKey('island-1')));
        await helpers.tapVisible(
          t,
          find.byKey(const ValueKey('level-unit_04')),
        );
        await t.pump(const Duration(milliseconds: 500));
        expect(find.byType(LessonPlayer), findsOneWidget);
        expect(original.data.toJson(), before);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.pump();
      },
    );
  }
}
