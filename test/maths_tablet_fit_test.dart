import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
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
import 'package:science_adventure/features/maths/maths_art.dart';

import 'setup_screen_test.dart' as helpers;

/// On a 1280×800 tablet the status and navigation bars leave about 716 of
/// the 800 (teacher review 4). Before the setting became a strip, 90 of the
/// 255 Maths questions had answers below the action strip, up to 464 too
/// low. With the app's theme and the chart answers beside their chart
/// (teacher review 6), every question fits a 1280×800 browser page, and on
/// the tablet the rest are at most a short scroll away.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonLibrary maths;
  late Catalog science;
  setUpAll(() async {
    maths = await LessonLibrary.loadMaths();
    science = await Catalog.load();
    for (final font in ['Nunito', 'Fredoka', 'Cairo']) {
      await (FontLoader(
        font,
      )..addFont(rootBundle.load('assets/fonts/$font.ttf'))).load();
    }
  });

  // The Android tablet between its system bars, and the web app in a
  // 1280×800 browser page (as in teacher review 6).
  for (final (label, bars) in [
    ('the Android tablet', true),
    ('a 1280×800 browser page', false),
  ]) {
    testWidgets('every Maths question shows its answers on $label', (t) async {
      t.view.physicalSize = const Size(1280, 800);
      t.view.devicePixelRatio = 1;
      if (bars) {
        t.view.padding = const FakeViewPadding(top: 24, bottom: 60);
        t.view.viewPadding = const FakeViewPadding(top: 24, bottom: 60);
      }
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPadding);
      addTearDown(t.view.resetViewPadding);
      await t.runAsync(() async {
        for (final asset in [mathsObjectAsset, mathsBackdropAsset]) {
          await Flame.images.load(asset);
        }
      });
      var questions = 0;
      final below = <String, double>{};
      for (final lesson in maths.lessons.values) {
        for (var index = 0; index < lesson.steps.length; index++) {
          final step = lesson.steps[index];
          if (step.json['mathWorkshop'] != null) continue;
          final session = LessonSession.fresh(lesson)..index = index;
          final store = MemoryProgressStore(
            const AppData(profile: ChildProfile(name: 'Nour'))
                .withSubjectProgress(
                  'maths',
                  journeys: {lesson.id: session.toJson()},
                ),
          );
          await t.pumpWidget(const SizedBox());
          await t.pumpWidget(
            ProviderScope(
              overrides: [
                storeProvider.overrideWithValue(store),
                catalogProvider.overrideWithValue(science),
                lessonLibraryProvider.overrideWith((ref) async => maths),
                narrationProvider.overrideWith(
                  (ref) => helpers.SilentNarration(),
                ),
              ],
              // The app's own theme: without it the buttons are smaller and
              // chart answers looked as if they fit (teacher review 6).
              child: MaterialApp(
                theme: adventureTheme(store.data.profile),
                home: LessonPlayer(lesson: lesson),
              ),
            ),
          );
          await t.pump();
          await t.pump(const Duration(milliseconds: 100));
          final options = find.byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'maths-option-',
                ),
          );
          if (options.evaluate().isEmpty) continue;
          questions++;
          final strip = t.getRect(
            find.byKey(const ValueKey('lesson-controls')),
          );
          final lowest = options
              .evaluate()
              .map((element) => t.getRect(find.byWidget(element.widget)).bottom)
              .reduce((a, b) => a > b ? a : b);
          if (lowest > strip.top) below[step.id] = lowest - strip.top;
        }
      }
      expect(questions, greaterThan(250));
      // Charts put their answers beside the chart on a wide screen (teacher
      // review 6): none may need scrolling. A few other questions on the
      // tablet (its bars take 84 of the 800) are at most a short scroll away.
      final charts = below.keys.where(
        (id) => maths.lessons.values
            .expand((lesson) => lesson.steps)
            .any((s) => s.id == id && s.json['mathVisual']?['type'] == 'chart'),
      );
      expect(charts, isEmpty, reason: 'chart answers below the strip: $below');
      expect(
        below.length,
        lessThanOrEqualTo(bars ? 6 : 0),
        reason: 'answers below the strip: $below',
      );
      for (final MapEntry(key: id, value: distance) in below.entries) {
        expect(distance, lessThanOrEqualTo(40), reason: id);
      }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump();
    });
  }
}
