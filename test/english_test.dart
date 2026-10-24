import 'dart:convert';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/catalog.dart';
import 'package:science_adventure/content/curriculum.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/content/school_years.dart';
import 'package:science_adventure/core/design.dart';
import 'package:science_adventure/core/ids.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/data/db/app_database.dart';
import 'package:science_adventure/data/drift_progress_store.dart';
import 'package:science_adventure/domain/canonical_json.dart';
import 'package:science_adventure/features/english/english_art.dart';
import 'package:science_adventure/features/lesson/lesson_player.dart';
import 'package:science_adventure/features/lesson/session.dart';
import 'package:science_adventure/features/lesson/step_rules.dart';
import 'package:science_adventure/features/maths/maths_art.dart';
import 'package:science_adventure/games/question_engine.dart';

import 'setup_screen_test.dart' as helpers;
import 'support/review_images.dart';

/// Year 1 English (owner request, 23 October 2026), built from the family's
/// companion "English Made Easy": 9 units, 3 term quizzes and chart skills.
/// Remembers what the lesson read aloud.
class _Voice extends helpers.SilentNarration {
  final spoken = <String>[];
  @override
  Future<void> speak(String text) async => spoken.add(text);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonLibrary english;
  late Catalog science, catalogue;

  setUpAll(() async {
    english = await LessonLibrary.loadEnglish();
    science = await Catalog.load();
    catalogue = Catalog.fromJson(
      jsonDecode(
        await rootBundle.loadString('assets/content/english_catalog.json'),
      ) as Map<String, dynamic>,
    );
    for (final font in ['Nunito', 'Fredoka', 'Cairo']) {
      await (FontLoader(
        font,
      )..addFont(rootBundle.load('assets/fonts/$font.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Iterable<LessonStep> steps() =>
      english.lessons.values.expand((lesson) => lesson.steps);

  group('the subject', () {
    test('English is a Year 1 subject with its own progress', () {
      final year = SchoolYears.builtIn.byId('y1')!;
      expect(year.subjects.map((s) => s.curriculum), [
        currentCurriculum,
        mathsCurriculum,
        englishCurriculum,
      ]);
      expect(progressKeyOf(englishCurriculum), 'y1.english');
      expect(curriculumOfKey('y1.english'), englishCurriculum);
      expect(subjectKindOf('y1.english'), 'english');
      expect(catalogue.curriculum, englishCurriculum);
      expect(catalogue.progressKey, 'y1.english');
      for (final lesson in english.lessons.values) {
        expect(lesson.subject, 'english', reason: lesson.id);
        expect(lesson.progressKey, 'y1.english', reason: lesson.id);
      }
    });

    test('the catalogue lists every lesson, term by term', () {
      expect(
        catalogue.levels.map((l) => l.id).toList(),
        LessonLibrary.englishIds,
      );
      expect(catalogue.islands, hasLength(4));
      expect(catalogue.levels.where((l) => l.quiz), hasLength(3));
      for (final id in LessonLibrary.englishIds) {
        expect(LessonLibrary.availableIds, contains(id));
      }
    });

    test('every graded question has a goal activity in English and Arabic', () {
      for (final lesson in english.lessons.values) {
        final goals = {
          for (final a in lesson.json['goalActivities'] as List)
            (a as Map)['objective']: a,
        };
        for (final step in lesson.steps.where((s) => s.assessed)) {
          final activity = goals[step.objective];
          expect(activity, isNotNull, reason: step.id);
          expect(activity!['textAr'], matches(RegExp(r'[\u0600-\u06ff]')));
        }
      }
    });

    test('every picture a step names is painted', () {
      for (final step in steps()) {
        final visual = step.json['englishVisual'] as Map?;
        final names = [
          if (visual?['type'] == 'picture') ...visual!['items'] as List,
          if (visual?['type'] == 'story' && visual?['picture'] != null)
            visual!['picture'],
          for (final o in step.json['options'] as List)
            if ((o as Map)['picture'] != null) o['picture'],
        ];
        for (final name in names) {
          expect(
            hasEnglishPicture('$name'),
            isTrue,
            reason: '${step.id} $name',
          );
        }
      }
      // The Maths pictures are reused, never painted twice.
      for (final word in englishWords) {
        expect(mathsThings, isNot(contains(word)), reason: word);
        expect(mathsObjectCells.keys, isNot(contains(word)), reason: word);
      }
    });
  });

  group('teacher review 8', () {
    test('the chart uses the playing child\'s name, or Sam', () {
      final charts = english.lessons['eng_charts']!;
      final nour = charts.forChild('Nour');
      final step = nour.steps.firstWhere((s) => s.title == 'The most books');
      expect(step.prompt, 'On which day did Nour read the most books?');
      expect(
        (step.json['englishVisual'] as Map)['title'],
        'Books Nour read this week',
      );
      expect(
        charts.forChild('').steps[1].prompt,
        'On which day did Sam read the most books?',
      );
      // Only the text changes: IDs and answers are the same.
      expect(nour.steps.map((s) => s.id), charts.steps.map((s) => s.id));
      expect(step.answer, charts.steps[1].answer);
      for (final lesson in english.lessons.values) {
        expect(
          jsonEncode(lesson.forChild('Nour').json),
          isNot(contains('{name}')),
          reason: lesson.id,
        );
        expect(jsonEncode(lesson.json), isNot(contains('Seif')));
      }
      // The Science garden's "Is the {name} alive?" names the thing, not
      // the child.
      final garden = Lesson({
        'id': 'unit_01',
        'steps': <dynamic>[],
        'ui': {'question': 'Is the {name} alive?'},
      });
      expect(garden.forChild('Nour'), same(garden));
    });

    test('every part of a story has its own picture', () {
      for (final id in [
        'eng_unit_01',
        'eng_unit_02',
        'eng_unit_04',
        'eng_unit_07',
      ]) {
        final story = english.lessons[id]!.steps.first;
        expect(story.kind, 'explore');
        for (final part in story.json['options'] as List) {
          expect(
            (part as Map)['picture'],
            isNotNull,
            reason: '$id ${part['label']}',
          );
          expect(englishScenes, contains(part['picture']));
        }
      }
    });

    test('"whispered" is no longer sorted as scared', () {
      final feelings = english.lessons['eng_unit_07']!.steps.firstWhere(
        (s) => s.title == 'Feeling verbs',
      );
      expect(feelings.options.map((o) => o.label), contains('trembled'));
      expect(
        feelings.options.map((o) => o.label),
        isNot(contains('whispered')),
      );
    });
  });

  group('written words', () {
    test('a word matches only its exact spelling', () {
      const answer = {'type': 'word', 'value': 'ee'};
      expect(matchesAnswer(answer, 'ee'), isTrue);
      expect(matchesAnswer(answer, 'ea'), isFalse);
      expect(matchesAnswer(answer, 'EE'), isFalse);
      expect(matchesAnswer(answer, ''), isFalse);
      expect(matchesAnswer(answer, null), isFalse);
    });

    test('step rules read the word from the slots', () {
      final tree = steps().firstWhere(
        (s) => s.json['letters']?['say'] == 'tree',
      );
      expect(tree.isWord && tree.isWritten, isTrue);
      expect(StepRules.selection(tree, {}, {'answer': 'ee'}), 'ee');
      expect(StepRules.reviewItems(tree, {}, {'answer': 'ea'}), {'answer'});
      expect(StepRules.reviewItems(tree, {}, {'answer': 'ee'}), isEmpty);
      // The whole word, so the child sees what it should have been.
      expect(StepRules.answerReference(tree, {'answer'}), 'tree');
    });

    test('the tiles never spell the answer in order', () {
      for (final step in steps().where((s) => s.isWord)) {
        final tiles = List<String>.from(step.json['letters']['tiles'] as List);
        expect(tiles, [...tiles]..sort(), reason: step.id);
        final answer = step.answer!['value'] as String;
        expect(tiles.length, greaterThan(answer.length), reason: step.id);
      }
    });
  });

  group('playing', () {
    final screen = GlobalKey();
    var voice = _Voice();

    Future<MemoryProgressStore> open(
      WidgetTester t,
      Lesson lesson,
      int index, {
      Size size = const Size(1280, 800),
      double scale = 1,
    }) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final session = LessonSession.fresh(lesson)..index = index;
      final store = MemoryProgressStore(
        const AppData(profile: ChildProfile(name: 'Nour')).withSubjectProgress(
          lesson.progressKey,
          journeys: {lesson.id: session.toJson()},
        ),
      );
      await t.runAsync(
        () => Flame.images.loadAll([
          englishBackdropAsset,
          englishWordAsset,
          englishSceneAsset,
          mathsObjectAsset,
          mathsThingAsset,
        ]),
      );
      await t.pumpWidget(const SizedBox());
      voice = _Voice();
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            catalogProvider.overrideWithValue(science),
            lessonLibraryProvider.overrideWith((ref) async => english),
            narrationProvider.overrideWith((ref) => voice),
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
            home: RepaintBoundary(
              key: screen,
              child: LessonPlayer(lesson: lesson.forChild(null)),
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      return store;
    }

    Map<String, dynamic> current(MemoryProgressStore store, Lesson lesson) =>
        Map<String, dynamic>.from(
          store.data
              .progressForSubject('y1.english')
              .journeys[lesson.id]!['current'],
        );

    Finder check() => find.byKey(const ValueKey('lessonCheck'));
    Finder next() => find.byKey(const ValueKey('lessonNext'));

    testWidgets('a story goes on only after every part is heard', (t) async {
      final lesson = english.lessons['eng_unit_01']!;
      await open(t, lesson, 0);
      expect(next(), findsNothing);
      for (final card in lesson.steps.first.options) {
        await helpers.tapVisible(
          t,
          find.byKey(ValueKey('english-option-${card.id}')),
        );
      }
      expect(next(), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('missing sounds are spelled with letter tiles', (t) async {
      final lesson = english.lessons['eng_unit_01']!;
      final index = lesson.steps.indexWhere(
        (s) => s.json['letters']?['say'] == 'tree',
      );
      final store = await open(t, lesson, index);
      final tiles = List<String>.from(
        lesson.steps[index].json['letters']['tiles'] as List,
      );
      Future<void> tile(String letter, [int skip = 0]) {
        final at = tiles.indexed
            .where((e) => e.$2 == letter)
            .elementAt(skip)
            .$1;
        return helpers.tapVisible(t, find.byKey(ValueKey('letter-tile-$at')));
      }

      expect(t.widget<ButtonStyleButton>(check()).onPressed, isNull);
      await tile('o');
      await tile('a');
      await helpers.tapVisible(t, check());
      expect(current(store, lesson)['mistakes'], 1);
      final delete = find.byKey(const ValueKey('letter-delete'));
      await helpers.tapVisible(t, delete);
      await helpers.tapVisible(t, delete);
      await tile('e');
      // A used tile is spent: the second e is the other tile.
      await tile('e', 1);
      await helpers.tapVisible(t, check());
      final saved = current(store, lesson);
      expect(saved['done'], isTrue);
      expect(saved['outcome'], 'afterHint');
      expect(saved['placements'], {'answer': 'ee'});
      expect(t.takeException(), isNull);
    });

    testWidgets('sorting sentences into Real and Fantasy', (t) async {
      final lesson = english.lessons['eng_unit_01']!;
      final index = lesson.steps.indexWhere(
        (s) => s.title == 'Real or fantasy?',
      );
      final step = lesson.steps[index];
      final store = await open(t, lesson, index);
      final expected = Map<String, String>.from(step.answer!['value'] as Map);
      for (final MapEntry(key: option, value: target) in expected.entries) {
        await helpers.tapVisible(
          t,
          find.byKey(ValueKey('english-option-$option')),
        );
        // The child hears the sentence before choosing its basket
        // (teacher review 8).
        expect(voice.spoken.last, step.label(option));
        await helpers.tapVisible(
          t,
          find.byKey(ValueKey('english-target-$target')),
        );
      }
      await helpers.tapVisible(t, check());
      expect(current(store, lesson)['outcome'], 'firstTry');
      expect(t.takeException(), isNull);
    });

    testWidgets('every English step fits a tablet and a phone with big text', (
      t,
    ) async {
      for (final lesson in english.lessons.values) {
        for (final (index, step) in lesson.forChild(null).steps.indexed) {
          for (final (size, scale) in const [
            (Size(1280, 800), 1.0),
            (Size(390, 844), 1.5),
          ]) {
            await open(t, lesson, index, size: size, scale: scale);
            expect(find.text(step.prompt), findsWidgets, reason: step.id);
            expect(t.takeException(), isNull, reason: '${step.id} $size');
            if (writeReviewImages && scale == 1) {
              await t.runAsync(() async {
                final boundary =
                    screen.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final image = await boundary.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await saveReviewImage('english/${step.id}.png', bytes);
                image.dispose();
              });
            }
          }
        }
      }
      await t.pumpWidget(const SizedBox());
      await t.pump();
    });
  });

  group('saving', () {
    late AppDatabase db;
    late DriftProgressStore store;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      store = await DriftProgressStore.open(db);
    });
    tearDown(() => db.close());

    test(
      'English progress has its own rows and leaves the others alone',
      () async {
        final attempt = UnitAttempt(
          unitId: 'eng_unit_01',
          completedAt: DateTime(2026, 10, 24),
          objectives: const {'eng.u01.main.01': DecisionOutcome.firstTry},
          completed: true,
          effortStars: 3,
          attemptId: Ids.uuidV7(),
        );
        final data =
            AppData(
                  activeChildId: Ids.uuidV7(),
                  profile: const ChildProfile(name: 'Nour'),
                )
                .withSubjectProgress(
                  'maths',
                  journeys: const {
                    'math_unit_01': {'version': 2, 'index': 4},
                  },
                )
                .withSubjectProgress(
                  'y1.english',
                  attempts: [attempt],
                  journeys: const {
                    'eng_unit_02': {'version': 1, 'index': 3},
                  },
                );
        await store.write(data);
        expect(
          (await db.select(db.unitAttempts).get()).single.curriculum,
          englishCurriculum,
        );
        expect((await db.select(db.journeys).get()).map((j) => j.curriculum), {
          mathsCurriculum,
          englishCurriculum,
        });
        final reopened = await DriftProgressStore.open(db);
        expect(
          canonicalJson(reopened.read().toJson()),
          canonicalJson(data.toJson()),
        );
        final english = reopened.read().progressForSubject('y1.english');
        expect(english.isComplete('eng_unit_01'), isTrue);
        expect(english.journeys['eng_unit_02']!['index'], 3);
        expect(
          reopened.read().progressForSubject('maths').journeys['math_unit_01'],
          {'version': 2, 'index': 4},
        );
      },
    );
  });
}
