import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'diagnostics/app_log.dart';
import 'models.dart';

/// What [ProgressStore.read] had to do to produce usable data (AUD-006).
enum StorageRecovery {
  /// The saved data was read as it is.
  none,

  /// The main copy was unreadable; the last good copy was used instead. The
  /// unreadable copy is preserved for a rescue export.
  restoredFromBackup,
}

/// Thrown when neither the saved data nor its last good copy can be read.
/// Nothing is deleted; the parent can export the raw data or start again
/// while a copy is kept.
class SaveDataUnreadable implements Exception {
  const SaveDataUnreadable(this.cause);
  final Object cause;
  @override
  String toString() => 'SaveDataUnreadable(${cause.runtimeType})';
}

abstract interface class ProgressStore {
  AppData read();
  Future<void> write(AppData data);

  /// How the most recent [read] obtained its data.
  StorageRecovery get recovery;

  /// Every raw copy the store holds, verbatim, as one JSON document for a
  /// parent-initiated rescue export. It contains child names and photos and
  /// must never be logged or sent anywhere automatically.
  String rescueExport();

  /// Whether unreadable copies are being kept for a rescue export.
  bool get hasUnreadableCopies;

  /// Permanently removes the preserved unreadable copies. Only called after a
  /// parent confirmed it behind the parent gate.
  Future<void> discardUnreadableCopies();
}

class HiveProgressStore implements ProgressStore {
  HiveProgressStore(this.box, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final Box<String> box;
  final DateTime Function() _clock;

  static const dataKey = 'data';

  /// The last copy that was written successfully, refreshed at most every
  /// [backupInterval] and whenever private data is removed.
  static const backupKey = 'data.bak';

  /// An unreadable main copy, preserved before anything overwrites it.
  static const unreadableKey = 'data.unreadable';
  static const unreadableBackupKey = 'data.bak.unreadable';
  static const backupInterval = Duration(minutes: 10);

  DateTime? _lastBackup;
  String? _unreadable;
  StorageRecovery _recovery = StorageRecovery.none;

  static Future<HiveProgressStore> open() async {
    await Hive.initFlutter();
    return HiveProgressStore(
      await Hive.openBox<String>(
        'science_adventure_v1',
        compactionStrategy: (entries, deleted) => deleted > 20,
      ),
    );
  }

  static AppData _decode(String raw) =>
      AppData.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));

  @override
  StorageRecovery get recovery => _recovery;

  @override
  AppData read() {
    _recovery = StorageRecovery.none;
    final raw = box.get(dataKey);
    if (raw == null) return const AppData();
    try {
      return _decode(raw);
    } on Object catch (error, stack) {
      AppLog.error('storage', 'Saved data unreadable', error, stack);
      final backup = box.get(backupKey);
      if (backup != null) {
        try {
          final restored = _decode(backup);
          _unreadable = raw;
          _recovery = StorageRecovery.restoredFromBackup;
          AppLog.info('storage', 'Restored the last good copy');
          return restored;
        } on Object catch (backupError, backupStack) {
          AppLog.error(
            'storage',
            'Last good copy unreadable',
            backupError,
            backupStack,
          );
        }
      }
      throw SaveDataUnreadable(error);
    }
  }

  @override
  Future<void> write(AppData data) async {
    // Preserve an unreadable main copy before it is overwritten.
    final unreadable = _unreadable;
    if (unreadable != null) {
      if (box.get(unreadableKey) == null) {
        await box.put(unreadableKey, unreadable);
      }
      _unreadable = null;
    }
    final removedPrivateData = _removesPrivateData(box.get(dataKey), data);
    final json = jsonEncode(data.toJson());
    await box.put(dataKey, json);
    final now = _clock();
    final last = _lastBackup;
    if (removedPrivateData ||
        last == null ||
        now.difference(last) >= backupInterval) {
      // Refreshing on removal keeps a deleted child or photo out of the
      // backup as well.
      await box.put(backupKey, json);
      _lastBackup = now;
    }
    if (removedPrivateData) await box.compact();
    await box.flush();
  }

  /// Whether [next] drops a child or changes a photo compared with the
  /// stored copy, so the append-only file must be compacted to purge it.
  bool _removesPrivateData(String? previous, AppData next) {
    if (previous == null) return false;
    final Map<String, Object?> before;
    try {
      final old = _decode(previous);
      before = {...old.childRecords, ...old.quarantinedChildren};
    } on Object {
      // The previous copy is unreadable (and already preserved): compact.
      return true;
    }
    final after = {...next.childRecords, ...next.quarantinedChildren};
    return before.entries.any(
      (entry) =>
          !after.containsKey(entry.key) ||
          _photo(entry.value) != _photo(after[entry.key]),
    );
  }

  static Object? _photo(Object? record) => record is Map
      ? (record['profile'] is Map ? record['profile']['photo'] : null)
      : null;

  @override
  String rescueExport() => jsonEncode({
    'format': 'science-adventure-rescue-v1',
    'exportedAt': _clock().toUtc().toIso8601String(),
    'data': box.get(dataKey),
    'lastGoodCopy': box.get(backupKey),
    'unreadableCopy': box.get(unreadableKey) ?? _unreadable,
    'unreadableLastGoodCopy': box.get(unreadableBackupKey),
  });

  /// Starts again with empty data after the parent confirmed it, keeping the
  /// unreadable copies so they can still be exported later.
  Future<void> startAgainKeepingCopy() async {
    final raw = box.get(dataKey);
    if (raw != null && box.get(unreadableKey) == null) {
      await box.put(unreadableKey, raw);
    }
    final backup = box.get(backupKey);
    if (backup != null && box.get(unreadableBackupKey) == null) {
      await box.put(unreadableBackupKey, backup);
    }
    await box.delete(dataKey);
    await box.delete(backupKey);
    await box.flush();
    _unreadable = null;
    _lastBackup = null;
    _recovery = StorageRecovery.none;
  }

  @override
  bool get hasUnreadableCopies =>
      _unreadable != null ||
      box.get(unreadableKey) != null ||
      box.get(unreadableBackupKey) != null;

  @override
  Future<void> discardUnreadableCopies() async {
    _unreadable = null;
    await box.delete(unreadableKey);
    await box.delete(unreadableBackupKey);
    await box.compact();
    await box.flush();
  }
}

class MemoryProgressStore implements ProgressStore {
  MemoryProgressStore([this.data = const AppData()]);
  AppData data;
  @override
  AppData read() => data;
  @override
  Future<void> write(AppData value) async {
    data = value;
  }

  @override
  StorageRecovery get recovery => StorageRecovery.none;

  @override
  String rescueExport() => jsonEncode({
    'format': 'science-adventure-rescue-v1',
    'data': jsonEncode(data.toJson()),
  });

  @override
  bool get hasUnreadableCopies => false;

  @override
  Future<void> discardUnreadableCopies() async {}
}
