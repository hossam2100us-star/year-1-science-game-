import 'dart:convert';

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/catalog.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/core/design.dart';
import 'package:science_adventure/core/diagnostics/failure.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/lesson/lesson_player.dart';
import 'package:science_adventure/features/lesson/session.dart';
import 'package:science_adventure/features/maths/maths_art.dart';
import 'package:science_adventure/features/maths/maths_workshop.dart';

import 'setup_screen_test.dart' as helpers;

Map<String, dynamic> copied(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

Map<String, dynamic> workshop(Lesson lesson) =>
    Map<String, dynamic>.from(lesson.steps.first.json['mathWorkshop'] as Map);

List<Map<String, dynamic>> tasks(Map<String, dynamic> config) =>
    (config['tasks'] as List).cast<Map<String, dynamic>>();

Map<String, dynamic> oneTask(
  Map<String, dynamic> config,
  Map<String, dynamic> task,
) => {
  ...config,
  'tasks': [task],
};

Future<void> preloadImages(WidgetTester t) async {
  await t.runAsync(() async {
    for (final asset in [mathsObjectAsset, mathsBackdropAsset]) {
      await Flame.images.load(asset);
    }
  });
}

Future<void> tap(WidgetTester t, String key) async {
  final button = find.byKey(ValueKey(key));
  expect(button, findsOneWidget);
  await t.ensureVisible(button);
  await t.pump();
  await t.tap(button);
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> mountWorkshop(
  WidgetTester t,
  Map<String, dynamic> config, {
  Map<String, dynamic> initial = const {},
  required Future<void> Function(Map<String, dynamic>, bool) save,
  ValueChanged<String>? say,
}) async {
  await preloadImages(t);
  await t.pumpWidget(
    MaterialApp(
      theme: adventureTheme(const ChildProfile(name: 'Nour')),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: MathsWorkshop(
                    config: config,
                    initial: initial,
                    onSave: save,
                    onSay: say ?? (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pump();
}

Future<void> finishTask(WidgetTester t, Map<String, dynamic> task) async {
  switch (task['mode']) {
    case 'count':
      for (var object = 0; object < (task['count'] as int); object++) {
        await tap(t, 'maths-count-object-$object');
      }
      await tap(t, 'maths-workshop-choice-${task['correctId']}');
    case 'build':
      var count = task['initialCount'] as int? ?? 0;
      final target = task['target'] as int;
      while (count != target) {
        await tap(t, count < target ? 'maths-build-add' : 'maths-build-remove');
        count += count < target ? 1 : -1;
      }
      await tap(t, 'maths-build-check');
    case 'choose':
      await tap(t, 'maths-workshop-choice-${task['correctId']}');
    default:
      fail('Unsupported production workshop mode: ${task['mode']}');
  }
  await tap(t, 'maths-workshop-next');
}

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

  testWidgets('counting visits each object once before offering an answer', (
    t,
  ) async {
    final config = workshop(maths.lessons['math_unit_01']!);
    final task = tasks(config).firstWhere((task) => task['mode'] == 'count');
    final saved = <Map<String, dynamic>>[];
    final said = <String>[];
    await mountWorkshop(
      t,
      oneTask(config, task),
      save: (lab, complete) async {
        saved.add(copied(lab));
        expect(complete, isFalse);
      },
      say: said.add,
    );
    expect(find.byKey(const ValueKey('maths-count-total')), findsOneWidget);
    expect(
      find.byKey(ValueKey('maths-workshop-choice-${task['correctId']}')),
      findsNothing,
    );
    await tap(t, 'maths-count-object-0');
    await tap(t, 'maths-count-object-0');
    expect(saved, hasLength(1), reason: 'Repeated touches are not new objects');
    expect(saved.single['counted'], [0]);
    expect(said, ['1']);
    expect(find.text('1 counted'), findsOneWidget);
    for (var object = 1; object < (task['count'] as int); object++) {
      await tap(t, 'maths-count-object-$object');
    }
    expect(
      saved.last['counted'],
      List.generate(task['count'] as int, (index) => index),
    );
    expect(find.text('${task['count']} counted'), findsOneWidget);
    expect(
      find.byKey(ValueKey('maths-workshop-choice-${task['correctId']}')),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('a wrong answer gives a hint without completing practice', (
    t,
  ) async {
    final config = workshop(maths.lessons['math_unit_03']!);
    final task = tasks(config).first;
    final wrong = (task['choices'] as List).firstWhere(
      (choice) => choice['id'] != task['correctId'],
    ) as Map;
    var lab = <String, dynamic>{};
    var complete = false;
    await mountWorkshop(
      t,
      oneTask(config, task),
      save: (next, done) async {
        lab = copied(next);
        complete = done;
      },
    );
    await tap(t, 'maths-workshop-choice-${wrong['id']}');
    expect(lab['passed'], isFalse);
    expect(lab['completedTasks'], isNull);
    expect(complete, isFalse);
    expect(find.text(task['hint'] as String), findsOneWidget);
    expect(find.byKey(const ValueKey('maths-workshop-next')), findsNothing);
    await tap(t, 'maths-workshop-choice-${task['correctId']}');
    expect(lab['passed'], isTrue);
    expect(complete, isFalse, reason: 'The child still has to finish practice');
    await tap(t, 'maths-workshop-next');
    expect(complete, isTrue);
    expect(lab['completedTasks'], [task['id']]);
    expect(t.takeException(), isNull);
  });

  testWidgets('a built group can overshoot and be corrected by removing one', (
    t,
  ) async {
    final config = workshop(maths.lessons['math_unit_01']!);
    final task = tasks(config).firstWhere((task) => task['mode'] == 'build');
    var lab = <String, dynamic>{};
    var complete = false;
    await mountWorkshop(
      t,
      oneTask(config, task),
      save: (next, done) async {
        lab = copied(next);
        complete = done;
      },
    );
    expect(
      t
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('maths-build-remove')),
          )
          .onPressed,
      isNull,
    );
    final target = task['target'] as int;
    for (var count = 0; count <= target; count++) {
      await tap(t, 'maths-build-add');
    }
    await tap(t, 'maths-build-check');
    expect(lab['built'], target + 1);
    expect(lab['passed'], isFalse);
    expect(complete, isFalse);
    expect(find.text(task['hint'] as String), findsOneWidget);
    await tap(t, 'maths-build-remove');
    expect(lab['built'], target);
    await tap(t, 'maths-build-check');
    expect(lab['passed'], isTrue);
    await tap(t, 'maths-workshop-next');
    expect(complete, isTrue);
    expect(t.takeException(), isNull);
  });

  testWidgets('the production player restores a partially counted lab', (
    t,
  ) async {
    final lesson = maths.lessons['math_unit_01']!;
    final config = workshop(lesson);
    final task = tasks(config).first;
    final session = LessonSession.fresh(lesson)
      ..current = {
        'lab': {
          'taskIndex': 0,
          'counted': [0, 1],
        },
        'freeDone': false,
      };
    final store = MemoryProgressStore(
      const AppData(
        profile: ChildProfile(name: 'Nour'),
      ).withSubjectProgress('maths', journeys: {lesson.id: session.toJson()}),
    );
    await preloadImages(t);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
          catalogProvider.overrideWithValue(science),
          lessonLibraryProvider.overrideWith((ref) async => maths),
          narrationProvider.overrideWith((ref) => helpers.SilentNarration()),
        ],
        child: MaterialApp(
          theme: adventureTheme(store.data.profile),
          home: LessonPlayer(lesson: lesson),
        ),
      ),
    );
    await t.pump();
    expect(find.text('2 counted'), findsOneWidget);
    await tap(t, 'maths-count-object-0');
    expect(find.text('2 counted'), findsOneWidget);
    await tap(t, 'maths-count-object-2');
    final journey = store.data.progressForSubject('maths').journeys[lesson.id]!;
    expect((journey['current'] as Map)['lab']['counted'], [0, 1, 2]);
    expect(journey['attemptId'], session.attemptId);
    expect(journey['index'], 0);
    expect(store.data.attempts, isEmpty);
    expect(store.data.progressForSubject('maths').attempts, isEmpty);
    expect(
      MathsWorkshop.isComplete(
        config,
        Map<String, dynamic>.from((journey['current'] as Map)['lab'] as Map),
      ),
      isFalse,
    );
    expect(
      find.byKey(ValueKey('maths-workshop-choice-${task['correctId']}')),
      findsNothing,
    );
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump();
  });

  testWidgets('a failed save rolls back the counted object and permits retry', (
    t,
  ) async {
    final config = workshop(maths.lessons['math_unit_01']!);
    final task = tasks(config).first;
    var attempts = 0;
    final said = <String>[];
    var lab = <String, dynamic>{};
    await mountWorkshop(
      t,
      oneTask(config, task),
      save: (next, complete) async {
        if (attempts++ == 0) throw StateError('test save failure');
        lab = copied(next);
      },
      say: said.add,
    );
    await tap(t, 'maths-count-object-0');
    expect(find.text('0 counted'), findsOneWidget);
    expect(lab, isEmpty);
    expect(said, isEmpty);
    expect(
      find.text(saveFailureMessage(FailureKind.unexpected)),
      findsOneWidget,
    );
    await tap(t, 'maths-count-object-0');
    expect(find.text('1 counted'), findsOneWidget);
    expect(lab['counted'], [0]);
    expect(said, ['1']);
    expect(attempts, 2);
    expect(t.takeException(), isNull);
  });

  testWidgets('failed completion preserves passed practice for a safe retry', (
    t,
  ) async {
    final config = workshop(maths.lessons['math_unit_03']!);
    final task = tasks(config).first;
    var lab = <String, dynamic>{};
    var complete = false;
    var rejectCompletion = true;
    await mountWorkshop(
      t,
      oneTask(config, task),
      save: (next, done) async {
        if (done && rejectCompletion) {
          rejectCompletion = false;
          throw StateError('test completion failure');
        }
        lab = copied(next);
        complete = done;
      },
    );
    await tap(t, 'maths-workshop-choice-${task['correctId']}');
    expect(lab['passed'], isTrue);
    await tap(t, 'maths-workshop-next');
    expect(complete, isFalse);
    expect(lab['completedTasks'], isNull);
    expect(lab['passed'], isTrue);
    expect(find.byKey(const ValueKey('maths-workshop-next')), findsOneWidget);
    expect(find.text('You are ready for the next discovery!'), findsNothing);
    await tap(t, 'maths-workshop-next');
    expect(complete, isTrue);
    expect(lab['completedTasks'], [task['id']]);
    expect(find.text('You are ready for the next discovery!'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  for (final id in LessonLibrary.mathsIds.where(
    (id) => !id.startsWith('math_quiz_'),
  )) {
    testWidgets('$id has a satisfiable ungraded production workshop', (
      t,
    ) async {
      final lesson = maths.lessons[id]!;
      final intro = lesson.steps.first;
      expect(intro.assessed, isFalse);
      expect(intro.isFree, isTrue);
      final config = workshop(lesson);
      final practice = tasks(config);
      expect(practice, isNotEmpty);
      var lab = <String, dynamic>{};
      var complete = false;
      await mountWorkshop(
        t,
        config,
        save: (next, done) async {
          lab = copied(next);
          complete = done;
        },
      );
      for (var index = 0; index < practice.length; index++) {
        await finishTask(t, practice[index]);
        expect(lab['completedTasks'], [
          for (final task in practice.take(index + 1)) task['id'],
        ]);
        expect(complete, index == practice.length - 1);
      }
      expect(MathsWorkshop.isComplete(config, lab), isTrue);
      expect(
        find.text('You are ready for the next discovery!'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('maths-workshop-next')), findsNothing);
      expect(t.takeException(), isNull, reason: id);
      await t.pumpWidget(const SizedBox());
      await t.pump();
    });
  }
}
