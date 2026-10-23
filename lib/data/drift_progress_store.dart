import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../content/curriculum.dart';
import '../core/ids.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../domain/canonical_json.dart';
import 'db/app_database.dart';
import 'repositories.dart';
import 'sync/outbox.dart';

/// [ProgressStore] on SQLite (AUD-004).
///
/// The app keeps its `AppData` view and `AppController` API; this store maps
/// it to rows and, on every save, writes only the rows that changed (one
/// journey, one usage day, ...) inside a single transaction, instead of
/// re-encoding every child and photo. Data is loaded once when the store
/// opens, so [read] stays synchronous.
///
/// For a child linked to a parent account, the same transaction also queues
/// each change in the [outbox] for sync; other children never produce one.
class DriftProgressStore implements ProgressStore {
  DriftProgressStore._(this.db, this.deviceId)
    : children = ChildRepository(db),
      settings = SettingsRepository(db),
      progress = ProgressRepository(db),
      quarantine = QuarantineRepository(db),
      outbox = SyncOutbox(db);

  final AppDatabase db;

  /// Identifies this install in per-device usage counters.
  final String deviceId;
  final ChildRepository children;
  final SettingsRepository settings;
  final ProgressRepository progress;
  final _curricula = <String, ProgressRepository>{};

  /// The progress tables of one curriculum (Year 1 Maths, later years).
  ProgressRepository _progressOf(String curriculum) =>
      curriculum == currentCurriculum
      ? progress
      : _curricula.putIfAbsent(
          curriculum,
          () => ProgressRepository(db, curriculum: curriculum),
        );
  final QuarantineRepository quarantine;
  final SyncOutbox outbox;

  AppData _data = const AppData();
  Map<String, _ChildSnapshot> _snapshots = {};
  Map<String, Map<String, dynamic>> _savedRaw = {};
  Set<String> _quarantineIds = {};
  bool _activeStored = false;
  Set<String> _linked = {};

  /// Children whose changes are synced with the parent account.
  Set<String> get linkedChildren => Set.unmodifiable(_linked);

  /// Usage recorded by other devices (after sync), per child and day.
  Map<String, Map<String, int>> _otherUsage = {};

  // Legacy/Hive Maths records are normalized on their next save, without
  // changing the child's in-memory record or the existing database schema.
  // Entries are `childId/progressKey`.
  Set<String> _needsNormalization = {};

  static const deviceKey = 'device.id';
  static const activeChildKey = 'child.active';

  static Future<DriftProgressStore> open(AppDatabase db) async {
    var device = await db.meta(deviceKey);
    if (device == null) {
      device = Ids.uuidV7();
      await db.setMeta(deviceKey, device);
    }
    final store = DriftProgressStore._(db, device);
    await store.reload();
    return store;
  }

  /// Rebuilds the in-memory view from the database.
  Future<void> reload() async {
    final rows = await children.all();
    final family = <String, Map<String, dynamic>>{};
    _otherUsage = {};
    _needsNormalization = {};
    for (final row in rows) {
      family[row.id] = await _childRecord(row);
    }
    final damaged = {
      for (final q in await quarantine.all())
        if (q.source == 'child')
          q.legacyId ?? 'record-${q.id}': jsonDecode(q.rawJson),
    };
    final active = await db.meta(activeChildKey);
    _data = rows.isEmpty
        // A fresh install starts under a UUIDv7, never 'local-child'.
        ? AppData(activeChildId: Ids.uuidV7(), quarantinedChildren: damaged)
        : AppData.fromJson({
            'schemaVersion': 3,
            'activeChildId': active ?? rows.first.id,
            'children': family,
            if (damaged.isNotEmpty) 'quarantine': damaged,
          });
    _activeStored = active != null && active == _data.activeChildId;
    _linked = {
      for (final r in rows)
        if (r.syncStatus == 'linked') r.id,
    };
    _savedRaw = Map.of(_data.savedChildren);
    _quarantineIds = _data.quarantinedChildren.keys.toSet();
    final order = [for (final r in rows) r.id];
    _snapshots = rows.isEmpty
        ? {}
        : {
            for (final entry in _data.childRecords.entries)
              entry.key: _ChildSnapshot.of(
                entry.key == _data.activeChildId
                    ? _data
                    : AppData.fromJson(entry.value),
              )..sortOrder = order.indexOf(entry.key),
          };
  }

