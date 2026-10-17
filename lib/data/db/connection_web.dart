import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import '../../core/diagnostics/app_log.dart';

const appDatabaseName = 'science_adventure';
final _sqlite3 = Uri.parse('sqlite3.wasm');
final _worker = Uri.parse('drift_worker.js');

/// The app's SQLite database in the browser: web/sqlite3.wasm with drift's
/// worker (web/drift_worker.js), kept in OPFS or IndexedDB as the browser
/// allows.
///
/// [fallback] opens the same IndexedDB data without a shared worker, for a
/// browser whose shared worker cannot load sqlite3.wasm (an embedded
/// Chromium did this). Tabs are not coordinated in that mode, so it is only
/// used when the usual way fails.
QueryExecutor appDatabaseConnection({bool fallback = false}) =>
    DatabaseConnection.delayed(
      Future(() async {
        if (!fallback) {
          final result = await WasmDatabase.open(
            databaseName: appDatabaseName,
            sqlite3Uri: _sqlite3,
            driftWorkerUri: _worker,
          );
          AppLog.info(
            'database',
            'Browser storage: ${result.chosenImplementation.name}',
          );
          return result.resolvedExecutor;
        }
        final probed = await WasmDatabase.probe(
          sqlite3Uri: _sqlite3,
          driftWorkerUri: _worker,
          databaseName: appDatabaseName,
        );
        if (!probed.availableStorages.contains(
          WasmStorageImplementation.unsafeIndexedDb,
        )) {
          throw StateError('This browser has no IndexedDB storage');
        }
        AppLog.info('database', 'Browser storage: IndexedDB, one tab');
        return probed.open(
          WasmStorageImplementation.unsafeIndexedDb,
          appDatabaseName,
        );
      }),
    );
