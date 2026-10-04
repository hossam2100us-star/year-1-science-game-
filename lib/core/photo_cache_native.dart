import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'diagnostics/app_log.dart';

Future<void> removeTemporaryPhoto(String path) async {
  try {
    final cache = await (await getTemporaryDirectory()).resolveSymbolicLinks();
    final file = File(path);
    final canonical = await file.resolveSymbolicLinks();
    // Never delete the parent's original gallery image or anything outside app cache.
    if (canonical.startsWith('$cache${Platform.pathSeparator}'))
      await file.delete();
  } catch (error, stack) {
    // A missing cache file must not discard a successfully imported avatar.
    AppLog.warning(
      'photo',
      'Temporary photo copy was not removed',
      error,
      stack,
    );
  }
}
