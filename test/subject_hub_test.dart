import 'package:flutter/material.dart';
import 'package:flame/flame.dart';

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/world/subject_hub.dart';
import 'package:science_adventure/features/world/world_map.dart';

import 'setup_screen_test.dart' as helpers;
import 'support/review_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Legacy science save migrates without changing progress or profile', () {
    final old = {
      'schemaVersion': 1,
      'profile': const ChildProfile(name: 'Nour').toJson(),
      'settings': const AppSettings().toJson(),
      'dailySeconds': {'2026-09-28': 120},
      'attempts': [
        UnitAttempt(
          unitId: 'unit_02',
          completedAt: DateTime(2026),
          objectives: {'roots': DecisionOutcome.afterHint},
          completed: true,
          effortStars: 3,
          attemptId: 'original',
        ).toJson(),
      ],
      'journeys': {
        'unit_02': {'index': 4, 'prediction': 'saved'},
      },
    };
    final loaded = AppData.fromJson(old);
    expect(loaded.profile!.name, 'Nour');
    expect(loaded.journeys, old['journeys']);
    expect(loaded.attempts.single.attemptId, 'original');
    final updated = loaded.copyWith(
      otherSubjects: {
        'math': {
          'journeys': {
            'unit_02': {'index': 9},
          },
        },
      },
    );
    final scienceUpdate = updated.copyWith(
      journeys: {
        'unit_02': {'index': 5},
      },
    );
    final restored = AppData.fromJson(scienceUpdate.toJson());
    expect(restored.toJson()['schemaVersion'], 3);
    expect(restored.journeys['unit_02']!['index'], 5);
    expect(restored.otherSubjects['math']!['journeys']['unit_02']['index'], 9);
    expect(
      restored.attempts.single.objectives['roots'],
      DecisionOutcome.afterHint,
    );
    expect(restored.dailySeconds, old['dailySeconds']);
  });
  testWidgets(
    'Science opens from subjects and returns without changing progress',
    (t) async {
      t.view.physicalSize = const Size(1280, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      helpers.testCatalog = await helpers.loadTestCatalog();
      for (final font in ['Nunito', 'Fredoka', 'Cairo']) {
        await (FontLoader(
          font,
        )..addFont(rootBundle.load('assets/fonts/$font.ttf'))).load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      final store = MemoryProgressStore(
        const AppData(
          profile: ChildProfile(name: 'Nour'),
          journeys: {
            'unit_02': {'index': 3},
          },
        ),
      );
      final before = store.data.toJson();
      final pictureKey = GlobalKey();
      await t.runAsync(
        () => Flame.images.loadAll([
          'maths-islands-v2.webp',
          'english-islands-v1.webp',
        ]),
      );
      await helpers.mount(
        t,
        RepaintBoundary(
          key: pictureKey,
          child: SubjectHub(onParentChanged: (_) {}),
        ),
        store,
      );
      await t.runAsync(
        () => precacheImage(
          const AssetImage('assets/images/islands-v2.webp'),
          pictureKey.currentContext!,
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      await t.pumpAndSettle();
      await t.runAsync(() async {
        final image =
            await (pictureKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await saveReviewImage('subject-hub.png', bytes);
        image.dispose();
      });
      expect(find.byKey(const ValueKey('subject-science')), findsOneWidget);
      expect(find.byKey(const ValueKey('subject-maths')), findsOneWidget);
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('subject-science')),
      );
      await t.pumpAndSettle();
      expect(find.byType(WorldMap), findsOneWidget);
      await t.tap(find.byTooltip('Subjects'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('subject-science')), findsOneWidget);
      expect(store.data.toJson(), before);
      expect(t.takeException(), isNull);
    },
  );
}