  Future<Map<String, dynamic>> _childRecord(ChildRow row) async {
    final photo = row.hasProfile ? await children.photo(row.id) : null;
    final totals = <String, int>{};
    final others = <String, int>{};
    for (final u in await progress.usage(row.id)) {
      totals[u.day] = (totals[u.day] ?? 0) + u.seconds;
      if (u.deviceId != deviceId) {
        others[u.day] = (others[u.day] ?? 0) + u.seconds;
      }
    }
    _otherUsage[row.id] = others;
    final attempts = await progress.attempts(row.id);
    final subjects = await progress.subjects(row.id);
    // Year 1 Maths and every later curriculum keep their progress in the
    // progress tables under their curriculum ID (ADR-0021). Rows of a
    // curriculum this version does not know stay stored, unread.
    final keys = {
      for (final c in await progress.curricula(row.id))
        if (c != currentCurriculum && curriculumOfKey(progressKeyOf(c)) != null)
          progressKeyOf(c),
      for (final key in subjects.keys)
        if (key != 'science' && curriculumOfKey(key) != null) key,
    };
    for (final key in keys) {
      final repo = _progressOf(curriculumOfKey(key)!);
      final record = subjects[key];
      final stored = await repo.attempts(row.id);
      final storedJourneys = await repo.journeys(row.id);
      final legacy =
          record != null &&
          (record.containsKey('attempts') || record.containsKey('journeys'));
      if (legacy) _needsNormalization.add('${row.id}/$key');
      final useLegacy = legacy && stored.isEmpty && storedJourneys.isEmpty;
      subjects[key] = {
        ...?record,
        'attempts': useLegacy
            ? record['attempts'] ?? []
            : [for (final a in stored) a.toJson()],
        'journeys': useLegacy
            ? record['journeys'] ?? <String, dynamic>{}
            : storedJourneys,
      };
    }
    return {
      'schemaVersion': 2,
      'profile': row.hasProfile
          ? {
              'name': row.displayName,
              'gender': row.gender,
              'avatar': row.avatar,
              'photo': photo == null ? null : base64Encode(photo),
              'palette': row.palette,
              'schoolYear': row.schoolYear,
            }
          : null,
      'settings': await settings.get(row.id) ?? const AppSettings().toJson(),
      'dailySeconds': totals,
      'pendingPhoto': row.pendingPhoto,
      'subjects': {
        ...subjects,
        'science': {
          'attempts': [for (final a in attempts) a.toJson()],
          'journeys': await progress.journeys(row.id),
        },
      },
    };
  }

  @override
  AppData read() => _data;

  @override
  StorageRecovery get recovery => StorageRecovery.none;

