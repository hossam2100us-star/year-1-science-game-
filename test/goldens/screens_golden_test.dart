@Tags(['golden'])
library;

import 'dart:math';

import 'package:flame/flame.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/catalog.dart';
import 'package:science_adventure/core/design.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/world/subject_hub.dart';
import 'package:science_adventure/parent/parent_area.dart';
import 'package:science_adventure/parent/parent_gate.dart';
import 'package:science_adventure/startup/startup_problem.dart';

import '../setup_screen_test.dart' as helpers;

/// Visual regression baselines (AUD-010). Text uses the test font, so the
/// images capture layout, colour and spacing, not glyph shapes.
///
/// Update after an intended visual change:
///     flutter test --update-goldens --tags golden
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    helpers.testCatalog = await Catalog.load();
  });

  Future<void> sized(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final (label, size) in [
    ('tablet', const Size(1280, 800)),
    ('phone', const Size(800, 360)),
  ]) {
    testWidgets('subject hub ($label)', (tester) async {
      await sized(tester, size);
      await helpers.mount(
        tester,
        SubjectHub(onParentChanged: (_) {}),
        MemoryProgressStore(const AppData(profile: ChildProfile(name: 'Nour'))),
      );
      // Decode the artwork for real so every run captures the same frame.
      await tester.runAsync(() => Flame.images.load('maths-islands-v2.webp'));
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/images/islands-v2.webp'),
          tester.element(find.byType(SubjectHub)),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(SubjectHub),
        matchesGoldenFile('subject_hub_$label.png'),
      );
    });
  }

  testWidgets('parent gate', (tester) async {
    ParentGatePolicy.reset();
    await sized(tester, const Size(1280, 800));
    await tester.pumpWidget(
      MaterialApp(
        theme: adventureTheme(null),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ParentGateDialog(
                gender: ChildGender.girl,
                random: Random(7),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await expectLater(
      find.byType(ParentGateDialog),
      matchesGoldenFile('parent_gate.png'),
    );
  });

  testWidgets('parent area settings', (tester) async {
    await sized(tester, const Size(1280, 800));
    await helpers.mount(
      tester,
      const ParentArea(),
      MemoryProgressStore(const AppData(profile: ChildProfile(name: 'Nour'))),
    );
    await helpers.tapVisible(tester, find.text('الإعدادات'));
    await tester.pump(const Duration(seconds: 1));
    await expectLater(
      find.byType(ParentArea),
      matchesGoldenFile('parent_area_settings.png'),
    );
  });

  testWidgets('startup problem', (tester) async {
    await sized(tester, const Size(1280, 800));
    await tester.pumpWidget(
      StartupProblemApp(problem: StartupProblem.storageFull, onRetry: () {}),
    );
    await expectLater(
      find.byType(StartupProblemApp),
      matchesGoldenFile('startup_problem.png'),
    );
  });
}
