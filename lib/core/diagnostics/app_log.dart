import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Privacy-safe local diagnostics (AUD-009, SEC-04).
///
/// Records are kept in a bounded in-memory ring buffer that a parent can copy
/// from the parent area. Nothing is sent anywhere.
///
/// Privacy rules, enforced by construction:
/// * [message] must be a developer-written constant describing the event.
///   Never interpolate child names, photos, emails, passwords, tokens,
///   headers or cookies into it.
/// * For an attached error only its runtime type is stored, never
///   `toString()`: exception messages can echo user data (for example a
///   [FormatException] includes the text it failed to parse).
/// * Stack traces are reduced to a few frames; they contain code locations
///   only.
final class AppLog {
  AppLog._();

  static const capacity = 200;
  static const _stackFrames = 8;
  static final ListQueue<LogEntry> _entries = ListQueue<LogEntry>();
  static bool _attached = false;

  static void _attach() {
    if (_attached) return;
    _attached = true;
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen(_record);
  }

  static void _record(LogRecord record) {
    final entry = LogEntry(
      time: record.time.toUtc(),
      level: record.level.name,
      area: record.loggerName,
      message: record.message,
      errorType: record.error?.runtimeType.toString(),
      stack: _trim(record.stackTrace),
    );
    _entries.addLast(entry);
    while (_entries.length > capacity) {
      _entries.removeFirst();
    }
    if (kDebugMode) debugPrint(entry.format());
  }

  static String? _trim(StackTrace? stack) {
    if (stack == null) return null;
    final lines = stack
        .toString()
        .split('\n')
        .where((l) => l.trim().isNotEmpty);
    return lines.take(_stackFrames).join('\n');
  }

  static Logger _logger(String area) {
    _attach();
    return Logger(area);
  }

  /// A failure the user may notice (a save that did not happen, a screen
  /// that could not open).
  static void error(
    String area,
    String message, [
    Object? error,
    StackTrace? stack,
  ]) => _logger(area).severe(message, error, stack);

  /// A degraded but recoverable condition (narration unavailable, a sound
  /// that did not play, a temporary file that could not be removed).
  static void warning(
    String area,
    String message, [
    Object? error,
    StackTrace? stack,
  ]) => _logger(area).warning(message, error, stack);

  static void info(String area, String message) => _logger(area).info(message);

  /// Snapshot of the buffer, oldest first.
  static List<LogEntry> get entries => List.unmodifiable(_entries);

  /// Plain-text export for the parent area.
  static String export() => _entries.isEmpty
      ? 'No diagnostic events recorded in this session.'
      : _entries.map((e) => e.format()).join('\n\n');

  @visibleForTesting
  static void clear() => _entries.clear();
}

@immutable
class LogEntry {
  const LogEntry({
    required this.time,
    required this.level,
    required this.area,
    required this.message,
    this.errorType,
    this.stack,
  });
  final DateTime time;
  final String level, area, message;
  final String? errorType, stack;

  String format() => [
    '${time.toIso8601String()} $level [$area] $message',
    if (errorType != null) '  error type: $errorType',
    if (stack != null) stack!.split('\n').map((l) => '  $l').join('\n'),
  ].join('\n');
}
