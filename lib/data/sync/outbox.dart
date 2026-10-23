import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../core/models.dart';
import '../db/app_database.dart';

/// Local changes to linked children waiting to be pushed (Future System
/// Architecture §12). Entries are written in the same transaction as the
/// change itself, so a change is never saved without its entry.
///
/// Each entry is the JSON of one `Mutation` of `api/openapi.yaml` (without
/// its `mutationId`, which is a column). Changes to the same thing are
/// coalesced while the entry has never been sent: one patch per child or
/// settings (keeping the *first* `base` values, what the server last had, so
/// it can still merge field by field), one put per journey and usage day.
/// An entry that was sent without a clear answer is never rewritten: the
/// server may already have applied it.
class SyncOutbox {
  SyncOutbox(this.db);
  final AppDatabase db;

  static String childKey(String childId) => 'child:$childId';
  static String settingsKey(String childId) => 'settings:$childId';
  static String attemptKey(String id) => 'attempt:$id';
  static String journeyKey(String childId, String curriculum, String key) =>
      'journey:$childId:$curriculum:$key';
  static String usageKey(String childId, String day) => 'usage:$childId:$day';

  /// The child fields the server keeps (photos never leave the device).
  static Map<String, dynamic> childFields(ChildProfile profile) => {
    'displayName': profile.name,
    'gender': profile.gender.name,
    'avatar': profile.avatar,
    'palette': profile.palette.name,
    'schoolYear': profile.schoolYear,
  };

  static Map<String, dynamic> attemptPayload(
    String curriculum, {
    required String unitId,
    required int contentVersion,
    required bool completed,
    required int effortStars,
    required String completedAt,
    required String clientAttemptId,
    required Map<String, String> objectives,
  }) => {
    'curriculum': curriculum,
    'unitId': unitId,
    'contentVersion': contentVersion,
    'completed': completed,
    'effortStars': effortStars,
    'completedAt': completedAt,
    'clientAttemptId': clientAttemptId,
    'objectives': objectives,
  };

  static Map<String, dynamic> decode(OutboxRow row) =>
      Map<String, dynamic>.from(jsonDecode(row.payloadJson) as Map);

