import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/catalog.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/lesson/lesson_player.dart';
import 'package:science_adventure/features/lesson/session.dart';

import '../setup_screen_test.dart' as helpers;

class _Voice extends helpers.SilentNarration {
  final spoken = <String>[];
  @override
  Future<void> speak(String text) async => spoken.add(text);
}

/// The last step of a lesson: the result is recorded once, spoken, and no
/// failed-save message appears. Narration used to read the current scene
/// after the session had moved past its last step, which threw a RangeError
/// that the player reported as a failed save (found during the Maths work).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonLibrary library;
  late Catalog catalog;
  setUpAll(() async {
    library = await LessonLibrary.load();
    catalog = await Catalog.load();
  });

  for (final id in ['quiz_01', 'unit_06']) {
    testWidgets('finishing $id speaks the result without a save error', (
      t,
    ) async {
      t.view.physicalSize = const Size(1280, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final lesson = library.lessons[id]!;
      final session = LessonSession.fresh(lesson)
        ..index = lesson.steps.length - 1;
      for (final step in lesson.steps) {
        session.responses[step.id] = {
          'completed': true,
          if (step.assessed) 'outcome': 'firstTry',
        };
      }
      final store = MemoryProgressStore(
        AppData(
          profile: const ChildProfile(name: 'Nour'),
          journeys: {id: session.toJson()},
        ),
      );
      final voice = _Voice();
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            catalogProvider.overrideWithValue(catalog),
            lessonLibraryProvider.overrideWith((ref) async => library),
            narrationProvider.overrideWith((ref) => voice),
          ],
          child: MaterialApp(home: LessonPlayer(lesson: lesson)),
        ),
      );
      await t.pump();
      await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
      await t.pump(const Duration(seconds: 1));

      expect(find.byType(SnackBar), findsNothing);
      expect(store.data.attempts.where((a) => a.unitId == id), hasLength(1));
      expect(store.data.journeys.containsKey(id), isFalse);
      expect(
        voice.spoken.last,
        lesson.quiz ? contains('out of ten') : startsWith('Great effort'),
      );
      expect(t.takeException(), isNull);
    });
  }
}
