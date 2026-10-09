import 'dart:convert';

import 'package:drift/drift.dart';

import '../content/curriculum.dart';
import '../core/ids.dart';
import '../core/models.dart';
import 'db/app_database.dart';

/// Row-level access to children and their profiles (AUD-004). Repositories
/// never see Flutter widgets or Hive; the UI never sees SQL.
class ChildRepository {
  ChildRepository(this.db);
  final AppDatabase db;

  Future<void> upsertProfile(
    String id, {
    required ChildProfile? profile,
    required bool pendingPhoto,
    required int sortOrder,
    String? legacyId,
  }) => db
      .into(db.children)
      .insertOnConflictUpdate(
        ChildrenCompanion.insert(
          id: id,
          legacyId: Value.absentIfNull(legacyId),
          hasProfile: profile != null,
          displayName: Value(profile?.name ?? ''),
          gender: Value((profile?.gender ?? ChildGender.boy).name),
          avatar: Value(profile?.avatar ?? 0),
          palette: Value((profile?.palette ?? PaletteChoice.automatic).name),
          pendingPhoto: Value(pendingPhoto),
          sortOrder: sortOrder,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

  Future<void> setPhoto(String id, Uint8List? bytes) async {
    if (bytes == null) {
      await (db.delete(
        db.childPhotos,
      )..where((t) => t.childId.equals(id))).go();
    } else {
      await db
          .into(db.childPhotos)
          .insertOnConflictUpdate(
            ChildPhotosCompanion.insert(childId: id, bytes: bytes),
          );
    }
  }

  /// Deleting a child removes every dependent row (foreign-key cascade).
  Future<void> delete(String id) =>
      (db.delete(db.children)..where((t) => t.id.equals(id))).go();

  Future<List<ChildRow>> all() => (db.select(
    db.children,
  )..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).get();

  Future<ChildRow?> row(String id) =>
      (db.select(db.children)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Uint8List?> photo(String id) async => (await (db.select(
    db.childPhotos,
  )..where((t) => t.childId.equals(id))).getSingleOrNull())?.bytes;
}

class SettingsRepository {
  SettingsRepository(this.db);
  final AppDatabase db;

  Future<void> put(String childId, Map<String, dynamic> settings) => db
      .into(db.childSettings)
      .insertOnConflictUpdate(
        ChildSettingsCompanion.insert(
          childId: childId,
          json: jsonEncode(settings),
        ),
      );

  Future<Map<String, dynamic>?> get(String childId) async {
    final row = await (db.select(
      db.childSettings,
    )..where((t) => t.childId.equals(childId))).getSingleOrNull();
    return row == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(row.json) as Map);
  }

  /// The server version these settings are based on (0: never synced).
  Future<int> version(String childId) async =>
      (await (db.select(
        db.childSettings,
      )..where((t) => t.childId.equals(childId))).getSingleOrNull())?.version ??
      0;
}

/// Attempts, journeys, usage and other-subject records.
class ProgressRepository {
  ProgressRepository(this.db, {this.curriculum = currentCurriculum});
  final AppDatabase db;

  /// Attempts and journeys of other curricula are never read or changed.
  final String curriculum;

  /// Brings the child's stored attempts in line with [attempts] while keeping
  /// every existing row's ID (sync identifies an attempt by that ID, so an
  /// attempt must never get a new one). Attempts are append-only in normal
  /// play; a progress reset removes them. Returns the rows added (with their
  /// new IDs) and the IDs of rows removed.
  Future<
    ({List<({String id, UnitAttempt attempt})> added, List<String> removed})
  >
  replaceAttempts(String childId, List<UnitAttempt> attempts) async {
    final rows = await attemptRows(childId);
    final pool = <String, List<AttemptRow>>{};
    for (final row in rows) {
      pool.putIfAbsent(_rowKey(row.row, row.objectives), () => []).add(row.row);
    }
    final kept = <String>{};
    final added = <({String id, UnitAttempt attempt})>[];
    for (var i = 0; i < attempts.length; i++) {
      final a = attempts[i];
      final match = pool[attemptKey(a)];
      if (match != null && match.isNotEmpty) {
        final row = match.removeAt(0);
        kept.add(row.id);
        if (row.sortOrder != i) {
          await (db.update(db.unitAttempts)..where((t) => t.id.equals(row.id)))
              .write(UnitAttemptsCompanion(sortOrder: Value(i)));
        }
        continue;
      }
      final id = Ids.uuidV7();
      added.add((id: id, attempt: a));
      await db
          .into(db.unitAttempts)
          .insert(
            UnitAttemptsCompanion.insert(
              id: id,
              childId: childId,
              curriculum: curriculum,
              clientAttemptId: a.attemptId,
              unitId: a.unitId,
              contentVersion: a.contentVersion,
              completed: a.completed,
              effortStars: a.effortStars,
              completedAt: a.completedAt.toIso8601String(),
              sortOrder: i,
            ),
          );
      for (final o in a.objectives.entries) {
        await db
            .into(db.attemptObjectives)
            .insert(
              AttemptObjectivesCompanion.insert(
                attemptId: id,
                objectiveId: o.key,
                outcome: o.value.name,
              ),
            );
      }
    }
    final removed = [
      for (final r in rows)
        if (!kept.contains(r.row.id)) r.row.id,
    ];
    for (final id in removed) {
      await (db.delete(db.unitAttempts)..where((t) => t.id.equals(id))).go();
    }
    return (added: added, removed: removed);
  }

  /// Identity of an attempt: the app's own attempt ID when it has one,
  /// otherwise everything recorded about it (very old saves had no ID).
  static String attemptKey(UnitAttempt a) => a.attemptId.isNotEmpty
      ? 'id:${a.attemptId}'
      : 'v:${jsonEncode([a.unitId, a.completedAt.toIso8601String(), a.completed, a.effortStars, a.contentVersion, (a.objectives.entries.map((e) => '${e.key}=${e.value.name}').toList()..sort())])}';

  static String _rowKey(AttemptRow row, List<ObjectiveRow> objectives) =>
      row.clientAttemptId.isNotEmpty
      ? 'id:${row.clientAttemptId}'
      : 'v:${jsonEncode([row.unitId, DateTime.parse(row.completedAt).toIso8601String(), row.completed, row.effortStars, row.contentVersion, (objectives.map((o) => '${o.objectiveId}=${o.outcome}').toList()..sort())])}';

  Future<List<({AttemptRow row, List<ObjectiveRow> objectives})>> attemptRows(
    String childId,
  ) async {
    final rows =
        await (db.select(db.unitAttempts)
              ..where(
                (t) =>
                    t.childId.equals(childId) & t.curriculum.equals(curriculum),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
            .get();
    return [
      for (final row in rows)
        (
          row: row,
          objectives: await (db.select(
            db.attemptObjectives,
          )..where((t) => t.attemptId.equals(row.id))).get(),
        ),
    ];
  }

  Future<List<UnitAttempt>> attempts(String childId) async {
    final rows =
        await (db.select(db.unitAttempts)
              ..where(
                (t) =>
                    t.childId.equals(childId) & t.curriculum.equals(curriculum),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
            .get();
    final result = <UnitAttempt>[];
    for (final row in rows) {
      final objectives = await (db.select(
        db.attemptObjectives,
      )..where((t) => t.attemptId.equals(row.id))).get();
      result.add(
        UnitAttempt(
          unitId: row.unitId,
          completedAt: DateTime.parse(row.completedAt),
          objectives: {
            for (final o in objectives)
              o.objectiveId: DecisionOutcome.values.byName(o.outcome),
          },
          completed: row.completed,
          effortStars: row.effortStars,
          attemptId: row.clientAttemptId,
          contentVersion: row.contentVersion,
        ),
      );
    }
    return result;
  }

  Future<void> putJourney(
    String childId,
    String key,
    Map<String, dynamic> json,
  ) => db
      .into(db.journeys)
      .insertOnConflictUpdate(
        JourneysCompanion.insert(
          childId: childId,
          curriculum: curriculum,
          journeyKey: key,
          json: jsonEncode(json),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

  Future<void> deleteJourney(String childId, String key) =>
      (db.delete(db.journeys)..where(
            (t) =>
                t.childId.equals(childId) &
                t.curriculum.equals(curriculum) &
                t.journeyKey.equals(key),
          ))
          .go();

  /// The server version the stored journey is based on (0: never synced).
  Future<int> journeyVersion(String childId, String key) async =>
      (await (db.select(db.journeys)..where(
                (t) =>
                    t.childId.equals(childId) &
                    t.curriculum.equals(curriculum) &
                    t.journeyKey.equals(key),
              ))
              .getSingleOrNull())
          ?.version ??
      0;

  Future<Map<String, Map<String, dynamic>>> journeys(String childId) async {
    final rows =
        await (db.select(db.journeys)..where(
              (t) =>
                  t.childId.equals(childId) & t.curriculum.equals(curriculum),
            ))
            .get();
    return {
      for (final r in rows)
        r.journeyKey: Map<String, dynamic>.from(jsonDecode(r.json) as Map),
    };
  }

  /// Per-device counters; the total for a day is the sum over devices (a
  /// grow-only counter that sync can merge without losing time).
  Future<void> putUsage(
    String childId,
    String deviceId,
    String day,
    int seconds,
  ) => db
      .into(db.usageDaily)
      .insertOnConflictUpdate(
        UsageDailyCompanion.insert(
          childId: childId,
          deviceId: deviceId,
          day: day,
          seconds: seconds,
        ),
      );

  Future<void> deleteUsage(String childId, String deviceId, String day) =>
      (db.delete(db.usageDaily)..where(
            (t) =>
                t.childId.equals(childId) &
                t.deviceId.equals(deviceId) &
                t.day.equals(day),
          ))
          .go();

  Future<List<UsageRow>> usage(String childId) =>
      (db.select(db.usageDaily)..where((t) => t.childId.equals(childId))).get();

  Future<void> putSubject(String childId, String subject, Object? json) => db
      .into(db.otherSubjects)
      .insertOnConflictUpdate(
        OtherSubjectsCompanion.insert(
          childId: childId,
          subject: subject,
          json: jsonEncode(json),
        ),
      );

  Future<void> deleteSubject(String childId, String subject) => (db.delete(
    db.otherSubjects,
  )..where((t) => t.childId.equals(childId) & t.subject.equals(subject))).go();

  Future<Map<String, Map<String, dynamic>>> subjects(String childId) async {
    final rows = await (db.select(
      db.otherSubjects,
    )..where((t) => t.childId.equals(childId))).get();
    return {
      for (final r in rows)
        r.subject: Map<String, dynamic>.from(jsonDecode(r.json) as Map),
    };
  }
}

class QuarantineRepository {
  QuarantineRepository(this.db);
  final AppDatabase db;

  Future<void> add(String source, String? legacyId, Object? raw) => db
      .into(db.quarantinedRecords)
      .insert(
        QuarantinedRecordsCompanion.insert(
          source: source,
          legacyId: Value(legacyId),
          // Always a JSON document; a raw text copy becomes a JSON string.
          rawJson: jsonEncode(raw),
          foundAt: DateTime.now().toUtc(),
        ),
      );

  Future<List<QuarantineRow>> all() => db.select(db.quarantinedRecords).get();

  Future<void> deleteWhere(bool Function(QuarantineRow) test) async {
    for (final row in await all()) {
      if (test(row)) {
        await (db.delete(
          db.quarantinedRecords,
        )..where((t) => t.id.equals(row.id))).go();
      }
    }
  }
}
