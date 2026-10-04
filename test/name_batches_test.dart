import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/features/biology/body_workshop.dart';

/// AUD-018 (g): body-part names appear in small batches; placements and
/// scoring are untouched because the parent map is used as-is.
void main() {
  final options = [
    for (var i = 1; i <= 12; i++)
      PictureItem.fromJson({'id': 'p$i', 'label': 'Part $i'}),
  ];

  Future<Map<String, String>> pump(
    WidgetTester tester,
    Map<String, String> placements,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => NameBatches(
              options: options,
              placements: placements,
              builder: (p) => TextButton(
                key: ValueKey(p.id),
                onPressed: () => setState(() => placements[p.id] = p.id),
                child: Text(p.label),
              ),
            ),
          ),
        ),
      ),
    );
    return placements;
  }

  String range(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('names-range'))).data!;

  testWidgets('shows five names at a time with paging', (tester) async {
    await pump(tester, {});
    expect(find.byType(TextButton), findsNWidgets(NameBatches.batchSize));
    expect(range(tester), '1–5 / 12');
    await tester.tap(find.byKey(const ValueKey('names-next')));
    await tester.pump();
    expect(range(tester), '6–10 / 12');
    await tester.tap(find.byKey(const ValueKey('names-next')));
    await tester.pump();
    expect(range(tester), '11–12 / 12');
    expect(find.byType(TextButton), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('names-previous')));
    await tester.pump();
    expect(range(tester), '6–10 / 12');
  });

  testWidgets('opens the next batch once a batch is fully placed', (
    tester,
  ) async {
    final placements = await pump(tester, {});
    for (var i = 1; i <= 5; i++) {
      await tester.tap(find.byKey(ValueKey('p$i')));
      await tester.pump();
    }
    expect(range(tester), '6–10 / 12');
    expect(placements.length, 5, reason: 'placements are the caller map');
  });

  testWidgets('a restored journey opens at the first unfinished batch', (
    tester,
  ) async {
    await pump(tester, {for (var i = 1; i <= 7; i++) 'p$i': 'p$i'});
    expect(range(tester), '6–10 / 12');
  });

  testWidgets('five or fewer names need no paging', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NameBatches(
            options: options.take(5).toList(),
            placements: const {},
            builder: (p) => Text(p.label),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('names-range')), findsNothing);
    expect(find.text('Part 5'), findsOneWidget);
  });
}
