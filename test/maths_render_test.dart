import 'dart:ui' as ui;

import 'package:flame/flame.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/catalog.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/design.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/lesson/lesson_player.dart';
import 'package:science_adventure/features/lesson/session.dart';
import 'package:science_adventure/features/maths/maths_visual.dart';

import 'setup_screen_test.dart' as helpers;
import 'support/review_images.dart';

/// Every bundled Maths screen uses the production player and a real resume
/// record. Review PNGs remain opt-in and never enter the repository.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalog science;
  late Catalog maths;
  late LessonLibrary library;

  setUpAll(() async {
    science = await Catalog.load();
    maths = await Catalog.loadMaths();
    library = await LessonLibrary.loadAll();
    for (final font in ['Nunito', 'Fredoka', 'Cairo']) {
      await (FontLoader(
        font,
      )..addFont(rootBundle.load('assets/fonts/$font.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> capture(WidgetTester t, GlobalKey key, String name) async {
    if (!writeReviewImages) return;
    await t.pump();
    await t.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final picture = await boundary.toImage();
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      await saveReviewImage('maths/$name.png', bytes);
      picture.dispose();
    });
  }

  Future<void> mount(
    WidgetTester t,
    Widget child,
    MemoryProgressStore store,
  ) async {
    await t.runAsync(
      () => Flame.images.loadAll([
        'maths-islands-v2.webp',
        'maths-objects-v2.webp',
        'maths-backdrops-v2.webp',
      ]),
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
          catalogProvider.overrideWithValue(science),
          mathsCatalogProvider.overrideWith((ref) async => maths),
          lessonLibraryProvider.overrideWith((ref) async => library),
          narrationProvider.overrideWith((ref) => helpers.SilentNarration()),
        ],
        child: MaterialApp(
          theme: adventureTheme(store.data.profile),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.5),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: child,
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 100));
  }

  for (final (label, size) in [
    ('phone', const Size(390, 844)),
    ('tablet', const Size(1280, 800)),
  ]) {
    testWidgets('Every Maths lesson step renders at $label with 1.5x text', (
      t,
    ) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      var rendered = 0;
      for (final lesson in library.lessons.values.where(
        (lesson) => lesson.subject == 'maths',
      )) {
        final representative = lesson.steps.indexWhere(
          (step) => step.json['mathVisual'] is Map,
        );
        for (var index = 0; index < lesson.steps.length; index++) {
          final session = LessonSession.fresh(lesson)..index = index;
          final store = MemoryProgressStore(
            const AppData(profile: ChildProfile(name: 'Nour'))
                .withSubjectProgress(
                  'maths',
                  journeys: {lesson.id: session.toJson()},
                ),
          );
          final pictureKey = GlobalKey();
          await mount(
            t,
            RepaintBoundary(
              key: pictureKey,
              child: LessonPlayer(lesson: lesson),
            ),
            store,
          );
          expect(
            t.takeException(),
            isNull,
            reason: '$label / ${lesson.steps[index].id}',
          );
          if (index == (representative < 0 ? 0 : representative)) {
            if (writeReviewImages &&
                find.byType(MathsVisual).evaluate().isNotEmpty) {
              await t.ensureVisible(find.byType(MathsVisual).first);
              await t.pump();
            }
            await capture(t, pictureKey, '${lesson.id}_$label');
          }
          if (index == 0 && lesson.id == 'math_unit_01') {
            await capture(t, pictureKey, 'first_workshop_$label');
          }
          rendered++;
          await t.pumpWidget(const SizedBox());
          await t.pump();
        }
      }
      expect(
        rendered,
        library.lessons.values
            .where((lesson) => lesson.subject == 'maths')
            .fold<int>(0, (count, lesson) => count + lesson.steps.length),
      );
    });
  }

  Map<String, dynamic>? findDiagram(Object? value, String type) {
    if (value is Map) {
      if (value['type'] == type) return Map<String, dynamic>.from(value);
      for (final child in value.values) {
        final found = findDiagram(child, type);
        if (found != null) return found;
      }
    } else if (value is List) {
      for (final child in value) {
        final found = findDiagram(child, type);
        if (found != null) return found;
      }
    }
    return null;
  }

  testWidgets('Bird chart retains the book\'s two-unit scale', (t) async {
    t.view.physicalSize = const Size(1280, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final step = library.lessons['math_charts']!.steps.firstWhere(
      (step) => (step.json['mathVisual'] as Map?)?['style'] == 'bar',
    );
    final pictureKey = GlobalKey();
    await mount(
      t,
      Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: pictureKey,
            child: SizedBox(
              width: 500,
              child: MathsVisual(
                data: Map<String, dynamic>.from(step.json['mathVisual']),
              ),
            ),
          ),
        ),
      ),
      MemoryProgressStore(const AppData(profile: ChildProfile(name: 'Nour'))),
    );
    for (final tick in ['0', '2', '4', '6', '8', '10']) {
      expect(find.text(tick), findsOneWidget);
    }
    for (final tick in ['1', '3', '5', '7', '9']) {
      expect(find.text(tick), findsNothing);
    }
    expect(t.takeException(), isNull);
    await capture(t, pictureKey, 'bird_chart_scale');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Book clock, fraction, chart, count and shape diagrams render', (
    t,
  ) async {
    t.view.physicalSize = const Size(1280, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    for (final type in ['clock', 'fraction', 'chart', 'count', 'shape']) {
      final diagram = findDiagram(
        library.lessons.values
            .where((lesson) => lesson.subject == 'maths')
            .map((lesson) => lesson.json)
            .toList(),
        type,
      );
      expect(diagram, isNotNull, reason: 'The book supplies a $type diagram.');
      final pictureKey = GlobalKey();
      await mount(
        t,
        Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: pictureKey,
              child: SizedBox(
                width: 500,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: MathsVisual(data: diagram!),
                  ),
                ),
              ),
            ),
          ),
        ),
        MemoryProgressStore(const AppData(profile: ChildProfile(name: 'Nour'))),
      );
      expect(t.takeException(), isNull, reason: type);
      await capture(t, pictureKey, 'diagram_$type');
      await t.pumpWidget(const SizedBox());
    }
  });
}
