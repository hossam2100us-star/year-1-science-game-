import 'failure.dart';

/// Web has no `dart:io` file errors; storage errors arrive as Hive errors.
FailureKind? classifyPlatformFailure(Object error) => null;
