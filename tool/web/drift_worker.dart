// The web worker that runs the app's SQLite database in the browser
// (drift's WasmDatabase). Compiled to web/drift_worker.js with
//   scripts/build_drift_worker.ps1
// and committed; rebuild it whenever drift is upgraded.
import 'package:drift/wasm.dart';

void main() => WasmDatabase.workerMainForOpen();
