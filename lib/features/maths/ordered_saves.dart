/// Saves a child's touches one at a time, in the order they happened.
///
/// A touch is shown at once and never waits for the save before it: a child
/// counting quickly must not lose an object (on a tablet, seven quick
/// touches once counted three, and the numbers on the apples were out of
/// order). When a save fails, the touches queued after it are dropped with
/// it, and [onFailed] gets the last state that was stored.
class OrderedSaves<T> {
  OrderedSaves(this.saved);

  /// The last state the lesson stored.
  T saved;
  Future<void> _queue = Future.value();
  int _generation = 0;

  void add(
    T next,
    Future<void> Function(T value) save, {
    void Function()? onSaved,
    required void Function(T saved, Object error, StackTrace stack) onFailed,
  }) {
    final generation = _generation;
    _queue = _queue.then((_) async {
      if (generation != _generation) return;
      try {
        await save(next);
        saved = next;
        onSaved?.call();
      } catch (error, stack) {
        _generation++;
        onFailed(saved, error, stack);
      }
    });
  }
}
