import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/diagnostics/app_log.dart';
import '../../core/ids.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../domain/canonical_json.dart';
import '../db/app_database.dart';
import '../drift_progress_store.dart';
import '../repositories.dart';

/// Counts and timing of one migration run, stored in app meta (no
/// telemetry) and shown in diagnostics.
class MigrationReport {
  MigrationReport({
    required this.children,
    required this.attempts,
    required this.objectives,
    required this.journeys,
    required this.usageDays,
    required this.subjects,
    required this.quarantined,
    required this.renamedIds,
    required this.milliseconds,
    this.dryRun = false,
    this.skipped = false,
  });

  final int children, attempts, objectives, journeys, usageDays, subjects;
  final int quarantined, renamedIds, milliseconds;
  final bool dryRun, skipped;

  Map<String, Object> toJson() => {
    'children': children,
    'attempts': attempts,
    'objectives': objectives,
    'journeys': journeys,
    'usageDays': usageDays,
    'subjects': subjects,
    'quarantined': quarantined,
    'renamedIds': renamedIds,
    'milliseconds': milliseconds,
    'dryRun': dryRun,
  };
}

/// The copy in SQLite does not match what was read from Hive. The
/// transaction is rolled back and Hive is untouched.
class MigrationVerificationError extends Error {
  MigrationVerificationError(this.what);
  final String what;
  @override
  String toString() => 'MigrationVerificationError($what)';
}

class _DryRunRollback implements Exception {
  const _DryRunRollback(this.report);
  final MigrationReport report;
}

/// One-time copy of the Hive save into SQLite with zero data loss
/// (docs/MIGRATION_PLAN.md, AUD-004/AUD-006):
///
/// 1. read Hive with the tolerant per-child reader (last-good fallback);
/// 2. give every non-UUID child ID a UUIDv7, keeping the old one as
///    `legacy_id`;
/// 3. write all rows in ONE transaction, together with the quarantined
///    records and any raw unreadable Hive copies;
/// 4. read the rows back and compare every child record and every count;
///    any difference rolls the whole transaction back;
/// 5. mark success in app meta. Hive itself is never modified.
class HiveToDriftMigration {
  HiveToDriftMigration(this.hive, this.db, {this.beforeVerify});
  final HiveProgressStore hive;
  final AppDatabase db;

  /// Test hook: runs inside the transaction after the rows are written.
  final Future<void> Function()? beforeVerify;

  static const statusKey = 'migration.hive_v3';
  static const reportKey = 'migration.hive_v3.report';

  Future<bool> get completed => completedIn(db);

  static Future<bool> completedIn(AppDatabase db) async =>
      await db.meta(statusKey) == 'completed';

  /// Runs the migration (or, with [dryRun], performs every step and then
  /// rolls back). Throws [SaveDataUnreadable] if Hive cannot be read at all
  /// and [MigrationVerificationError] if the copy does not match.
  Future<MigrationReport> run({bool dryRun = false}) async {
    if (await completed) return _skipped();
    final clock = Stopwatch()..start();
    final source = hive.read();
    final idMap = {
      for (final id in source.childRecords.keys)
        id: Ids.isUuid(id) ? id : Ids.uuidV7(),
    };
    final target = _renamed(source, idMap);
    final expected = {
      for (final e in source.childRecords.entries)
        idMap[e.key]!: canonicalJson(_normalised(e.value)),
    };

    try {
      final report = await db.transaction(() async {
        final store = await DriftProgressStore.open(db);
        await store.write(target);
        for (final e in idMap.entries) {
          if (e.key != e.value) {
            await (db.update(db.children)..where((t) => t.id.equals(e.value)))
                .write(ChildrenCompanion(legacyId: Value(e.key)));
          }
        }
        final rawCopies = hive.rawUnreadableCopies();
        final quarantine = QuarantineRepository(db);
        for (final copy in rawCopies.entries) {
          await quarantine.add('hive:${copy.key}', null, copy.value);
        }
        await beforeVerify?.call();

        final report = await _verify(
          expected,
          target,
          rawCopies.length,
          idMap,
          clock,
          dryRun,
        );
        if (dryRun) throw _DryRunRollback(report);
        await db.setMeta(reportKey, jsonEncode(report.toJson()));
        await db.setMeta(statusKey, 'completed');
        return report;
      });
      // Freeze the Hive copy: it must never be played on again.
      await hive.markMigratedToDatabase();
      return report;
    } on _DryRunRollback catch (rollback) {
      return rollback.report;
    } on Object catch (error, stack) {
      AppLog.error(
        'migration',
        'Hive to SQLite migration rolled back',
        error,
        stack,
      );
      rethrow;
    }
  }

