@Tags(['benchmark'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:science_adventure/core/ids.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/data/db/app_database.dart';
import 'package:science_adventure/data/drift_progress_store.dart';
import 'package:science_adventure/data/migration/hive_to_drift.dart';

/// Host-machine measurements for docs/TEST_REPORT.md (not run in CI):
///     flutter test --tags benchmark
/// Numbers are from a desktop, not a low-RAM tablet.
AppData bigFamily() {
  var data = AppData(activeChildId: Ids.uuidV7());
  for (var c = 0; c < 10; c++) {
    final child = AppData(
      activeChildId: Ids.uuidV7(),
      profile: ChildProfile(
        name: 'Child $c',
        photo: Uint8List.fromList(List.generate(300000, (i) => (i * c) % 251)),
      ),
      attempts: [
        for (var a = 0; a < 20; a++)
          UnitAttempt(
            unitId: 'unit_0${a % 9 + 1}',
            completedAt: DateTime(2026, 9, 1).add(Duration(hours: a)),
            objectives: {
              for (var o = 0; o < 10; o++)
                'obj.$a.$o': DecisionOutcome.firstTry,
            },
            completed: true,
            effortStars: 3,
            attemptId: 'unit-$a',
          ),
      ],
      journeys: {
        for (var j = 0; j < 13; j++)
          'unit_${j.toString().padLeft(2, '0')}': {
            'version': 1,
            'attemptId': 'a$j',
            'index': 3,
            'responses': {
              for (var s = 0; s < 8; s++)
                'step.$s': {'completed': true, 'outcome': 'firstTry'},
            },
            'current': {
              'selected': ['x', 'y'],
            },
          },
      },
      dailySeconds: {
        for (var d = 0; d < 60; d++)
          '2026-08-${(d % 28 + 1).toString().padLeft(2, '0')}-$d': 600,
      },
    );
    // addChild makes the new child active; then give it its progress.
    data = c == 0
        ? child
        : data
              .addChild(child.activeChildId, child.profile!)
              .copyWith(
                attempts: child.attempts,
                journeys: child.journeys,
                dailySeconds: child.dailySeconds,
              );
  }
  return data;
}

void main() {
  test('save latency and migration time on this machine', () async {
    final dir = await Directory.systemTemp.createTemp('science_bench_');
    Hive.init(dir.path);
    final hive = HiveProgressStore(await Hive.openBox<String>('bench'));
    final data = bigFamily();
    final active = data.activeChildId;
    Map<String, dynamic> journeyAt(int i) => {
      ...data.journeys.values.first,
      'index': i,
    };

    await hive.write(data);
    final blobBytes = utf8.encode(hive.box.get('data')!).length;
    final hiveWatch = Stopwatch()..start();
    var current = data;
    for (var i = 0; i < 20; i++) {
      current = current.copyWith(
        journeys: {...current.journeys, 'unit_00': journeyAt(i)},
      );
      await hive.write(current);
    }
    final hiveMs = hiveWatch.elapsedMicroseconds / 20 / 1000;

    final db = AppDatabase(NativeDatabase(File('${dir.path}/bench.sqlite')));
    final migrationWatch = Stopwatch()..start();
    final report = await HiveToDriftMigration(hive, db).run();
    final migrationMs = migrationWatch.elapsedMilliseconds;

    final store = await DriftProgressStore.open(db);
    var drift = store.read();
    final driftWatch = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      drift = drift.copyWith(
        journeys: {...drift.journeys, 'unit_00': journeyAt(i)},
      );
      await store.write(drift);
    }
    final driftMs = driftWatch.elapsedMicroseconds / 20 / 1000;

    // ignore: avoid_print
    print(
      'BENCH children=${report.children} attempts=${report.attempts} '
      'objectives=${report.objectives} journeys=${report.journeys} '
      'usageDays=${report.usageDays} blobBytes=$blobBytes '
      'hiveSaveMs=${hiveMs.toStringAsFixed(1)} '
      'sqliteSaveMs=${driftMs.toStringAsFixed(1)} '
      'migrationMs=$migrationMs active=${active.isNotEmpty}',
    );
    await db.close();
    await Hive.close();
    await dir.delete(recursive: true);
  });
}
