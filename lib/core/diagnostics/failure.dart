import 'package:hive/hive.dart';

import 'failure_io_stub.dart' if (dart.library.io) 'failure_io.dart';

/// The real category of a failure, so the message shown to the user matches
/// what went wrong (AUD-009). Previously every failure said "free some space".
enum FailureKind {
  /// The device has no space left to write.
  storageFull,

  /// Storage could not be opened or written for another platform reason.
  storageUnavailable,

  /// Saved data has an unexpected shape and could not be read or updated.
  corruptData,

  /// A defect in the game itself.
  unexpected,
}

FailureKind classifyFailure(Object error) {
  final platform = classifyPlatformFailure(error);
  if (platform != null) return platform;
  if (error is HiveError) return FailureKind.storageUnavailable;
  if (error is FormatException || error is TypeError) {
    return FailureKind.corruptData;
  }
  return FailureKind.unexpected;
}

/// Child-facing explanation of a failed save. The child UI is English
/// (see docs/ARCHITECTURE_DECISIONS.md, ADR-0004).
String saveFailureMessage(FailureKind kind) => switch (kind) {
  FailureKind.storageFull => 'Could not save: this device is full. Ask a grown-up to free some space, then try again.',
  FailureKind.storageUnavailable => 'Could not save right now because the device storage is busy. Please try again.',
  FailureKind.corruptData => 'Could not save because some saved data looks damaged. Your last saved step is safe. Ask a grown-up to check the parent area.',
  FailureKind.unexpected => 'Could not save because of a problem in the game. Your last saved step is safe. Please try again.',
};
