import 'dart:convert';

import 'package:drift/drift.dart';

import '../../content/lesson.dart';
import '../../core/models.dart';
import '../../domain/journey/journey_state.dart';
import '../../domain/merge/journey_merge.dart';
import '../db/app_database.dart';
import '../repositories.dart';
import 'outbox.dart';

/// Something sync could not decide alone; shown to parents until they act
/// on it (conflicts are never discarded silently, §14).
class SyncIssue {
  const SyncIssue({
    required this.kind,
    required this.childId,
    this.childName = '',
    this.field,
    this.mine,
    this.theirs,
  });

  /// `field`: another device changed [field] differently; the account's
  /// value [theirs] is kept and this device's [mine] can be re-applied.
  /// `childRemoved`: the child was removed from the account elsewhere.
  /// `childUnavailable`: the child could not be linked (it was deleted from
  /// the account before); it stays on this device only.
  final String kind;
  final String childId;
  final String childName;
  final String? field;
  final Object? mine, theirs;

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'childId': childId,
    'childName': childName,
    'field': ?field,
    'mine': ?mine,
    'theirs': ?theirs,
  };

  factory SyncIssue.fromJson(Map<String, dynamic> j) => SyncIssue(
    kind: j['kind'] as String,
    childId: j['childId'] as String,
    childName: j['childName'] as String? ?? '',
    field: j['field'] as String?,
    mine: j['mine'],
    theirs: j['theirs'],
  );
}

/// Why a child cannot be linked.
enum LinkProblem { noProfile, name, alreadyLinked }

class LinkException implements Exception {
  const LinkException(this.problem);
  final LinkProblem problem;
  @override
  String toString() => 'LinkException(${problem.name})';
}

/// The database side of sync: linking children, push results and pulled
/// changes. Methods that change what the app shows must run inside
/// `AppController.applyExternal`, serialised with saves, followed by a
/// reload; they report whether local data changed.
class SyncStore {
  SyncStore(this.db, {required this.deviceId})
    : outbox = SyncOutbox(db),
      progress = ProgressRepository(db);

  final AppDatabase db;
  final String deviceId;
  final SyncOutbox outbox;
  final ProgressRepository progress;

  static const cursorKey = 'sync.cursor';
  static const accountKey = 'sync.account';
  static const lastSyncKey = 'sync.last';
  static const issuesKey = 'sync.issues';

  static const _childFields = ['displayName', 'gender', 'avatar', 'palette'];

  /// The name rules of the server contract (`DisplayName`).
  static final _syncableName = RegExp(r"^[\p{L}\p{M} '’\-]*$", unicode: true);
  static bool nameSyncable(String name) =>
      name.length <= 24 && _syncableName.hasMatch(name);

  // ---- state -----------------------------------------------------------------

  Future<int> cursor() async =>
      int.tryParse(await db.meta(cursorKey) ?? '') ?? 0;