  @override
  Future<void> write(AppData data) async {
    final records = data.childRecords;
    final next = <String, _ChildSnapshot>{};
    final nextRaw = <String, Map<String, dynamic>>{};
    await db.transaction(() async {
      for (final id in _snapshots.keys) {
        if (records.containsKey(id)) continue;
        await children.delete(id);
        if (_linked.contains(id)) await outbox.childDelete(id);
      }
      var order = 0;
      for (final entry in records.entries) {
        final id = entry.key;
        final active = id == data.activeChildId;
        final previous = _snapshots[id];
        _ChildSnapshot snapshot;
        if (!active &&
            previous != null &&
            identical(_savedRaw[id], data.savedChildren[id])) {
          snapshot = previous; // Untouched saved child: nothing to parse.
        } else {
          snapshot = _ChildSnapshot.of(
            active ? data : AppData.fromJson(entry.value),
          );
        }
        if (!active) nextRaw[id] = data.savedChildren[id]!;
        await _writeChild(id, order, previous, snapshot);
        next[id] = snapshot;
        order++;
      }
      await _writeQuarantine(data.quarantinedChildren);
      if (data.activeChildId != _data.activeChildId || !_activeStored) {
        await db.setMeta(activeChildKey, data.activeChildId);
      }
    });
    // Publish only after the transaction committed.
    _activeStored = true;
    _linked = _linked.intersection(records.keys.toSet());
    _snapshots = next;
    _savedRaw = nextRaw;
    _data = data;
    _needsNormalization = {};
  }

  Future<void> _writeChild(
    String id,
    int order,
    _ChildSnapshot? before,
    _ChildSnapshot after,
  ) async {
    // A linked child always existed before this save (linking is explicit).
    final sync = before != null && _linked.contains(id) ? outbox : null;
    if (before == null ||
        before.profileKey != after.profileKey ||
        before.sortOrder != order) {
      await children.upsertProfile(
        id,
        profile: after.profile,
        pendingPhoto: after.pendingPhoto,
        sortOrder: order,
      );
      final (from, to) = (before?.profile, after.profile);
      if (sync != null && from != null && to != null) {
        final old = SyncOutbox.childFields(from);
        final now = SyncOutbox.childFields(to);
        await sync.childPatch(
          id,
          changed: {
            for (final k in now.keys)
              if (now[k] != old[k]) k: now[k],
          },
          before: old,
          baseVersion: (await children.row(id))!.version,
        );
      }
    }
    after.sortOrder = order;
    if (before == null || !_samePhoto(before.photo, after.photo)) {
      await children.setPhoto(id, after.photo);
    }
    if (before == null || before.settings != after.settings) {
      await settings.put(id, after.settingsJson);
      if (sync != null && before != null) {
        final old = before.settingsJson;
        final now = after.settingsJson;
        await sync.settingsPatch(
          id,
          changed: {
            for (final k in now.keys)
              if (now[k] != old[k]) k: now[k],
          },
          before: old,
          baseVersion: await settings.version(id),
        );
      }
    }
    if (before == null || before.attempts != after.attempts) {
      final change = await progress.replaceAttempts(id, after.attemptList);
      if (sync != null) {
        for (final (id: attemptId, :attempt) in change.added) {
          await sync.attemptCreate(
            id,
            attemptId,
            SyncOutbox.attemptPayload(
              progress.curriculum,
              unitId: attempt.unitId,
              contentVersion: attempt.contentVersion,
              completed: attempt.completed,
              effortStars: attempt.effortStars,
              completedAt: attempt.completedAt.toIso8601String(),
              clientAttemptId: attempt.attemptId,
              objectives: {
                for (final o in attempt.objectives.entries) o.key: o.value.name,
              },
            ),
          );
        }
        for (final removed in change.removed) {
          await sync.attemptDelete(id, removed);
        }
      }
    }
    for (final key in {...?before?.journeys.keys, ...after.journeys.keys}) {
      final value = after.journeys[key];
      if (value == null) {
        await progress.deleteJourney(id, key);
        await sync?.journeyDelete(id, progress.curriculum, key);
      } else if (before?.journeys[key] != value) {
        await progress.putJourney(id, key, after.journeyJson[key]!);
        await sync?.journeyPut(
          id,
          progress.curriculum,
          key,
          after.journeyJson[key]!,
          baseVersion: await progress.journeyVersion(id, key),
        );
      }
    }
    final others = _otherUsage[id] ?? const {};
    for (final day in {...?before?.usage.keys, ...after.usage.keys}) {
      final total = after.usage[day];
      if (total == null) {
        // Play time already on the server stays there (a grow-only counter).
        await progress.deleteUsage(id, deviceId, day);
      } else if (before?.usage[day] != total) {
        final local = total - (others[day] ?? 0);
        await progress.putUsage(id, deviceId, day, local < 0 ? 0 : local);
        await sync?.usagePut(id, day, local < 0 ? 0 : local);
      }
    }
    for (final key in {...?before?.subjects.keys, ...after.subjects.keys}) {
      if (key != 'science' && curriculumOfKey(key) != null) {
        await _writeSubjectProgress(id, key, before, after, sync);
      }
    }
    for (final key in {...?before?.subjects.keys, ...after.subjects.keys}) {
      final value = after.subjects[key];
      if (value == null) {
        await progress.deleteSubject(id, key);
      } else if (curriculumOfKey(key) != null) {
        final metadata = _subjectMetadata(after.subjectJson[key]!);
        final previous = before?.subjectJson[key];
        if (_needsNormalization.contains('$id/$key') ||
            previous == null ||
            canonicalJson(_subjectMetadata(previous)) !=
                canonicalJson(metadata)) {
          await progress.putSubject(id, key, metadata);
        }
      } else if (before?.subjects[key] != value) {
        await progress.putSubject(id, key, after.subjectJson[key]);
      }
    }
  }

