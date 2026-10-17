import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

const appDatabaseName = 'science_adventure';

/// The app's SQLite database on Android (and on a computer in tests).
/// [fallback] is for the browser only.
QueryExecutor appDatabaseConnection({bool fallback = false}) =>
    driftDatabase(name: appDatabaseName);
