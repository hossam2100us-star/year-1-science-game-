import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/lesson/lesson_player.dart';
import 'package:science_adventure/features/lesson/session.dart';

import 'setup_screen_test.dart' as helpers;

class FailBoundaryStore extends MemoryProgressStore {
  FailBoundaryStore(super.data);
  int writes = 0;
  @override
  Future<void> write(AppData value) async {
    if (++writes == 2) throw StateError('Disk unavailable');
    await super.write(value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonLibrary library;
  setUpAll(() async {
    library = await LessonLibrary.load();
    helpers.testCatalog = await helpers.loadTestCatalog();
  });
  AppData progress() {
    final lesson = library.lessons['unit_04']!;
    final session = LessonSession.fresh(lesson)..index = 2;
    session.responses[lesson.steps[0].id] = {
      'completed': true,
      'selected': lesson.steps[0].options.map((o) => o.id).toList(),
      'touched': lesson.steps[0].options.map((o) => o.id).toList(),
    };
    session.responses[lesson.steps[1].id] = {
      'completed': true,
      'done': true,
      'outcome': 'afterHint',
      'mistakes': 1,
      'placements': lesson.steps[1].answer!['value'],
    };
    session.current = {
      'selected': ['window'],
      'placements': {'window': 'paper'},
      'mistakes': 1,
    };
    return AppData(
      profile: const ChildProfile(name: 'Nour'),
      journeys: {'unit_04': session.toJson()},
    );
  }

  testWidgets(
    'Back and next preserve unfinished work, score and restart position',
    (t) async {
      final store = MemoryProgressStore(progress());
      final lesson = library.lessons['unit_04']!;
      const previous = ValueKey('lessonPrevious');
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      await helpers.tapVisible(t, find.byKey(previous));
      expect(store.data.journeys[lesson.id]!['index'], 1);
      await helpers.tapVisible(t, find.byKey(previous));
      expect(store.data.journeys[lesson.id]!['index'], 0);
      expect(t.widget<IconButton>(find.byKey(previous)).onPressed, isNull);
      await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
      expect(
        store.data.journeys[lesson.id]!['index'],
        1,
      ); // Do not skip reviewed screens.
      await t.pumpWidget(const SizedBox());
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
      final saved = store.data.journeys[lesson.id]!;
      expect(saved['index'], 2);
      expect(saved['current']['placements'], {'window': 'paper'});
      expect(saved['current']['mistakes'], 1);
      expect(saved['responses'][lesson.steps[1].id]['outcome'], 'afterHint');
      expect(store.data.attempts, isEmpty);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'A failed backward boundary save keeps the current screen and progress',
    (t) async {
      final store = FailBoundaryStore(progress());
      await helpers.mount(
        t,
        LessonPlayer(lesson: library.lessons['unit_04']!),
        store,
      );
      await helpers.tapVisible(t, find.byKey(const ValueKey('lessonPrevious')));
      expect(store.data.journeys['unit_04']!['index'], 2);
      expect(find.text('3/13'), findsOneWidget);
      expect(store.data.journeys['unit_04']!['current']['placements'], {
        'window': 'paper',
      });
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('Special plant experiments expose previous-screen navigation', (
    t,
  ) async {
    final lesson = library.lessons['unit_02']!;
    final session = LessonSession.fresh(lesson)..index = 3;
    final store = MemoryProgressStore(
      AppData(
        profile: const ChildProfile(name: 'Nour'),
        journeys: {lesson.id: session.toJson()},
      ),
    );
    await helpers.mount(t, LessonPlayer(lesson: lesson), store);
    await helpers.tapVisible(t, find.byKey(const ValueKey('lessonPrevious')));
    expect(store.data.journeys[lesson.id]!['index'], 2);
    await helpers.tapVisible(t, find.byKey(const ValueKey('lessonPrevious')));
    expect(store.data.journeys[lesson.id]!['index'], 1);
    expect(t.takeException(), isNull);
  });
}
