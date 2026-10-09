import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/ids.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/data/db/app_database.dart';
import 'package:science_adventure/data/drift_progress_store.dart';
import 'package:science_adventure/data/sync/outbox.dart';
import 'package:science_adventure/data/sync/sync_store.dart';

UnitAttempt attempt(String id) => UnitAttempt(
  unitId: 'unit_02',
  completedAt: DateTime(2026, 10, 9, 9, 30),
  objectives: const {'o.1': DecisionOutcome.firstTry},
  completed: true,
  effortStars: 3,
  attemptId: id,
);

void main() {
  late AppDatabase db;
  late DriftProgressStore store;
  late SyncStore sync;
  late String childId;

  /// What the outbox holds, oldest first: `entity op` plus the mutation.
  Future<List<Map<String, dynamic>>> queued() async {
    final rows = await (db.select(
      db.outbox,
    )..orderBy([(t) => OrderingTerm(expression: t.seq)])).get();
    return [for (final r in rows) SyncOutbox.decode(r)];
  }

  List<String> ops(List<Map<String, dynamic>> q) => [
    for (final m in q) '${m['entity']} ${m['op']}',
  ];

  Future<void> save(AppData Function(AppData) change) =>
      store.write(change(store.read()));

  /// The server confirmed everything waiting (versions as given).
  Future<void> confirmAll({int version = 1}) async {
    final rows = await sync.outbox.takeBatch();
    await sync.applyResults(rows, [
      for (final r in rows)
        {'mutationId': r.mutationId, 'status': 'applied', 'version': version},
    ]);
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    store = await DriftProgressStore.open(db);
    sync = SyncStore(db, deviceId: store.deviceId);
    childId = Ids.uuidV7();
    await store.write(
      AppData(
        activeChildId: childId,
        profile: const ChildProfile(name: 'Laila', gender: ChildGender.girl),
        attempts: [attempt('unit_02-1')],
        journeys: const {
          'unit_01.garden': {'version': 1, 'results': <String, dynamic>{}},
        },
        dailySeconds: const {'2026-10-09': 300},
      ),
    );
  });

  tearDown(() => db.close());

  test('a child that is not linked never queues anything', () async {
    await save((d) => d.copyWith(attempts: [...d.attempts, attempt('x-2')]));
    await save(
      (d) => d.copyWith(settings: d.settings.copyWith(breakMinutes: 20)),
    );
    expect(await queued(), isEmpty);
  });

  group('linking', () {
    test('queues everything the child has, in order', () async {
      await sync.useAccount('parent-1');
      await sync.link(childId);
      await store.reload();
      final q = await queued();
      expect(ops(q), [
        'child create',
        'settings patch',
        'attempt create',
        'journey put',
        'usage put',
      ]);
      expect(q[0]['payload'], {
        'displayName': 'Laila',
        'gender': 'girl',
        'avatar': 0,
        'palette': 'automatic',
        'settings': const AppSettings().toJson(),
      });
      final row = (await db.select(db.unitAttempts).get()).single;
      expect(q[2]['id'], row.id);
      expect(q[2]['payload'], {
        'curriculum': 'y1.science',
        'unitId': 'unit_02',
        'contentVersion': 1,
        'completed': true,
        'effortStars': 3,
        'completedAt': '2026-10-09T09:30:00.000',
        'clientAttemptId': 'unit_02-1',
        'objectives': {'o.1': 'firstTry'},
      });
      expect(q[4]['payload'], {'seconds': 300});
      expect(store.linkedChildren, {childId});
    });

    test('refuses a child whose name the account would reject', () async {
      await save(
        (d) => d.copyWith(profile: const ChildProfile(name: 'Laila 2')),
      );
      await expectLater(
        sync.link(childId),
        throwsA(
          isA<LinkException>().having(
            (e) => e.problem,
            'problem',
            LinkProblem.name,
          ),
        ),
      );
      expect(await queued(), isEmpty);
    });

    test(
      'a change before the child reached the server joins the create',
      () async {
        await sync.useAccount('parent-1');
        await sync.link(childId);
        await store.reload();
        await save(
          (d) => d.copyWith(profile: const ChildProfile(name: 'Lulu')),
        );
        await save(
          (d) => d.copyWith(settings: d.settings.copyWith(music: false)),
        );
        final q = await queued();
        expect(ops(q).where((o) => o.startsWith('child')), ['child create']);
        expect((q[0]['payload'] as Map)['displayName'], 'Lulu');
        expect(((q[0]['payload'] as Map)['settings'] as Map)['music'], isFalse);
        // The settings sent with the link must not undo the change.
        expect((q[1]['payload'] as Map)['music'], isFalse);
      },
    );
  });

  group('a linked child', () {
    setUp(() async {
      await sync.useAccount('parent-1');
      await sync.link(childId);
      await store.reload();
      await confirmAll(version: 1);
    });

    test('keeps its server version when the profile is saved', () async {
      await save((d) => d.copyWith(profile: const ChildProfile(name: 'Lulu')));
      final row = (await db.select(db.children).get()).single;
      expect(row.version, 1);
      expect(row.syncStatus, 'linked');
    });

    test('queues one patch per child with the first base values', () async {
      await save(
        (d) => d.copyWith(
          profile: const ChildProfile(name: 'Lulu', gender: ChildGender.girl),
        ),
      );
      await save(
        (d) => d.copyWith(
          profile: const ChildProfile(
            name: 'Lola',
            gender: ChildGender.girl,
            avatar: 2,
          ),
        ),
      );
      final q = await queued();
      expect(ops(q), ['child patch']);
      expect(q.single['payload'], {'displayName': 'Lola', 'avatar': 2});
      expect(q.single['base'], {'displayName': 'Laila', 'avatar': 0});
      expect(q.single['baseVersion'], 1);
    });

    test('a change after a patch was sent goes into a new entry', () async {
      await save((d) => d.copyWith(profile: const ChildProfile(name: 'Lulu')));
      final sent = await sync.outbox.takeBatch();
      await sync.outbox.release([for (final r in sent) r.seq], 'offline');
      await save((d) => d.copyWith(profile: const ChildProfile(name: 'Lola')));
      final q = await queued();
      expect(ops(q), ['child patch', 'child patch']);
      expect(q[0]['payload'], containsPair('displayName', 'Lulu'));
      expect(q[1]['base'], containsPair('displayName', 'Lulu'));
    });

    test('progress is queued as it is saved', () async {
      await save(
        (d) => d.copyWith(
          attempts: [...d.attempts, attempt('unit_02-2')],
          journeys: {
            ...d.journeys,
            'unit_03': {'version': 1, 'index': 1},
          },
        ),
      );
      await save(
        (d) => d.copyWith(
          journeys: {
            ...d.journeys,
            'unit_03': {'version': 1, 'index': 2},
          },
          dailySeconds: {'2026-10-09': 360},
        ),
      );
      await save((d) => d.copyWith(dailySeconds: {'2026-10-09': 420}));
      final q = await queued();
      expect(ops(q), ['attempt create', 'journey put', 'usage put']);
      expect((q[1]['payload'] as Map)['state'], {'version': 1, 'index': 2});
      expect(q[2]['payload'], {'seconds': 420});
    });

    test('a reset queues deletions; finished play time stays', () async {
      await save((d) => d.resetProgress());
      final q = await queued();
      expect(ops(q), ['attempt delete', 'journey delete']);
    });

    test('deleting the child replaces what was waiting', () async {
      await save((d) => d.copyWith(profile: const ChildProfile(name: 'Lulu')));
      await save(
        (d) => d.addChild(Ids.uuidV7(), const ChildProfile(name: 'Omar')),
      );
      await save((d) => d.removeChild(childId, emptyId: Ids.uuidV7()));
      final q = await queued();
      expect(ops(q), ['child delete']);
      expect(q.single['id'], childId);
    });
  });

  test('deleting a child the server never received sends nothing', () async {
    await sync.useAccount('parent-1');
    await sync.link(childId);
    await store.reload();
    await save(
      (d) => d.addChild(Ids.uuidV7(), const ChildProfile(name: 'Omar')),
    );
    await save((d) => d.removeChild(childId, emptyId: Ids.uuidV7()));
    expect(await queued(), isEmpty);
  });
}
