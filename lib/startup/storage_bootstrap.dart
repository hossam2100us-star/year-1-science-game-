import '../core/diagnostics/app_log.dart';
import '../core/storage.dart';
import '../data/db/app_database.dart';
import '../data/drift_progress_store.dart';
import '../data/migration/hive_to_drift.dart';

/// Outcome of opening local storage at startup.
sealed class StorageOpening {}

/// Ready to play with [store].
class StorageReady extends StorageOpening {
  StorageReady(this.store, {this.migrated});
  final ProgressStore store;

  /// Set when this launch copied the Hive save into SQLite.
  final MigrationReport? migrated;
}

/// The Hive save and its last good copy cannot be read; the recovery screen
/// handles it (nothing is deleted).
class StorageUnreadable extends StorageOpening {
  StorageUnreadable(this.hive);
  final HiveProgressStore hive;
}

/// Storage could not be opened at all.
class StorageFailed extends StorageOpening {
  StorageFailed(this.error);
  final Object error;
}

/// Chooses and opens the progress store (ADR-0005, docs/MIGRATION_PLAN.md):
///
/// * migration already done → SQLite only. Hive is a frozen backup from that
///   point and is never used again, so a SQLite problem is reported rather
///   than silently showing older progress;
/// * not migrated yet → read Hive (recovery screen if unreadable), copy it
///   into SQLite in one verified transaction, then play on SQLite;
/// * the copy fails → play on Hive for this session (nothing is lost) and
///   retry next launch;
/// * web → the same, with SQLite in the browser (sqlite3.wasm, a web worker)
///   and the earlier Hive save copied into it once. If the browser's usual
///   way fails, [openFallbackDatabase] opens the same data another way
///   before giving up on the database.
Future<StorageOpening> openProgressStore({
  required Future<HiveProgressStore> Function() openHive,
  required AppDatabase Function()? openDatabase,
  AppDatabase Function()? openFallbackDatabase,
}) async {
  AppDatabase? db;
  var fallback = false;
  if (openDatabase != null) {
    final ways = [openDatabase, ?openFallbackDatabase];
    Object? failure;
    for (final open in ways) {
      fallback = open != openDatabase;
      try {
        db = open();
        if (await HiveToDriftMigration.completedIn(db)) {
          return StorageReady(await DriftProgressStore.open(db));
        }
        failure = null;
        break;
      } catch (error, stack) {
        AppLog.error('startup', 'Opening the database failed', error, stack);
        await _close(db);
        db = null;
        failure = error;
      }
    }
    // Before migration Hive still holds the only copy, so it can be used;
    // after migration _hiveOnly reports the problem instead.
    if (failure != null) return _hiveOnly(openHive, failedDatabase: failure);
  }

  final HiveProgressStore hive;
  try {
    hive = await openHive();
  } catch (error, stack) {
    AppLog.error('startup', 'Opening storage failed', error, stack);
    await _close(db);
    return StorageFailed(error);
  }
  try {
    hive.read();
  } on SaveDataUnreadable {
    await _close(db);
    return StorageUnreadable(hive);
  }
  if (db == null) return StorageReady(hive);
  if (fallback && hive.migratedToDatabase) {
    // The other way found no copied save where the usual way keeps it (for
    // example OPFS): copying the older Hive save again would hide newer
    // progress, so report it and try the usual way next launch.
    await _close(db);
    return StorageFailed(
      StateError('The saved progress is not in this browser storage'),
    );
  }

  try {
    final report = await HiveToDriftMigration(hive, db).run();
    AppLog.info('startup', 'Saved progress moved to the local database');
    return StorageReady(await DriftProgressStore.open(db), migrated: report);
  } catch (error, stack) {
    AppLog.error(
      'startup',
      'Database copy failed; using the old save',
      error,
      stack,
    );
    await _close(db);
    return StorageReady(hive);
  }
}

Future<StorageOpening> _hiveOnly(
  Future<HiveProgressStore> Function() openHive, {
  required Object failedDatabase,
}) async {
  try {
    final hive = await openHive();
    // After a migration the Hive copy is older than the database: playing on
    // it would show outdated progress, so report the problem instead.
    if (hive.migratedToDatabase) return StorageFailed(failedDatabase);
    hive.read();
    return StorageReady(hive);
  } on SaveDataUnreadable {
    return StorageFailed(failedDatabase);
  } catch (error) {
    return StorageFailed(error);
  }
}

Future<void> _close(AppDatabase? db) async {
  try {
    await db?.close();
  } catch (error, stack) {
    AppLog.warning('startup', 'Closing the database failed', error, stack);
  }
}