  Future<DateTime?> lastSync() async {
    final value = await db.meta(lastSyncKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> markSynced(DateTime at) =>
      db.setMeta(lastSyncKey, at.toUtc().toIso8601String());

  Future<List<SyncIssue>> issues() async {
    final raw = await db.meta(issuesKey);
    if (raw == null) return const [];
    return [
      for (final i in jsonDecode(raw) as List)
        SyncIssue.fromJson(Map<String, dynamic>.from(i as Map)),
    ];
  }

  Future<void> _addIssue(SyncIssue issue) async {
    final all = [
      for (final i in await issues())
        // A newer conflict on the same field replaces the older one.
        if (!(i.kind == issue.kind &&
            i.childId == issue.childId &&
            i.field == issue.field))
          i,
      issue,
    ];
    await db.setMeta(issuesKey, jsonEncode([for (final i in all) i.toJson()]));
  }

  Future<void> dismissIssue(SyncIssue issue) async {
    final rest = [
      for (final i in await issues())
        if (!(i.kind == issue.kind &&
            i.childId == issue.childId &&
            i.field == issue.field))
          i,
    ];
    if (rest.isEmpty) return db.deleteMeta(issuesKey);
    await db.setMeta(issuesKey, jsonEncode([for (final i in rest) i.toJson()]));
  }

  // ---- accounts and linking --------------------------------------------------

  /// Children synced with [userId]'s account. Signing in to another account
  /// first turns every linked child back into a device-only child (nothing
  /// is deleted), so one parent's children never reach another account.
  Future<bool> useAccount(String userId) async {
    final current = await db.meta(accountKey);
    if (current == userId) return false;
    final changed = current != null || await _anyLinked();
    if (changed) await unlinkAll();
    await db.setMeta(accountKey, userId);
    return changed;
  }

  Future<bool> _anyLinked() async =>
      (await (db.select(db.children)
                ..where((t) => t.syncStatus.equals('linked'))
                ..limit(1))
              .get())
          .isNotEmpty;

  /// Stops syncing: every child stays on this device with all its progress.
  Future<void> unlinkAll() => db.transaction(() async {
    await db
        .update(db.children)
        .write(
          const ChildrenCompanion(
            syncStatus: Value('local'),
            version: Value(0),
          ),
        );
    await db
        .update(db.childSettings)
        .write(const ChildSettingsCompanion(version: Value(0)));
    await db
        .update(db.journeys)
        .write(const JourneysCompanion(version: Value(0)));
    await outbox.clear();
    for (final key in [cursorKey, accountKey, issuesKey]) {
      await db.deleteMeta(key);
    }
  });

  /// Starts syncing [childId]: queues everything the child has, so the
  /// account receives it (repeating this is harmless: the server recognises
  /// what it already has).
  Future<void> link(String childId) => db.transaction(() async {
    final row = await (db.select(
      db.children,
    )..where((t) => t.id.equals(childId))).getSingleOrNull();
    if (row == null || !row.hasProfile) {
      throw const LinkException(LinkProblem.noProfile);
    }
    if (row.syncStatus == 'linked') {
      throw const LinkException(LinkProblem.alreadyLinked);
    }
    if (!nameSyncable(row.displayName)) {
      throw const LinkException(LinkProblem.name);
    }
    await _setChild(
      childId,
      const ChildrenCompanion(syncStatus: Value('linked')),
    );
    await _queueSnapshot(row);
  });

  Future<void> _queueSnapshot(ChildRow row) async {
    final id = row.id;
    final settings =
        await SettingsRepository(db).get(id) ?? const AppSettings().toJson();
    await outbox.childCreate(id, _fieldsOf(row), settings);
    // If the account already has this child (linked before), the create
    // changes nothing there: these settings replace the account's.
    await outbox.settingsReplace(id, settings);
    for (final a in await progress.attemptRows(id)) {
      await outbox.attemptCreate(
        id,
        a.row.id,
        SyncOutbox.attemptPayload(
          a.row.curriculum,
          unitId: a.row.unitId,
          contentVersion: a.row.contentVersion,
          completed: a.row.completed,
          effortStars: a.row.effortStars,
          completedAt: a.row.completedAt,
          clientAttemptId: a.row.clientAttemptId,
          objectives: {for (final o in a.objectives) o.objectiveId: o.outcome},
        ),
      );
    }
    final journeys = await (db.select(
      db.journeys,
    )..where((t) => t.childId.equals(id))).get();
    for (final j in journeys) {
      await outbox.journeyPut(
        id,
        j.curriculum,
        j.journeyKey,
        Map<String, dynamic>.from(jsonDecode(j.json) as Map),
        baseVersion: j.version,
      );
    }
    final usage = await (db.select(
      db.usageDaily,
    )..where((t) => t.childId.equals(id) & t.deviceId.equals(deviceId))).get();
    for (final u in usage) {
      await outbox.usagePut(id, u.day, u.seconds);
    }
  }

  static Map<String, dynamic> _fieldsOf(ChildRow row) => {
    'displayName': row.displayName,
    'gender': row.gender,
    'avatar': row.avatar,
    'palette': row.palette,
  };

  Future<void> _setChild(String id, ChildrenCompanion values) =>
      (db.update(db.children)..where((t) => t.id.equals(id))).write(values);

  Future<ChildRow?> _child(String id) =>
      (db.select(db.children)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Stops syncing one child after the account refused it.
  Future<void> _unlink(ChildRow row, String kind) async {
    await _setChild(
      row.id,
      const ChildrenCompanion(syncStatus: Value('local'), version: Value(0)),
    );
    await outbox.dropChild(row.id);
    await _addIssue(
      SyncIssue(kind: kind, childId: row.id, childName: row.displayName),
    );
  }

  // ---- push ------------------------------------------------------------------

  /// The request body for [rows]. Versions are filled in now, from what this
  /// device last received: a journey is always sent against the version it
  /// was merged with, and a patch that was queued before the child reached
  /// the server gets the child's first version.
  Future<List<Map<String, dynamic>>> mutations(List<OutboxRow> rows) async {
    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      final m = SyncOutbox.decode(row)..['mutationId'] = row.mutationId;
      switch ((m['entity'], m['op'])) {
        case ('journey', 'put'):
          final local = await _journey(
            m['childId'] as String,
            m['curriculum'] as String,
            m['key'] as String,
          );
          if (local != null) m['baseVersion'] = local.version;
        case ('child', 'patch'):
          if ((m['baseVersion'] as int? ?? 0) < 1) {
            final child = await _child(m['id'] as String);
            m['baseVersion'] = _atLeastOne(child?.version);
          }
        case ('settings', 'patch'):
          if ((m['baseVersion'] as int? ?? 0) < 1) {
            m['baseVersion'] = _atLeastOne(
              await SettingsRepository(db).version(m['childId'] as String),
            );
          }
      }
      result.add(m);
    }
    return result;
  }

  static int _atLeastOne(int? v) => v == null || v < 1 ? 1 : v;

  Future<JourneyRow?> _journey(String childId, String curriculum, String key) =>
      (db.select(db.journeys)..where(
            (t) =>
                t.childId.equals(childId) &
                t.curriculum.equals(curriculum) &
                t.journeyKey.equals(key),
          ))
          .getSingleOrNull();

  /// Applies the server's answers to a push of [rows]. Entries without an
  /// answer go back to the queue.
  Future<bool> applyResults(
    List<OutboxRow> rows,
    List<Map<String, dynamic>> results,
  ) => db.transaction(() async {
    final byId = {for (final r in results) r['mutationId'] as String: r};
    var changed = false;
    final unanswered = <int>[];
    for (final row in rows) {
      final result = byId[row.mutationId];
      if (result == null) {
        unanswered.add(row.seq);
        continue;
      }
      final m = SyncOutbox.decode(row);
      final status = result['status'] as String;
      final version = result['version'] as int?;
      if (status == 'rejected') {
        final code =
            (result['error'] as Map?)?['code'] as String? ?? 'rejected';
        changed |= await _rejected(row, m, code);
        continue;
      }
      await outbox.remove(row.seq);
      if (status == 'conflict') {
        changed |= await _conflict(m, result);
      } else {
        await _confirmed(m, version);
      }
    }
    if (unanswered.isNotEmpty) {
      await outbox.release(unanswered, 'no_result');
    }
    return changed;
  });

  Future<void> _confirmed(Map<String, dynamic> m, int? version) async {
    if (version == null) return;
    switch ((m['entity'], m['op'])) {
      case ('child', 'create' || 'patch'):
        await _setChild(
          m['id'] as String,
          ChildrenCompanion(version: Value(version)),
        );
      case ('settings', 'patch'):
        await (db.update(db.childSettings)
              ..where((t) => t.childId.equals(m['childId'] as String)))
            .write(ChildSettingsCompanion(version: Value(version)));
      case ('journey', 'put'):
        await _setJourneyVersion(m, version);
    }
  }

  Future<void> _setJourneyVersion(Map<String, dynamic> m, int version) =>
      (db.update(db.journeys)..where(
            (t) =>
                t.childId.equals(m['childId'] as String) &
                t.curriculum.equals(m['curriculum'] as String) &
                t.journeyKey.equals(m['key'] as String),
          ))
          .write(JourneysCompanion(version: Value(version)));

  Future<bool> _conflict(
    Map<String, dynamic> m,
    Map<String, dynamic> result,
  ) async {
    final server = result['server'] as Map?;
    switch (m['entity']) {
      case 'child':
        final row = await _child(m['id'] as String);
        if (row == null || server == null) return false;
        return _childConflict(row, Map<String, dynamic>.from(server), [
          for (final f in result['conflictFields'] as List? ?? []) f as String,
        ], recreate: m['op'] == 'create');
      case 'journey':
        return _journeyConflict(
          m,
          server == null ? null : Map.from(server),
          result['version'] as int? ?? 0,
        );
    }
    return false;
  }

  /// The account kept its values for [fields] (name and gender: identity
  /// fields). This device takes them and remembers its own for the parent.
  /// After a create that found the child already there, the device's
  /// avatar and colours are sent again (the later change wins for those).
  Future<bool> _childConflict(
    ChildRow row,
    Map<String, dynamic> server,
    List<String> fields, {
    required bool recreate,
  }) async {
    final local = _fieldsOf(row);
    final adopt = <String, dynamic>{};
    final resend = <String, dynamic>{};
    for (final f in fields) {
      if (local[f] == server[f]) continue;
      if (f == 'displayName' || f == 'gender') {
        adopt[f] = server[f];
        await _addIssue(
          SyncIssue(
            kind: 'field',
            childId: row.id,
            childName: server['displayName'] as String? ?? row.displayName,
            field: f,
            mine: local[f],
            theirs: server[f],
          ),
        );
      } else if (recreate) {
        resend[f] = local[f];
      }
    }
    final version = server['version'] as int;
    await _setChild(
      row.id,
      ChildrenCompanion(
        version: Value(version),
        displayName: adopt.containsKey('displayName')
            ? Value(adopt['displayName'] as String)
            : const Value.absent(),
        gender: adopt.containsKey('gender')
            ? Value(adopt['gender'] as String)
            : const Value.absent(),
      ),
    );
    if (resend.isNotEmpty) {
      await outbox.childPatch(
        row.id,
        changed: resend,
        before: {for (final f in resend.keys) f: server[f]},
        baseVersion: version,
      );
    }
    return adopt.isNotEmpty;
  }

  /// Another device moved the lesson on: both copies are merged (progress
  /// never goes backwards) and the result is sent again. A journey the
  /// account deleted (lesson finished or progress reset) after this device
  /// last synced it stays deleted; a run started here later is kept.
  Future<bool> _journeyConflict(
    Map<String, dynamic> m,
    Map<String, dynamic>? server,
    int serverVersion,
  ) async {
    final childId = m['childId'] as String;
    final curriculum = m['curriculum'] as String;
    final key = m['key'] as String;
    final local = await _journey(childId, curriculum, key);
    if (local == null) return false; // Deleted here meanwhile; that is queued.
    if (server == null) {
      if (local.version == 0) {
        await _setJourneyVersion(m, serverVersion);
        await outbox.journeyPut(
          childId,
          curriculum,
          key,
          Map<String, dynamic>.from(jsonDecode(local.json) as Map),
          baseVersion: serverVersion,
        );
        return false;
      }
      await _deleteJourney(childId, curriculum, key);
      return true;
    }
    final state = Map<String, dynamic>.from(server['state'] as Map);
    final merged = mergeJourney(
      Map<String, dynamic>.from(jsonDecode(local.json) as Map),
      state,
    );
    final version = server['version'] as int;
    await _writeJourney(childId, curriculum, key, merged, version);
    await outbox.journeyPut(
      childId,
      curriculum,
      key,
      merged,
      baseVersion: version,
    );
    return true;
  }

  Future<bool> _rejected(
    OutboxRow row,
    Map<String, dynamic> m,
    String code,
  ) async {
    if (code != 'child_deleted') {
      // Kept for the parent to see and retry.
      await outbox.quarantine(row.seq, code);
      return false;
    }
    // The child is gone from the account: its changes have nowhere to go.
    await outbox.remove(row.seq);
    final childId = (m['childId'] ?? m['id']) as String;
    final child = await _child(childId);
    if (child == null || child.syncStatus != 'linked') return false;
    if (child.version == 0) {
      // It was never synced under this link: keep it, on this device only.
      await _unlink(child, 'childUnavailable');
      return true;
    }
    return false; // The pull removes it, as on the device that deleted it.
  }

  // ---- pull ------------------------------------------------------------------

  /// Applies pulled [changes] (every page of one pull, in order) and stores
  /// [cursor] in the same transaction. Children come first, so the records
  /// of a child created on another device always find it.
  ///
  /// A [complete] pull (from the start, after the server forgot old
  /// deletions) lists every child of the account: a synced child missing
  /// from it was removed from the account. It is kept on this device only.
  Future<bool> applyChanges(
    List<Map<String, dynamic>> changes,
    int cursor, {
    bool complete = false,
  }) => db.transaction(() async {
    var changed = false;
    final waiting = await _waitingByEntity();
    for (final c in changes.where((c) => c['entity'] == 'child')) {
      changed |= await _pullChild(c, waiting);
    }
    if (complete) {
      final listed = {
        for (final c in changes)
          if (c['entity'] == 'child' && c['op'] != 'delete') c['id'],
      };
      final linked =
          await (db.select(db.children)..where(
                (t) =>
                    t.syncStatus.equals('linked') &
                    t.version.isBiggerThanValue(0),
              ))
              .get();
      for (final row in linked.where((r) => !listed.contains(r.id))) {
        await _unlink(row, 'childUnavailable');
        changed = true;
      }
    }
    for (final c in changes.where((c) => c['entity'] != 'child')) {
      changed |= switch (c['entity']) {
        'settings' => await _pullSettings(c, waiting),
        'attempt' => await _pullAttempt(c, waiting),
        'journey' => await _pullJourney(c, waiting),
        'usage' => await _pullUsage(c),
        _ => false,
      };
    }
    await db.setMeta(cursorKey, '$cursor');
    return changed;
  });

  /// Local entries not yet confirmed (waiting or quarantined), by entity.
  Future<Map<String, List<Map<String, dynamic>>>> _waitingByEntity() async {
    final rows = await (db.select(
      db.outbox,
    )..orderBy([(t) => OrderingTerm(expression: t.seq)])).get();
    final out = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      out.putIfAbsent(r.entityId, () => []).add(SyncOutbox.decode(r));
    }
    return out;
  }

  /// Fields this device changed and has not sent yet: they keep the local
  /// value (the push lets the server merge them).
  static Set<String> _localFields(List<Map<String, dynamic>>? waiting) => {
    for (final m in waiting ?? const <Map<String, dynamic>>[])
      if (m['op'] == 'patch' || m['op'] == 'create')
        ...Map<String, dynamic>.from(m['payload'] as Map).keys,
  };

  static bool _deleting(List<Map<String, dynamic>>? waiting) =>
      waiting?.any((m) => m['op'] == 'delete') ?? false;

  Future<bool> _pullChild(
    Map<String, dynamic> c,
    Map<String, List<Map<String, dynamic>>> waiting,
  ) async {
    final id = c['id'] as String;
    final pending = waiting[SyncOutbox.childKey(id)];
    if (_deleting(pending)) return false;
    final row = await _child(id);
    if (c['op'] == 'delete') {
      if (row == null || row.syncStatus != 'linked') return false;
      if (row.version == 0) {
        await _unlink(row, 'childUnavailable');
      } else {
        // Removed from the account by the parent on another device.
        await (db.delete(db.children)..where((t) => t.id.equals(id))).go();
        await outbox.dropChild(id);
        await _addIssue(
          SyncIssue(
            kind: 'childRemoved',
            childId: id,
            childName: row.displayName,
          ),
        );
      }
      return true;
    }
    final data = Map<String, dynamic>.from(c['data'] as Map);
    final version = c['version'] as int;
    if (row == null) {
      final last = await (db.selectOnly(
        db.children,
      )..addColumns([db.children.sortOrder.max()])).getSingle();
      await db
          .into(db.children)
          .insert(
            ChildrenCompanion.insert(
              id: id,
              hasProfile: true,
              displayName: Value(data['displayName'] as String),
              gender: Value(data['gender'] as String),
              avatar: Value(data['avatar'] as int),
              palette: Value(data['palette'] as String),
              sortOrder: (last.read(db.children.sortOrder.max()) ?? -1) + 1,
              version: Value(version),
              syncStatus: const Value('linked'),
              updatedAt: DateTime.now().toUtc(),
            ),
          );
      await db
          .into(db.childSettings)
          .insert(
            ChildSettingsCompanion.insert(
              childId: id,
              json: jsonEncode(const AppSettings().toJson()),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      return true;
    }
    if (row.syncStatus != 'linked') {
      // Linked to this account before: send everything this device has.
      await _setChild(id, const ChildrenCompanion(syncStatus: Value('linked')));
      await _queueSnapshot(row);
      return true;
    }
    if (version <= row.version && pending == null) return false;
    final keep = _localFields(pending);
    final local = _fieldsOf(row);
    final next = {
      for (final f in _childFields) f: keep.contains(f) ? local[f] : data[f],
    };
    final differs = _childFields.any((f) => next[f] != local[f]);
    await _setChild(
      id,
      ChildrenCompanion(
        version: Value(version > row.version ? version : row.version),
        displayName: Value(next['displayName'] as String),
        gender: Value(next['gender'] as String),
        avatar: Value(next['avatar'] as int),
        palette: Value(next['palette'] as String),
      ),
    );
    return differs;
  }

  Future<bool> _linked(String childId) async =>
      (await _child(childId))?.syncStatus == 'linked';

  Future<bool> _pullSettings(
    Map<String, dynamic> c,
    Map<String, List<Map<String, dynamic>>> waiting,
  ) async {
    final childId = c['childId'] as String;
    if (!await _linked(childId)) return false;
    final repo = SettingsRepository(db);
    final local = await repo.get(childId) ?? const AppSettings().toJson();
    final keep = {
      ..._localFields(waiting[SyncOutbox.settingsKey(childId)]),
      // A create not yet sent carries the settings too.
      if (waiting[SyncOutbox.childKey(childId)]?.any(
            (m) => m['op'] == 'create',
          ) ??
          false)
        ...local.keys,
    };
    final data = Map<String, dynamic>.from(c['data'] as Map);
    final next = {
      ...local,
      for (final e in data.entries)
        if (!keep.contains(e.key)) e.key: e.value,
    };
    // Validated like every stored setting before the app uses it.
    final json = AppSettings.fromJson(next).toJson();
    final differs = jsonEncode(json) != jsonEncode(local);
    await db
        .into(db.childSettings)
        .insertOnConflictUpdate(
          ChildSettingsCompanion.insert(
            childId: childId,
            json: jsonEncode(json),
            version: Value(c['version'] as int),
          ),
        );
    return differs;
  }

  Future<bool> _pullAttempt(
    Map<String, dynamic> c,
    Map<String, List<Map<String, dynamic>>> waiting,
  ) async {
    final id = c['id'] as String;
    final childId = c['childId'] as String;
    if (!await _linked(childId)) return false;
    final existing = await (db.select(
      db.unitAttempts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (c['op'] == 'delete') {
      if (existing == null) return false;
      await (db.delete(db.unitAttempts)..where((t) => t.id.equals(id))).go();
      return true;
    }
    if (existing != null || _deleting(waiting[SyncOutbox.attemptKey(id)])) {
      return false; // Attempts never change once recorded.
    }
    final data = Map<String, dynamic>.from(c['data'] as Map);
    final last =
        await (db.selectOnly(db.unitAttempts)
              ..addColumns([db.unitAttempts.sortOrder.max()])
              ..where(db.unitAttempts.childId.equals(childId)))
            .getSingle();
    await db
        .into(db.unitAttempts)
        .insert(
          UnitAttemptsCompanion.insert(
            id: id,
            childId: childId,
            curriculum: data['curriculum'] as String,
            clientAttemptId: data['clientAttemptId'] as String,
            unitId: data['unitId'] as String,
            contentVersion: data['contentVersion'] as int,
            completed: data['completed'] as bool,
            effortStars: data['effortStars'] as int,
            completedAt: data['completedAt'] as String,
            sortOrder: (last.read(db.unitAttempts.sortOrder.max()) ?? -1) + 1,
          ),
        );
    for (final o in Map<String, dynamic>.from(
      data['objectives'] as Map,
    ).entries) {
      await db
          .into(db.attemptObjectives)
          .insert(
            AttemptObjectivesCompanion.insert(
              attemptId: id,
              objectiveId: o.key,
              outcome: o.value as String,
            ),
          );
    }
    return true;
  }

  Future<bool> _pullJourney(
    Map<String, dynamic> c,
    Map<String, List<Map<String, dynamic>>> waiting,
  ) async {
    final childId = c['childId'] as String;
    final curriculum = c['curriculum'] as String;
    final key = c['key'] as String;
    if (!await _linked(childId)) return false;
    final pending = waiting[SyncOutbox.journeyKey(childId, curriculum, key)];
    final local = await _journey(childId, curriculum, key);
    if (c['op'] == 'delete') {
      if (local == null) return false;
      await _deleteJourney(childId, curriculum, key);
      return true;
    }
    final version = c['version'] as int;
    if (local != null && local.version >= version) return false;
    if (local == null && _deleting(pending)) return false;
    final state = Map<String, dynamic>.from((c['data'] as Map)['state'] as Map);
    if (!_readable(key, state)) {
      // Never applied, never dropped: kept for a rescue export.
      await QuarantineRepository(db).add('sync:journey', key, state);
      return false;
    }
    final mine = local == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(local.json) as Map);
    final waitingPut = pending?.any((m) => m['op'] == 'put') ?? false;
    if (mine != null && waitingPut) {
      final merged = mergeJourney(mine, state);
      await _writeJourney(childId, curriculum, key, merged, version);
      await outbox.journeyPut(
        childId,
        curriculum,
        key,
        merged,
        baseVersion: version,
      );
    } else {
      await _writeJourney(childId, curriculum, key, state, version);
    }
    return true;
  }

  /// A lesson journey must match the typed model before the app restores it.
  static bool _readable(String key, Map<String, dynamic> state) {
    if (!LessonLibrary.availableIds.contains(key)) return true;
    try {
      JourneyState.fromJson(state);
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _writeJourney(
    String childId,
    String curriculum,
    String key,
    Map<String, dynamic> state,
    int version,
  ) => db
      .into(db.journeys)
      .insertOnConflictUpdate(
        JourneysCompanion.insert(
          childId: childId,
          curriculum: curriculum,
          journeyKey: key,
          json: jsonEncode(state),
          version: Value(version),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

  Future<void> _deleteJourney(
    String childId,
    String curriculum,
    String key,
  ) async {
    await (db.delete(db.journeys)..where(
          (t) =>
              t.childId.equals(childId) &
              t.curriculum.equals(curriculum) &
              t.journeyKey.equals(key),
        ))
        .go();
    await (db.delete(db.outbox)..where(
          (t) =>
              t.entityId.equals(
                SyncOutbox.journeyKey(childId, curriculum, key),
              ) &
              t.status.isNotIn(['inflight']),
        ))
        .go();
  }

  /// Play time is a per-device counter that only grows.
  Future<bool> _pullUsage(Map<String, dynamic> c) async {
    final childId = c['childId'] as String;
    if (!await _linked(childId)) return false;
    final device = c['deviceId'] as String;
    final day = c['day'] as String;
    final seconds = c['seconds'] as int;
    final existing =
        await (db.select(db.usageDaily)..where(
              (t) =>
                  t.childId.equals(childId) &
                  t.deviceId.equals(device) &
                  t.day.equals(day),
            ))
            .getSingleOrNull();
    if (existing != null && existing.seconds >= seconds) return false;
    await progress.putUsage(childId, device, day, seconds);
    return true;
  }
}
