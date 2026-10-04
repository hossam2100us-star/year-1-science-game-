import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/biology/lesson_player.dart';
import 'package:science_adventure/features/biology/session.dart';
import 'package:science_adventure/features/science/earth_collection.dart';
import 'package:science_adventure/features/science/science_picture.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Lesson lesson;
  setUpAll(() async {
    lesson = (await LessonLibrary.load()).lessons['unit_08']!;
    helpers.testCatalog = await helpers.loadTestCatalog();
    for (final name in ['Nunito', 'Fredoka', 'Cairo']) {
      await (FontLoader(
        name,
      )..addFont(rootBundle.load('assets/fonts/$name.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final file in scienceAtlases.keys) {
      await Flame.images.load(file);
    }
  });

  void size(WidgetTester t, Size value) {
    t.view.physicalSize = value;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  MemoryProgressStore start(int index) {
    final session = LessonSession.fresh(lesson)..index = index;
    for (final step in lesson.steps.take(index)) {
      session.responses[step.id] = {'completed': true};
    }
    return MemoryProgressStore(
      AppData(
        profile: const ChildProfile(name: 'Nour'),
        journeys: {lesson.id: session.toJson()},
      ),
    );
  }

  Map current(MemoryProgressStore store) =>
      store.data.journeys[lesson.id]!['current'];
  Future<void> tap(WidgetTester t, String key) =>
      helpers.tapVisible(t, find.byKey(ValueKey(key)));
  Future<void> reopen(
    WidgetTester t,
    MemoryProgressStore store, {
    double scale = 1,
  }) async {
    await t.pumpWidget(const SizedBox());
    await helpers.mount(t, LessonPlayer(lesson: lesson), store, scale: scale);
  }

  Future<void> drag(WidgetTester t, String source, String target) async {
    final from = find.byKey(ValueKey(source)),
        to = find.byKey(ValueKey(target));
    await t.ensureVisible(from);
    await t.pump();
    final gesture = await t.startGesture(t.getCenter(from));
    await gesture.moveBy(const Offset(0, -25));
    await t.pump();
    await t.ensureVisible(to);
    await t.pump();
    await gesture.moveTo(t.getCenter(to));
    await t.pump();
    await gesture.up();
    await t.pump(const Duration(milliseconds: 300));
  }

  Future<void> capture(WidgetTester t, GlobalKey key, String name) =>
      t.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final picture = await boundary.toImage();
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        await Directory('tmp/earth-collections').create(recursive: true);
        await File('tmp/earth-collections/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });

  testWidgets(
    'Soil locations and magnifier preserve all five independent discoveries',
    (t) async {
      size(t, const Size(1280, 900));
      final store = start(5), boundary = GlobalKey();
      await helpers.mount(
        t,
        RepaintBoundary(
          key: boundary,
          child: LessonPlayer(lesson: lesson),
        ),
        store,
      );
      expect(
        find.byKey(const ValueKey('lab-find-small_stones')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('lab-find-worm')), findsNothing);
      await tap(t, 'lab-soil-spot-2');
      expect(current(store)['lab']?['visited'], isNull);
      await tap(t, 'lab-find-worm');
      expect(current(store)['lab']['visited'], ['worm']);
      await reopen(t, store);
      expect(
        find.byKey(const ValueKey('lab-find-small_stones')),
        findsOneWidget,
      );
      await drag(t, 'lab-soil-lens', 'soil-lens-target-small_stones');
      expect(current(store)['lab']['visited'], contains('small_stones'));
      expect(find.byKey(const ValueKey('lessonNext')), findsNothing);
      await tap(t, 'lab-find-dead_leaf');
      await reopen(t, store);
      expect(
        find.byKey(const ValueKey('lab-find-tiny_insect')),
        findsOneWidget,
      );
      await tap(t, 'lab-find-tiny_insect');
      await tap(t, 'lab-find-sand');
      expect(
        current(store)['lab']['visited'],
        containsAll(lesson.steps[5].options.map((item) => item.id)),
      );
      expect(current(store)['freeDone'], true);
      expect(current(store)['outcome'], isNull);
      expect(current(store)['mistakes'], 0);
      await reopen(t, store);
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      expect(current(store)['lab']['visited'].length, 5);
      await tap(t, 'lab-find-small_stones');
      expect(current(store)['lab']['visited'].length, 5);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Beach tap and drag hide collected litter and survive reopening',
    (t) async {
      size(t, const Size(360, 760));
      final store = start(11), boundary = GlobalKey();
      await helpers.mount(
        t,
        RepaintBoundary(
          key: boundary,
          child: LessonPlayer(lesson: lesson),
        ),
        store,
        scale: 1.5,
      );
      await capture(t, boundary, 'beach-phone');
      final rectangles = [
        for (final item in lesson.steps[11].options)
          t.getRect(find.byKey(ValueKey('lab-find-${item.id}'))),
        t.getRect(find.byKey(const ValueKey('lab-litter-basket'))),
      ];
      for (var i = 0; i < rectangles.length; i++) {
        final rect = rectangles[i];
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(360));
        for (var j = i + 1; j < rectangles.length; j++) {
          expect(rect.overlaps(rectangles[j]), false);
        }
      }
      await drag(t, 'lab-find-plastic_bag', 'lab-litter-basket');
      expect(current(store)['lab']['visited'], ['plastic_bag']);
      expect(find.byKey(const ValueKey('lab-find-plastic_bag')), findsNothing);
      await reopen(t, store, scale: 1.5);
      expect(find.byKey(const ValueKey('lab-find-plastic_bag')), findsNothing);
      await tap(t, 'lab-find-paper');
      await tap(t, 'lab-find-bottle');
      expect(current(store)['freeDone'], true);
      expect(current(store)['outcome'], isNull);
      await reopen(t, store);
      for (final item in lesson.steps[11].options) {
        expect(find.byKey(ValueKey('lab-find-${item.id}')), findsNothing);
      }
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Own-rule rock groups keep original IDs, resume, rename, and allow drag changes',
    (t) async {
      size(t, const Size(360, 900));
      final store = start(10), boundary = GlobalKey();
      await helpers.mount(
        t,
        RepaintBoundary(
          key: boundary,
          child: LessonPlayer(lesson: lesson),
        ),
        store,
        scale: 1.5,
      );
      const first = 'My first group', second = 'My second group';
      final bins = [
        for (final group in [first, second])
          t.getRect(
            find.byKey(ValueKey('lab-group-large_smooth_stone-$group')),
          ),
      ];
      expect(bins.first.overlaps(bins.last), false);
      for (final rect in bins) {
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(360));
      }
      expect(
        t
            .widget<EarthRockPicture>(
              find.descendant(
                of: find.byKey(const ValueKey('lab-find-large_smooth_stone')),
                matching: find.byType(EarthRockPicture),
              ),
            )
            .index,
        0,
      );
      await capture(t, boundary, 'rocks-phone');
      await tap(t, 'lab-group-large_smooth_stone-$second');
      expect(current(store)['lab']['large_smooth_stone'], second);
      expect(find.byKey(const ValueKey('lab-find-dark_stone')), findsOneWidget);
      await reopen(t, store, scale: 1.5);
      expect(find.byKey(const ValueKey('lab-find-dark_stone')), findsOneWidget);
      await tap(t, 'lab-rock-name-groups');
      await t.enterText(
        find.byKey(const ValueKey('rock-group-name-0')),
        'Rough',
      );
      await t.enterText(
        find.byKey(const ValueKey('rock-group-name-1')),
        'Smooth',
      );
      await tap(t, 'rock-group-names-save');
      expect(current(store)['lab']['groupLabels'], {
        first: 'Rough',
        second: 'Smooth',
      });
      expect(current(store)['lab']['large_smooth_stone'], second);
      expect(current(store)['lab']['visited'], ['large_smooth_stone']);
      for (final entry in [
        ('dark_stone', first),
        ('small_rough_stone', second),
        ('light_stone', first),
      ]) {
        await tap(t, 'lab-group-${entry.$1}-${entry.$2}');
      }
      expect(current(store)['freeDone'], true);
      expect(current(store)['outcome'], isNull);
      expect(current(store)['mistakes'], 0);
      for (var i = 0; i < 3; i++) {
        await tap(t, 'lab-rock-previous');
      }
      await drag(t, 'lab-find-large_smooth_stone', 'rock-bin-$first');
      expect(current(store)['lab']['large_smooth_stone'], first);
      expect(current(store)['lab']['visited'].length, 4);
      expect(current(store)['freeDone'], true);
      await reopen(t, store);
      expect(current(store)['lab']['groupLabels'], {
        first: 'Rough',
        second: 'Smooth',
      });
      expect(find.byKey(const ValueKey('lessonNext')), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
