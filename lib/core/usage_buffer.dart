import 'dart:async';

/// Collects contiguous play time and writes it as one span (AUD-004).
///
/// Writing on every 10-second tick saved the whole state 360 times an hour.
/// Spans are written when they reach [flushEvery], when play stops, or when
/// the next span is not contiguous or belongs to another child. Each span
/// remembers its child, so a switch can never credit time to the wrong one.
class UsageBuffer {
  UsageBuffer(this._write, {this.flushEvery = const Duration(seconds: 60)});

  final Future<void> Function(String owner, DateTime from, DateTime to) _write;
  final Duration flushEvery;

  DateTime? _from, _to;
  String? _owner;

  /// Unsaved play time currently held in memory.
  Duration get pending =>
      _from == null ? Duration.zero : _to!.difference(_from!);

  /// Adds one tick. Returns a write that has started, if any, so the caller
  /// can report a failure.
  Future<void>? add(DateTime from, DateTime to, String owner) {
    Future<void>? started;
    if (_owner != owner || _to != from) {
      started = flush();
      _from = from;
      _owner = owner;
    }
    _to = to;
    if (to.difference(_from!) >= flushEvery) started = flush();
    return started;
  }

  /// Writes and clears the pending span. A failed write is reported to the
  /// caller; the span is not retried to avoid counting time twice.
  Future<void> flush() async {
    final (from, to, owner) = (_from, _to, _owner);
    _from = _to = _owner = null;
    if (from == null || to == null || owner == null) return;
    await _write(owner, from, to);
  }
}