  /// A subject record without its attempts and journeys, which live in the
  /// progress tables.
  static Map<String, dynamic> _subjectMetadata(Map<String, dynamic> record) => {
    for (final entry in record.entries)
      if (entry.key != 'attempts' && entry.key != 'journeys')
        entry.key: entry.value,
  };

  /// Writes the attempts and journeys of one curriculum other than Year 1
  /// Science (kept in the main fields) to its progress tables.
  Future<void> _writeSubjectProgress(
    String childId,
    String key,
    _ChildSnapshot? before,
    _ChildSnapshot after,
    SyncOutbox? sync,
  ) async {
    final curriculum = curriculumOfKey(key)!;
    final repo = _progressOf(curriculum);
    final oldRecord = before?.subjectJson[key];
    final record = after.subjectJson[key];
    final normalize = _needsNormalization.contains('$childId/$key');
    if (oldRecord == null && record == null && !normalize) return;
    if (before?.subjects[key] == after.subjects[key] && !normalize) {
      return;
    }
    AppData view(Map<String, dynamic>? value) =>
        AppData(otherSubjects: {key: ?value}).progressForSubject(key);
    final previous = view(oldRecord);
    final next = view(record);
    if (normalize ||
        canonicalJson([for (final a in previous.attempts) a.toJson()]) !=
            canonicalJson([for (final a in next.attempts) a.toJson()])) {
      final change = await repo.replaceAttempts(childId, next.attempts);
      if (sync != null) {
        for (final (id: attemptId, :attempt) in change.added) {
          await sync.attemptCreate(
            childId,
            attemptId,
            SyncOutbox.attemptPayload(
              curriculum,
              unitId: attempt.unitId,
              contentVersion: attempt.contentVersion,
              completed: attempt.completed,
              effortStars: attempt.effortStars,
              completedAt: attempt.completedAt.toIso8601String(),
              clientAttemptId: attempt.attemptId,
              objectives: {
                for (final o in attempt.objectives.entries) o.key: o.value.name,
              },
            ),
          );
        }
        for (final attemptId in change.removed) {
          await sync.attemptDelete(childId, attemptId);
        }
      }
    }
    for (final journey in {...previous.journeys.keys, ...next.journeys.keys}) {
      final value = next.journeys[journey];
      if (value == null) {
        await repo.deleteJourney(childId, journey);
        await sync?.journeyDelete(childId, curriculum, journey);
      } else if (normalize ||
          canonicalJson(previous.journeys[journey]) != canonicalJson(value)) {
        await repo.putJourney(childId, journey, value);
        await sync?.journeyPut(
          childId,
          curriculum,
          journey,
          value,
          baseVersion: await repo.journeyVersion(childId, journey),
        );
      }
    }
  }

