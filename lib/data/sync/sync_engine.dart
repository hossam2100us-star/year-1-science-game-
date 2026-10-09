import 'dart:async';
import 'dart:convert';

import '../../core/diagnostics/app_log.dart';
import '../remote/api_client.dart';
import '../remote/api_errors.dart';
import 'sync_store.dart';

/// Why a sync stopped early. Play is never affected: everything waits in
/// the outbox and the next sync tries again.
enum SyncFailure {
  /// No connection, or the server could not be reached.
  offline,

  /// The session ended; the parent signs in again.
  signedOut,

  /// The account's email address is not confirmed yet.
  emailNotVerified,

  /// The server is busy, in maintenance or failing; try again later.
  unavailable,

  /// Something this version of the app did not expect (logged, no data).
  unexpected,
}

/// How the engine touches local data. Both run between the app's saves
/// (`AppController.exclusive` / `applyExternal`), never during one.
typedef Exclusive = Future<T> Function<T>(Future<T> Function() action);
typedef ApplyExternal = Future<bool> Function(Future<bool> Function() apply);

/// One sync: push every waiting change (batches of at most 100, one request
/// at a time), then pull everything new since the last cursor and apply it
/// in one transaction (Future System Architecture §12).
class SyncEngine {
  SyncEngine({
    required this.store,
    required this.client,
    required this.userId,
    required this.exclusive,
    required this.applyExternal,
  });

  final SyncStore store;
  final ApiClient client;
  final String userId;
  final Exclusive exclusive;
  final ApplyExternal applyExternal;

  /// The push body is limited to 1 MB; stay well below it.
  static const maxBatchBytes = 768 * 1024;
  static const maxBatch = 100;
  static const pageSize = 500;

  /// Conflicts are merged and sent again; this bounds that loop per sync.
  static const maxRounds = 20;

  Future<SyncFailure?>? _running;

  /// Runs a sync, or joins the one already running. Returns null on success.
  Future<SyncFailure?> run() =>
      _running ??= _run().whenComplete(() => _running = null);

  Future<SyncFailure?> _run() async {
    try {
      await applyExternal(() => store.useAccount(userId));
      await exclusive(store.outbox.releaseInflight);
      for (var round = 0; round < maxRounds; round++) {
        final sent = await _pushBatch();
        if (sent == null) break;
        if (!sent) return _failure;
      }
      final failure = await _pull();
      if (failure != null) return failure;
      await store.markSynced(DateTime.now());
      return null;
    } on Object catch (error, stack) {
      AppLog.error('sync', 'Sync failed', error, stack);
      return SyncFailure.unexpected;
    }
  }

  SyncFailure? _failure;

  /// Sends one batch. Null when nothing was waiting; false when it failed.
  Future<bool?> _pushBatch() async {
    final batch = await exclusive(() async {
      final rows = await store.outbox.takeBatch(limit: maxBatch);
      final all = await store.mutations(rows);
      var bytes = 0;
      var keep = 0;
      for (final m in all) {
        bytes += utf8.encode(jsonEncode(m)).length;
        if (keep > 0 && bytes > maxBatchBytes) break;
        keep++;
      }
      if (keep < rows.length) {
        await store.outbox.untake([for (final r in rows.skip(keep)) r.seq]);
      }
      return (
        rows: rows.take(keep).toList(),
        mutations: all.take(keep).toList(),
      );
    });
    if (batch.rows.isEmpty) return null;
    final List<Map<String, dynamic>> results;
    try {
      results = await client.push(batch.mutations);
    } on Object catch (error) {
      // The server may or may not have applied them: they are sent again
      // with the same mutation IDs, which the server recognises.
      await exclusive(
        () => store.outbox.release([
          for (final r in batch.rows) r.seq,
        ], _reason(error)),
      );
      _failure = _classify(error);
      return false;
    }
    await applyExternal(() => store.applyResults(batch.rows, results));
    return true;
  }

  Future<SyncFailure?> _pull() async {
    final start = await store.cursor();
    var cursor = start;
    final changes = <Map<String, dynamic>>[];
    var restarted = false;
    while (true) {
      final PullPage page;
      try {
        page = await client.pull(cursor, limit: pageSize);
      } on ApiProblem catch (error) {
        if (error.status == 410 && !restarted) {
          // Offline for longer than the server keeps deletions: start over.
          restarted = true;
          cursor = 0;
          changes.clear();
          continue;
        }
        return _classify(error);
      } on Object catch (error) {
        return _classify(error);
      }
      changes.addAll(page.changes);
      cursor = page.cursor;
      if (!page.hasMore) break;
    }
    if (changes.isEmpty && cursor == start && !restarted) return null;
    await applyExternal(
      () => store.applyChanges(changes, cursor, complete: restarted),
    );
    return null;
  }

  static String _reason(Object error) => switch (error) {
    ApiProblem(:final code) => code,
    NetworkFailure() => 'offline',
    SignedOut() => 'signed_out',
    _ => 'unexpected',
  };

  static SyncFailure _classify(Object error) {
    switch (error) {
      case NetworkFailure():
        return SyncFailure.offline;
      case SignedOut():
        return SyncFailure.signedOut;
      case ApiProblem(status: 401):
        return SyncFailure.signedOut;
      case ApiProblem(status: 403, code: 'email_not_verified'):
        return SyncFailure.emailNotVerified;
      case ApiProblem(:final status) when status == 429 || status >= 500:
        return SyncFailure.unavailable;
      case ApiProblem(:final status, :final code):
        AppLog.warning('sync', 'Unexpected answer $status $code');
        return SyncFailure.unexpected;
      default:
        AppLog.warning('sync', 'Unexpected sync error ${error.runtimeType}');
        return SyncFailure.unexpected;
    }
  }
}
