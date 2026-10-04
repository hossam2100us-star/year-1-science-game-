import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/ids.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/data/db/app_database.dart';
import 'package:science_adventure/data/drift_progress_store.dart';
import 'package:science_adventure/domain/canonical_json.dart';

/// Counts statements that change data, to prove a save writes only the rows
/// that changed (AUD-004).
class WriteCounter extends QueryInterceptor {
  int writes = 0;
  @override
  Future<int> runInsert(QueryExecutor e, String sql, List<Object?> args) {
    writes++;
    return super.runInsert(e, sql, args);
  }

  @override
  Future<int> runUpdate(QueryExecutor e, String sql, List<Object?> args) {
    writes++;
    return super.runUpdate(e, sql, args);
  }

  @override
  Future<int> runDelete(QueryExecutor e, String sql, List<Object?> args) {
    writes++;
    return super.runDelete(e, sql, args);
  }
}

AppData family() {
  final photo = Uint8List.fromList(List.generate(4000, (i) => i % 251));
  final nour = AppData(
    activeChildId: Ids.uuidV7(),
    profile: ChildProfile(
      name: 'Nour',
      gender: ChildGender.girl,
      avatar: 2,
      photo: photo,
      palette: PaletteChoice.berry,
    ),
    settings: const AppSettings(arabic: false, breakMinutes: 20, boyVoice: 'v'),
    attempts: [
      UnitAttempt(
        unitId: 'unit_02',
        completedAt: DateTime(2026, 10, 1, 9, 30),
        objectives: const {
          'u02.roots': DecisionOutcome.firstTry,
          'u02.stem': DecisionOutcome.explained,
        },
        completed: true,
        effortStars: 3,
        attemptId: 'unit_02-123',
        contentVersion: 4,
      ),
    ],
    dailySeconds: const {'2026-10-01': 600, '2026-10-02': 30},
    journeys: const {
      'unit_03': {
        'version': 2,
        'attemptId': 'a',
        'index': 1,
        'responses': <String, dynamic>{},
        'current': {'outcome': null},
      },
      'unit_01.garden': {'version': 1, 'results': <String, dynamic>{}},
    },
    otherSubjects: const {
      'math': {'saved': true},
    },
    quarantinedChildren: const {'old-id': 'damaged'},
  );
  // Adam is added, then Nour (with all the progress) is active again.
  return nour
      .addChild(Ids.uuidV7(), const ChildProfile(name: 'Adam'))
      .selectChild(nour.activeChildId);
}

void main() {
  late AppDatabase db;
  late WriteCounter counter;

  setUp(() {
    counter = WriteCounter();
    db = AppDatabase(NativeDatabase.memory().interceptWith(counter));
  });
  tearDown(() => db.close());

  test('a fresh install starts empty under a UUIDv7', () async {
    final store = await DriftProgressStore.open(db);
    expect(store.read().profile, isNull);
    expect(Ids.isUuid(store.read().activeChildId), isTrue);
  });

  test('a whole family round-trips through the tables', () async {
    final store = await DriftProgressStore.open(db);
    final data = family();
    await store.write(data);

    final reopened = await DriftProgressStore.open(db);
    expect(
      canonicalJson(reopened.read().toJson()),
      canonicalJson(data.toJson()),
    );
    expect(reopened.read().profile!.photo, data.profile!.photo);
  });

  test('saving one journey writes one row, not the whole family', () async {
    final store = await DriftProgressStore.open(db);
    var data = family();
    await store.write(data);

    counter.writes = 0;
    data = data.copyWith(
      journeys: {
        ...data.journeys,
        'unit_03': {...data.journeys['unit_03']!, 'index': 2},
      },
    );
    await store.write(data);
    expect(counter.writes, 1);

    counter.writes = 0;
    await store.write(
      data.copyWith(dailySeconds: {...data.dailySeconds, '2026-10-02': 40}),
    );
    expect(counter.writes, 1, reason: 'one usage row');

    counter.writes = 0;
    await store.write(store.read());
    expect(counter.writes, 0, reason: 'nothing changed');
  });

  test('deleting a child removes every dependent row', () async {
    final store = await DriftProgressStore.open(db);
    final data = family();
    await store.write(data);
    final nourId = data.activeChildId;
    await store.write(data.removeChild(nourId, emptyId: Ids.uuidV7()));

    Future<int> count(TableInfo<Table, dynamic> t) async =>
        (await db.select(t).get()).length;
    expect(await count(db.children), 1);
    expect(await count(db.childPhotos), 0);
    expect(await count(db.unitAttempts), 0);
    expect(await count(db.attemptObjectives), 0);
    expect(await count(db.journeys), 0);
    expect(await count(db.usageDaily), 0);
    expect(await count(db.otherSubjects), 0);
  });

  test('usage from another device is kept and summed', () async {
    final store = await DriftProgressStore.open(db);
    final data = family();
    await store.write(data);
    final id = data.activeChildId;
    await db
        .into(db.usageDaily)
        .insert(
          UsageDailyCompanion.insert(
            childId: id,
            deviceId: 'tablet-2',
            day: '2026-10-02',
            seconds: 100,
          ),
        );

    final reopened = await DriftProgressStore.open(db);
    final seen = reopened.read();
    expect(seen.dailySeconds['2026-10-02'], 130);
    await reopened.write(
      seen.copyWith(dailySeconds: {...seen.dailySeconds, '2026-10-02': 140}),
    );
    final rows = await db.select(db.usageDaily).get();
    expect(
      rows.firstWhere((r) => r.deviceId == 'tablet-2').seconds,
      100,
      reason: 'another device row is never overwritten',
    );
    expect(
      rows
          .firstWhere(
            (r) => r.deviceId == reopened.deviceId && r.day == '2026-10-02',
          )
          .seconds,
      40,
    );
  });

  test('constraints reject impossible values', () async {
    final store = await DriftProgressStore.open(db);
    await store.write(family());
    final child = (await db.select(db.children).get()).first.id;
    expect(
      () => db
          .into(db.unitAttempts)
          .insert(
            UnitAttemptsCompanion.insert(
              id: Ids.uuidV7(),
              childId: child,
              clientAttemptId: 'x',
              unitId: 'unit_01',
              contentVersion: 1,
              completed: true,
              effortStars: 7,
              completedAt: '2026-10-01T00:00:00.000',
              sortOrder: 0,
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
    expect(
      () => db
          .into(db.journeys)
          .insert(
            JourneysCompanion.insert(
              childId: 'missing',
              journeyKey: 'k',
              json: '{}',
              updatedAt: DateTime(2026),
            ),
          ),
      throwsA(isA<SqliteException>()),
      reason: 'foreign keys are enforced',
    );
  });
}
