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
import 'package:science_adventure/features/biology/body_workshop.dart';
import 'package:science_adventure/features/biology/biology_art.dart';
import 'package:science_adventure/features/plants/plant_mission_stage.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Lesson lesson, quiz;
  setUpAll(() async {
    helpers.testCatalog = await helpers.loadTestCatalog();
    final library = await LessonLibrary.load();
    lesson = library.lessons['unit_03']!;
    quiz = library.lessons['quiz_01']!;
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final font in ['Nunito', 'Fredoka', 'Cairo']) {
      await (FontLoader(
        font,
      )..addFont(rootBundle.load('assets/fonts/$font.ttf'))).load();
    }
    for (final name in [
      'explorer-boy-v2.webp',
      'explorer-girl-v2.webp',
      'five-senses-v2.webp',
      'sense-objects-v2.webp',
      'sound-atlas-v2.png',
      'science-details-v2.png',
      'plant-lab-v1.webp',
      'garden-v2.webp',
    ]) {
      await Flame.images.load(name);
    }
  });
  MemoryProgressStore storeFor(
    Lesson book,
    int index, {
    ChildGender gender = ChildGender.boy,
  }) => MemoryProgressStore(
    AppData(
      profile: ChildProfile(name: 'Nour', gender: gender),
      journeys: {book.id: (LessonSession.fresh(book)..index = index).toJson()},
    ),
  );
  void size(WidgetTester t, Size value) {
    t.view.physicalSize = value;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Map<String, dynamic> oldSave(int through) {
    final ids = List<String>.from(lesson.json['legacyStepIds']);
    return {
      'version': 1,
      'attemptId': 'original-attempt',
      'index': through,
      'stepId': through < ids.length ? ids[through] : null,
      'responses': {
        for (final id in ids.take(through))
          id: {
            'completed': true,
            'done': true,
            'outcome': 'explained',
            'mistakes': 2,
          },
      },
      'current': <String, dynamic>{},
    };
  }

  test('Thirteen activities retain twelve objectives and all five senses', () {
    expect(lesson.steps.length, 13);
    expect(lesson.objectives.length, 12);
    expect(lesson.steps[1].options.map((p) => p.id).toSet(), {
      'sight',
      'hearing',
      'smell',
      'taste',
      'touch',
    });
    expect(lesson.steps[2].options.length, 13);
  });
  test(
    'Each grouped discovery keeps its source answer among three partners',
    () {
      for (final step in lesson.steps.where(
        (s) => s.json['discoveryChoices'] is Map,
      )) {
        final groups = step.json['discoveryChoices'] as Map;
        expect(groups.keys.toSet(), step.options.map((p) => p.id).toSet());
        final answer = step.answer!['value'] as Map;
        final allTargets = step.targets.map((p) => p.id).toSet();
        for (final item in step.options) {
          final choices = List<String>.from(groups[item.id]);
          expect(choices.length, 3, reason: item.id);
          expect(choices.toSet().length, 3);
          expect(choices.every(allTargets.contains), isTrue);
          expect(choices, contains(answer[item.id]));
        }
      }
    },
  );
  test('Old completed attempt retains its identity and assisted evidence', () {
    final session = LessonSession.restore(lesson, oldSave(49));
    expect(session.finished, true);
    expect(session.attemptId, 'original-attempt');
    expect(session.result().objectives.length, 12);
    expect(
      session.result().objectives.values.every((v) => v.name == 'explained'),
      true,
    );
    expect(LessonSession.restore(lesson, session.toJson()).finished, true);
  });
  test('Practice never becomes a newly assessed success during migration', () {
    final session = LessonSession.restore(lesson, oldSave(32));
    expect(session.step.id, 'unit_03.eye-workshop.v2');
    expect(session.responses['unit_03.body-workshop.v2']['completed'], true);
    expect(session.result().objectives, isEmpty);
  });
  test(
    'Partial anatomy, senses and later measurement state survive migration',
    () {
      final session = LessonSession.restore(lesson, oldSave(8));
      expect(session.step.id, 'unit_03.body-workshop.v2');
      expect((session.current['placements'] as Map).keys.toSet(), {
        'head',
        'neck',
        'chin',
        'shoulder',
        'arm',
      });
      final senses = LessonSession.restore(lesson, oldSave(2));
      expect((senses.current['touched'] as List).length, 4);
      final saved = oldSave(43);
      saved['responses'] = {};
      saved['current'] = {'shoeA': 15, 'shoeB': 7};
      final later = LessonSession.restore(lesson, saved);
      expect(later.responses[lesson.steps[11].id]['resumeState']['shoeA'], 15);
    },
  );
  testWidgets('All five sense cards must be explored', (t) async {
    size(t, const Size(1100, 800));
    final store = storeFor(lesson, 1);
    await helpers.mount(t, LessonPlayer(lesson: lesson), store);
    for (final id in ['sight', 'hearing', 'smell', 'taste']) {
      await helpers.tapVisible(t, find.byKey(ValueKey('biology-item-$id')));
    }
    expect(store.data.journeys[lesson.id]!['current']['touched'].length, 4);
    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('biology-item-touch')),
    );
    await helpers.tapVisible(t, find.byKey(const ValueKey('lessonNext')));
    expect(store.data.journeys[lesson.id]!['index'], 2);
    await t.pumpWidget(const SizedBox());
  });
  for (final gender in ChildGender.values) {
    testWidgets('All anatomy locations accept direct touch for $gender', (
      t,
    ) async {
      size(t, const Size(1100, 800));
      final store = storeFor(lesson, 2, gender: gender);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      for (final p in lesson.steps[2].options) {
        await helpers.tapVisible(t, find.byKey(ValueKey('body-piece-${p.id}')));
        expect(
          t.widget<BodyWorkshop>(find.byType(BodyWorkshop)).camera,
          const Rect.fromLTWH(.14, 0, .72, .96),
        );
        for (final part in lesson.steps[2].targets) {
          expect(
            find.byKey(ValueKey('body-spot-${part.id}')),
            findsOneWidget,
            reason: 'Every body part must remain available after selection',
          );
        }
        final targetMaterial = find
            .ancestor(
              of: find.byKey(ValueKey('body-spot-${p.id}')),
              matching: find.byType(Material),
            )
            .first;
        expect(
          t.widget<Material>(targetMaterial).color,
          const Color(0xFFFFFCF4),
          reason: 'Selecting a name must not highlight its correct target',
        );
        final markers = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key as ValueKey<String>).value.startsWith('body-spot-'),
        );
        final rectangles = [
          for (final e in markers.evaluate())
            t.getRect(find.byWidget(e.widget)),
        ];
        for (var i = 0; i < rectangles.length; i++) {
          expect(rectangles[i].width, greaterThanOrEqualTo(64));
          for (var j = i + 1; j < rectangles.length; j++) {
            expect(
              rectangles[i].overlaps(rectangles[j]),
              isFalse,
              reason: 'Anatomy touch buttons must not overlap',
            );
          }
        }
        await helpers.tapVisible(t, find.byKey(ValueKey('body-spot-${p.id}')));
        expect(
          store.data.journeys[lesson.id]!['current']['placements'][p.id],
          p.id,
        );
      }
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(store.data.journeys[lesson.id]!['current']['outcome'], 'firstTry');
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
  testWidgets('Eye correction retains hint history after reopening', (t) async {
    size(t, const Size(1100, 800));
    final store = storeFor(lesson, 3);
    await helpers.mount(t, LessonPlayer(lesson: lesson), store);
    for (final p in lesson.steps[3].options) {
      await helpers.tapVisible(t, find.byKey(ValueKey('body-piece-${p.id}')));
      await helpers.tapVisible(
        t,
        find.byKey(
          ValueKey('body-spot-${p.id == 'eyebrow' ? 'eyelid' : p.id}'),
        ),
      );
    }
    await helpers.tapVisible(t, find.text('Check my discovery'));
    expect(store.data.journeys[lesson.id]!['current']['mistakes'], 1);
    await t.pumpWidget(const SizedBox());
    await helpers.mount(t, LessonPlayer(lesson: lesson), store);
    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('body-piece-eyebrow')),
    );
    final piece = find.byKey(const ValueKey('body-piece-eyebrow'));
    final spot = find.byKey(const ValueKey('body-spot-eyebrow'));
    await t.ensureVisible(spot);
    await t.pump();
    await t.drag(piece, t.getCenter(spot) - t.getCenter(piece));
    await t.pump();
    await helpers.tapVisible(t, find.text('Check my discovery'));
    expect(store.data.journeys[lesson.id]!['current']['outcome'], 'afterHint');
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('Grouped questions preserve evidence per learning objective', (
    t,
  ) async {
    size(t, const Size(1100, 800));
    final store = storeFor(lesson, 8);
    await helpers.mount(t, LessonPlayer(lesson: lesson), store);
    final answers = lesson.steps[8].answer!['value'] as Map;
    for (var i = 0; i < lesson.steps[8].options.length; i++) {
      final item = lesson.steps[8].options[i];
      await helpers.tapVisible(
        t,
        find.byKey(ValueKey('biology-item-${item.id}')),
      );
      await helpers.tapVisible(
        t,
        find.byKey(
          ValueKey(
            'biology-target-${item.id == 'apple_helper' ? 'ears' : answers[item.id]}',
          ),
        ),
      );
      if (i + 1 < lesson.steps[8].options.length) {
        await helpers.tapVisible(
          t,
          find.byKey(const ValueKey('biology-discovery-next')),
        );
      }
    }
    await helpers.tapVisible(t, find.text('Check my discovery'));
    final before = Map.from(
      store.data.journeys[lesson.id]!['current']['objectiveEvidence'],
    );
    expect(before.values.where((v) => v == 'firstTry').length, 2);
    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('biology-discovery-previous')),
    );
    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('biology-discovery-previous')),
    );
    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('biology-item-apple_helper')),
    );
    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('biology-target-nose')),
    );
    await helpers.tapVisible(t, find.text('Check my discovery'));
    final after =
        store.data.journeys[lesson.id]!['current']['objectiveEvidence'] as Map;
    expect(after.values.where((v) => v == 'firstTry').length, 2);
    expect(after.values.where((v) => v == 'afterHint').length, 1);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Discovery trail shows one scene and retains every original answer',
    (t) async {
      size(t, const Size(1100, 800));
      final store = storeFor(lesson, 5);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      final step = lesson.steps[5];
      for (var i = 0; i < step.options.length; i++) {
        final item = step.options[i];
        final visibleQuestions = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key as ValueKey<String>).value.startsWith('biology-item-'),
        );
        expect(visibleQuestions, findsOneWidget);
        expect(find.byKey(ValueKey('biology-item-${item.id}')), findsOneWidget);
        expect(
          find.byKey(
            ValueKey('biology-target-${step.answer!['value'][item.id]}'),
          ),
          findsOneWidget,
        );
        final partners = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key as ValueKey<String>).value.startsWith('biology-target-'),
        );
        expect(partners, findsNWidgets(3));
        await helpers.tapVisible(
          t,
          find.byKey(
            ValueKey('biology-target-${step.answer!['value'][item.id]}'),
          ),
        );
        expect(store.data.journeys[lesson.id]!['current']['done'], false);
        if (i + 1 < step.options.length) {
          await helpers.tapVisible(
            t,
            find.byKey(const ValueKey('biology-discovery-next')),
          );
        }
      }
      await helpers.tapVisible(t, find.text('Check my discovery'));
      expect(store.data.journeys[lesson.id]!['current']['outcome'], 'firstTry');
      expect(
        (store.data.journeys[lesson.id]!['current']['placements'] as Map)
            .length,
        step.options.length,
      );
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Sense detective has three partners and does not picture its count answer',
    (t) async {
      size(t, const Size(1100, 800));
      final store = storeFor(lesson, 8);
      await helpers.mount(t, LessonPlayer(lesson: lesson), store);
      expect(find.byKey(const ValueKey('biology-item-count')), findsOneWidget);
      final targets = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('biology-target-'),
      );
      expect(targets, findsNWidgets(3));
      expect(
        find.byWidgetPredicate((w) => w is BiologyPicture && w.art == 'five'),
        findsOneWidget,
        reason: 'Five is only an answer option, never the question image',
      );
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('biology-target-ten')),
      );
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('biology-discovery-next')),
      );
      expect(
        find.byKey(const ValueKey('biology-item-apple_helper')),
        findsOneWidget,
      );
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('biology-discovery-previous')),
      );
      expect(
        store.data.journeys[lesson.id]!['current']['placements']['count'],
        'ten',
      );
      expect(store.data.journeys[lesson.id]!['current']['outcome'], isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Marbles use source counts and two independent comparisons', (
    t,
  ) async {
    size(t, const Size(1100, 800));
    final store = storeFor(lesson, 7);
    await helpers.mount(t, LessonPlayer(lesson: lesson), store);
    for (final row in lesson.steps[7].table) {
      for (var i = 0; i < row['value']; i++) {
        expect(
          find.byKey(ValueKey("marble-${row['name']}-$i")),
          findsOneWidget,
        );
      }
    }
    for (final e in (lesson.steps[7].answer!['value'] as Map).entries) {
      await helpers.tapVisible(
        t,
        find.byKey(ValueKey('biology-item-${e.key}')),
      );
      await helpers.tapVisible(
        t,
        find.byKey(ValueKey('biology-item-${e.value}')),
      );
    }
    await helpers.tapVisible(t, find.text('Check my discovery'));
    expect(store.data.journeys[lesson.id]!['current']['outcome'], 'firstTry');
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('All thirteen activities fit small landscape and larger text', (
    t,
  ) async {
    size(t, const Size(800, 360));
    for (var i = 0; i < lesson.steps.length; i++) {
      await helpers.mount(
        t,
        LessonPlayer(lesson: lesson),
        storeFor(lesson, i),
        scale: 1.5,
      );
      expect(t.takeException(), isNull, reason: lesson.steps[i].id);
      await t.pumpWidget(const SizedBox());
    }
  });
  testWidgets('Quiz arm trail still accepts its complete ordered answer', (
    t,
  ) async {
    size(t, const Size(1100, 800));
    final store = storeFor(quiz, 8);
    await helpers.mount(t, LessonPlayer(lesson: quiz), store);
    for (final id in quiz.steps[8].answer!['value']) {
      final spot = find.byKey(ValueKey('body-spot-$id'));
      await t.ensureVisible(spot);
      await t.pump();
      // Every explicit marker dispatches its own anatomical ID.
      await t.tapAt(t.getCenter(spot));
      await t.pump();
    }
    await helpers.tapVisible(t, find.text('Check my discovery'));
    expect(store.data.journeys[quiz.id]!['current']['outcome'], 'firstTry');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('Quiz garden labels keep whole words at phone width and 1.5x', (
    t,
  ) async {
    size(t, const Size(360, 740));
    final store = storeFor(quiz, 0);
    await helpers.mount(t, LessonPlayer(lesson: quiz), store, scale: 1.5);
    final table = find.text('Table');
    await t.ensureVisible(table);
    await t.pump();
    final paragraph = t.renderObject<RenderParagraph>(table);
    expect(
      paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
      ),
      hasLength(1),
      reason: 'Table must not wrap into Tabl and e',
    );
    expect(t.widget<Text>(table).style!.fontSize, 24);
    final step = quiz.steps.first;
    for (final id in List<String>.from(step.answer!['value'])) {
      await helpers.tapVisible(t, find.byKey(ValueKey('biology-item-$id')));
    }
    await helpers.tapVisible(t, find.text('Check my discovery'));
    expect(store.data.journeys[quiz.id]!['current']['outcome'], 'firstTry');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('Render actual revised screens for visual review', (t) async {
    size(t, const Size(1280, 900));
    for (final index in [0, 1, 2, 3, 4, 5, 7]) {
      final key = GlobalKey();
      await helpers.mount(
        t,
        RepaintBoundary(
          key: key,
          child: LessonPlayer(lesson: lesson),
        ),
        storeFor(lesson, index),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await t.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('tmp').create(recursive: true);
        await File('tmp/ourselves-v2-${index + 1}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await t.pumpWidget(const SizedBox());
    }
  });
  testWidgets('Render revised biology subjects on the child scene colour', (
    t,
  ) async {
    size(t, const Size(1280, 900));
    final key = GlobalKey();
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: const Color(0xFFE6F0D7),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final art in [
                    'hear_music',
                    'smell_flowers',
                    'Car',
                    'toys',
                    'paper',
                    'wind',
                    'dry_and_drooping',
                  ])
                    SizedBox(
                      width: 305,
                      child: Column(
                        children: [
                          if (const [
                            'toys',
                            'paper',
                            'wind',
                            'dry_and_drooping',
                          ].contains(art))
                            PlantMissionPicture(id: art, height: 175)
                          else
                            BiologyPicture(art: art, height: 175),
                          Text(art),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    expect(t.takeException(), isNull);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await t.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('tmp').create(recursive: true);
      await File('tmp/biology-subjects-review.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await t.pumpWidget(const SizedBox());
  });
}
