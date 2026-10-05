import 'dart:io';

import 'failure.dart';

/// errno / Win32 codes that mean "no space left on the device".
const _diskFullCodes = {
  28, // ENOSPC (Linux, Android, macOS)
  39, // ERROR_HANDLE_DISK_FULL (Windows)
  112, // ERROR_DISK_FULL (Windows)
};

FailureKind? classifyPlatformFailure(Object error) {
  if (error is FileSystemException) {
    return _diskFullCodes.contains(error.osError?.errorCode)
        ? FailureKind.storageFull
        : FailureKind.storageUnavailable;
  }
  return null;
}
