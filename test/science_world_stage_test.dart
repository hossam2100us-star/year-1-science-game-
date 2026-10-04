import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/features/science/science_picture.dart';
import 'package:science_adventure/features/science/science_world_stage.dart';

class _WorldHarness extends StatefulWidget {
  const _WorldHarness({
    super.key,
    required this.step,
    this.selected = const {},
    this.placements = const {},
    this.reviewItems = const {},
  });
  final LessonStep step;
  final Set<String> selected, reviewItems;
  final Map<String, String> placements;
  @override
  State<_WorldHarness> createState() => _WorldHarnessState();
}

class _WorldHarnessState extends State<_WorldHarness> {
  late Set<String> selected = {...widget.selected};
  late Map<String, String> placements = {...widget.placements};
  final selections = <String>[], voices = <String>[];
  final placed = <(String, String)>[];
  @override
  Widget build(BuildContext context) => ScienceWorldStage(
    key: ValueKey(widget.step.id),
    step: widget.step,
    selected: selected,
    placements: placements,
    reviewItems: widget.reviewItems,
    done: false,
    onSpeak: voices.add,
    onItem: (id) => setState(() {
      selections.add(id);
      if (widget.step.kind == 'explore') {
        selected.add(id);
      } else if (widget.step.isMulti || widget.step.isOrder) {
        selected.contains(id) ? selected.remove(id) : selected.add(id);
      } else {
        selected = {id};
      }
    }),
    onPlace: (id, target) => setState(() {
      placed.add((id, target));
      placements[id] = target;
    }),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LessonLibrary library;
  setUpAll(() async {
    library = await LessonLibrary.load();
  });

  void size(WidgetTester t, Size value) {
    t.view.physicalSize = value;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<GlobalKey<_WorldHarnessState>> mount(
    WidgetTester t,
    LessonStep step, {
    Set<String> selected = const {},
    Map<String, String> placements = const {},
    Set<String> reviewItems = const {},
  }) async {
    final key = GlobalKey<_WorldHarnessState>();
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _WorldHarness(
                key: key,
                step: step,
                selected: selected,
                placements: placements,
                reviewItems: reviewItems,
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    return key;
  }

  Future<void> tap(WidgetTester t, String key) async {
    final finder = find.byKey(ValueKey(key));
    await t.ensureVisible(finder);
    await t.pump();
    await t.tap(finder);
    await t.pump();
  }

  testWidgets(
    'One current mapping discovery retains every alternative and editable choices',
    (t) async {
      size(t, const Size(360, 740));
      final step = library.lessons['unit_07']!.steps[2];
      final key = await mount(t, step);
      final state = key.currentState!;
      expect(state.selections, isEmpty);
      expect(state.placed, isEmpty);
      expect(
        find.byKey(ValueKey('science-item-${step.options.first.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('science-item-${step.options.last.id}')),
        findsNothing,
      );
      for (final target in step.targets) {
        expect(
          find.byKey(ValueKey('science-target-${target.id}')),
          findsOneWidget,
        );
      }
      await tap(t, 'science-world-listen');
      expect(state.selections, isEmpty);
      expect(state.placed, isEmpty);
      expect(
        t
            .widget<TextButton>(
              find.byKey(const ValueKey('science-world-next')),
            )
            .onPressed,
        isNull,
      );
      // An arbitrary alternative is retained rather than corrected by the scene.
      await tap(t, 'science-target-${step.targets.first.id}');
      expect(state.placements[step.options.first.id], step.targets.first.id);
      expect(state.placed.length, 1);
      await tap(t, 'science-world-next');
      expect(
        find.byKey(ValueKey('science-item-${step.options.last.id}')),
        findsOneWidget,
      );
      await tap(t, 'science-target-${step.targets.last.id}');
      await tap(t, 'science-world-previous');
      expect(
        find.text('Your choice: ${step.targets.first.label}'),
        findsOneWidget,
      );
      await tap(t, 'science-target-${step.targets.last.id}');
      expect(state.placements[step.options.first.id], step.targets.last.id);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Mapping restarts at the first missing or explicitly revisited discovery',
    (t) async {
      size(t, const Size(1280, 860));
      final step = library.lessons['unit_09']!.steps[6];
      final saved = {step.options.first.id: step.targets.first.id};
      final key = await mount(t, step, placements: saved);
      expect(
        find.byKey(ValueKey('science-item-${step.options[1].id}')),
        findsOneWidget,
      );
      expect(key.currentState!.placed, isEmpty);
      await t.pumpWidget(const SizedBox());
      final review = await mount(
        t,
        step,
        placements: saved,
        reviewItems: {step.options.first.id},
      );
      expect(
        find.byKey(ValueKey('science-item-${step.options.first.id}')),
        findsOneWidget,
      );
      expect(review.currentState!.placements, saved);
      expect(review.currentState!.placed, isEmpty);
      for (final target in step.targets) {
        expect(
          find.byKey(ValueKey('science-target-${target.id}')),
          findsOneWidget,
        );
      }
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Water exploration requires its original touches; speech and travel add none',
    (t) async {
      size(t, const Size(360, 740));
      final step = library.lessons['unit_08']!.steps.first;
      final key = await mount(t, step, selected: {step.options.first.id});
      final state = key.currentState!;
      expect(
        find.byKey(ValueKey('science-item-${step.options[1].id}')),
        findsOneWidget,
      );
      await tap(t, 'science-world-listen');
      await tap(t, 'science-world-next');
      expect(state.selected, {step.options.first.id});
      expect(state.selections, isEmpty);
      await tap(t, 'science-world-previous');
      for (var i = 1; i < step.options.length; i++) {
        await tap(t, 'science-item-${step.options[i].id}');
        if (i < step.options.length - 1) await tap(t, 'science-world-next');
      }
      expect(state.selected, step.options.map((item) => item.id).toSet());
      expect(state.selections.length, 4);
      await tap(t, 'science-item-${step.options.last.id}');
      expect(state.selections.length, 4);
      expect(
        state.voices.last,
        step.json['senseDescriptions'][step.options.last.id],
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Collections and ordering reflect only child selections', (
    t,
  ) async {
    size(t, const Size(360, 740));
    final collection = library.lessons['unit_07']!.steps[1];
    final key = await mount(t, collection);
    expect(key.currentState!.selected, isEmpty);
    await tap(t, 'science-item-${collection.options.last.id}');
    expect(key.currentState!.selected, {collection.options.last.id});
    await t.pumpWidget(const SizedBox());
    final order = library.lessons['unit_08']!.steps[8];
    final ordered = await mount(t, order);
    for (final item in order.options.reversed.take(2)) {
      await tap(t, 'science-item-${item.id}');
    }
    expect(
      ordered.currentState!.selected.toList(),
      order.options.reversed.take(2).map((item) => item.id).toList(),
    );
    expect(
      find.byKey(const ValueKey('science-world-order-path')),
      findsOneWidget,
    );
    await tap(t, 'science-item-${order.options.last.id}');
    expect(ordered.currentState!.selected, {
      order.options[order.options.length - 2].id,
    });
    expect(t.takeException(), isNull);
  });

  for (final viewport in [const Size(360, 740), const Size(1280, 860)]) {
    testWidgets(
      'Power room mixes choices and keeps their positions at $viewport',
      (t) async {
        size(t, viewport);
        final step = library.lessons['unit_07']!.steps[1];
        final harness = await mount(t, step);
        List<String> visibleOrder() => t
            .widgetList<InkWell>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is InkWell &&
                    widget.key is ValueKey<String> &&
                    (widget.key! as ValueKey<String>).value.startsWith(
                      'science-item-',
                    ),
              ),
            )
            .map(
              (widget) => (widget.key! as ValueKey<String>).value.substring(
                'science-item-'.length,
              ),
            )
            .toList();
        final before = visibleOrder();
        expect(before.toSet(), step.options.map((item) => item.id).toSet());
        expect(before.length, 7);
        final electric = Set<String>.from(step.answer!['value']);
        // Correct answers must not form one four-item block in the visible room.
        var run = 0;
        for (final id in before) {
          run = electric.contains(id) ? run + 1 : 0;
          expect(run, lessThanOrEqualTo(2));
        }
        // On the phone, avoid placing one electric answer in every full row.
        if (viewport.width == 360) {
          final rowCounts = [
            for (var i = 0; i + 1 < before.length; i += 2)
              before.sublist(i, i + 2).where(electric.contains).length,
          ];
          expect(rowCounts.toSet(), containsAll({0, 1, 2}));
        }
        expect(harness.currentState!.selected, isEmpty);
        await tap(t, 'science-item-lamp');
        expect(harness.currentState!.selected, {'lamp'});
        expect(visibleOrder(), before);
        await tap(t, 'science-item-book');
        expect(harness.currentState!.selected, {'lamp', 'book'});
        expect(visibleOrder(), before);
        await tap(t, 'science-item-book');
        expect(harness.currentState!.selected, {'lamp'});
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Explicit null quiz context suppresses a legacy answer-shaped focus',
    (t) async {
      final step = library.lessons['quiz_02']!.steps[8];
      await mount(t, step);
      expect(step.focus, 'window');
      expect(
        find.byWidgetPredicate((w) => w is SciencePicture && w.art == 'window'),
        findsNothing,
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Every new world question fits phone/tablet and has separate usable targets',
    (t) async {
      size(t, const Size(360, 740));
      for (final viewport in [const Size(360, 740), const Size(1280, 860)]) {
        t.view.physicalSize = viewport;
        for (final id in [
          'unit_07',
          'unit_08',
          'unit_09',
          'quiz_02',
          'quiz_03',
          'quiz_04',
        ]) {
          for (final step in library.lessons[id]!.steps.where(
            (step) => step.json['lab'] == null,
          )) {
            final key = await mount(t, step);
            expect(key.currentState!.selections, isEmpty, reason: step.id);
            expect(key.currentState!.placed, isEmpty, reason: step.id);
            final rects = <Rect>[];
            for (final target in step.targets) {
              final rect = t.getRect(
                find.byKey(ValueKey('science-target-${target.id}')),
              );
              expect(rect.width, greaterThanOrEqualTo(48), reason: step.id);
              expect(rect.height, greaterThanOrEqualTo(48), reason: step.id);
              expect(rect.left, greaterThanOrEqualTo(0), reason: step.id);
              expect(
                rect.right,
                lessThanOrEqualTo(viewport.width),
                reason: step.id,
              );
              for (final previous in rects) {
                expect(rect.overlaps(previous), isFalse, reason: step.id);
              }
              rects.add(rect);
            }
            expect(
              t.takeException(),
              isNull,
              reason: '${step.id} at $viewport',
            );
            await t.pumpWidget(const SizedBox());
          }
        }
      }
    },
  );
}