  Future<MigrationReport> _verify(
    Map<String, String> expected,
    AppData target,
    int rawCopies,
    Map<String, String> idMap,
    Stopwatch clock,
    bool dryRun,
  ) async {
    final reopened = await DriftProgressStore.open(db);
    final actual = reopened.read();
    final records = actual.childRecords;
    if (!_sameKeys(records.keys, expected.keys)) {
      throw MigrationVerificationError('child set');
    }
    for (final e in expected.entries) {
      if (canonicalJson(_normalised(records[e.key]!)) != e.value) {
        throw MigrationVerificationError('child record');
      }
    }
    if (actual.activeChildId != target.activeChildId) {
      throw MigrationVerificationError('active child');
    }
    if (!_sameKeys(
      actual.quarantinedChildren.keys,
      target.quarantinedChildren.keys,
    )) {
      throw MigrationVerificationError('quarantine');
    }

    // Table counts must equal what the source contained.
    var attempts = 0, objectives = 0, journeys = 0, usage = 0, subjects = 0;
    for (final record in target.childRecords.values) {
      final child = AppData.fromJson(record);
      attempts += child.attempts.length;
      objectives += child.attempts.fold(0, (n, a) => n + a.objectives.length);
      journeys += child.journeys.length;
      final maths = child.progressForSubject('maths');
      attempts += maths.attempts.length;
      objectives += maths.attempts.fold(0, (n, a) => n + a.objectives.length);
      journeys += maths.journeys.length;
      usage += child.dailySeconds.length;
      subjects += child.otherSubjects.length;
    }
    Future<int> rows(TableInfo<Table, dynamic> t) async =>
        (await db
                .customSelect(
                  'SELECT COUNT(*) AS c FROM "${t.actualTableName}"',
                )
                .getSingle())
            .read<int>('c');
    final quarantined = target.quarantinedChildren.length + rawCopies;
    for (final (name, table, count)
        in <(String, TableInfo<Table, dynamic>, int)>[
          ('children', db.children, target.childRecords.length),
          ('attempts', db.unitAttempts, attempts),
          ('objectives', db.attemptObjectives, objectives),
          ('journeys', db.journeys, journeys),
          ('usage', db.usageDaily, usage),
          ('subjects', db.otherSubjects, subjects),
          ('quarantine', db.quarantinedRecords, quarantined),
        ]) {
      if (await rows(table) != count) throw MigrationVerificationError(name);
    }
    return MigrationReport(
      children: target.childRecords.length,
      attempts: attempts,
      objectives: objectives,
      journeys: journeys,
      usageDays: usage,
      subjects: subjects,
      quarantined: quarantined,
      renamedIds: idMap.entries.where((e) => e.key != e.value).length,
      milliseconds: clock.elapsedMilliseconds,
      dryRun: dryRun,
    );
  }

  MigrationReport _skipped() => MigrationReport(
    children: 0,
    attempts: 0,
    objectives: 0,
    journeys: 0,
    usageDays: 0,
    subjects: 0,
    quarantined: 0,
    renamedIds: 0,
    milliseconds: 0,
    skipped: true,
  );

  static bool _sameKeys(Iterable<String> a, Iterable<String> b) =>
      a.toSet().length == b.toSet().length && a.toSet().containsAll(b);

  /// Any stored child record (schema 1 or 2) in its current-schema form.
  static Map<String, dynamic> _normalised(Map<String, dynamic> record) =>
      AppData.fromJson(record).activeChildRecord;

  /// The same family with child IDs replaced through [idMap].
  static AppData _renamed(AppData data, Map<String, String> idMap) {
    final json = data.toJson();
    final children = json['children'] as Map<String, Map<String, dynamic>>;
    return AppData.fromJson({
      ...json,
      'activeChildId': idMap[data.activeChildId],
      'children': {for (final e in children.entries) idMap[e.key]!: e.value},
    });
  }
}
