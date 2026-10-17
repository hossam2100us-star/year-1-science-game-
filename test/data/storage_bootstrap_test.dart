import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/data/db/app_database.dart';
import 'package:science_adventure/data/drift_progress_store.dart';
import 'package:science_adventure/startup/storage_bootstrap.dart';

import '../web/save_model_test.dart' show child, family;

/// A database whose child inserts fail, to force a failed migration.
class RefusingDatabase extends AppDatabase {
  RefusingDatabase() : super(NativeDatabase.memory());
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        "CREATE TRIGGER refuse BEFORE INSERT ON children "
        "BEGIN SELECT RAISE(ABORT, 'disk said no'); END",
      );
    },
  );
}

void main() {
  // Two databases are open at once in the fallback tests.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late HiveProgressStore hive;
  late AppDatabase db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('science_boot_');
    Hive.init(dir.path);
    hive = HiveProgressStore(await Hive.openBox<String>('boot_test'));
    await hive.box.put(
      'data',
      jsonEncode(family({'local-child': child('Nour')}, 'local-child')),
    );
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('first launch after the update migrates and plays on SQLite', () async {
    final result = await openProgressStore(
      openHive: () async => hive,
      openDatabase: () => db,
    );
    expect(result, isA<StorageReady>());
    final ready = result as StorageReady;
    expect(ready.store, isA<DriftProgressStore>());
    expect(ready.migrated!.children, 1);
    expect(ready.store.read().profile!.name, 'Nour');
    expect(hive.migratedToDatabase, isTrue);
    expect(
      jsonDecode(hive.box.get('data')!),
      isA<Map<String, dynamic>>(),
      reason: 'the Hive save itself is untouched',
    );
  });

  test('later launches use SQLite without touching Hive', () async {
    await openProgressStore(openHive: () async => hive, openDatabase: () => db);
    final result = await openProgressStore(
      openHive: () async => throw StateError('Hive must not be opened'),
      openDatabase: () => db,
    );
    expect((result as StorageReady).store, isA<DriftProgressStore>());
    expect(result.migrated, isNull);
  });

  test(
    'database unavailable before migration: play on the Hive save',
    () async {
      final result = await openProgressStore(
        openHive: () async => hive,
        openDatabase: () => throw const FileSystemException('locked'),
      );
      expect((result as StorageReady).store, same(hive));
    },
  );

  test('database unavailable after migration: report, never show older '
      'progress', () async {
    await hive.markMigratedToDatabase();
    final result = await openProgressStore(
      openHive: () async => hive,
      openDatabase: () => throw const FileSystemException('locked'),
    );
    expect(result, isA<StorageFailed>());
  });

  test(
    'a failed copy keeps playing on the Hive save and retries later',
    () async {
      final result = await openProgressStore(
        openHive: () async => hive,
        openDatabase: RefusingDatabase.new,
      );
      expect((result as StorageReady).store, same(hive));
      expect(hive.migratedToDatabase, isFalse);
    },
  );

  test('an unreadable Hive save goes to the recovery screen', () async {
    await hive.box.put('data', 'garbage');
    final result = await openProgressStore(
      openHive: () async => hive,
      openDatabase: () => db,
    );
    expect(result, isA<StorageUnreadable>());
  });

  test('without a database the Hive store is used', () async {
    final result = await openProgressStore(
      openHive: () async => hive,
      openDatabase: null,
    );
    expect((result as StorageReady).store, same(hive));
  });

  group('the other way to open the database (browsers)', () {
    // Fails on the first query, like the browser database when its worker
    // cannot load sqlite3.wasm.
    AppDatabase unreachable() =>
        AppDatabase(LazyDatabase(() => throw StateError('Failed to fetch')));

    test('used when the usual way fails; the save is copied there', () async {
      final result = await openProgressStore(
        openHive: () async => hive,
        openDatabase: unreachable,
        openFallbackDatabase: () => db,
      );
      final ready = result as StorageReady;
      expect(ready.store, isA<DriftProgressStore>());
      expect(ready.migrated!.children, 1);
      expect(ready.store.read().profile!.name, 'Nour');
      expect(hive.migratedToDatabase, isTrue);
    });

    test('later launches find the copy that way without Hive', () async {
      await openProgressStore(
        openHive: () async => hive,
        openDatabase: () => db,
      );
      final result = await openProgressStore(
        openHive: () async => throw StateError('Hive must not be opened'),
        openDatabase: unreachable,
        openFallbackDatabase: () => db,
      );
      expect((result as StorageReady).store, isA<DriftProgressStore>());
      expect(result.migrated, isNull);
    });

    test('not tried when the usual way works', () async {
      final result = await openProgressStore(
        openHive: () async => hive,
        openDatabase: () => db,
        openFallbackDatabase: () => fail('the usual way worked'),
      );
      expect((result as StorageReady).store, isA<DriftProgressStore>());
    });

    test('both fail before migration: play on the Hive save', () async {
      final result = await openProgressStore(
        openHive: () async => hive,
        openDatabase: unreachable,
        openFallbackDatabase: unreachable,
      );
      expect((result as StorageReady).store, same(hive));
    });

    test(
      'both fail after migration: report, never show older progress',
      () async {
        await hive.markMigratedToDatabase();
        final result = await openProgressStore(
          openHive: () async => hive,
          openDatabase: unreachable,
          openFallbackDatabase: unreachable,
        );
        expect(result, isA<StorageFailed>());
      },
    );

    test('no copy that way after migration: report instead of copying the '
        'older Hive save again', () async {
      await hive.markMigratedToDatabase();
      final result = await openProgressStore(
        openHive: () async => hive,
        openDatabase: unreachable,
        openFallbackDatabase: () => db,
      );
      expect(result, isA<StorageFailed>());
    });
  });
}
