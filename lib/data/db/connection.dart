// How the app's SQLite database is opened: drift_flutter on Android, drift's
// WebAssembly build in the browser.
export 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';