  Future<void> _writeQuarantine(Map<String, Object?> records) async {
    final ids = records.keys.toSet();
    if (setEquals(ids, _quarantineIds)) return;
    await quarantine.deleteWhere(
      (q) => q.source == 'child' && !ids.contains(q.legacyId),
    );
    for (final id in ids.difference(_quarantineIds)) {
      await quarantine.add('child', id, records[id]);
    }
    _quarantineIds = ids;
  }

  static bool _samePhoto(Uint8List? a, Uint8List? b) =>
      identical(a, b) ||
      (a != null && b != null && listEquals(a, b)) ||
      (a == null && b == null);

  @override
  String rescueExport() => jsonEncode({
    'format': 'science-adventure-rescue-v1',
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'data': jsonEncode(_data.toJson()),
  });

  /// Rescue copy including quarantined and raw legacy records.
  Future<String> fullRescueExport() async => jsonEncode({
    'format': 'science-adventure-rescue-v1',
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'data': jsonEncode(_data.toJson()),
    'quarantined': [
      for (final q in await quarantine.all())
        {
          'source': q.source,
          'legacyId': q.legacyId,
          'raw': jsonDecode(q.rawJson),
        },
    ],
  });

  @override
  bool get hasUnreadableCopies => _hasLegacyCopies;
  bool _hasLegacyCopies = false;

  /// Called after opening: whether raw unreadable Hive copies were carried.
  Future<void> refreshLegacyFlag() async {
    _hasLegacyCopies = (await quarantine.all()).any(
      (q) => q.source.startsWith('hive:'),
    );
  }

  @override
  Future<void> discardUnreadableCopies() async {
    await quarantine.deleteWhere((q) => q.source.startsWith('hive:'));
    _hasLegacyCopies = false;
  }
}

/// What the database holds for one child, in comparable form.
class _ChildSnapshot {
  _ChildSnapshot._({
    required this.profile,
    required this.pendingPhoto,
    required this.profileKey,
    required this.photo,
    required this.settingsJson,
    required this.settings,
    required this.attemptList,
    required this.attempts,
    required this.journeyJson,
    required this.journeys,
    required this.usage,
    required this.subjectJson,
    required this.subjects,
  });

  factory _ChildSnapshot.of(AppData child) {
    final profile = child.profile;
    final settingsJson = child.settings.toJson();
    return _ChildSnapshot._(
      profile: profile,
      pendingPhoto: child.pendingPhoto,
      profileKey: canonicalJson({
        'profile': profile == null
            ? null
            : {...profile.toJson(), 'photo': null},
        'pendingPhoto': child.pendingPhoto,
      }),
      photo: profile?.photo,
      settingsJson: settingsJson,
      settings: canonicalJson(settingsJson),
      attemptList: child.attempts,
      attempts: canonicalJson([for (final a in child.attempts) a.toJson()]),
      journeyJson: child.journeys,
      journeys: {
        for (final e in child.journeys.entries) e.key: canonicalJson(e.value),
      },
      usage: Map.of(child.dailySeconds),
      subjectJson: child.otherSubjects,
      subjects: {
        for (final e in child.otherSubjects.entries)
          e.key: canonicalJson(e.value),
      },
    );
  }

  final ChildProfile? profile;
  final bool pendingPhoto;
  final String profileKey;
  final Uint8List? photo;
  final Map<String, dynamic> settingsJson;
  final String settings;
  final List<UnitAttempt> attemptList;
  final String attempts;
  final Map<String, Map<String, dynamic>> journeyJson;
  final Map<String, String> journeys;
  final Map<String, int> usage;
  final Map<String, Map<String, dynamic>> subjectJson;
  final Map<String, String> subjects;
  int? sortOrder;
}
