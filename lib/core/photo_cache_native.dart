import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<void> removeTemporaryPhoto(String path) async {
  try {
    final cache = await (await getTemporaryDirectory()).resolveSymbolicLinks();
    final file = File(path);
    final canonical = await file.resolveSymbolicLinks();
    // Never delete the parent's original gallery image or anything outside app cache.
    if (canonical.startsWith('$cache${Platform.pathSeparator}'))
      await file.delete();
  } catch (_) {
    // A missing cache file must not discard a successfully imported avatar.
  }
}
