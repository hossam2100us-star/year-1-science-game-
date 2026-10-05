/// Stable identifiers for migrating the first illustrated garden save format.
/// This unlocks the next adventure without inventing a whole-unit assessment.
const gardenDiscoveryIds = {
  'cat',
  'tree',
  'car',
  'plant',
  'chair',
  'bird',
  'cloud',
};

bool gardenResultsComplete(Object? results) =>
    results is Map &&
    gardenDiscoveryIds.every(
      (id) =>
          const ['firstTry', 'afterHint', 'explained'].contains(results[id]),
    );

bool gardenAdventureComplete(Map<String, dynamic>? journey) {
  if (journey == null || journey['version'] != 1) return false;
  if (journey['needsCorrection'] == true && journey['completedOnce'] != true) {
    return false;
  }
  if (journey['completedOnce'] == true ||
      gardenResultsComplete(journey['results'])) {
    return true;
  }
  final history = journey['history'];
  return history is List &&
      history.any(
        (round) => round is Map && gardenResultsComplete(round['results']),
      );
}
