import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:science_adventure/core/ids.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/data/db/app_database.dart';
import 'package:science_adventure/data/drift_progress_store.dart';
import 'package:science_adventure/data/migration/hive_to_drift.dart';
import 'package:science_adventure/domain/canonical_json.dart';

import '../web/save_model_test.dart' show child, family;

/// Migration test matrix (docs/MIGRATION_PLAN.md §4, AUD-004).
void main() {
  late Directory dir;
  late Box<String> box;
  late HiveProgressStore hive;
  late AppDatabase db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('science_migration_');
    Hive.init(dir.path);
    box = await Hive.openBox<String>('migration_test');
    hive = HiveProgressStore(box);
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Future<void> save(Map<String, Object?> blob) =>
      box.put('data', jsonEncode(blob));

  Future<int> count(TableInfo<Table, dynamic> t) async =>
      (await db.select(t).get()).length;

  /// Child records as the app sees them after migration, keyed by legacy id.
  Future<Map<String, String>> migratedByLegacyId() async {
    final store = await DriftProgressStore.open(db);
    final rows = await db.select(db.children).get();
    final legacy = {for (final r in rows) r.id: r.legacyId ?? r.id};
    return {
      for (final e in store.read().childRecords.entries)
        legacy[e.key]!: canonicalJson(
          AppData.fromJson(e.value).activeChildRecord,
        ),
    };
  }

  String normalised(Map<String, dynamic> record) =>
      canonicalJson(AppData.fromJson(record).activeChildRecord);

  test('empty install: one empty profile, marked complete', () async {
    final report = await HiveToDriftMigration(hive, db).run();
    expect(report.children, 1);
    expect(await HiveToDriftMigration(hive, db).completed, isTrue);
    final store = await DriftProgressStore.open(db);
    expect(store.read().profile, isNull);
    expect(Ids.isUuid(store.read().activeChildId), isTrue);
  });

  test('one child: every record survives and gets a UUIDv7', () async {
    await save(family({'local-child': child('Nour')}, 'local-child'));
    final report = await HiveToDriftMigration(hive, db).run();
    expect(report.children, 1);
    expect(report.attempts, 1);
    expect(report.objectives, 1);
    expect(report.journeys, 1);
    expect(report.usageDays, 1);
    expect(report.renamedIds, 1);
    final row = (await db.select(db.children).get()).single;
    expect(Ids.isUuid(row.id), isTrue);
    expect(row.legacyId, 'local-child');
    expect(
      (await migratedByLegacyId())['local-child'],
      normalised(child('Nour')),
    );
    final attempt = (await db.select(db.unitAttempts).get()).single;
    expect(
      attempt.clientAttemptId,
      'unit_02-1',
      reason: 'legacy attempt id kept',
    );
  });

  test('several children, active child and a UUID id kept as is', () async {
    final uuid = Ids.uuidV7();
    final hex = 'ab' * 16;
    await save(
      family({
        'local-child': child('Nour'),
        hex: child('Adam'),
        uuid: child('Sara', gender: 'girl'),
      }, hex),
    );
    final report = await HiveToDriftMigration(hive, db).run();
    expect(report.children, 3);
    expect(report.renamedIds, 2);
    final migrated = await migratedByLegacyId();
    expect(migrated.keys, unorderedEquals(['local-child', hex, uuid]));
    final store = await DriftProgressStore.open(db);
    expect(store.read().profile!.name, 'Adam', reason: 'active child kept');
    expect(store.read().childRecords.containsKey(uuid), isTrue);
  });

  test('a damaged child is quarantined verbatim, the others migrate', () async {
    final damaged = {'schemaVersion': 2, 'profile': 'garbled'};
    await save(
      family({'local-child': child('Nour'), 'bad': damaged}, 'local-child'),
    );
    final report = await HiveToDriftMigration(hive, db).run();
    expect(report.children, 1);
    expect(report.quarantined, 1);
    final row = (await db.select(db.quarantinedRecords).get()).single;
    expect(row.source, 'child');
    expect(row.legacyId, 'bad');
    expect(jsonDecode(row.rawJson), damaged);
  });

  test('legacy single-child v1 save migrates', () async {
    final v1 = {
      'schemaVersion': 1,
      'profile': child('Nour')['profile'],
      'settings': const AppSettings().toJson(),
      'dailySeconds': {'2026-09-28': 120},
      'attempts': [
        UnitAttempt(
          unitId: 'unit_01',
          completedAt: DateTime(2026, 9, 28, 8),
          objectives: const {'u01.main.01': DecisionOutcome.afterHint},
          completed: true,
          effortStars: 2,
          attemptId: 'unit_01-9',
        ).toJson(),
      ],
      'journeys': {
        'unit_02': {'index': 4},
      },
    };
    await save(v1);
    final report = await HiveToDriftMigration(hive, db).run();
    expect(report.attempts, 1);
    expect(report.journeys, 1);
    expect((await migratedByLegacyId()).values.single, normalised(v1));
  });

  test('an active journey, usage across days and a photo are exact', () async {
    final photo = base64Encode(
      Uint8List.fromList(List.generate(999, (i) => i % 256)),
    );
    final record = child('Nour')
      ..['profile'] = {...(child('Nour')['profile'] as Map), 'photo': photo}
      ..['dailySeconds'] = {'2026-10-01': 3599, '2026-10-02': 1};
    (record['subjects'] as Map)['math'] = {'saved': true};
    await save(family({'local-child': record}, 'local-child'));
    await HiveToDriftMigration(hive, db).run();
    expect((await migratedByLegacyId())['local-child'], normalised(record));
    expect(await count(db.childPhotos), 1);
    expect(await count(db.usageDaily), 2);
    expect(await count(db.otherSubjects), 1);
  });

  test('unreadable main copy: migrates the last good copy and keeps the '
      'unreadable one in quarantine', () async {
    await hive.write(
      AppData.fromJson(family({'local-child': child('Nour')}, 'local-child')),
    );
    await box.put('data', '{"schemaVersion": 3, broken');
    final report = await HiveToDriftMigration(hive, db).run();
    expect(report.children, 1);
    final quarantined = await db.select(db.quarantinedRecords).get();
    expect(quarantined.single.source, 'hive:data.unreadable');
    expect(
      jsonDecode(quarantined.single.rawJson),
      '{"schemaVersion": 3, broken',
    );
  });

  test('both Hive copies unreadable: nothing is migrated or deleted', () async {
    await box.put('data', 'garbage');
    expect(
      () => HiveToDriftMigration(hive, db).run(),
      throwsA(isA<SaveDataUnreadable>()),
    );
    expect(await count(db.children), 0);
    expect(box.get('data'), 'garbage');
  });

  test(
    'an interrupted migration rolls back completely and can run again',
    () async {
      await save(family({'local-child': child('Nour')}, 'local-child'));
      final before = box.get('data');
      await expectLater(
        HiveToDriftMigration(
          hive,
          db,
          beforeVerify: () async => throw StateError('power cut'),
        ).run(),
        throwsStateError,
      );
      for (final t in <TableInfo<Table, dynamic>>[
        db.children,
        db.unitAttempts,
        db.journeys,
        db.usageDaily,
      ]) {
        expect(await count(t), 0, reason: t.actualTableName);
      }
      expect(await HiveToDriftMigration(hive, db).completed, isFalse);
      expect(box.get('data'), before, reason: 'Hive is never modified');

      final report = await HiveToDriftMigration(hive, db).run();
      expect(report.children, 1);
    },
  );

  test('a copy that does not match is rejected and rolled back', () async {
    await save(family({'local-child': child('Nour')}, 'local-child'));
    await expectLater(
      HiveToDriftMigration(
        hive,
        db,
        beforeVerify: () => db.delete(db.journeys).go(),
      ).run(),
      throwsA(isA<MigrationVerificationError>()),
    );
    expect(await count(db.children), 0);
  });

  test('re-running after success is a no-op', () async {
    await save(family({'local-child': child('Nour')}, 'local-child'));
    await HiveToDriftMigration(hive, db).run();
    final again = await HiveToDriftMigration(hive, db).run();
    expect(again.skipped, isTrue);
    expect(await count(db.children), 1);
  });

  test('dry run reports and leaves nothing behind', () async {
    await save(family({'local-child': child('Nour')}, 'local-child'));
    final report = await HiveToDriftMigration(hive, db).run(dryRun: true);
    expect(report.dryRun, isTrue);
    expect(report.children, 1);
    expect(await count(db.children), 0);
    expect(await HiveToDriftMigration(hive, db).completed, isFalse);
  });
}
