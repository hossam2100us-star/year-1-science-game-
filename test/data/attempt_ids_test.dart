import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/ids.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/data/db/app_database.dart';
import 'package:science_adventure/data/drift_progress_store.dart';

/// Sync identifies an attempt by its row ID, so saving must never give an
/// existing attempt a new ID (it would be uploaded again as a new attempt).
UnitAttempt attempt(String id, int day, {String unit = 'unit_01'}) =>
    UnitAttempt(
      unitId: unit,
      completedAt: DateTime(2026, 10, day, 9, 30),
      objectives: const {'o.1': DecisionOutcome.firstTry},
      completed: true,
      effortStars: 2,
      attemptId: id,
    );

void main() {
  late AppDatabase db;
  late DriftProgressStore store;
  late AppData data;

  Future<Map<String, String>> rowIds() async {
    final rows = await db.select(db.unitAttempts).get();
    return {
      for (final r in rows)
        r.clientAttemptId.isEmpty
                ? 'legacy@${r.completedAt}'
                : r.clientAttemptId:
            r.id,
    };
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    store = await DriftProgressStore.open(db);
    data = AppData(
      activeChildId: Ids.uuidV7(),
      profile: const ChildProfile(name: 'Nour', gender: ChildGender.girl),
      attempts: [attempt('unit_01-1', 1), attempt('unit_01-2', 2)],
    );
    await store.write(data);
  });
  tearDown(() => db.close());

  test('adding an attempt keeps the IDs of the earlier ones', () async {
    final before = await rowIds();
    data = data.copyWith(attempts: [...data.attempts, attempt('unit_01-3', 3)]);
    await store.write(data);
    final after = await rowIds();
    expect(after['unit_01-1'], before['unit_01-1']);
    expect(after['unit_01-2'], before['unit_01-2']);
    expect(after.keys, containsAll(['unit_01-1', 'unit_01-2', 'unit_01-3']));
  });

  test('IDs survive reopening the database', () async {
    final before = await rowIds();
    final reopened = await DriftProgressStore.open(db);
    final read = reopened.read();
    await reopened.write(
      read.copyWith(attempts: [...read.attempts, attempt('unit_01-9', 9)]),
    );
    final after = await rowIds();
    expect(after['unit_01-1'], before['unit_01-1']);
    expect(after['unit_01-2'], before['unit_01-2']);
  });

  test('old attempts without an app ID keep their IDs too', () async {
    final legacy = UnitAttempt(
      unitId: 'unit_02',
      completedAt: DateTime(2026, 9, 1, 8),
      objectives: const {'o.2': DecisionOutcome.explained},
      completed: false,
      effortStars: 1,
    );
    data = data.copyWith(attempts: [legacy, ...data.attempts]);
    await store.write(data);
    final first = await rowIds();
    data = data.copyWith(attempts: [...data.attempts, attempt('unit_01-4', 4)]);
    await store.write(data);
    final second = await rowIds();
    final legacyKey = first.keys.firstWhere((k) => k.startsWith('legacy@'));
    expect(second[legacyKey], first[legacyKey]);
  });

  test('a progress reset removes the attempts', () async {
    await store.write(data.copyWith(attempts: const []));
    expect(await rowIds(), isEmpty);
    expect(await db.select(db.attemptObjectives).get(), isEmpty);
  });
}
