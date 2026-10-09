/// Merging two copies of a journey (in-progress lesson state, or another
/// per-child progress record) that two devices changed independently.
///
/// Future System Architecture §14, "progress-monotonic merge":
/// - the child never goes backwards: the further position wins;
/// - every finished step from either copy is kept (union of responses);
/// - when both copies answered the same step, the server's copy is kept: it
///   reached the server first, so it is the first recorded outcome (the same
///   rule as `AttemptRecorder`, which prevents score inflation);
/// - the losing side's unfinished step (transient UI state) is dropped.
///
/// Records that are not lesson journeys (discovery results, the review
/// schedule) are merged key by key: nested maps are merged recursively,
/// keys present on one side only are kept, and for a value both sides hold
/// the server's wins. Pure functions, no I/O.
library;

Map<String, dynamic> mergeJourney(
  Map<String, dynamic> local,
  Map<String, dynamic> server,
) {
  if (_isLessonJourney(local) && _isLessonJourney(server)) {
    return _mergeLesson(local, server);
  }
  return mergeRecords(local, server);
}

bool _isLessonJourney(Map<String, dynamic> j) =>
    j['index'] is int && j['responses'] is Map && j['attemptId'] is String;

int _progress(Map<String, dynamic> j) => j['index'] as int;

Map<String, dynamic> _mergeLesson(
  Map<String, dynamic> local,
  Map<String, dynamic> server,
) {
  // Two different runs through the lesson cannot be mixed step by step: the
  // run that got further is kept (finished runs are separate attempts).
  if (local['attemptId'] != server['attemptId']) {
    final l = _progress(local);
    final s = _progress(server);
    final lr = (local['responses'] as Map).length;
    final sr = (server['responses'] as Map).length;
    return (l > s || (l == s && lr > sr)) ? local : server;
  }
  final ahead = _progress(local) > _progress(server) ? local : server;
  final responses = <String, dynamic>{
    ...Map<String, dynamic>.from(local['responses'] as Map),
    ...Map<String, dynamic>.from(server['responses'] as Map),
  };
  return {...ahead, 'responses': responses};
}

/// Key-by-key union; the server's value wins where both hold a non-map value.
Map<String, dynamic> mergeRecords(
  Map<String, dynamic> local,
  Map<String, dynamic> server,
) {
  final out = <String, dynamic>{...local};
  for (final entry in server.entries) {
    final mine = local[entry.key];
    final theirs = entry.value;
    if (mine is Map && theirs is Map) {
      out[entry.key] = mergeRecords(
        Map<String, dynamic>.from(mine),
        Map<String, dynamic>.from(theirs),
      );
    } else {
      out[entry.key] = theirs;
    }
  }
  return out;
}