  /// The entry for [entityKey] that may still be rewritten.
  Future<OutboxRow?> _open(String entityKey) =>
      (db.select(db.outbox)
            ..where(
              (t) =>
                  t.entityId.equals(entityKey) &
                  t.status.equals('pending') &
                  t.tries.equals(0),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.seq)])
            ..limit(1))
          .getSingleOrNull();

  Future<void> _add(String entityKey, Map<String, dynamic> mutation) => db
      .into(db.outbox)
      .insert(
        OutboxCompanion.insert(
          mutationId: Ids.uuidV7(),
          entity: mutation['entity'] as String,
          op: mutation['op'] as String,
          entityId: entityKey,
          baseVersion: Value(mutation['baseVersion'] as int?),
          payloadJson: jsonEncode(mutation),
          createdAt: DateTime.now().toUtc(),
        ),
      );

  Future<void> _rewrite(OutboxRow row, Map<String, dynamic> mutation) =>
      (db.update(db.outbox)..where((t) => t.seq.equals(row.seq))).write(
        OutboxCompanion(
          op: Value(mutation['op'] as String),
          payloadJson: Value(jsonEncode(mutation)),
          baseVersion: Value(mutation['baseVersion'] as int?),
          // Idempotency is per mutation ID, so new content needs a new ID.
          mutationId: Value(Ids.uuidV7()),
        ),
      );

  Future<void> _dropOpen(String entityKey) =>
      (db.delete(db.outbox)..where(
            (t) =>
                t.entityId.equals(entityKey) &
                t.status.equals('pending') &
                t.tries.equals(0),
          ))
          .go();

  // ---- children --------------------------------------------------------------

  Future<void> childCreate(
    String childId,
    Map<String, dynamic> fields,
    Map<String, dynamic> settings,
  ) => _add(childKey(childId), {
    'entity': 'child',
    'op': 'create',
    'id': childId,
    'payload': {..._withoutYearOne(fields), 'settings': settings},
  });

  /// A child in Year 1 is created without `schoolYear`: servers from before
  /// school years refuse fields they do not know, and every server takes a
  /// child without one as Year 1 (ADR-0021). A changed year is always sent.
  static Map<String, dynamic> _withoutYearOne(Map<String, dynamic> fields) => {
    for (final e in fields.entries)
      if (!(e.key == 'schoolYear' && e.value == 'y1')) e.key: e.value,
  };

  Future<void> childPatch(
    String childId, {
    required Map<String, dynamic> changed,
    required Map<String, dynamic> before,
    required int baseVersion,
  }) => _patch(
    childKey(childId),
    {'entity': 'child', 'op': 'patch', 'id': childId},
    changed,
    before,
    baseVersion,
    fold: (create) => {
      ...create,
      'payload': _withoutYearOne({
        ...Map<String, dynamic>.from(create['payload'] as Map),
        ...changed,
      }),
    },
    create: childKey(childId),
  );

  Future<void> settingsPatch(
    String childId, {
    required Map<String, dynamic> changed,
    required Map<String, dynamic> before,
    required int baseVersion,
  }) => _patch(
    settingsKey(childId),
    {'entity': 'settings', 'op': 'patch', 'childId': childId},
    changed,
    before,
    baseVersion,
    fold: (create) {
      final payload = Map<String, dynamic>.from(create['payload'] as Map);
      return {
        ...create,
        'payload': {
          ...payload,
          'settings': {
            ...Map<String, dynamic>.from(payload['settings'] as Map),
            ...changed,
          },
        },
      };
    },
    create: childKey(childId),
  );

  /// The account's settings for the child become [settings], whatever they
  /// were (no `base`: the server keeps the later change). Used when linking.
  Future<void> settingsReplace(String childId, Map<String, dynamic> settings) =>
      _add(settingsKey(childId), {
        'entity': 'settings',
        'op': 'patch',
        'childId': childId,
        'baseVersion': 0,
        'payload': settings,
      });

  /// [fold] puts the change into the child's create when that has not been
  /// sent yet (the server has nothing to patch then); a settings patch
  /// queued with the create gets the change too, or it would undo it.
  Future<void> _patch(
    String entityKey,
    Map<String, dynamic> head,
    Map<String, dynamic> changed,
    Map<String, dynamic> before,
    int baseVersion, {
    required Map<String, dynamic> Function(Map<String, dynamic>) fold,
    required String create,
  }) async {
    if (changed.isEmpty) return;
    final unsent = await _open(create);
    final folded = unsent != null && unsent.op == 'create';
    if (folded) await _rewrite(unsent, fold(decode(unsent)));
    final open = await _open(entityKey);
    if (open == null || open.op != 'patch') {
      if (folded) return;
      return _add(entityKey, {
        ...head,
        'baseVersion': baseVersion,
        'payload': changed,
        'base': {for (final k in changed.keys) k: before[k]},
      });
    }
    final old = decode(open);
    final base = old['base'] == null
        ? null
        : Map<String, dynamic>.from(old['base'] as Map);
    if (base != null) {
      for (final k in changed.keys) {
        base.putIfAbsent(k, () => before[k]);
      }
    }
    await _rewrite(open, {
      ...old,
      'payload': {
        ...Map<String, dynamic>.from(old['payload'] as Map),
        ...changed,
      },
      'base': ?base,
    });
  }

  /// Everything still waiting for the child is replaced by its deletion; a
  /// child the server never received needs no request at all.
  Future<void> childDelete(String childId) async {
    final unsent = await _open(childKey(childId));
    await dropChild(childId, unsentOnly: true);
    if (unsent != null && unsent.op == 'create') return;
    await _add(childKey(childId), {
      'entity': 'child',
      'op': 'delete',
      'id': childId,
    });
  }

  /// Removes the child's entries ([unsentOnly]: only those never sent).
  Future<void> dropChild(String childId, {bool unsentOnly = false}) =>
      (db.delete(db.outbox)..where((t) {
            final ofChild =
                t.entityId.equals(childKey(childId)) |
                t.entityId.equals(settingsKey(childId)) |
                t.entityId.like('journey:$childId:%') |
                t.entityId.like('usage:$childId:%') |
                (t.entity.equals('attempt') &
                    t.payloadJson.like('%"childId":"$childId"%'));
            return unsentOnly
                ? ofChild & t.status.equals('pending') & t.tries.equals(0)
                : ofChild;
          }))
          .go();

  // ---- progress --------------------------------------------------------------

  Future<void> attemptCreate(
    String childId,
    String attemptId,
    Map<String, dynamic> payload,
  ) => _add(attemptKey(attemptId), {
    'entity': 'attempt',
    'op': 'create',
    'id': attemptId,
    'childId': childId,
    'payload': payload,
  });

  Future<void> attemptDelete(String childId, String attemptId) async {
    final unsent = await _open(attemptKey(attemptId));
    if (unsent != null && unsent.op == 'create') {
      return _dropOpen(attemptKey(attemptId));
    }
    await _add(attemptKey(attemptId), {
      'entity': 'attempt',
      'op': 'delete',
      'id': attemptId,
      'childId': childId,
    });
  }

  /// [baseVersion] is informational: the sync engine sends the journey's
  /// current local version, which already includes every merge.
  Future<void> journeyPut(
    String childId,
    String curriculum,
    String key,
    Map<String, dynamic> state, {
    required int baseVersion,
  }) async {
    final entityKey = journeyKey(childId, curriculum, key);
    final mutation = <String, dynamic>{
      'entity': 'journey',
      'op': 'put',
      'childId': childId,
      'curriculum': curriculum,
      'key': key,
      'baseVersion': baseVersion,
      'payload': {'state': state, 'contentVersion': null},
    };
    final open = await _open(entityKey);
    if (open == null) return _add(entityKey, mutation);
    await _rewrite(open, mutation);
  }

  Future<void> journeyDelete(
    String childId,
    String curriculum,
    String key,
  ) async {
    final entityKey = journeyKey(childId, curriculum, key);
    await _dropOpen(entityKey);
    await _add(entityKey, {
      'entity': 'journey',
      'op': 'delete',
      'childId': childId,
      'curriculum': curriculum,
      'key': key,
    });
  }

  /// This device's play time for one day (the server keeps the larger value).
  Future<void> usagePut(String childId, String day, int seconds) async {
    final entityKey = usageKey(childId, day);
    final mutation = {
      'entity': 'usage',
      'op': 'put',
      'childId': childId,
      'day': day,
      'payload': {'seconds': seconds.clamp(0, 86400)},
    };
    final open = await _open(entityKey);
    if (open == null) return _add(entityKey, mutation);
    await _rewrite(open, mutation);
  }

  // ---- sending ---------------------------------------------------------------

  /// The oldest waiting entries, marked as being sent.
  Future<List<OutboxRow>> takeBatch({int limit = 100}) =>
      db.transaction(() async {
        final rows =
            await (db.select(db.outbox)
                  ..where((t) => t.status.equals('pending'))
                  ..orderBy([(t) => OrderingTerm(expression: t.seq)])
                  ..limit(limit))
                .get();
        if (rows.isEmpty) return rows;
        await (db.update(db.outbox)
              ..where((t) => t.seq.isIn([for (final r in rows) r.seq])))
            .write(const OutboxCompanion(status: Value('inflight')));
        return rows;
      });

  /// Entries whose outcome is unknown go back to the queue, marked as sent.
  Future<void> release(Iterable<int> seqs, String reason) => db.customUpdate(
    "UPDATE outbox SET status = 'pending', tries = tries + 1, last_error = ? "
    'WHERE seq IN (${List.filled(seqs.length, '?').join(', ')})',
    variables: [
      Variable.withString(reason),
      for (final s in seqs) Variable.withInt(s),
    ],
    updates: {db.outbox},
  );

  /// Entries taken but not sent (the batch was too large) wait again.
  Future<void> untake(List<int> seqs) =>
      (db.update(db.outbox)..where((t) => t.seq.isIn(seqs))).write(
        const OutboxCompanion(status: Value('pending')),
      );

  /// After a crash during a push nothing is known about entries being sent.
  Future<void> releaseInflight() => db.customUpdate(
    "UPDATE outbox SET status = 'pending', tries = tries + 1 "
    "WHERE status = 'inflight'",
    updates: {db.outbox},
  );

  Future<void> remove(int seq) =>
      (db.delete(db.outbox)..where((t) => t.seq.equals(seq))).go();

  /// Kept, visible to parents, and sent again only when they ask: a rejected
  /// change is never dropped silently.
  Future<void> quarantine(int seq, String reason) =>
      (db.update(db.outbox)..where((t) => t.seq.equals(seq))).write(
        OutboxCompanion(
          status: const Value('quarantined'),
          lastError: Value(reason),
        ),
      );

  Future<void> retryQuarantined() =>
      (db.update(db.outbox)..where((t) => t.status.equals('quarantined')))
          .write(const OutboxCompanion(status: Value('pending')));

  Future<List<OutboxRow>> quarantined() =>
      (db.select(db.outbox)
            ..where((t) => t.status.equals('quarantined'))
            ..orderBy([(t) => OrderingTerm(expression: t.seq)]))
          .get();

  /// Entries not yet confirmed by the server (waiting or being sent).
  Future<int> waitingCount() async {
    final count = db.outbox.seq.count();
    final row =
        await (db.selectOnly(db.outbox)
              ..addColumns([count])
              ..where(db.outbox.status.isIn(['pending', 'inflight'])))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> clear() => db.delete(db.outbox).go();
}
