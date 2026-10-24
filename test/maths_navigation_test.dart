import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/catalog.dart';
import 'package:science_adventure/content/curriculum.dart';
import 'package:science_adventure/content/school_years.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/design.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/biology/sticker_album.dart';
import 'package:science_adventure/features/lesson/lesson_player.dart';
import 'package:science_adventure/features/lesson/session.dart';
import 'package:science_adventure/features/maths/maths_visual.dart';
import 'package:science_adventure/features/world/subject_hub.dart';
import 'package:science_adventure/features/world/world_map.dart';
import 'package:science_adventure/l10n/parent_strings.dart';
import 'package:science_adventure/parent/unit_report.dart';

import 'setup_screen_test.dart' as helpers;
import 'maths_workshop_test.dart' as workshops;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalog maths, english;
  late LessonLibrary library;

  setUpAll(() async {
    helpers.testCatalog = await Catalog.load();
    maths = await Catalog.loadMaths();
    english = Catalog.fromJson(
      jsonDecode(
        await rootBundle.loadString('assets/content/english_catalog.json'),
      ) as Map<String, dynamic>,
    );
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

  Future<void> mount(
    WidgetTester t,
    Widget child,
    MemoryProgressStore store, {
    double scale = 1,
  }) async {
    await t.runAsync(
      () => Flame.images.loadAll([
        'maths-islands-v2.webp',
        'english-islands-v1.webp',
        'maths-objects-v2.webp',
        'maths-backdrops-v2.webp',
        'maths-things-v1.webp',
      ]),
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
          catalogProvider.overrideWithValue(helpers.testCatalog),
          narrationProvider.overrideWith((ref) => helpers.SilentNarration()),
          mathsCatalogProvider.overrideWith((ref) async => maths),
          // The English card reads its catalogue like Maths; a file read
          // inside the test's fake clock does not finish after the first
          // test, so the loaded catalogue is given.
          subjectCatalogProvider.overrideWith(
            (ref, subject) async => switch (subject.curriculum) {
              mathsCurriculum => maths,
              englishCurriculum => english,
              _ => helpers.testCatalog,
            },
          ),
          lessonLibraryProvider.overrideWith((ref) async => library),
        ],
        child: MaterialApp(
          theme: adventureTheme(store.data.profile),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: child,
        ),
      ),
    );
    await t.pump();
  }

  test('Maths catalogue publishes every lesson with isolated locks', () {
    expect(maths.subject, 'maths');
    expect(maths.islands, hasLength(4));
    expect(
      maths.levels.map((l) => l.id).toSet(),
      LessonLibrary.mathsIds.toSet(),
    );
    expect(
      library.lessons.values.where((l) => l.subject == 'science'),
      hasLength(13),
    );
    expect(
      library.lessons.values.where((l) => l.subject == 'maths'),
      hasLength(22),
    );
    final boundary = maths.islands.first.levels.last.id;
    final attempt = UnitAttempt(
      unitId: boundary,
      completedAt: DateTime(2026),
      objectives: const {},
      completed: true,
      effortStars: 3,
    );
    final scienceOnly = AppData(attempts: [attempt]);
    expect(maths.islandUnlocked(1, scienceOnly), isFalse);
    final mathsComplete = scienceOnly.withSubjectProgress(
      'maths',
      attempts: [attempt],
    );
    expect(maths.islandUnlocked(1, mathsComplete), isTrue);
    expect(mathsComplete.attempts, scienceOnly.attempts);
  });

  for (final (size, scale) in [
    (const Size(390, 844), 1.5),
    (const Size(800, 360), 1.5),
    (const Size(1280, 800), 1.5),
    (const Size(390, 844), 2.0),
  ]) {
    testWidgets('Maths navigation and resume fit $size with $scale text', (
      t,
    ) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final store = MemoryProgressStore(
        const AppData(
          profile: ChildProfile(name: 'Nour'),
          journeys: {
            'unit_02': {'index': 3},
          },
        ),
      );
      final science = store.data.journeys;
      await mount(t, SubjectHub(onParentChanged: (_) {}), store, scale: scale);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: 'Subject hub at $size');
      await helpers.tapVisible(t, find.byKey(const ValueKey('subject-maths')));
      expect(t.takeException(), isNull, reason: 'Maths map at $size');
      expect(find.byType(WorldMap), findsOneWidget);
      expect(
        t.widget<WorldMap>(find.byType(WorldMap)).catalogue!.subject,
        'maths',
      );
      await helpers.tapVisible(t, find.byKey(const ValueKey('island-0')));
      expect(t.takeException(), isNull, reason: 'Maths island at $size');
      expect(find.byType(IslandScreen), findsOneWidget);
      final lessonId = maths.islands.first.levels.first.id;
      final lesson = library.lessons[lessonId]!;
      await helpers.tapVisible(t, find.byKey(ValueKey('level-$lessonId')));
      await t.pump(const Duration(milliseconds: 500));
      expect(t.takeException(), isNull, reason: 'Maths lesson start at $size');
      expect(find.byType(LessonPlayer), findsOneWidget);
      expect(
        t.widget<LessonPlayer>(find.byType(LessonPlayer)).lesson.subject,
        'maths',
      );
      for (final task in workshops.tasks(workshops.workshop(lesson))) {
        await workshops.finishTask(t, task);
        expect(t.takeException(), isNull, reason: '${task['id']} at $size');
      }
      await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
      expect(
        store.data.progressForSubject('maths').journeys[lessonId]!['index'],
        1,
      );
      await helpers.tapVisible(t, find.byKey(const ValueKey('lessonPrevious')));
      expect(
        store.data.progressForSubject('maths').journeys[lessonId]!['index'],
        0,
      );
      await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
      await helpers.tapVisible(t, find.byTooltip('Save and return to map'));
      expect(find.byType(IslandScreen), findsOneWidget);
      await helpers.tapVisible(t, find.byKey(ValueKey('level-$lessonId')));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('2/${lesson.steps.length}'), findsOneWidget);
      await helpers.tapVisible(t, find.byTooltip('Save and return to map'));
      await helpers.tapVisible(t, find.byTooltip('My map'));
      expect(find.byType(WorldMap), findsOneWidget);
      await helpers.tapVisible(t, find.byTooltip('Subjects'));
      expect(find.byKey(const ValueKey('subject-science')), findsOneWidget);
      expect(store.data.journeys, science);
      expect(store.data.attempts, isEmpty);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Maths reports and earned words read the Maths subject', (
    t,
  ) async {
    final level = maths.islands.first.levels.first;
    final lesson = library.lessons[level.id]!;
    final attempt = UnitAttempt(
      unitId: level.id,
      completedAt: DateTime(2026),
      objectives: {lesson.objectives.first: DecisionOutcome.firstTry},
      completed: true,
      effortStars: 3,
    );
    final store = MemoryProgressStore(
      const AppData(profile: ChildProfile(name: 'Nour'))
          .withSubjectProgress('maths', attempts: [attempt]),
    );
    await mount(
      t,
      Scaffold(
        body: SingleChildScrollView(
          child: UnitReport(level: level, arabic: false, subject: 'maths'),
        ),
      ),
      store,
    );
    await t.pumpAndSettle();
    expect(
      find.text(parentStrings(false).unitReportFirstTryOf(1, 1)),
      findsOneWidget,
    );
    await t.pumpWidget(const SizedBox());
    await mount(t, const StickerAlbum(subject: 'maths'), store);
    await t.pumpAndSettle();
    expect(find.text(lesson.stickers.first['word'] as String), findsOneWidget);
    // The earned word shows its own picture, not one icon for every word.
    expect(find.byType(MathsVisual), findsOneWidget);
    expect(
      find.text(
        'My science words! Finish a unit to earn its stickers. Tap an earned sticker to listen.',
      ),
      findsNothing,
    );
    expect(store.data.attempts, isEmpty);
    expect(t.takeException(), isNull);
  });

  testWidgets('A Maths quiz saves its score separately and retries Maths', (
    t,
  ) async {
    final quiz = library.lessons['math_quiz_01']!;
    final session = LessonSession.fresh(quiz)..index = quiz.steps.length - 1;
    for (var index = 0; index < quiz.steps.length - 1; index++) {
      session.responses[quiz.steps[index].id] = {
        'completed': true,
        'outcome': index == 0 ? 'afterHint' : 'firstTry',
      };
    }
    final store = MemoryProgressStore(
      AppData(
        profile: const ChildProfile(name: 'Nour'),
        journeys: const {
          'unit_02': {'index': 3},
        },
        attempts: [
          UnitAttempt(
            unitId: 'quiz_01',
            completedAt: DateTime(2026),
            objectives: const {'quiz01.01': DecisionOutcome.firstTry},
            completed: true,
            effortStars: 3,
          ),
        ],
      ).withSubjectProgress('maths', journeys: {quiz.id: session.toJson()}),
    );
    final scienceJourneys = store.data.journeys;
    final scienceAttempts = store.data.attempts;
    await mount(
      t,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => LessonRoute(id: quiz.id)),
            ),
            child: const Text('Continue my Maths challenge'),
          ),
        ),
      ),
      store,
    );
    await helpers.tapVisible(t, find.text('Continue my Maths challenge'));
    final answer = quiz.steps.last.answer!['value'] as String;
    await helpers.tapVisible(t, find.byKey(ValueKey('maths-option-$answer')));
    await helpers.tapVisible(t, find.byKey(const ValueKey('lessonCheck')));
    await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
    final mathsProgress = store.data.progressForSubject('maths');
    expect(mathsProgress.latest(quiz.id)!.firstTry, 9);
    expect(mathsProgress.latest(quiz.id)!.afterHint, 1);
    expect(mathsProgress.journeys.containsKey(quiz.id), isFalse);
    expect(store.data.attempts, scienceAttempts);
    expect(store.data.journeys, scienceJourneys);
    await helpers.tapVisible(t, find.text('Play the tricky games again'));
    await t.pump(const Duration(milliseconds: 500));
    final retry = t.widget<LessonPlayer>(find.byType(LessonPlayer));
    expect(retry.lesson.subject, 'maths');
    expect(retry.lesson.id, quiz.json['practiceUnitId']);
    expect(store.data.attempts, scienceAttempts);
    expect(store.data.journeys, scienceJourneys);
    expect(t.takeException(), isNull);
  });
}
